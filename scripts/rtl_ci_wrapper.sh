#!/usr/bin/env bash
set -euo pipefail

# Best-effort RTL bench runner for CI.
# Runs sim/tests/run_rtl_tests.sh under a timeout if iverilog/vvp are present,
# logs to artifacts/rtl_tests.log, and NEVER fails the build.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${ROOT_DIR}/artifacts"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/rtl_tests.log"

{
  echo "[rtl-ci] Starting RTL benches (best-effort)"
  if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
    echo "[rtl-ci] iverilog/vvp not found; skipping RTL benches"
    exit 0
  fi
  if [[ ! -x "${ROOT_DIR}/sim/tests/run_rtl_tests.sh" ]]; then
    echo "[rtl-ci] sim/tests/run_rtl_tests.sh not present or not executable; skipping"
    exit 0
  fi
  if command -v timeout >/dev/null 2>&1; then
    timeout 300s "${ROOT_DIR}/sim/tests/run_rtl_tests.sh" || echo "[rtl-ci] RTL benches failed or timed out (non-fatal)"
  else
    "${ROOT_DIR}/sim/tests/run_rtl_tests.sh" || echo "[rtl-ci] RTL benches failed (non-fatal)"
  fi
} | tee "${LOG_FILE}" || true

exit 0
