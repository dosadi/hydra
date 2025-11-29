#!/bin/bash
# Run UVM Performance Tests
# This script runs performance profiling tests for Hydra verification

set -e

echo "========================================"
echo "    HYDRA UVM PERFORMANCE TESTS"
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
echo "Running Performance Profiling Tests..."
echo "------------------------------------"

# Test: Performance Test
echo "Performance Profiling Test"
if [ -f "tests/hydra_performance_test.sv" ]; then
    echo "✓ Performance test file found"
else
    echo "✗ Performance test file missing"
fi

if [ -f "sequences/hydra_performance_sequence.sv" ]; then
    echo "✓ Performance sequence file found"
else
    echo "✗ Performance sequence file missing"
fi

echo ""
echo "Performance Test Setup Complete"
echo "To run actual performance tests, use a SystemVerilog simulator with UVM support:"
echo "  - Questa/ModelSim: vsim -c -do 'run -all' hydra_uvm_pkg +UVM_TESTNAME=hydra_performance_test"
echo "  - VCS: vcs -sverilog +incdir+${UVM_HOME}/src +define+UVM_NO_DPI hydra_uvm_pkg.sv"
echo "    ./simv +UVM_TESTNAME=hydra_performance_test"
echo ""
echo "Performance metrics will be reported in the simulation output"
echo ""
echo "========================================"