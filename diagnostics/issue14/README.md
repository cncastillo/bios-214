# Windows setup candidate for issue #14

This PR is a diagnostic; leave it unmerged until native Windows validation finishes.

The candidate selects MKL through FFTW.jl's supported per-project preference on
Windows. It preserves Julia's thread count for simulation. The preference must be
set inside each Pluto notebook's environment before importing FFTW or KomaMRI;
setting it in the Pluto server's environment does not configure its notebooks.

The proposed first import cell is:

```julia
begin
    using Preferences
    Sys.iswindows() && Preferences.set_preferences!("FFTW", "provider" => "mkl"; force=true)
    using FFTW, KomaMRI
end
```

The notebook carries this initialization code and reapplies the preference in
every fresh environment before FFTW loads; no separate preference file is shared.

Pluto must save FFTW and Preferences as direct notebook dependencies. No global
startup file, private NFFT thread switch, or four-thread cap is required. Existing
notebook workers that already loaded FFTW need one restart.

The launcher passes `threads=Threads.nthreads()` to `Pluto.run`, so a command
such as `julia +1.10 --threads=auto run_pluto.jl lab/2/activity2.jl` applies to the
notebook worker too.

## Validation

- `.github/workflows/issue14-fftw-windows.yml`: the upstream FFTW #306 stress
  case, plain Julia and Malt, MKL at 8 and 20 Julia threads and an FFTW control
  at 8 threads. FFT results
  are checked against an independent direct DFT. The FFTW control may crash.
- The same workflow checks MKL in a fresh, isolated Pluto 1.0.4 notebook
  environment at both thread counts. It asserts that the preference is set
  before FFTW loads and that the worker receives the requested thread count.
- `.github/workflows/issue14-windows.yml`: the pinned, reduced Activity 2
  reconstruction with deterministic synthetic samples, MKL in plain Julia and
  Malt at 8 and 20 threads. Every reconstructed image is compared with the
  single-thread FFTW reference, requiring relative error below `5e-4`.

Local Julia 1.10.13 checks passed: Pluto 1.0.4 startup order and thread propagation
on macOS; 10,000 MKL FFTs in plain Julia at 8 threads and Malt at 20 threads in
x86 Linux Docker; NFFT 0.14.3 forward and adjoint accuracy with MKL at 20 threads
(relative errors `5.6e-7` and `4.7e-7`). The reconstruction comparison harness
also passed on macOS in plain Julia at 1 and 20 threads and Malt at 20 threads;
all image differences were below `1e-5` relative to the one-thread reference.
These are not native Windows results.

Native Windows validation of this candidate is pending. The exact student's
Activity 2 crash remains unconfirmed; the standalone Windows FFTW crash was
reproduced in the earlier CI runs.

References: [course issue #14](https://github.com/cncastillo/bios-214/issues/14),
[FFTW.jl #306](https://github.com/JuliaMath/FFTW.jl/issues/306),
[FFTW provider documentation](https://juliamath.github.io/FFTW.jl/stable/).
