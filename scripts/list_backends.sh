#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# list_backends.sh
# - List available backends with their compile-time and runtime status
# - Quick reference for backend selection
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BIN="$PROJECT_ROOT/sim/sim_voxel"
SYSNAME="$(uname -s) $(uname -m)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Options
SHOW_RUNTIME=0
JSON_OUTPUT=0

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=${ID:-unknown}
else
    case "$(uname)" in
        Darwin)
            OS="macos"
            ;;
        FreeBSD)
            OS="freebsd"
            ;;
        Linux)
            OS="linux"
            ;;
        *)
            OS="unknown"
            ;;
    esac
fi

for arg in "$@"; do
    case $arg in
        --runtime|-r)
            SHOW_RUNTIME=1
            ;;
        --json|-j)
            JSON_OUTPUT=1
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "List available Hydra backends."
            echo ""
            echo "Options:"
            echo "  --runtime, -r  Test runtime availability (requires sim binary)"
            echo "  --json, -j     Output in JSON format"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
    esac
done

# Get backend info from sim binary if available
COMPILED_BACKENDS=""
if [ -f "$SIM_BIN" ]; then
    if [ $SHOW_RUNTIME -eq 1 ]; then
        cap_output=$($SIM_BIN --caps 2>&1 || true)
        COMPILED_BACKENDS=$(echo "$cap_output" | sed -n '/Available backends:/,/=====/p' | grep '  - ' | sed 's/  - //' | tr '\n' ',' | sed 's/,$//')
    fi
fi

# Define all possible backends
declare -A BACKENDS
BACKENDS[SDL]="Default cross-platform backend using SDL2"
BACKENDS[Headless]="No-display backend for CI and automation"
BACKENDS[OpenGL]="Hardware-accelerated OpenGL backend"
BACKENDS[Vulkan]="High-performance Vulkan backend (experimental)"
BACKENDS[Wayland]="Native Wayland backend (Linux, stub)"
BACKENDS[X11]="Native X11 backend (Linux, stub)"
BACKENDS[fbdev]="Linux framebuffer device backend (stub)"
BACKENDS[Win32]="Native Win32/Direct2D backend (Windows, stub)"
BACKENDS[macOS]="Native Cocoa/Metal backend (macOS, stub)"

# Check which are compiled
declare -A COMPILED
COMPILED[SDL]="always"
COMPILED[Headless]="always"

if [ -n "$COMPILED_BACKENDS" ]; then
    for b in SDL Headless OpenGL Vulkan Wayland X11 fbdev Win32 macOS; do
        if echo "$COMPILED_BACKENDS" | grep -qi "$b"; then
            COMPILED[$b]="yes"
        else
            COMPILED[$b]="no"
        fi
    done
fi

# Runtime test results (if requested)
declare -A RUNTIME_OK

if [ $SHOW_RUNTIME -eq 1 ] && [ -f "$SIM_BIN" ]; then
    # Test headless (should always work)
    temp_frame="/tmp/backend_test_$$.ppm"
    if HYDRA_BACKEND=headless FRAME_DUMP="$temp_frame" AUTO_EXIT=1 $SIM_BIN >/dev/null 2>&1; then
        RUNTIME_OK[Headless]="yes"
    else
        RUNTIME_OK[Headless]="no"
    fi
    rm -f "$temp_frame"

    # Could test others but they may require DISPLAY
    # For now just mark as "untested"
    for b in SDL OpenGL Vulkan Wayland X11 fbdev Win32 macOS; do
        RUNTIME_OK[$b]="untested"
    done
fi

