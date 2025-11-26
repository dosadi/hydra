#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# probe_platform.sh
# - Comprehensive platform and backend probe
# - Checks compile-time and runtime availability
# - Provides actionable recommendations for missing backends
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BIN="$PROJECT_ROOT/sim/sim_voxel"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Options
JSON_OUTPUT=0
VERBOSE=0
CHECK_RUNTIME=0

for arg in "$@"; do
    case $arg in
        --json)
            JSON_OUTPUT=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        --runtime|-r)
            CHECK_RUNTIME=1
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Check backend availability and provide setup recommendations."
            echo ""
            echo "Options:"
            echo "  --json         Output in JSON format"
            echo "  --verbose, -v  Show detailed information"
            echo "  --runtime, -r  Test runtime initialization (requires sim binary)"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
    esac
done

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" == "Darwin" ]; then
        echo "macos"
    elif [ "$(uname)" == "FreeBSD" ]; then
        echo "freebsd"
    elif [ "$OS" == "Windows_NT" ]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Check if command exists
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Check if library is available
has_lib() {
    case "$OS" in
        ubuntu|debian)
            dpkg -l "$1" >/dev/null 2>&1
            ;;
        fedora|rhel|centos)
            rpm -q "$1" >/dev/null 2>&1
            ;;
        arch)
            pacman -Q "$1" >/dev/null 2>&1
            ;;
        macos)
            brew list "$1" >/dev/null 2>&1
            ;;
        freebsd)
            pkg info "$1" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Check SDL2
check_sdl() {
    local status="missing"
    local version=""
    local video_driver=""

    if has_cmd sdl2-config; then
        version=$(sdl2-config --version 2>/dev/null || echo "unknown")
        status="available"
    elif has_lib libsdl2-dev || has_lib SDL2 || has_lib sdl2; then
        status="available"
        version="installed"
    fi

    # Try to detect video driver
    if [ -n "$DISPLAY" ]; then
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            video_driver="wayland"
        else
            video_driver="x11"
        fi
    else
        video_driver="none (headless)"
    fi

    echo "$status|$version|$video_driver"
}

# Check OpenGL
check_opengl() {
    local status="missing"
    local version=""
    local renderer=""

    if has_cmd glxinfo; then
        version=$(glxinfo 2>/dev/null | grep "OpenGL version" | cut -d: -f2 | xargs || echo "unknown")
        renderer=$(glxinfo 2>/dev/null | grep "OpenGL renderer" | cut -d: -f2 | xargs || echo "unknown")
        if [ -n "$version" ] && [ "$version" != "unknown" ]; then
            status="available"
        fi
    elif has_lib libgl1-mesa-dev || has_lib mesa-libGL || has_lib mesa; then
        status="installed"
        version="unknown (run glxinfo to check)"
    fi

    echo "$status|$version|$renderer"
}

# Check Vulkan
check_vulkan() {
    local status="missing"
    local version=""
    local devices=""

    if has_cmd vulkaninfo; then
        version=$(vulkaninfo 2>/dev/null | grep "Vulkan Instance Version:" | cut -d: -f2 | xargs || echo "unknown")
        device_count=$(vulkaninfo 2>/dev/null | grep -c "deviceName" || echo "0")
        if [ "$device_count" -gt 0 ]; then
            status="available"
            devices="$device_count device(s)"
        else
            status="no-devices"
        fi
    elif has_lib libvulkan-dev || has_lib vulkan-loader || has_lib vulkan; then
        status="installed"
        version="unknown (run vulkaninfo to check)"
    fi

    echo "$status|$version|$devices"
}

# Get installation commands
get_install_cmd() {
    local package=$1
    case "$OS" in
        ubuntu|debian)
            echo "sudo apt install $package"
            ;;
        fedora|rhel|centos)
            echo "sudo dnf install $package"
            ;;
        arch)
            echo "sudo pacman -S $package"
            ;;
        macos)
            echo "brew install $package"
            ;;
        freebsd)
            echo "sudo pkg install $package"
            ;;
        *)
            echo "install $package"
            ;;
    esac
}

if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${BOLD}=== Hydra Platform Probe ===${NC}"
    echo ""
    echo -e "${CYAN}Platform:${NC} $(uname -s) $(uname -m)"
    echo -e "${CYAN}OS:${NC} $OS"
    echo ""
fi

# Array to store results
declare -a results

# SDL Check
IFS='|' read -r sdl_status sdl_version sdl_driver <<< "$(check_sdl)"
results+=("SDL|$sdl_status|$sdl_version|$sdl_driver")

