#!/usr/bin/env bash
# Check that Verilator meets the recommended major version (default: 5).
set -euo pipefail

RECOMMENDED_MAJOR="${RECOMMENDED_MAJOR:-5}"
VERILATOR_BIN="${VERILATOR:-verilator}"

if ! command -v "${VERILATOR_BIN}" >/dev/null 2>&1; then
  echo "[verilator-check] Verilator not found (VERILATOR=${VERILATOR_BIN})" >&2
  exit 1
fi

ver_line="$("${VERILATOR_BIN}" --version | head -n1)"
ver_num="$(echo "$ver_line" | sed -E 's/.*Verilator ([0-9]+)\.([0-9]+).*/\1.\2/')"
major="${ver_num%%.*}"

echo "[verilator-check] Found ${ver_line}"

if [[ -z "$major" ]]; then
  echo "[verilator-check] Could not parse Verilator version" >&2
  exit 1
fi

if (( major < RECOMMENDED_MAJOR )); then
  echo "[verilator-check] Verilator major ${major} < recommended ${RECOMMENDED_MAJOR}" >&2
  exit 1
fi

echo "[verilator-check] OK: Verilator meets recommended major ${RECOMMENDED_MAJOR}+"
