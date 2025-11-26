#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Shortcut to bootstrap macOS dev env for Hydra (Homebrew + Python deps).

set -euo pipefail

echo "Hydra macOS env bootstrap starting..."

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found; install from https://brew.sh/ and rerun."
    exit 1
fi

brew update
brew install sdl2 sdl2_ttf python@3.12 pkg-config

python3 -m pip install --upgrade pip
python3 -m pip install cocotb pytest

echo "macOS dev env ready. Use CMake preset 'macos' to build."
