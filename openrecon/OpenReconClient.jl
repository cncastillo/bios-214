module OpenReconClient

using Sockets
using KomaMRIFiles: MRIFiles

export start, recon, stop, reconstruct, recon_docker

struct Server
    container::String
    port::Int
    image::String
end

const server = Ref{Union{Nothing,Server}}(nothing)

function send_raw(socket, raw, config)
    name = zeros(UInt8, 1024)
    name[1:ncodeunits(config)] .= codeunits(config)
    write(socket, UInt16(1), name)
    xml = MRIFiles.GeneralParametersToXML(deepcopy(raw.params)) * '\0'
    write(socket, UInt16(3), UInt32(ncodeunits(xml)), xml)
    for profile in raw.profiles
        header = IOBuffer()
        write(header, profile.head)
        write(socket, UInt16(1008), take!(header), profile.traj, profile.data)
    end
    write(socket, UInt16(4))
end

function receive_image(socket)
    header = IOBuffer(read(socket, 198))
    seek(header, 2)
    read(header, UInt16) == 5 || error("Expected a Float32 image from this reconstruction")
    seek(header, 16)
    matrix = ntuple(_ -> Int(read(header, UInt16)), 3)
    fov_mm = ntuple(_ -> read(header, Float32), 3)
    channels = Int(read(header, UInt16))
    matrix[3] == channels == 1 || error("Expected one 2D magnitude image")
    metadata = String(read(socket, Int(read(socket, UInt64))))
    pixels = Vector{Float32}(undef, prod(matrix) * channels)
    read!(socket, pixels)
    image = permutedims(reshape(pixels, matrix[1], matrix[2]))
    return (; image, fov_mm, metadata)
end

"""Send Koma RawAcquisitionData unchanged and return the MRD images as Julia arrays."""
function reconstruct(raw; host=ip"127.0.0.1", port=9002, config="bios214radial", timeout=180)
    socket = connect(host, port)
    timer = Timer(_ -> close(socket), timeout)
    sender = @async try
        send_raw(socket, raw, config)
    catch
        close(socket)
        rethrow()
    end
    images = @NamedTuple{image::Matrix{Float32}, fov_mm::NTuple{3,Float32}, metadata::String}[]
    try
        while true
            message = read(socket, UInt16)
            message == 4 && break
            if message == 1022
                push!(images, receive_image(socket))
            elseif message == 5
                @info rstrip(String(read(socket, Int(read(socket, UInt32)))), '\0')
            else
                error("Unexpected MRD message: $message")
            end
        end
        wait(sender)
        isempty(images) && error("The MRD server returned no images")
        return images
    finally
        close(timer)
        close(socket)
    end
end

"""Start one OpenRecon container, or reuse it if already started. Accepts a local or GHCR image."""
function start(; image=nothing)
    current = server[]
    if current !== nothing
        image === nothing || image == current.image ||
            error("OpenRecon is already running; call OpenReconClient.stop() before changing images")
        return nothing
    end
    image = something(image, "openrecon_research_bios214radial:v0.1.2")
    container = strip(read(`docker run --rm -d --platform linux/amd64
                            -p 127.0.0.1::9002 $image`, String))
    try
        ready = timedwait(() -> occursin("Serving...", read(`docker logs $container`, String)),
                          60; pollint=0.5)
        ready == :ok || error("MRD server did not start")
        address = strip(read(`docker port $container 9002/tcp`, String))
        port = parse(Int, last(split(address, ':')))
        server[] = Server(container, port, image)
    catch
        @error "OpenRecon container output" log=read(ignorestatus(`docker logs $container`), String)
        run(ignorestatus(`docker stop $container`))
        rethrow()
    end
    return nothing
end

"""Reconstruct raw data using the running server and return one Float32[y,x] matrix."""
function recon(raw; timeout=180)
    current = server[]
    current === nothing && error("Call OpenReconClient.start() before OpenReconClient.recon(raw)")
    try
        return only(reconstruct(raw; port=current.port, timeout)).image
    catch
        @error "OpenRecon container output" log=read(ignorestatus(`docker logs $(current.container)`), String)
        rethrow()
    end
end

"""Stop the container started by this client. Safe to call more than once."""
function stop()
    current = server[]
    current === nothing && return nothing
    run(`docker stop $(current.container)`)
    server[] = nothing
    return nothing
end

"""Reconstruct once, starting and stopping a container only if none is already running."""
function recon_docker(raw; image=nothing)
    temporary = server[] === nothing
    start(; image)
    try
        return recon(raw)
    finally
        temporary && stop()
    end
end

end
