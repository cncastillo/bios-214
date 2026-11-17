# OpenRecon client

Use Julia 1.10 and start Docker Desktop before running the client.
In your Koma simulation, set `"return_type" => "raw"` in `sim_params`
and save the result as `raw`.

From the repository root:

```julia
using KomaMRIFiles
include("openrecon/OpenReconClient.jl")
using .OpenReconClient
OpenReconClient.start()
image = OpenReconClient.recon(raw)
```

The first `start()` downloads the course image if needed; this can take a few
minutes. It uses `ghcr.io/mcgrathcm/bios214-radial:0.1.2-build-3`.

Call `OpenReconClient.recon(raw)` with each new simulation result. The container
stays running between calls. The result is a 128 x 128 image array indexed as
`image[y, x]`.
The expected input is 128 samples per spoke and 202 spokes.

When finished:

```julia
OpenReconClient.stop()
```
