#!/usr/bin/env bash
set -euo pipefail

# Collect useful logs/artifacts for CI debugging.
# This is a best-effort helper used in CI jobs; missing files are ignored.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART_DIR="${ROOT_DIR}/artifacts"
mkdir -p "${ART_DIR}"

# Frame regression artifacts
if [ -f "${ROOT_DIR}/sim/build/frame_test.ppm" ]; then
  cp "${ROOT_DIR}/sim/build/frame_test.ppm" "${ART_DIR}/frame_test.ppm" || true
fi
if [ -f "${ROOT_DIR}/sim/tests/golden_frame.ppm" ]; then
  cp "${ROOT_DIR}/sim/tests/golden_frame.ppm" "${ART_DIR}/golden_frame.ppm" || true
fi
if [ -f "${ROOT_DIR}/sim/build/frame_diff.log" ]; then
  cp "${ROOT_DIR}/sim/build/frame_diff.log" "${ART_DIR}/frame_diff.log" || true
fi

# SDK build log (if caller redirected setup_sdk.sh output here)
if [ -f "${ROOT_DIR}/artifacts/sdk_build.log" ]; then
  : # already in place
fi

# QEMU console log (if qemu_hydra_smoke.sh redirected it here)
if [ -f "${ROOT_DIR}/artifacts/qemu_console.log" ]; then
  : # already in place
fi

# RTL benches log (if rtl_ci_wrapper.sh ran)
if [ -f "${ROOT_DIR}/artifacts/rtl_tests.log" ]; then
  : # already in place
fi

exit 0
