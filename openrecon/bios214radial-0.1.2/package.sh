#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v uv >/dev/null
command -v 7z >/dev/null
bash "${ROOT}/build.sh"
BUILD_DIR="${ROOT}/build/package"
VENV="${ROOT}/build/package-venv"
if [ ! -x "${VENV}/bin/python" ]; then
    uv venv --seed "${VENV}"
fi
uv pip install --python "${VENV}/bin/python" -r "${ROOT}/packaging/requirements.txt"
source "${VENV}/bin/activate"
RECIPE="${BUILD_DIR}/recipes/bios214radial"
mkdir -p "${RECIPE}" "${ROOT}/dist"
cp "${ROOT}/vendor/openrecon/recipes/"*.py "${BUILD_DIR}/recipes/"
cp "${ROOT}/vendor/openrecon/recipes/"{build.sh,OpenReconSchema_1.1.0.json} "${BUILD_DIR}/recipes/"
cp "${ROOT}/recipe/OpenReconLabel.json" "${RECIPE}/"
cp "${ROOT}/recipe/OpenReconREADME.md" "${RECIPE}/README.md"
cp "${ROOT}/packaging/params.sh" "${RECIPE}/"
uv run --no-project --python "${VENV}/bin/python" "${ROOT}/packaging/make_docs.py" \
    "${RECIPE}/README.md" "${RECIPE}/docs.pdf"
case "$(docker info --format '{{.Architecture}}')" in
    arm64|aarch64) export OPENRECON_DIND_PLATFORM=linux/arm64 ;;
    *) export OPENRECON_DIND_PLATFORM=linux/amd64 ;;
esac
docker pull --platform "${OPENRECON_DIND_PLATFORM}" docker:24.0-dind
(
    cd "${RECIPE}"
    CI=1 BUILD_PACKAGE_SELECTION=openrecon BUILD_PACKAGE_SELECTION_OVERRIDE=1 \
        bash ../build.sh --local-cache --ignore-mdpdf
)
cp "${RECIPE}/openrecon/OpenRecon_research_bios214radial_V0.1.2.zip" "${ROOT}/dist/"
cp "${RECIPE}/docs.pdf" "${ROOT}/dist/OpenRecon_research_bios214radial_V0.1.2.pdf"
