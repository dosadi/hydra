#!/bin/bash

# Hydra UVM Testbench Run Script
# This script compiles and runs the UVM verification testbench

set -e

echo "=== Hydra UVM Testbench Runner ==="

# Set up directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERIFICATION_DIR="$PROJECT_ROOT/verification/uvm"
RTL_DIR="$PROJECT_ROOT/rtl"

# Create output directory
OUTPUT_DIR="$VERIFICATION_DIR/sim"
mkdir -p "$OUTPUT_DIR"

# UVM compilation flags
UVM_FLAGS="-ntb_opts uvm-1.2"

# Source files
SOURCES=(
    "$VERIFICATION_DIR/hydra_uvm_pkg.sv"
    "$VERIFICATION_DIR/hydra_testbench.sv"
)

echo "Compiling UVM testbench..."

# Compile with VCS (if available)
if command -v vcs &> /dev/null; then
    echo "Using VCS for compilation..."
    vcs -sverilog $UVM_FLAGS -f "${SOURCES[@]}" -o "$OUTPUT_DIR/hydra_tb_simv"
    echo "Running simulation..."
    "$OUTPUT_DIR/hydra_tb_simv" +UVM_TESTNAME=hydra_csr_test

# Compile with Questa/ModelSim (if available)
elif command -v vsim &> /dev/null; then
    echo "Using ModelSim for compilation..."
    vlib "$OUTPUT_DIR/work"
    vmap work "$OUTPUT_DIR/work"

    for src in "${SOURCES[@]}"; do
        vlog -sv $UVM_FLAGS "$src"
    done

    echo "Running simulation..."
    vsim -c -do "run -all; quit" work.hydra_testbench +UVM_TESTNAME=hydra_csr_test

# Fallback: just check syntax with verilator
elif command -v verilator &> /dev/null; then
    echo "Verilator found - checking syntax only..."
    verilator --lint-only -sv $UVM_FLAGS "${SOURCES[@]}"
    echo "Syntax check passed!"

else
    echo "No SystemVerilog simulator found. Please install VCS, ModelSim, or Questa."
    echo "For syntax checking only, install Verilator."
    exit 1
fi

echo "=== Testbench run complete ==="