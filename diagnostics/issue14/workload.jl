using KomaMRI, LinearAlgebra, Random, TOML
import KomaMRIBase.PulseDesigner as PD
import MRISequenceBuildingBlocks as SBB
import KomaMRI: MRIReco
const NFFT = MRIReco.MRIOperators.NFFT
const FFTW = NFFT.FFTW

include(joinpath(@__DIR__, "2cd7102e-dd92-11f1-8cb3-895d35658f26.jl"))

function workload()
    println("ENVIRONMENT ", (julia=VERSION, os=Sys.KERNEL, arch=Sys.ARCH,
        threads=Threads.nthreads(), koma=pkgversion(KomaMRI), mrireco=pkgversion(MRIReco),
        nfft=pkgversion(NFFT), fftw=pkgversion(FFTW)))
    flush(stdout)
    sys = Scanner(limits=HardwareLimits(B0=3.0, B1=20e-6, Gmax=30e-3, Smax=180,
        ADC_Δt=1e-6, DUR_Δt=10e-6, GR_Δt=10e-6, RF_Δt=1e-6,
        RF_dead_time=120e-6, RF_ring_down_time=50e-6, ADC_dead_time=10e-6))
    excitation = SBB.build_pencil_beam(π/2, 80e-3, 256e-3, 40, sys; B1=12e-6)
    seq = build_2d_se_epi(excitation, sys)
    signal = randn(MersenneTwister(14), ComplexF32, sum(seq.ADC.N), 1)
    raw = signal_to_raw_data(signal, seq; sys)
    println("INPUT ", (samples=size(signal), profiles=length(raw.profiles), matrix=(seq.DEF["Nx"], seq.DEF["Ny"])))
    flush(stdout)
    results = Dict{String,Any}[]
    for iteration in 1:3
        FFTW.set_num_threads(1)
        timed = @timed reconstruct_with_labels(raw)
        images = timed.value.images
        all(x -> all(isfinite, x.image), images) || error("Non-finite reconstruction")
        summary = Dict("iteration"=>iteration, "seconds"=>timed.time,
            "allocated_bytes"=>timed.bytes, "images"=>length(images),
            "shapes"=>[collect(size(x.image)) for x in images],
            "norms"=>[Float64(norm(x.image)) for x in images])
        push!(results, summary)
        println("PASS ", summary)
        flush(stdout)
        GC.gc()
    end
    return Dict("julia"=>string(VERSION), "os"=>string(Sys.KERNEL), "arch"=>string(Sys.ARCH),
        "threads"=>Threads.nthreads(), "results"=>results)
end

if abspath(PROGRAM_FILE) == @__FILE__
    result = workload()
    open(ARGS[1], "w") do io
        TOML.print(io, result)
    end
end
