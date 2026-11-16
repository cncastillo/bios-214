# Reduced from https://github.com/JuliaMath/FFTW.jl/issues/306.
using FFTW, Random, InteractiveUtils

versioninfo()
println("FFTW.jl=", pkgversion(FFTW), " FFTW library=", FFTW.version)
FFTW.set_num_threads(6)
println("FFTW threads=", FFTW.get_num_threads())
flush(stdout)

data = rand(MersenneTwister(14), ComplexF32, 64)
for iteration in 1:10000
    fft(data)
    if iteration % 1000 == 0
        println("PASS ", iteration)
        flush(stdout)
    end
end
println("Completed the FFTW #306 reproducer without crashing")
