#!/usr/bin/env bash
# scripts/wrap_sim_build.sh
# Small wrapper to build the Verilated SDL sim with helpful dependency checks

set -eu

usage() {
    cat <<EOF
Usage: $0 [--install-deps] [-j N]

Checks for required tools (verilator, libsdl2) and runs 'make' in the sim/ directory.

Options:
  --install-deps   Run ./scripts/install_deps.sh (requires sudo)
  -j N             Pass -jN to make
  --help           Show this help

Examples:
  ./scripts/wrap_sim_build.sh -j4
  ./scripts/wrap_sim_build.sh --install-deps
EOF
}

INSTALL_DEPS=0
MAKE_J=""

while (("$#")); do
    case "$1" in
        --install-deps) INSTALL_DEPS=1; shift ;;
        -j) MAKE_J="$2"; shift 2 ;;
        -j*) MAKE_J="${1#-j}"; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown arg: $1"; usage; exit 2 ;;
    esac
done

SCRIPTDIR=$(cd "$(dirname "$0")" && pwd)

if [ "$INSTALL_DEPS" -eq 1 ]; then
    echo "Running install script (may prompt for sudo)..."
    bash "$SCRIPTDIR/install_deps.sh" --yes
fi

echo "Checking for Verilator..."
if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator: not found. Please run: ./scripts/install_deps.sh" >&2
    exit 1
fi

echo "Checking for SDL2 development files..."
if ! pkg-config --exists sdl2; then
    echo "SDL2 pkg-config not found. Ensure libsdl2-dev is installed." >&2
    echo "Try: sudo apt-get install libsdl2-dev libsdl2-ttf-dev" >&2
    exit 1
fi

echo "Building sim in ./sim"
pushd sim >/dev/null
if [ -n "$MAKE_J" ]; then
    echo "Running: make -j$MAKE_J"
    make -j"$MAKE_J"
else
    echo "Running: make"
    make
fi
RC=$?
popd >/dev/null

if [ $RC -ne 0 ]; then
    echo "Build failed (exit $RC). Check sim/ output above." >&2
    exit $RC
fi

echo "Build succeeded. Run './sim/sim_voxel' to launch the viewer (or see sim/Makefile targets)."
