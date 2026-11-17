using BartIO, KomaMRIBase, KomaMRIFiles
using SHA

const SEQUENCE_PATH = joinpath(@__DIR__, "..", "sequence", "radial_bssfp.seq")

function sequence_info()
    seq = read_seq(SEQUENCE_PATH; verify_signature=true, verbose=false)
    blocks = findall(is_ADC_on, seq.ADC)
    labels = get_labels(seq)
    lines = [labels[b].LIN for b in blocks]
    samples = only(unique(seq.ADC[b].N for b in blocks))
    matrix = Int(seq.DEF["Nx"])
    fov = Float64.(seq.DEF["FOV"])
    # In this radial file Ny is the number of spokes, not image height.
    @assert matrix == 128 && samples == 128 && lines == collect(0:201)
    @assert seq.DEF["Nz"] == 1
    _, k_adc = get_kspace(seq)
    @assert maximum(abs, k_adc[:, 3]) < 1e-6
    trajectory = permutedims(reshape(k_adc, samples, length(blocks), 3), (3, 1, 2))
    trajectory[3, :, :] .= 0 # BART requires exactly zero along singleton image axes.
    trajectory .*= reshape(fov, 3, 1, 1) # cycles/m -> BART grid coordinates
    @info "Fixed radial sequence" matrix spokes=length(blocks) samples fov sha256=bytes2hex(sha256(read(SEQUENCE_PATH)))
    return (; matrix, fov, lines, trajectory=ComplexF32.(trajectory))
end

"""Reconstruct complex kspace[coil, spoke, sample], indexed by Pulseq LIN, to image[y, x]."""
function recon(kspace, lines)
    info = sequence_info()
    @assert ndims(kspace) == 3 && size(kspace, 3) == 128
    @assert size(kspace, 2) == length(lines) == length(info.lines)
    @assert sort(vec(lines)) == info.lines "Expected each LIN=0:201 exactly once."
    data = permutedims(ComplexF32.(kspace[:, sortperm(vec(lines)), :]), (3, 2, 1))
    data = reshape(data, 1, 128, length(info.lines), size(data, 3))
    coil_images = BartIO.bart(1, "nufft -i -x128:128:1 -l0.1 -m100", info.trajectory, data)
    coil_images = reshape(coil_images, info.matrix, info.matrix, :)
    image = dropdims(sqrt.(sum(abs2, coil_images; dims=3)); dims=3)
    return (; image=Float32.(permutedims(image)), fov_mm=Float32.(1000 .* info.fov))
end
