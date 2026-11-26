# Reduced from https://github.com/JuliaMath/FFTW.jl/issues/306.
using Preferences
provider = get(ARGS, 1, "fftw")
Preferences.set_preferences!("FFTW", "provider" => provider; force=true)
using FFTW, Random, InteractiveUtils

@assert FFTW.fftw_provider == provider
versioninfo()
println("FFTW.jl=", pkgversion(FFTW), " provider=", FFTW.fftw_provider, " FFTW library=", FFTW.version)
FFTW.set_num_threads(6)
println("FFTW threads=", FFTW.get_num_threads())
flush(stdout)

data = rand(MersenneTwister(14), ComplexF32, 64)
reference = ComplexF64[sum(data[n+1] * cis(-2π*k*n/64) for n in 0:63) for k in 0:63]
for iteration in 1:10000
    result = fft(data)
    if iteration % 1000 == 0
        @assert isapprox(result, reference; rtol=2e-6)
        println("PASS ", iteration)
        flush(stdout)
    end
end
println("Completed the FFTW #306 reproducer with correct FFT results")
