#!/usr/bin/env bash
set -euo pipefail

# Hydra SDK setup helper: builds libhydra and userspace tools from the tree.
# This script is non-destructive and can be re-run; it overwrites the SDK
# binaries in scripts/ and logs to artifacts/sdk_build.log.
#
# Usage:
#   ./scripts/setup_sdk.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOG_DIR="${ROOT_DIR}/artifacts"
mkdir -p "${LOG_DIR}"

{
echo "[hydra] Building libhydra"
make -C "${ROOT_DIR}/drivers/libhydra" >/dev/null

echo "[hydra] Building blit smoke test"
gcc -I "${ROOT_DIR}/drivers/linux/uapi" -O2 -o "${ROOT_DIR}/scripts/hydra_blit_smoketest" "${ROOT_DIR}/scripts/hydra_blit_smoketest.c"

echo "[hydra] Building libhydra-based DMA+blit demo"
gcc -I "${ROOT_DIR}/drivers/linux/uapi" -I "${ROOT_DIR}/drivers/libhydra" -O2 -o "${ROOT_DIR}/scripts/hydra_dma_blit_demo" \
  "${ROOT_DIR}/scripts/hydra_dma_blit_demo.c" "${ROOT_DIR}/drivers/libhydra/hydra.c"

echo "[hydra] Building IRQ test helper"
gcc -I "${ROOT_DIR}/drivers/linux/uapi" -O2 -o "${ROOT_DIR}/scripts/hydra_irq_test" \
  "${ROOT_DIR}/scripts/hydra_irq_test.c"

if command -v pkg-config >/dev/null && pkg-config --exists libdrm; then
  echo "[hydra] Building DRM info tool"
  if ! gcc -I "${ROOT_DIR}/drivers/linux/uapi" $(pkg-config --cflags libdrm) \
       -o "${ROOT_DIR}/scripts/hydra_drm_info" "${ROOT_DIR}/scripts/hydra_drm_info.c" \
       $(pkg-config --libs libdrm); then
    echo "[hydra] DRM info build failed (missing headers or libs?), skipping"
  fi
else
  echo "[hydra] Skipping DRM info tool (libdrm not found)"
fi

echo "[hydra] SDK setup complete"
} | tee "${LOG_DIR}/sdk_build.log"
