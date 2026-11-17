# OpenRecon

Fixed 2D radial reconstruction: 128 samples, 202 spokes, LIN 0:201 and 4 µs
dwell, returning a 128 x 128 magnitude image. The container uses its bundled
reference sequence; students' sequences are used by Koma on the host.

## Build

Requires Docker with Linux amd64 support, Git, uv, 7z and internet access.
From the repository root:

```bash
cd openrecon/bios214radial-0.1.2
bash package.sh
```

This fetches the Neurocontainers builder at commit
`5fc5675e94f6148ec5e9c8f766a57dba330ef51d`, builds the application and writes the
scanner ZIP under `dist/`. Use `bash build.sh` for the application image only.
The build inputs, including the original signed `.seq`, are in `recipe/`.
The original recipe uses live apt repositories and some unpinned Python
dependencies, so fresh build hashes can differ.

## Reconstruct Koma data

Load the Docker tar inside the scanner ZIP first. With Docker running and
Koma's `raw::RawAcquisitionData`, run from the repository root:

```julia
include("openrecon/OpenReconClient.jl")
using .OpenReconClient
image = recon_docker(raw)  # Matrix{Float32}, indexed [y,x]
```

The helper starts the image, streams MRD over TCP, returns the image and stops
the container. It mounts no files and needs only KomaMRIFiles and Julia's
built-in Sockets. For simulation, request `"return_type" => "raw"` from Koma,
or convert a signal matrix with `signal_to_raw_data(signal, seq; sys)`.
Tested on host Julia 1.10.13 with KomaMRIBase 0.15.2, KomaMRICore 0.14.0 and
KomaMRIFiles 0.12.0. The container retains Julia 1.12.7.
