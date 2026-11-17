# bios214radial

Version 0.1.2 | Research reconstruction | CPU only | ISMRMRD 1.4.1

## Purpose and sequence

Reconstruct the bundled 2D radial bSSFP Pulseq acquisition with Julia and BartIO 0.4 / BART 1.0.00. The image includes its Julia packages, BART binary and sequence; no network access or external trajectory file is required during reconstruction.

- FOV: 256 x 256 mm; slice thickness: 10 mm; output: 128 x 128 pixels.
- 202 spokes, 128 complex samples per spoke, 4 microsecond dwell; LIN = 0 through 201.
- TR / TE: 3 / 1.5 ms; 45 degree flip angle; 13 preparation shots without ADC.
- The file's Ny = 202 counts spokes. Output height is explicitly 128 pixels.

The scanner must execute the exact bundled radial_bssfp.seq. Its SHA-256 is 942ec998650e3172d32f36e7e9077a9ebb8916e98c4aa995b0fc5dda1f853b6a.

## Scanner configuration

Install OpenRecon_research_bios214radial_V0.1.2.zip through the OpenRecon package installer for the scanner software version. Select bios214radial for the Pulseq protocol. The package selects raw input and the image injector. Its sole configuration parameter is config = bios214radial. Internal server port: TCP 9002. Resources: 4 GB RAM, one CPU core, no GPU.

Use a 128 x 128 reconstruction matrix and the FOV and slice thickness above in the protocol. Disable Prio Recon in the sequence execution properties. The output matrix and FOV come from this fixed reconstruction. Slice position and directions come from the received acquisition headers.

## Input and returned image

Send raw, receiver-phase-corrected complex coil data. Each image group must contain each LIN exactly once,
with 128 untrimmed samples and no partition encoding. An unset MRD dwell field uses the sequence's
4 microseconds; a conflicting reported dwell is rejected. Noise, calibration-only, navigation,
phase-correction and dummy readouts are excluded. Images are grouped by average, slice, echo, cardiac
phase, repetition and set. LAST_IN_SLICE triggers reconstruction, with a final flush at measurement end.
Spoke arrival order may vary.

The reconstruction derives ADC-time coordinates from the sequence and uses regularized inverse NUFFT followed by root-sum-of-squares coil combination. It returns one Float32 magnitude MRD image per group: data order (channel,z,y,x) = (1,1,128,128), header matrix (128,128,1), FOV (256,256,10) mm. Position, directions and group counters are retained. Metadata retains DataRole=Image and Keep_image_geometry=1 from the scanner-working starter.

Every nonzero image is scaled uniformly to a peak of 4095 before clipping rounding residuals, preserving relative contrast. This includes weak signals that would otherwise display as black; zero images remain zero. This prevents integer wrap during scanner injection; these magnitude images are not quantitative proton-density maps.

## Validation and troubleshooting

The complete acquisition was Bloch-simulated with KomaMRI, and the container reconstructed the data through MRD sockets without transmitted trajectories. Tests also cover shuffled LIN, geometry and counters, and incompatible sampling. This is offline software validation; a physical scanner acquisition remains to be checked.

Retrieve /tmp/python-ismrmrd-server.log from the deployed container when investigating failures. Check the sequence identity, LIN coverage, sample count, dwell, receiver phase correction and scanner geometry. Interpreter gradient/FOV changes must agree with the bundled trajectory. Research vendor/manufacturer/UDI fields retain the supplied starter's template values.
