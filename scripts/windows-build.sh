#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOLUTION="$ROOT/drivers/windows/hydra_driver.sln"

if ! command -v msbuild >/dev/null 2>&1; then
  echo "[windows-build] msbuild not found; install Visual Studio build tools" >&2
  exit 1
fi

build_platform() {
  local platform=$1
  msbuild "$SOLUTION" /t:Rebuild /p:Configuration=Release /p:Platform="$platform" /verbosity:minimal
}

build_platform Win32
build_platform x64
