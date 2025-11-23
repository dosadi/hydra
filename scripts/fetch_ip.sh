#!/usr/bin/env bash
set -euo pipefail

# Fetch script for third-party IP (LitePCIe/LiteDRAM/LiteICLink/LiteX).
# With submodules, this script is now a thin wrapper around `git submodule update`.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Ensure submodules are present at the pinned commits recorded in third_party/README.md.
# This is safe to run multiple times and is what CI should call.
SUBMODULES=(
  third_party/litepcie
  third_party/litedram
  third_party/liteiclink
  third_party/litex
)

echo "[ip] Initializing/updating third_party submodules..."
git submodule update --init --recursive "${SUBMODULES[@]}"
echo "[ip] Done. Submodules are now checked out at their pinned commits."
