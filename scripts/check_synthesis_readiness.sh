#!/bin/bash
# ============================================================================
# Hydra Synthesis Readiness Check
# Verify that the design is ready for FPGA synthesis
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "    HYDRA SYNTHESIS READINESS CHECK"
echo "========================================"

# Check RTL files
echo ""
echo "Checking RTL files..."
echo "--------------------"

rtl_count=$(find "$PROJECT_ROOT/rtl" -name "*.sv" -not -name "*sim_harness*" | wc -l)
echo "✓ Found $rtl_count SystemVerilog RTL files"

# Check for synthesis-unsafe constructs
echo ""
echo "Checking for synthesis issues..."
echo "--------------------------------"

issues_found=0

# Check for initial blocks (not synthesizable)
if grep -r "initial begin" "$PROJECT_ROOT/rtl" --include="*.sv" >/dev/null 2>&1; then
    echo "⚠️  Found 'initial' blocks - may not be synthesizable"
    issues_found=$((issues_found + 1))
fi

# Check for delays (# delays)
if grep -r "#[0-9]" "$PROJECT_ROOT/rtl" --include="*.sv" >/dev/null 2>&1; then
    echo "⚠️  Found delay statements (#) - may not be synthesizable"
    issues_found=$((issues_found + 1))
fi

# Check for $display statements
if grep -r "\\$display" "$PROJECT_ROOT/rtl" --include="*.sv" >/dev/null 2>&1; then
    echo "⚠️  Found \$display statements - ignored in synthesis"
fi

# Check for SYNTHESIS guards
synthesis_guards=$(grep -r '`ifndef SYNTHESIS' "$PROJECT_ROOT/rtl" --include="*.sv" | wc -l)
echo "✓ Found $synthesis_guards SYNTHESIS guards"

# Check constraints
echo ""
echo "Checking constraints..."
echo "----------------------"

if [ -f "$PROJECT_ROOT/constraints/baseline.sdc" ]; then
    echo "✓ Found baseline SDC constraints"
else
    echo "✗ Missing baseline SDC constraints"
    issues_found=$((issues_found + 1))
fi

if [ -f "$PROJECT_ROOT/constraints/artix7.xdc" ]; then
    echo "✓ Found Artix-7 XDC constraints"
else
    echo "⚠️  Missing Artix-7 XDC constraints (optional)"
fi

# Check synthesis tools availability
echo ""
echo "Checking synthesis tools..."
echo "---------------------------"

tools_available=0

if command -v vivado >/dev/null 2>&1; then
    echo "✓ Vivado available"
    tools_available=$((tools_available + 1))
else
    echo "⚠️  Vivado not found"
fi

if command -v quartus_sh >/dev/null 2>&1; then
    echo "✓ Quartus available"
    tools_available=$((tools_available + 1))
else
    echo "⚠️  Quartus not found"
fi

if command -v yosys >/dev/null 2>&1; then
    echo "✓ Yosys available"
    tools_available=$((tools_available + 1))
else
    echo "⚠️  Yosys not found"
fi

# Check synthesis scripts
echo ""
echo "Checking synthesis scripts..."
echo "-----------------------------"

if [ -x "$PROJECT_ROOT/synthesis/vivado/run_synthesis.sh" ]; then
    echo "✓ Vivado synthesis script ready"
else
    echo "✗ Vivado synthesis script missing or not executable"
    issues_found=$((issues_found + 1))
fi

if [ -x "$PROJECT_ROOT/synthesis/quartus/run_synthesis.sh" ]; then
    echo "✓ Quartus synthesis script ready"
else
    echo "✗ Quartus synthesis script missing or not executable"
    issues_found=$((issues_found + 1))
fi

if [ -x "$PROJECT_ROOT/synthesis/yosys/run_synthesis.sh" ]; then
    echo "✓ Yosys synthesis script ready"
else
    echo "✗ Yosys synthesis script missing or not executable"
    issues_found=$((issues_found + 1))
fi

# Summary
echo ""
echo "========================================"
echo "           READINESS SUMMARY"
echo "========================================"

if [ $issues_found -eq 0 ]; then
    echo "✅ SYNTHESIS READY"
    echo "   - No blocking issues found"
    echo "   - $tools_available synthesis tools available"
    echo ""
    echo "Next steps:"
    echo "  make synth-vivado    # Run Vivado synthesis"
    echo "  make synth-quartus   # Run Quartus synthesis"
    echo "  make synth-yosys     # Run Yosys synthesis"
    echo "  make synth-analyze   # Analyze results"
else
    echo "⚠️  ISSUES FOUND: $issues_found blocking issues"
    echo "   Please resolve issues before synthesis"
fi

echo ""
echo "========================================"

exit $issues_found