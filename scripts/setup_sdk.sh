#!/usr/bin/env bash
set -euo pipefail

# Hydra SDK setup helper: builds libhydra and userspace tools from the tree.
# This script is non-destructive and will no-op if components are already built.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[hydra] Building libhydra"
make -C "${ROOT_DIR}/drivers/libhydra" >/dev/null

echo "[hydra] Building blit smoke test"
gcc -I "${ROOT_DIR}/drivers/linux/uapi" -O2 -o "${ROOT_DIR}/scripts/hydra_blit_smoketest" "${ROOT_DIR}/scripts/hydra_blit_smoketest.c"

if command -v pkg-config >/dev/null && pkg-config --exists libdrm; then
  echo "[hydra] Building DRM info tool"
  gcc -I "${ROOT_DIR}/drivers/linux/uapi" -o "${ROOT_DIR}/scripts/hydra_drm_info" "${ROOT_DIR}/scripts/hydra_drm_info.c" -ldrm
else
  echo "[hydra] Skipping DRM info tool (libdrm not found)"
fi

echo "[hydra] SDK setup complete"
