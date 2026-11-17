# OpenRecon client

Use Julia 1.10 and start Docker Desktop. In the Koma simulation, set
`"return_type" => "raw"` in `sim_params` and save the result as `raw`.

```julia
using KomaMRIFiles
include("openrecon/OpenReconClient.jl")
OpenReconClient.start()
image = OpenReconClient.recon(raw)
OpenReconClient.stop()
```

`start()` downloads `ghcr.io/mcgrathcm/bios214-radial:0.1.2-build-3` if needed
and chooses an available host port. Use `start(image="my-image", port=9003)`
to select them. The image must start an MRD server on container port 9002.
A running container is reused; an externally stopped container is restarted.
Call `stop()` before changing the image or port.

The default container requires its bundled `radial_bssfp.seq`: 202 spokes,
128 samples per spoke, 4 microsecond dwell and LIN 0 through 201. It uses its
bundled trajectory and returns a 128 × 128 Float32 magnitude image scaled to
0–4095. Raw single-coil and multicoil data are sent unchanged; reconstruction
and coil combination happen in the container.

```julia
image = OpenReconClient.recon(raw; config="myrecon")
images = OpenReconClient.recon(raw; config="myrecon", full=true)
```

`recon` returns one image, indexed as `[y, x]` for single-channel 2D output
and `[channel, z, y, x]` otherwise, retaining the transmitted numeric type.
`full=true` returns all images as records with `.image`, `.header` and
`.metadata`; these arrays always retain all four dimensions.

The optional `config_additional` keyword accepts scanner JSON text, sent
after the MRD XML header and before acquisitions. For example:

```julia
image = OpenReconClient.recon(raw;
    config_additional=raw"""{"parameters":{"config":"bios214radial"}}""")
```

As in the reference client, `parameters.config` or `parameters.customconfig`
can override `config`. Responses are read until `MRD_MESSAGE_CLOSE`.

Verified with Julia 1.10.13 against the published image's Python reference
client: single-coil and four-coil Koma simulations produced identical pixels,
all 26 image-header fields and metadata XML, using the same pinned image digest.
