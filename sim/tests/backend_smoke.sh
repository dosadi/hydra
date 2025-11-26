#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# backend_smoke.sh
# - Minimal smoke test for backend infrastructure
# - Quick sanity check that backends can initialize and render
# - Useful for CI and pre-commit checks
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/.."
SIM_BIN="$SIM_DIR/sim_voxel"
TEMP_DIR="${TEMP_DIR:-/tmp}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_count=0
fail_count=0
skip_count=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((pass_count++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((fail_count++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((skip_count++))
}

# Parse command line options
QUICK_MODE=0
VERBOSE=0

for arg in "$@"; do
    case $arg in
        --quick|-q)
            QUICK_MODE=1
            ;;
        --verbose|-v)
            VERBOSE=1
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --quick, -q    Quick mode (headless only, 1 frame)"
            echo "  --verbose, -v  Verbose output (show sim stderr)"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
    esac
done

# Check if sim binary exists
if [ ! -f "$SIM_BIN" ]; then
    echo -e "${RED}ERROR:${NC} sim_voxel not found at $SIM_BIN"
    echo "Please build the simulator first: make -C sim"
    exit 1
fi

echo "=== Backend Smoke Test ==="
echo "Binary: $SIM_BIN"
echo "Mode: $([ $QUICK_MODE -eq 1 ] && echo 'Quick' || echo 'Full')"
echo ""

# Test 1: Capabilities check
log_test "Backend capabilities check"
cap_output=$($SIM_BIN --caps 2>&1 || true)
if echo "$cap_output" | grep -q "Platform Capabilities"; then
    log_pass "Capabilities check works"

    # Parse available backends
    available_backends=$(echo "$cap_output" | sed -n '/Available backends:/,/=====/p' | grep '  - ' | sed 's/  - //' | tr '\n' ' ')
    log_info "Available backends: $available_backends"
else
    log_fail "Capabilities check failed"
fi

# Test 2: Headless backend (always available)
log_test "Headless backend smoke"
frame_file="$TEMP_DIR/smoke_headless_$$.ppm"
rm -f "$frame_file"

if [ $VERBOSE -eq 1 ]; then
    output=$(HYDRA_BACKEND=headless FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
    echo "$output"
else
    output=$(HYDRA_BACKEND=headless FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
fi

if [ -f "$frame_file" ]; then
    size=$(stat -c%s "$frame_file" 2>/dev/null || stat -f%z "$frame_file" 2>/dev/null)
    if [ "$size" -gt 1000 ]; then
        log_pass "Headless backend rendered frame ($size bytes)"
    else
        log_fail "Headless frame too small: $size bytes"
    fi
    rm -f "$frame_file"
else
    log_fail "Headless backend did not create frame dump"
fi

# Quick mode: skip remaining tests
if [ $QUICK_MODE -eq 1 ]; then
    log_info "Quick mode: skipping additional backend tests"
    echo ""
    echo "=== Quick Smoke Summary ==="
    echo -e "Passed: ${GREEN}$pass_count${NC}"
    echo -e "Failed: ${RED}$fail_count${NC}"
    [ $fail_count -eq 0 ] && echo -e "${GREEN}Quick smoke passed!${NC}" || echo -e "${RED}Quick smoke failed.${NC}"
    exit $fail_count
fi

# Test 3: SDL backend (should always work)
log_test "SDL backend smoke"
frame_file="$TEMP_DIR/smoke_sdl_$$.ppm"
rm -f "$frame_file"

# Use SDL with dummy video driver to avoid needing X11/Wayland
if [ $VERBOSE -eq 1 ]; then
    output=$(SDL_VIDEODRIVER=dummy HYDRA_BACKEND=sdl FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
    echo "$output"
else
    output=$(SDL_VIDEODRIVER=dummy HYDRA_BACKEND=sdl FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
fi

if echo "$output" | grep -qi "sdl\|dummy"; then
    log_pass "SDL backend initialized"
else
    log_fail "SDL backend failed to initialize"
fi

rm -f "$frame_file"

# Test 4: GL backend (if available)
if echo "$available_backends" | grep -qi "opengl"; then
    log_test "OpenGL backend smoke"

    # GL requires display; skip if no DISPLAY and not in CI with Xvfb
    if [ -z "$DISPLAY" ] && ! pgrep -x Xvfb > /dev/null 2>&1; then
        log_skip "GL backend (no DISPLAY available)"
    else
        frame_file="$TEMP_DIR/smoke_gl_$$.ppm"
        rm -f "$frame_file"

        if [ $VERBOSE -eq 1 ]; then
            output=$(HYDRA_BACKEND=gl FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
            echo "$output"
        else
            output=$(HYDRA_BACKEND=gl FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
        fi

        if echo "$output" | grep -qi "gl\|opengl" && ! echo "$output" | grep -qi "error.*failed"; then
            log_pass "GL backend initialized"
        else
            log_fail "GL backend failed"
        fi

        rm -f "$frame_file"
    fi
else
    log_skip "GL backend (not compiled)"
fi

# Test 5: Vulkan backend (if available)
if echo "$available_backends" | grep -qi "vulkan"; then
    log_test "Vulkan backend smoke"

    # Vulkan requires display; skip if no DISPLAY
    if [ -z "$DISPLAY" ] && ! pgrep -x Xvfb > /dev/null 2>&1; then
        log_skip "Vulkan backend (no DISPLAY available)"
    else
        frame_file="$TEMP_DIR/smoke_vulkan_$$.ppm"
        rm -f "$frame_file"

        if [ $VERBOSE -eq 1 ]; then
            output=$(HYDRA_BACKEND=vulkan FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
            echo "$output"
        else
            output=$(HYDRA_BACKEND=vulkan FRAME_DUMP="$frame_file" AUTO_EXIT=1 $SIM_BIN 2>&1 || true)
        fi

        if echo "$output" | grep -qi "vulkan" && ! echo "$output" | grep -qi "error.*failed"; then
            log_pass "Vulkan backend initialized"
        elif echo "$output" | grep -qi "no suitable.*device"; then
            log_skip "Vulkan backend (no suitable device)"
        else
            log_fail "Vulkan backend failed"
        fi

        rm -f "$frame_file"
    fi
else
    log_skip "Vulkan backend (not compiled)"
fi

# Test 6: Frame dump consistency
log_test "Frame dump consistency"
frame1="$TEMP_DIR/smoke_frame1_$$.ppm"
frame2="$TEMP_DIR/smoke_frame2_$$.ppm"
rm -f "$frame1" "$frame2"

# Render two frames with same seed
HYDRA_BACKEND=headless FRAME_DUMP="$frame1" AUTO_EXIT=1 HYDRA_WORLD_SEED=42 $SIM_BIN >/dev/null 2>&1 || true
HYDRA_BACKEND=headless FRAME_DUMP="$frame2" AUTO_EXIT=1 HYDRA_WORLD_SEED=42 $SIM_BIN >/dev/null 2>&1 || true

if [ -f "$frame1" ] && [ -f "$frame2" ]; then
    if cmp -s "$frame1" "$frame2"; then
        log_pass "Frame dumps are deterministic"
    else
        log_fail "Frame dumps differ (non-deterministic)"
    fi
else
    log_fail "Could not create test frames"
fi

rm -f "$frame1" "$frame2"

# Summary
echo ""
echo "=== Smoke Test Summary ==="
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"
echo -e "Skipped: ${YELLOW}$skip_count${NC}"

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}All smoke tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
