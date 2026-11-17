using NPZ
include("recon.jl")

input = npzread(ARGS[1])
result = recon(input["kspace"], input["lines"])
npzwrite(ARGS[2], Dict("image" => result.image, "fov_mm" => result.fov_mm))
