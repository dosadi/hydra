#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# test_backend_selection.sh
# - Test backend selection precedence: CLI > env > compiled availability
# - Verifies that HYDRA_BACKEND env and --backend CLI flag work correctly
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="$SCRIPT_DIR/.."
SIM_BIN="$SIM_DIR/sim_voxel"

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass_count=0
fail_count=0

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

# Check if sim binary exists
if [ ! -f "$SIM_BIN" ]; then
    echo -e "${RED}ERROR:${NC} sim_voxel not found at $SIM_BIN"
    echo "Please build the simulator first: make -C sim"
    exit 1
fi

echo "=== Backend Selection Test Suite ==="
echo

# Test 1: --show-capabilities flag works
log_test "Verify --show-capabilities flag"
if $SIM_BIN --show-capabilities 2>&1 | grep -q "Platform Capabilities"; then
    log_pass "Capabilities dump works"
else
    log_fail "Capabilities dump failed"
fi

# Test 2: Default backend selection (should pick SDL or best available)
log_test "Default backend selection"
output=$(FRAME_DUMP=/tmp/test_default.ppm AUTO_EXIT=1 HYDRA_BACKEND= $SIM_BIN 2>&1 || true)
if echo "$output" | grep -q "Backend:"; then
    backend=$(echo "$output" | grep "Backend:" | head -1)
    log_pass "Default selection: $backend"
else
    log_fail "Could not detect selected backend"
fi

# Test 3: HYDRA_BACKEND env var
log_test "HYDRA_BACKEND env var selection"
output=$(FRAME_DUMP=/tmp/test_env.ppm AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS $SIM_BIN 2>&1 || true)
if echo "$output" | grep -q "headless"; then
    log_pass "HYDRA_BACKEND=HEADLESS respected"
else
    log_fail "HYDRA_BACKEND env var not working"
fi

# Test 4: CLI --backend flag
log_test "CLI --backend flag selection"
output=$(FRAME_DUMP=/tmp/test_cli.ppm AUTO_EXIT=1 $SIM_BIN --backend HEADLESS 2>&1 || true)
if echo "$output" | grep -q "headless"; then
    log_pass "--backend HEADLESS flag works"
else
    log_fail "--backend flag not working"
fi

# Test 5: CLI overrides env (precedence test)
log_test "CLI --backend overrides HYDRA_BACKEND env"
output=$(FRAME_DUMP=/tmp/test_precedence.ppm AUTO_EXIT=1 HYDRA_BACKEND=SDL $SIM_BIN --backend HEADLESS 2>&1 || true)
if echo "$output" | grep -q "CLI override: backend=HEADLESS"; then
    log_pass "CLI correctly overrides env var"
else
    log_fail "Precedence test failed (CLI should override env)"
fi

# Test 6: Invalid backend fallback
log_test "Invalid backend fallback behavior"
output=$(FRAME_DUMP=/tmp/test_invalid.ppm AUTO_EXIT=1 HYDRA_BACKEND=NONEXISTENT $SIM_BIN 2>&1 || true)
if echo "$output" | grep -q "not recognized"; then
    log_pass "Invalid backend detected and logged"
else
    log_fail "Invalid backend not handled properly"
fi

# Test 7: Headless backend with frame dump
log_test "Headless backend frame dump"
rm -f /tmp/test_headless.ppm
output=$(FRAME_DUMP=/tmp/test_headless.ppm AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS $SIM_BIN 2>&1 || true)
if [ -f /tmp/test_headless.ppm ]; then
    file_size=$(stat -c%s /tmp/test_headless.ppm 2>/dev/null || stat -f%z /tmp/test_headless.ppm 2>/dev/null)
    if [ "$file_size" -gt 1000 ]; then
        log_pass "Headless backend dumped frame ($file_size bytes)"
    else
        log_fail "Frame dump too small: $file_size bytes"
    fi
else
    log_fail "Headless backend did not create frame dump"
fi

# Clean up test files
rm -f /tmp/test_*.ppm

echo
echo "=== Test Summary ==="
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
