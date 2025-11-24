#!/usr/bin/env bash
set -euo pipefail

# Simple tool version probe for CI/local sanity checks.

echo "[env] git rev-parse HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo 'n/a')"

if command -v verilator >/dev/null 2>&1; then
  echo "[env] verilator: $(verilator --version | head -n1)"
else
  echo "[env] verilator: not found"
fi

if command -v g++ >/dev/null 2>&1; then
  echo "[env] g++: $(g++ --version | head -n1)"
else
  echo "[env] g++: not found"
fi

if command -v sdl2-config >/dev/null 2>&1; then
  echo "[env] sdl2-config: $(sdl2-config --version)"
else
  echo "[env] sdl2-config: not found"
fi

if command -v pkg-config >/dev/null 2>&1 && pkg-config --exists SDL2_ttf; then
  echo "[env] SDL2_ttf: $(pkg-config --modversion SDL2_ttf)"
else
  echo "[env] SDL2_ttf: not found (pkg-config SDL2_ttf)"
fi

if command -v python3 >/dev/null 2>&1; then
  echo "[env] python3: $(python3 --version 2>&1)"
else
  echo "[env] python3: not found"
fi
