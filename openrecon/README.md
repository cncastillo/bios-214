# OpenRecon client

Requires Docker, Julia 1.10 and KomaMRIFiles. With Docker running and Koma's
`raw::RawAcquisitionData`, run from the repository root:

```julia
include("openrecon/OpenReconClient.jl")
using .OpenReconClient
OpenReconClient.start()
image = OpenReconClient.recon(raw)  # Matrix{Float32}, indexed [y,x]
```

Call `OpenReconClient.recon(raw)` again for each simulation. The container
stays running, including after rejected input. When finished, call:

```julia
OpenReconClient.stop()
```

The default image is `ghcr.io/mcgrathcm/bios214-radial:0.1.2-build-3`;
Docker pulls it on first use if needed. Repeated `start()` calls reuse the
running container; repeated `stop()` calls are safe. To select another image,
use `start(; image="...")` after stopping the current server. The original
`recon_docker(raw)` helper still starts and stops a container for one call;
if a server is already running, it reuses it and leaves it running.

The client mounts no files and needs only KomaMRIFiles and Julia's built-in
Sockets. For simulation, request `"return_type" => "raw"` from Koma, or convert
a signal matrix with `signal_to_raw_data(signal, seq; sys)`. Keeping the
container running avoids Docker startup and shutdown, but its adapter still
starts Julia/BART for each reconstruction.
Tested on host Julia 1.10.13 with KomaMRIBase 0.15.2, KomaMRICore 0.14.0 and
KomaMRIFiles 0.12.0. The container retains Julia 1.12.7.

The expected acquisition is 128 samples, 202 spokes, LIN 0:201 and 4 µs dwell;
the returned image is 128 x 128. No sequence or data files are mounted.
Build sources and downloadable ZIP/PDF releases are maintained in
[OpenReconContainers](https://github.com/mcgrathcm/OpenReconContainers/tree/bios214).
