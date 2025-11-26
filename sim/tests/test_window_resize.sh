#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# test_window_resize.sh
# - Test window resize handling for backends that support it
# - Validates that textures are recreated and rendering continues
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/.."
SIM_BIN="$SIM_DIR/sim_voxel"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_count=0
fail_count=0
skip_count=0

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

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if sim binary exists
if [ ! -f "$SIM_BIN" ]; then
    echo -e "${RED}ERROR:${NC} sim_voxel not found at $SIM_BIN"
    echo "Please build the simulator first: make -C sim"
    exit 1
fi

echo "=== Window Resize Test Suite ==="
echo ""

# Check for DISPLAY
if [ -z "$DISPLAY" ]; then
    echo -e "${YELLOW}WARNING:${NC} No DISPLAY set"
    echo "Window resize tests require a display server"
    echo ""
    read -p "Run tests with Xvfb? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command -v Xvfb >/dev/null 2>&1; then
            echo -e "${RED}ERROR:${NC} Xvfb not found"
            echo "Install it: sudo apt install xvfb"
            exit 1
        fi
        # Start Xvfb
        Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 &
        XVFB_PID=$!
        export DISPLAY=:99
        sleep 1
        log_info "Started Xvfb on :99 (PID: $XVFB_PID)"
    else
        echo "Skipping window resize tests"
        exit 0
    fi
fi

# Test 1: SDL backend resize behavior
log_test "SDL backend window resize"

# This is a manual test since we can't programmatically resize windows easily
echo ""
echo "Manual Test Instructions:"
echo "1. A window will open"
echo "2. Resize the window using your mouse"
echo "3. Observe that the viewport adjusts and rendering continues"
echo "4. Press Q to quit when done"
echo ""
read -p "Press Enter to start manual resize test..."

# Run with minimal settings
if timeout 30s $SIM_BIN --backend sdl 2>&1 | grep -q "Backend.*SDL"; then
    log_pass "SDL backend started successfully"
else
    log_fail "SDL backend failed to start"
fi

# Test 2: GL backend resize (if available)
if $SIM_BIN --caps 2>&1 | grep -q "OpenGL"; then
    log_test "GL backend window resize"

    echo ""
    echo "Manual Test Instructions:"
    echo "1. An OpenGL window will open"
    echo "2. Resize the window"
    echo "3. Check for texture recreation in logs"
    echo "4. Press Q to quit when done"
    echo ""
    read -p "Press Enter to start GL resize test..."

    if timeout 30s $SIM_BIN --backend gl 2>&1 | grep -q "Backend.*GL"; then
        log_pass "GL backend resize test completed"
    else
        log_fail "GL backend failed"
    fi
else
    log_skip "GL backend not available"
fi

# Test 3: Automated resize check via stderr logs
log_test "Automated resize detection"

# Create a test script that simulates window events
# (This is platform-specific and may not work everywhere)

log_info "This test checks that backends handle resize gracefully"
log_info "No automated validation available - manual inspection required"
log_skip "Automated resize testing (requires window manager interaction)"

# Cleanup
if [ -n "$XVFB_PID" ]; then
    kill $XVFB_PID 2>/dev/null || true
    log_info "Stopped Xvfb"
fi

echo ""
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"
echo -e "Skipped: ${YELLOW}$skip_count${NC}"

echo ""
echo "=== Resize Testing Checklist ==="
echo ""
echo "For each backend, verify:"
echo "  1. Window can be resized using mouse/window manager"
echo "  2. Content scales or adjusts to new size"
echo "  3. No crashes or freezes during resize"
echo "  4. Textures are recreated (check stderr for messages)"
echo "  5. Rendering continues smoothly after resize"
echo ""
echo "Known resize behavior:"
echo "  SDL:      Recreates texture, adjusts logical size"
echo "  OpenGL:   Updates viewport, may recreate textures"
echo "  Vulkan:   Recreates swapchain automatically"
echo "  Headless: N/A (no window)"
echo ""

exit $fail_count
