#!/bin/bash
# ============================================================================
# Hydra Yosys Synthesis Runner
# Open-source FPGA synthesis using Yosys + nextpnr
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$SCRIPT_DIR/output"

echo "========================================"
echo "    HYDRA YOSYS SYNTHESIS FLOW"
echo "========================================"

# Check if Yosys is available
if ! command -v yosys >/dev/null 2>&1; then
    echo "Error: Yosys not found in PATH"
    echo "Please install Yosys: https://github.com/YosysHQ/yosys"
    exit 1
fi

# Check if nextpnr is available
if ! command -v nextpnr-ecp5 >/dev/null 2>&1 && ! command -v nextpnr-ice40 >/dev/null 2>&1; then
    echo "Error: nextpnr not found in PATH"
    echo "Please install nextpnr for your target FPGA family"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# Create Yosys synthesis script
cat > synth.ys << EOF
# Yosys synthesis script for Hydra

# Read SystemVerilog sources
read -sv $PROJECT_ROOT/rtl/voxel_framebuffer_top.sv
read -sv $PROJECT_ROOT/rtl/voxel_axil_shell.sv
read -sv $PROJECT_ROOT/rtl/voxel_axil_csr.sv
read -sv $PROJECT_ROOT/rtl/voxel_csr.sv
read -sv $PROJECT_ROOT/rtl/voxel_raycaster_core_pipelined.sv
read -sv $PROJECT_ROOT/rtl/voxel_memory_64.sv
read -sv $PROJECT_ROOT/rtl/voxel_world_gen.sv
read -sv $PROJECT_ROOT/rtl/cdc_synchronizer.sv

# Read stub files (for synthesis)
read -sv $PROJECT_ROOT/rtl/axi_dma_stub.sv
read -sv $PROJECT_ROOT/rtl/axi_sdram_stub.sv
read -sv $PROJECT_ROOT/rtl/axi_stream_sink_stub.sv

# Hierarchy analysis
hierarchy -check -top voxel_framebuffer_top

# Convert to gate-level netlist
proc
opt
memory
opt
fsm
opt

# Map to target technology (generic for now)
techmap
opt

# Write synthesis results
write_verilog synth.v
write_json synth.json

# Generate statistics
stat
EOF

echo ""
echo "Running Yosys synthesis..."
echo "-------------------------"

# Run Yosys synthesis
yosys synth.ys > synth.log 2>&1

echo ""
echo "Synthesis completed!"
echo "Output files:"
echo "  - synth.v: Gate-level netlist"
echo "  - synth.json: JSON netlist for nextpnr"
echo "  - synth.log: Synthesis log"
echo ""

# Check if we can run place and route
if command -v nextpnr-ecp5 >/dev/null 2>&1; then
    echo "Running nextpnr for ECP5..."
    nextpnr-ecp5 --json synth.json --textcfg pnr.cfg > pnr.log 2>&1
    echo "Place and route completed!"
    echo "Output: pnr.cfg"
elif command -v nextpnr-ice40 >/dev/null 2>&1; then
    echo "Running nextpnr for iCE40..."
    nextpnr-ice40 --json synth.json --asc pnr.asc > pnr.log 2>&1
    echo "Place and route completed!"
    echo "Output: pnr.asc"
else
    echo "nextpnr not available - skipping place and route"
fi

echo ""
echo "========================================"