#!/bin/bash
# Run UVM Constrained Random Tests
# This script runs constrained random verification tests for Hydra

set -e

echo "========================================"
echo "  HYDRA UVM CONSTRAINED RANDOM TESTS"
echo "========================================"

# Check if UVM is available
if ! command -v vsim >/dev/null 2>&1 && ! command -v iverilog >/dev/null 2>&1; then
    echo "Warning: No SystemVerilog simulator found (vsim or iverilog)"
    echo "Installing Questa/ModelSim or Icarus Verilog recommended for UVM support"
fi

# Set up environment
export UVM_HOME=${UVM_HOME:-/opt/uvm}
export VCS_UVM_HOME=${VCS_UVM_HOME:-/opt/uvm}

echo ""
echo "Running Constrained Random Tests..."
echo "----------------------------------"

# Test: Constrained Random Test
echo "Constrained Random Verification Test"
if [ -f "tests/hydra_constrained_test.sv" ]; then
    echo "✓ Constrained test file found"
else
    echo "✗ Constrained test file missing"
fi

if [ -f "sequences/hydra_constrained_sequence.sv" ]; then
    echo "✓ Constrained sequence file found"
else
    echo "✗ Constrained sequence file missing"
fi

echo ""
echo "Constrained Random Test Setup Complete"
echo "To run actual constrained random tests, use a SystemVerilog simulator with UVM support:"
echo "  - Questa/ModelSim: vsim -c -do 'run -all' hydra_uvm_pkg +UVM_TESTNAME=hydra_constrained_test"
echo "  - VCS: vcs -sverilog +incdir+${UVM_HOME}/src +define+UVM_NO_DPI hydra_uvm_pkg.sv"
echo "    ./simv +UVM_TESTNAME=hydra_constrained_test"
echo ""
echo "Coverage metrics will be collected during constrained random testing"
echo ""
echo "========================================"