# OpenRecon client

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

The expected acquisition is 128 samples, 202 spokes, LIN 0:201 and 4 µs dwell;
the returned image is 128 x 128. No sequence or data files are mounted.
Build sources and downloadable ZIP/PDF releases are maintained in
[OpenReconContainers](https://github.com/mcgrathcm/OpenReconContainers/tree/bios214).
