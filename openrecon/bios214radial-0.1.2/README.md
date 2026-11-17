# bios214radial 0.1.2 source build

The original 0.1.2 reconstruction, Julia environment, signed `radial_bssfp.seq`,
Neurocontainers builder/shared macro and scanner-packaging helper are included.
No other local checkout is required. This is the fixed 2D radial reconstruction:
128 samples, 202 spokes, 4 microsecond dwell, 128 x 128 magnitude output.

Requirements: Docker with Linux amd64 support, `uv`, internet access for upstream
downloads, and `7z` for scanner packaging. `uv` supplies Python 3.13 if needed.

From this folder, build the application image with the Neurocontainers builder:

```bash
bash build.sh "$PWD/neurocontainers"
```

Or build the application and create the scanner package using the original
OpenRecon helper (its inherited patches are already applied):

```bash
bash package.sh "$PWD/neurocontainers"
```

Outputs: `bios214radial:0.1.2`, and for packaging,
`dist/OpenRecon_research_bios214radial_V0.1.2.zip` plus its PDF and checksums.
The ZIP contains `openrecon_research_bios214radial:v0.1.2`; load its Docker tar
if you also want that tag in the host Docker daemon.

The recipe and sequence are in `neurocontainers/recipes/bios214radial/`.
`PROVENANCE.json` records source pins and original image IDs;
`reference/` contains the original generated Dockerfile and source hashes.
Verify the supplied files with `shasum -a 256 -c SHA256SUMS`.

The original recipe uses live apt repositories and some unpinned Python
dependencies. These instructions reproduce its sources/process; fresh builds
are not guaranteed to have the original byte-for-byte image hash.
