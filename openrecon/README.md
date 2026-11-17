# OpenRecon

This folder contains the fixed 2D radial scanner reconstruction and its Julia
client for KomaMRI data.

- [bios214radial-0.1.2/](bios214radial-0.1.2/README.md): complete source build,
  including the original signed sequence, pinned Neurocontainers builder,
  Julia environment and OpenRecon scanner-packaging helper.
- [OpenReconClient.jl](OpenReconClient.jl): native Julia MRD/TCP client and
  Docker launcher, tested on Julia 1.10.13.

## Reconstruct Koma data

Docker must be running with
`openrecon_research_bios214radial:v0.1.2` already loaded. The transport needs
KomaMRIFiles; Julia's Sockets library is built in. The tested host environment
used KomaMRIBase 0.15.2, KomaMRICore 0.14.0 and KomaMRIFiles 0.12.0.

From the repository root, with Koma's `raw::RawAcquisitionData`:

```julia
include("openrecon/OpenReconClient.jl")
using .OpenReconClient

image = recon_docker(raw)  # 128 x 128 Matrix{Float32}, indexed [y,x]
```

To simulate first, using your existing `phantom`, `seq` and `sys`:

```julia
using KomaMRICore, KomaMRIFiles

raw = simulate(phantom, seq, sys; sim_params=Dict(
    "gpu" => false, "return_type" => "raw", "precision" => "f64",
    "Δt" => 4e-6, "Δt_rf" => 2e-6,
))
image = recon_docker(raw)
```

The helper starts the scanner image, sends data over TCP, receives the image
and stops the container. It mounts no files. The container keeps its bundled
reference trajectory; the student sequence is used only for simulation on the
host. Expected acquisition: 128 samples, 202 spokes, LIN 0:201, 4 µs dwell.
No Python streaming client or intermediate raw-data file is needed.

## Build

See the [build README](bios214radial-0.1.2/README.md). From the repository root:

```bash
cd openrecon/bios214radial-0.1.2
bash package.sh "$PWD/neurocontainers"
```

This builds the application and writes the scanner ZIP under `dist/`.
Load the Docker tar inside that ZIP to install the scanner image locally.
Build prerequisites are Docker with Linux amd64 support, uv, internet access
and 7z. The host uses Julia 1.10; the original container retains Julia 1.12.7.
