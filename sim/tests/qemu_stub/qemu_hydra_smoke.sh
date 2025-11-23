#!/usr/bin/env bash
set -euo pipefail

# Minimal QEMU smoke harness for the Hydra PCI stub.
#
# This script is intentionally conservative: it only runs a guest test when
# HYDRA_QEMU_GUEST_IMG is set and when the QEMU binary supports a `hydra-pci`
# device (as provided by sim/tests/qemu_stub/hydra_pci.c in a custom QEMU
# build). Otherwise, it exits successfully and logs that the test was skipped.
#
# Usage (host):
#   HYDRA_QEMU_GUEST_IMG=/path/to/hydra-guest.qcow2 \
#   QEMU_BIN=qemu-system-x86_64 \
#     sim/tests/qemu_stub/qemu_hydra_smoke.sh
#
# The guest image is expected to:
#   - Auto-load the hydra_pcie_drv + hydra_drm_stub modules, and
#   - Run a boot-time script that executes hydra_blit_smoketest and
#     hydra_dma_blit_demo, then shuts down with an appropriate exit code.

QEMU_BIN=${QEMU_BIN:-qemu-system-x86_64}
IMG=${HYDRA_QEMU_GUEST_IMG:-}

if ! command -v "${QEMU_BIN}" >/dev/null 2>&1; then
  echo "[qemu-hydra] QEMU binary '${QEMU_BIN}' not found, skipping" >&2
  exit 0
fi

if [[ -z "${IMG}" ]]; then
  echo "[qemu-hydra] HYDRA_QEMU_GUEST_IMG not set, skipping QEMU smoke" >&2
  exit 0
fi

# Check whether this QEMU build knows about hydra-pci; if not, skip.
if ! "${QEMU_BIN}" -device help 2>/dev/null | grep -q 'hydra-pci'; then
  echo "[qemu-hydra] QEMU does not have a 'hydra-pci' device, skipping" >&2
  exit 0
fi

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/artifacts"
mkdir -p "${LOG_DIR}"

set -x
"${QEMU_BIN}" \
  -M q35 -m 2048 \
  -device hydra-pci,bus=pcie.0,addr=0x3 \
  -drive file="${IMG}",if=virtio,format=qcow2 \
  -nographic | tee "${LOG_DIR}/qemu_console.log"
set +x

# If the guest powers off cleanly, QEMU will exit 0 and we treat that as
# success for this smoke test.

exit 0
