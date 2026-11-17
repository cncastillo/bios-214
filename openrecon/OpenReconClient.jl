module OpenReconClient
using Sockets
using KomaMRIFiles: MRIFiles
export start, recon, stop

const server = Ref{Any}(nothing)
const MRD_MESSAGE_CONFIG_FILE = UInt16(1)
const MRD_MESSAGE_METADATA_XML_TEXT = UInt16(3)
const MRD_MESSAGE_CLOSE = UInt16(4)
const MRD_MESSAGE_TEXT = UInt16(5)
const MRD_MESSAGE_ISMRMRD_ACQUISITION = UInt16(1008)
const MRD_MESSAGE_ISMRMRD_IMAGE = UInt16(1022)
const MRD_CONFIG_NAME_LENGTH = 1024
const ISMRMRD_IMAGE_HEADER_SIZE = 198
const ISMRMRD_DATA_TYPES = (UInt16, Int16, UInt32, Int32, Float32, Float64, ComplexF32, ComplexF64)
const ISMRMRD_IMAGE_HEADER = (
    version=UInt16, data_type=UInt16, flags=UInt64, measurement_uid=UInt32,
    matrix_size=NTuple{3,UInt16}, field_of_view=NTuple{3,Float32}, channels=UInt16,
    position=NTuple{3,Float32}, read_dir=NTuple{3,Float32}, phase_dir=NTuple{3,Float32},
    slice_dir=NTuple{3,Float32}, patient_table_position=NTuple{3,Float32},
    average=UInt16, slice=UInt16, contrast=UInt16, phase=UInt16, repetition=UInt16, set=UInt16,
    acquisition_time_stamp=UInt32, physiology_time_stamp=NTuple{3,UInt32},
    image_type=UInt16, image_index=UInt16, image_series_index=UInt16,
    user_int=NTuple{8,Int32}, user_float=NTuple{8,Float32}, attribute_string_len=UInt32,
)

_running(container) = strip(read(pipeline(ignorestatus(`docker inspect --format "{{.State.Running}}" $container`); stderr=devnull), String)) == "true"
function _ready(port)
    socket = try connect(ip"127.0.0.1", port) catch; return false end
    probe = @async try eof(socket) catch; true end
    try
        return timedwait(() -> istaskdone(probe), 0.1; pollint=0.01) == :timed_out || !fetch(probe)
    finally
        close(socket)
        wait(probe)
    end
end

function start(; image=nothing, port=nothing)
    current = server[]
    if current !== nothing && _running(current.container)
        (image === nothing || image == current.image) && (port === nothing || port == current.port) ||
            error("Call OpenReconClient.stop() before changing image or port")
        _ready(current.port) || error("OpenRecon is not accepting TCP connections")
        return nothing
    end
    image = something(image, current === nothing ? "ghcr.io/mcgrathcm/bios214-radial:0.1.2-build-3" : current.image)
    server[] = nothing
    container = strip(read(`docker run --rm -d --platform linux/amd64 -p 127.0.0.1:$(something(port, "")):9002 $image`, String))
    try
        port = parse(Int, last(split(strip(read(`docker port $container 9002/tcp`, String)), ':')))
        ready = timedwait(60; pollint=0.5) do
            _running(container) || error("OpenRecon container exited during startup")
            _ready(port)
        end
        ready == :ok || error("OpenRecon did not start accepting TCP connections")
        server[] = (; container, port, image)
    catch
        @error "OpenRecon" log=read(ignorestatus(`docker logs $container`), String)
        run(ignorestatus(`docker stop $container`))
        rethrow()
    end
    return nothing
end

function _image(socket)
    io = IOBuffer(read(socket, ISMRMRD_IMAGE_HEADER_SIZE))
    header = map(T -> read(io, T), ISMRMRD_IMAGE_HEADER)
    1 <= header.data_type <= length(ISMRMRD_DATA_TYPES) || error("Unsupported MRD data type: $(header.data_type)")
    T = ISMRMRD_DATA_TYPES[Int(header.data_type)]
    metadata = rstrip(String(read(socket, Int(read(socket, UInt64)))), '\0')
    pixels = Array{T}(undef, Int.(header.matrix_size)..., Int(header.channels))
    read!(socket, pixels)
    return (; image=permutedims(pixels, (4, 3, 2, 1)), header, metadata)
end

function recon(raw; config="bios214radial", config_additional=nothing, full=false, timeout=180)
    current = server[]
    current === nothing && error("Call OpenReconClient.start() first")
    socket = connect(ip"127.0.0.1", current.port)
    timer = Timer(_ -> close(socket), timeout)
    sender = @async try
        name = zeros(UInt8, MRD_CONFIG_NAME_LENGTH)
        name[1:ncodeunits(config)] .= codeunits(config)
        write(socket, MRD_MESSAGE_CONFIG_FILE, name)
        xml = MRIFiles.GeneralParametersToXML(deepcopy(raw.params)) * '\0'
        write(socket, MRD_MESSAGE_METADATA_XML_TEXT, UInt32(ncodeunits(xml)), xml)
        if config_additional !== nothing
            text = config_additional * '\0'
            write(socket, MRD_MESSAGE_TEXT, UInt32(ncodeunits(text)), text)
        end
        for profile in raw.profiles
            header = IOBuffer()
            write(header, profile.head)
            write(socket, MRD_MESSAGE_ISMRMRD_ACQUISITION, take!(header), profile.traj, profile.data)
        end
        write(socket, MRD_MESSAGE_CLOSE)
    catch
        close(socket)
        rethrow()
    end
    images = NamedTuple[]
    try
        while (message = read(socket, UInt16)) != MRD_MESSAGE_CLOSE
            if message == MRD_MESSAGE_ISMRMRD_IMAGE
                push!(images, _image(socket))
            elseif message == MRD_MESSAGE_TEXT
                @info rstrip(String(read(socket, Int(read(socket, UInt32)))), '\0')
            else
                error("Unexpected MRD message: $message")
            end
        end
        wait(sender)
        isempty(images) && error("OpenRecon returned no images")
        full && return images
        image = only(images).image
        return size(image, 1) == size(image, 2) == 1 ? dropdims(image; dims=(1, 2)) : image
    finally
        close(timer)
        close(socket)
    end
end

function stop()
    current = server[]
    current === nothing && return nothing
    _running(current.container) && run(`docker stop $(current.container)`)
    server[] = nothing
    return nothing
end
end
