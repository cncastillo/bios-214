#!/usr/bin/env bash
set -euo pipefail
NEUROCONTAINERS_ROOT="${1:?Usage: bash build.sh /path/to/neurocontainers}"
cd "${NEUROCONTAINERS_ROOT}"
uv run --python 3.13 --locked --extra dev sf-build bios214radial --architecture x86_64 --generate-release
uv run --python 3.13 --no-sync sf-test bios214radial --architecture x86_64 --offline-mode
