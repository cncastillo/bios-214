#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEUROCONTAINERS_ROOT="${ROOT}/build/neurocontainers"
git init -q "${NEUROCONTAINERS_ROOT}"
git -C "${NEUROCONTAINERS_ROOT}" fetch -q --depth=1 \
    https://github.com/neurodesk/neurocontainers.git \
    5fc5675e94f6148ec5e9c8f766a57dba330ef51d
git -C "${NEUROCONTAINERS_ROOT}" checkout -q --detach FETCH_HEAD
mkdir -p "${NEUROCONTAINERS_ROOT}/recipes/bios214radial"
cp "${ROOT}/recipe/"* "${NEUROCONTAINERS_ROOT}/recipes/bios214radial/"
cd "${NEUROCONTAINERS_ROOT}"
uv run --python 3.13 --locked sf-build bios214radial --architecture x86_64
uv run --python 3.13 --no-sync sf-test bios214radial --architecture x86_64 --offline-mode
