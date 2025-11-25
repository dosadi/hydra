#!/usr/bin/env bash
# Remove sim/obj_dir when the Verilator version has changed.
# Useful to avoid stale verilated artifacts across tool upgrades.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
OBJ_DIR="${REPO_ROOT}/sim/obj_dir"
VER_FILE="${OBJ_DIR}/.verilator_version"
VERILATOR_BIN="${VERILATOR:-verilator}"

if [ ! -d "${OBJ_DIR}" ]; then
  echo "[purge-obj-dir] ${OBJ_DIR} does not exist; nothing to do."
  exit 0
fi

if ! command -v "${VERILATOR_BIN}" >/dev/null 2>&1; then
  echo "[purge-obj-dir] Verilator not found (VERILATOR=${VERILATOR_BIN}); cannot check version." >&2
  exit 1
fi

current_version="$("${VERILATOR_BIN}" --version | head -n1)"

if [ ! -f "${VER_FILE}" ]; then
  echo "[purge-obj-dir] No version marker found; removing stale ${OBJ_DIR}."
  rm -rf "${OBJ_DIR}"
  exit 0
fi

recorded_version="$(cat "${VER_FILE}")"

if [ "${current_version}" != "${recorded_version}" ]; then
  echo "[purge-obj-dir] Verilator changed:"
  echo "  recorded: ${recorded_version}"
  echo "  current : ${current_version}"
  echo "[purge-obj-dir] Removing stale ${OBJ_DIR}."
  rm -rf "${OBJ_DIR}"
else
  echo "[purge-obj-dir] Verilator version unchanged (${current_version}); keeping ${OBJ_DIR}."
fi
