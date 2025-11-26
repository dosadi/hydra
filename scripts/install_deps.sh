#!/usr/bin/env bash
# scripts/install_deps.sh
# Install host packages required to build and run the Verilated SDL viewer
# Designed for Debian/Ubuntu-based systems. Use with care (invokes sudo).

set -eu

usage() {
    cat <<EOF
Usage: $0 [--yes] [--dry-run]

Installs host build/runtime packages commonly required by hydra's sim:
  - verilator
  - build-essential, g++, make, cmake, pkg-config
  - libsdl2-dev, libsdl2-ttf-dev
  - python3 (for helper scripts)

Options:
  --yes       Run non-interactively (pass -y to apt)
  --dry-run   Print what would be done, do not run apt
  --help      Show this help
EOF
}

DRY=0
YES=0

while (("$#")); do
    case "$1" in
        --dry-run) DRY=1; shift ;;
        --yes) YES=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown arg: $1"; usage; exit 2 ;;
    esac
done

PKGS=(verilator build-essential g++ make cmake pkg-config python3 \
      libsdl2-dev libsdl2-ttf-dev)

echo "Detected OS: $(uname -s) $(uname -r)"

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This installer currently supports Debian/Ubuntu (apt-get)." >&2
    echo "Please install the required packages using your distro's package manager." >&2
    exit 1
fi

if [ "$DRY" -eq 1 ]; then
    echo "DRY RUN: would install: ${PKGS[*]}"
    exit 0
fi

if [ "$YES" -eq 1 ]; then
    SUDO_ARGS=(--yes)
else
    SUDO_ARGS=()
fi

echo "Updating apt cache..."
sudo apt-get update

echo "Installing packages: ${PKGS[*]}"
sudo apt-get install "${SUDO_ARGS[@]}" -y "${PKGS[@]}"

echo "Done. You may need to re-login or run 'hash -r' for new commands to be visible." 

echo "Quick checks:"
for cmd in verilator sdl2-config ttf-config; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  $cmd: OK"
    else
        echo "  $cmd: MISSING (you may need additional packages or paths)"
    fi
done

echo "Tip: run ./scripts/wrap_sim_build.sh to build the sim after installing deps."
