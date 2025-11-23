#!/usr/bin/env bash
set -euo pipefail

# Hydra developer loop helper: build, test, and (optionally) exercise
# higher-level paths in one go.
#
# Usage:
#   ./scripts/hydra_dev_loop.sh
#
# Optional env:
#   HYDRA_QEMU_GUEST_IMG=/path/to/guest.qcow2  # enable QEMU smoke when QEMU is installed
#
# This is a convenience wrapper around the same pieces used in CI:
#   - Verilator+SDL sim build + frame regression (golden image check)
#   - SDK tools build (libhydra, blit smoketest, DMA+blit demo)
#   - Optional RTL benches (if iverilog/vvp are installed)
#   - Optional QEMU PCI stub smoke (if QEMU + guest image are configured)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "[dev-loop] Step 1: build sim and run frame regression"
cd sim
make
make test_frame
cd "${ROOT_DIR}"

echo "[dev-loop] Step 2: build SDK tools (libhydra, smoketests)"
chmod +x scripts/setup_sdk.sh
./scripts/setup_sdk.sh || echo "[dev-loop] setup_sdk.sh reported non-fatal issues (e.g., missing libdrm)"

# Optional: RTL benches via Icarus Verilog, best-effort with timeout.
if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
  if [[ -x sim/tests/run_rtl_tests.sh ]]; then
    echo "[dev-loop] Step 3 (optional): running RTL benches via sim/tests/run_rtl_tests.sh"
    if command -v timeout >/dev/null 2>&1; then
      timeout 300s sim/tests/run_rtl_tests.sh || echo "[dev-loop] RTL benches failed or timed out (non-fatal)"
    else
      sim/tests/run_rtl_tests.sh || echo "[dev-loop] RTL benches failed (non-fatal)"
    fi
  else
    echo "[dev-loop] RTL benches script not present; skipping"
  fi
else
  echo "[dev-loop] iverilog/vvp not found; skipping RTL benches"
fi

# Optional: QEMU PCI stub smoke if QEMU + guest image are configured.
if [[ -x sim/tests/qemu_stub/qemu_hydra_smoke.sh ]]; then
  if command -v qemu-system-x86_64 >/dev/null 2>&1 && [[ -n "${HYDRA_QEMU_GUEST_IMG:-}" ]]; then
    echo "[dev-loop] Step 4 (optional): running QEMU Hydra PCI stub smoke"
    QEMU_BIN=qemu-system-x86_64 HYDRA_QEMU_GUEST_IMG="${HYDRA_QEMU_GUEST_IMG}" \
      sim/tests/qemu_stub/qemu_hydra_smoke.sh || echo "[dev-loop] QEMU smoke failed (non-fatal)"
  else
    echo "[dev-loop] QEMU binary or HYDRA_QEMU_GUEST_IMG not configured; skipping QEMU smoke"
  fi
fi

echo "[dev-loop] Done"
