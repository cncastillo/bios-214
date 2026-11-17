using KomaMRIBase, KomaMRICore, KomaMRIFiles, NPZ, LinearAlgebra, Test
include("recon.jl")

function simulate_fixture()
    output = isempty(ARGS) ? "/tmp/bios214radial-koma-test" : ARGS[1]
    mkpath(output)
    seq = read_seq(SEQUENCE_PATH; verify_signature=true, verbose=false)
    info = sequence_info()
    axis = (-64:63) .* 0.002
    density = [Float32(
        ((x + 0.050)^2 + (y - 0.034)^2 < 0.018^2) +
        0.65 * ((x - 0.046)^2 + (y - 0.052)^2 < 0.012^2) +
        0.45 * ((x - 0.022)^2 + (y + 0.058)^2 < 0.014^2)
    ) for x in axis, y in axis]
    selected = findall(>(0), density)
    phantom = Phantom(; name="asymmetric_radial_test",
        x=[axis[i[1]] for i in selected], y=[axis[i[2]] for i in selected],
        z=zeros(length(selected)), ρ=Float64.(density[selected]),
        T1=fill(1.0, length(selected)), T2=fill(0.1, length(selected)))
    sys = Scanner(; limits=HardwareLimits(; B0=3.0, B1=10e-6, Gmax=80e-3, Smax=200, ADC_Δt=1e-6))
    parameters = Dict{String,Any}("gpu" => false, "return_type" => "mat",
        "precision" => "f64", "Δt" => 4e-6, "Δt_rf" => 2e-6)
    signal = simulate(phantom, seq, sys; sim_params=parameters)
    # Constant complex coil sensitivities isolate the RSS/axis handling.
    signal = hcat(vec(signal), 1im .* vec(signal)) ./ sqrt(2)
    raw = signal_to_raw_data(signal, seq; sys)
    raw.params["trajectory"] = "radial"
    @test length(raw.profiles) == 202
    @test all(p.head.idx.kspace_encode_step_1 == i - 1 for (i, p) in enumerate(raw.profiles))
    for profile in raw.profiles
        profile.traj = zeros(Float32, 0, 128)
        profile.head.trajectory_dimensions = 0
    end
    input_file = joinpath(output, "koma-input.h5")
    isfile(input_file) && rm(input_file)
    save(ISMRMRDFile(input_file), raw)
    data = permutedims(cat((p.data for p in raw.profiles)...; dims=3), (2, 3, 1))
    result = recon(data, info.lines)
    expected = permutedims(density)
    # Independent direct Fourier samples check trajectory units and NUFFT axes
    # without bSSFP transient contrast or a BART-generated input.
    kx, ky = vec(real.(info.trajectory[1, :, :])), vec(real.(info.trajectory[2, :, :]))
    ideal = zeros(ComplexF32, length(kx))
    for i in selected
        ideal .+= density[i] .* cis.(-2π .* (kx .* axis[i[1]] ./ 0.256 .+ ky .* axis[i[2]] ./ 0.256))
    end
    ideal_data = permutedims(reshape(hcat(ideal, 1im .* ideal) ./ sqrt(2), 128, 202, 2), (3, 2, 1))
    ideal_image = recon(ideal_data, info.lines).image
    ideal_correlation = dot(ideal_image, expected) / (norm(ideal_image) * norm(expected))
    gain = dot(result.image, expected) / sum(abs2, expected)
    nrmse = norm(result.image .- gain .* expected) / norm(gain .* expected)
    correlation = dot(result.image, expected) / (norm(result.image) * norm(expected))
    npzwrite(joinpath(output, "koma-reference.npz"), Dict(
        "expected" => expected, "image" => result.image, "kspace" => data,
        "lines" => info.lines, "fov_mm" => result.fov_mm,
        "ideal_image" => ideal_image, "ideal_correlation" => [ideal_correlation],
        "correlation" => [correlation], "nrmse" => [nrmse]))
    @info "KomaMRI radial reconstruction" spins=length(selected) correlation nrmse ideal_correlation
    @test size(result.image) == (128, 128)
    @test correlation > 0.95
    @test nrmse < 0.30
    @test ideal_correlation > 0.98
    @test_throws AssertionError recon(data, fill(0, 202))
    @test_throws AssertionError recon(data[:, 1:end-1, :], info.lines[1:end-1])
    return (; input_file, correlation, nrmse)
end

simulate_fixture()