# Output format
if [ $JSON_OUTPUT -eq 1 ]; then
    cat <<EOF
{
  "platform": "$SYSNAME",
  "os": "$OS",
  "compiled_backends": "${COMPILED_BACKENDS:-}",
  "backends": [
    {
      "name": "SDL",
      "description": "${BACKENDS[SDL]}",
      "compiled": "${COMPILED[SDL]:-unknown}",
      "status": "${COMPILED[SDL]:-unknown}",
      "runtime": "${RUNTIME_OK[SDL]:-untested}"
    },
    {
      "name": "Headless",
      "description": "${BACKENDS[Headless]}",
      "compiled": "${COMPILED[Headless]:-unknown}",
      "status": "${COMPILED[Headless]:-unknown}",
      "runtime": "${RUNTIME_OK[Headless]:-untested}"
    },
    {
      "name": "OpenGL",
      "description": "${BACKENDS[OpenGL]}",
      "compiled": "${COMPILED[OpenGL]:-unknown}",
      "status": "${COMPILED[OpenGL]:-unknown}",
      "runtime": "${RUNTIME_OK[OpenGL]:-untested}"
    },
    {
      "name": "Vulkan",
      "description": "${BACKENDS[Vulkan]}",
      "compiled": "${COMPILED[Vulkan]:-unknown}",
      "status": "${COMPILED[Vulkan]:-unknown}",
      "runtime": "${RUNTIME_OK[Vulkan]:-untested}"
    },
    {
      "name": "Wayland",
      "description": "${BACKENDS[Wayland]}",
      "compiled": "${COMPILED[Wayland]:-unknown}",
      "status": "${COMPILED[Wayland]:-unknown}",
      "runtime": "${RUNTIME_OK[Wayland]:-untested}"
    },
    {
      "name": "X11",
      "description": "${BACKENDS[X11]}",
      "compiled": "${COMPILED[X11]:-unknown}",
      "status": "${COMPILED[X11]:-unknown}",
      "runtime": "${RUNTIME_OK[X11]:-untested}"
    },
    {
      "name": "fbdev",
      "description": "${BACKENDS[fbdev]}",
      "compiled": "${COMPILED[fbdev]:-unknown}",
      "status": "${COMPILED[fbdev]:-unknown}",
      "runtime": "${RUNTIME_OK[fbdev]:-untested}"
    },
    {
      "name": "Win32",
      "description": "${BACKENDS[Win32]}",
      "compiled": "${COMPILED[Win32]:-unknown}",
      "status": "${COMPILED[Win32]:-unknown}",
      "runtime": "${RUNTIME_OK[Win32]:-untested}"
    },
    {
      "name": "macOS",
      "description": "${BACKENDS[macOS]}",
      "compiled": "${COMPILED[macOS]:-unknown}",
      "status": "${COMPILED[macOS]:-unknown}",
      "runtime": "${RUNTIME_OK[macOS]:-untested}"
    }
  ]
}
EOF
    exit 0
else
    echo -e "${BOLD}=== Hydra Backends ===${NC}"
    echo ""

    printf "%-12s %-10s %-10s %s\n" "Backend" "Compiled" "Runtime" "Description"
    printf "%-12s %-10s %-10s %s\n" "--------" "--------" "-------" "-----------"

    for b in SDL Headless OpenGL Vulkan Wayland X11 fbdev Win32 macOS; do
        # Compiled status
        compiled_status=""
        if [ "${COMPILED[$b]}" == "yes" ] || [ "${COMPILED[$b]}" == "always" ]; then
            compiled_status="${GREEN}✓${NC}"
        elif [ "${COMPILED[$b]}" == "no" ]; then
            compiled_status="${RED}✗${NC}"
        else
            compiled_status="${YELLOW}?${NC}"
        fi

        # Runtime status
        runtime_status=""
        if [ -n "${RUNTIME_OK[$b]}" ]; then
            if [ "${RUNTIME_OK[$b]}" == "yes" ]; then
                runtime_status="${GREEN}OK${NC}"
            elif [ "${RUNTIME_OK[$b]}" == "no" ]; then
                runtime_status="${RED}FAIL${NC}"
            else
                runtime_status="${YELLOW}?${NC}"
            fi
        else
            runtime_status="-"
        fi

        printf "%-21s %-19s %-18s %s\n" \
            "$(echo -e $b)" \
            "$(echo -e $compiled_status)" \
            "$(echo -e $runtime_status)" \
            "${BACKENDS[$b]}"
    done

    echo ""
    echo -e "${CYAN}Legend:${NC}"
    echo -e "  ${GREEN}✓${NC} = Compiled and available"
    echo -e "  ${RED}✗${NC} = Not compiled"
    echo -e "  ${YELLOW}?${NC} = Status unknown (build sim binary first)"
    if [ $SHOW_RUNTIME -eq 1 ]; then
        echo -e "  ${GREEN}OK${NC} = Runtime test passed"
        echo -e "  ${RED}FAIL${NC} = Runtime test failed"
    fi

    echo ""
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  Select backend: ${YELLOW}HYDRA_BACKEND=gl ./sim/sim_voxel${NC}"
    echo -e "  Or use CLI:     ${YELLOW}./sim/sim_voxel --backend headless${NC}"
    echo -e "  Show details:   ${YELLOW}./sim/sim_voxel --caps${NC}"

    if [ ! -f "$SIM_BIN" ]; then
        echo ""
        echo -e "${YELLOW}Note:${NC} sim binary not found at $SIM_BIN"
        echo -e "Build it to see compiled backends: ${CYAN}make -C sim${NC}"
    fi

    if [ $SHOW_RUNTIME -eq 0 ]; then
        echo ""
        echo -e "${BLUE}Tip:${NC} Use ${CYAN}--runtime${NC} to test backend initialization"
    fi
fi
