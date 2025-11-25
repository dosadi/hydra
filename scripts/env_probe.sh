#!/usr/bin/env bash
# Print toolchain versions for quick diagnostics (CI/local).
set -euo pipefail

echo "[env-probe] Repository root: $(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

print_version() {
  local name="$1" bin="$2"
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[env-probe] $name: $("$bin" --version | head -n1)"
  else
    echo "[env-probe] $name: not found (looked for '$bin')"
  fi
}

print_version "verilator" "${VERILATOR:-verilator}"
print_version "gcc" "${CC:-gcc}"
print_version "g++" "${CXX:-g++}"
print_version "python3" "${PYTHON:-python3}"

if command -v sdl2-config >/dev/null 2>&1; then
  echo "[env-probe] sdl2-config version: $(sdl2-config --version)"
else
  echo "[env-probe] sdl2-config: not found"
fi

if command -v cmake >/dev/null 2>&1; then
  echo "[env-probe] cmake: $(cmake --version | head -n1)"
fi

if command -v iverilog >/dev/null 2>&1; then
  echo "[env-probe] iverilog: $(iverilog -V 2>/dev/null | head -n1)"
fi

if command -v vvp >/dev/null 2>&1; then
  echo "[env-probe] vvp: $(vvp -V 2>/dev/null | head -n1)"
fi
