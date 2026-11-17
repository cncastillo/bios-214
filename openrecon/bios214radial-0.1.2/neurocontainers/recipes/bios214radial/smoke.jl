using Test
include("recon.jl")
info = sequence_info()
phantom = zeros(ComplexF32, 128, 128)
phantom[43, 80] = 1
phantom[89, 41] = 0.6
samples = BartIO.bart(1, "nufft", info.trajectory, phantom)
raw = permutedims(reshape(samples, 128, 202, 1), (3, 2, 1))
result = recon(raw, info.lines)
@test size(result.image) == (128, 128)
@test all(isfinite, result.image)
@test argmax(result.image) == CartesianIndex(80, 43)
@test result.fov_mm == Float32[256, 256, 10]
println("Fixed radial BART NUFFT passed")