if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${BOLD}SDL2:${NC}"
    if [ "$sdl_status" == "available" ]; then
        echo -e "  Status: ${GREEN}✓ Available${NC}"
        echo -e "  Version: $sdl_version"
        echo -e "  Video Driver: $sdl_driver"
    else
        echo -e "  Status: ${RED}✗ Missing${NC}"
        case "$OS" in
            ubuntu|debian)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'libsdl2-dev libsdl2-ttf-dev')"
                ;;
            fedora|rhel|centos)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'SDL2-devel SDL2_ttf-devel')"
                ;;
            arch)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'sdl2 sdl2_ttf')"
                ;;
            macos)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'sdl2 sdl2_ttf')"
                ;;
            freebsd)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'sdl2 sdl2_ttf')"
                ;;
        esac
    fi
    echo ""
fi

# OpenGL Check
IFS='|' read -r gl_status gl_version gl_renderer <<< "$(check_opengl)"
results+=("OpenGL|$gl_status|$gl_version|$gl_renderer")

if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${BOLD}OpenGL:${NC}"
    if [ "$gl_status" == "available" ]; then
        echo -e "  Status: ${GREEN}✓ Available${NC}"
        echo -e "  Version: $gl_version"
        [ $VERBOSE -eq 1 ] && echo -e "  Renderer: $gl_renderer"
    elif [ "$gl_status" == "installed" ]; then
        echo -e "  Status: ${YELLOW}⚠ Installed (not tested)${NC}"
        echo -e "  ${BLUE}Note:${NC} Run 'glxinfo' to verify"
    else
        echo -e "  Status: ${RED}✗ Missing${NC}"
        case "$OS" in
            ubuntu|debian)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'libgl1-mesa-dev mesa-utils')"
                ;;
            fedora|rhel|centos)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'mesa-libGL-devel mesa-demos')"
                ;;
            arch)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'mesa mesa-demos')"
                ;;
            macos)
                echo -e "  ${BLUE}Note:${NC} OpenGL is deprecated on macOS but still available"
                ;;
            freebsd)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'mesa-libs mesa-demos')"
                ;;
        esac
    fi
    echo ""
fi

# Vulkan Check
IFS='|' read -r vk_status vk_version vk_devices <<< "$(check_vulkan)"
results+=("Vulkan|$vk_status|$vk_version|$vk_devices")

if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${BOLD}Vulkan:${NC}"
    if [ "$vk_status" == "available" ]; then
        echo -e "  Status: ${GREEN}✓ Available${NC}"
        echo -e "  Version: $vk_version"
        echo -e "  Devices: $vk_devices"
    elif [ "$vk_status" == "no-devices" ]; then
        echo -e "  Status: ${YELLOW}⚠ No devices found${NC}"
        echo -e "  ${YELLOW}Note:${NC} Vulkan loader installed but no compatible GPU drivers"
        case "$OS" in
            ubuntu|debian)
                echo -e "  ${YELLOW}Install drivers:${NC} $(get_install_cmd 'mesa-vulkan-drivers')"
                ;;
            fedora|rhel|centos)
                echo -e "  ${YELLOW}Install drivers:${NC} $(get_install_cmd 'mesa-vulkan-drivers')"
                ;;
        esac
    elif [ "$vk_status" == "installed" ]; then
        echo -e "  Status: ${YELLOW}⚠ Installed (not tested)${NC}"
        echo -e "  ${BLUE}Note:${NC} Run 'vulkaninfo' to verify"
    else
        echo -e "  Status: ${RED}✗ Missing${NC}"
        case "$OS" in
            ubuntu|debian)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'libvulkan-dev vulkan-tools mesa-vulkan-drivers')"
                ;;
            fedora|rhel|centos)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'vulkan-headers vulkan-loader vulkan-tools mesa-vulkan-drivers')"
                ;;
            arch)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'vulkan-headers vulkan-icd-loader vulkan-tools mesa')"
                ;;
            macos)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'molten-vk vulkan-tools')"
                echo -e "  ${BLUE}Note:${NC} Vulkan on macOS uses MoltenVK (Metal translation)"
                ;;
            freebsd)
                echo -e "  ${YELLOW}Install:${NC} $(get_install_cmd 'vulkan-headers vulkan-loader')"
                ;;
        esac
    fi
    echo ""
fi

# Check runtime if requested and sim binary exists
if [ $CHECK_RUNTIME -eq 1 ]; then
    if [ -f "$SIM_BIN" ]; then
        if [ $JSON_OUTPUT -eq 0 ]; then
            echo -e "${BOLD}Runtime Backend Check:${NC}"
        fi

        cap_output=$($SIM_BIN --caps 2>&1 || true)
        available_backends=$(echo "$cap_output" | sed -n '/Available backends:/,/=====/p' | grep '  - ' | sed 's/  - //' | tr '\n' ',' | sed 's/,$//')

        if [ $JSON_OUTPUT -eq 0 ]; then
            echo -e "  ${CYAN}Compiled backends:${NC} $available_backends"

            # Quick init test for headless
            if echo "$available_backends" | grep -qi "headless"; then
                frame_file="/tmp/backend_probe_$$.ppm"
                rm -f "$frame_file"
                if HYDRA_BACKEND=headless FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN >/dev/null 2>&1; then
                    if [ -f "$frame_file" ]; then
                        echo -e "  ${GREEN}✓${NC} Headless backend functional"
                        rm -f "$frame_file"
                    fi
                fi
            fi
        fi
    else
        if [ $JSON_OUTPUT -eq 0 ]; then
            echo -e "${YELLOW}Runtime check skipped:${NC} sim binary not found at $SIM_BIN"
            echo -e "Build first: ${CYAN}make -C sim${NC}"
        fi
    fi
    [ $JSON_OUTPUT -eq 0 ] && echo ""
fi

# Recommendations
if [ $JSON_OUTPUT -eq 0 ]; then
    echo -e "${BOLD}=== Recommendations ===${NC}"

    all_ok=1
    if [ "$sdl_status" != "available" ]; then
        echo -e "${YELLOW}•${NC} Install SDL2 for basic backend support (required)"
        all_ok=0
    fi

    if [ "$gl_status" == "missing" ]; then
        echo -e "${YELLOW}•${NC} Install OpenGL for hardware-accelerated rendering (recommended)"
        all_ok=0
    elif [ "$gl_status" == "installed" ]; then
        echo -e "${BLUE}•${NC} Verify OpenGL with: ${CYAN}glxinfo | grep OpenGL${NC}"
    fi

    if [ "$vk_status" == "missing" ]; then
        echo -e "${BLUE}•${NC} Install Vulkan for high-performance rendering (optional)"
    elif [ "$vk_status" == "no-devices" ]; then
        echo -e "${YELLOW}•${NC} Install Vulkan GPU drivers for Vulkan support"
    elif [ "$vk_status" == "installed" ]; then
        echo -e "${BLUE}•${NC} Verify Vulkan with: ${CYAN}vulkaninfo${NC}"
    fi

    if [ -z "$DISPLAY" ]; then
        echo -e "${BLUE}•${NC} No DISPLAY set - use headless backend or set DISPLAY"
    fi

    if [ $all_ok -eq 1 ]; then
        echo -e "${GREEN}✓ All essential backends available${NC}"
    fi

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Install missing dependencies (see above)"
    echo -e "  2. Build simulator: ${CYAN}make -C sim${NC}"
    echo -e "  3. Check capabilities: ${CYAN}./sim/sim_voxel --caps${NC}"
    echo -e "  4. Run smoke test: ${CYAN}./sim/tests/backend_smoke.sh${NC}"
fi

# JSON output
if [ $JSON_OUTPUT -eq 1 ]; then
    echo "{"
    echo "  \"platform\": {"
    echo "    \"os\": \"$OS\","
    echo "    \"kernel\": \"$(uname -s)\","
    echo "    \"arch\": \"$(uname -m)\""
    echo "  },"
    echo "  \"backends\": {"
    echo "    \"sdl\": {"
    echo "      \"status\": \"$sdl_status\","
    echo "      \"version\": \"$sdl_version\","
    echo "      \"driver\": \"$sdl_driver\""
    echo "    },"
    echo "    \"opengl\": {"
    echo "      \"status\": \"$gl_status\","
    echo "      \"version\": \"$gl_version\","
    echo "      \"renderer\": \"$gl_renderer\""
    echo "    },"
    echo "    \"vulkan\": {"
    echo "      \"status\": \"$vk_status\","
    echo "      \"version\": \"$vk_version\","
    echo "      \"devices\": \"$vk_devices\""
    echo "    }"
    echo "  }"
    if [ $CHECK_RUNTIME -eq 1 ] && [ -f "$SIM_BIN" ]; then
        echo "  ,\"runtime\": {"
        echo "    \"available_backends\": \"$available_backends\""
        echo "  }"
    fi
    echo "}"
fi

# Exit code: 0 if SDL is available, 1 otherwise
[ "$sdl_status" == "available" ]
