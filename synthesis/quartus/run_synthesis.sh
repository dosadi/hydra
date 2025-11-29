#!/bin/bash
# ============================================================================
# Hydra Quartus Synthesis Runner
# Automated synthesis execution script for Intel Quartus
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
QUARTUS_DIR="$SCRIPT_DIR/quartus_project"

echo "========================================"
echo "    HYDRA QUARTUS SYNTHESIS FLOW"
echo "========================================"

# Check if Quartus is available
if ! command -v quartus_sh >/dev/null 2>&1; then
    echo "Error: Quartus not found in PATH"
    echo "Please ensure Intel Quartus is installed and in your PATH"
    exit 1
fi

# Create project directory
mkdir -p "$QUARTUS_DIR"
cd "$QUARTUS_DIR"

# Create Quartus project file
cat > hydra_synth.qpf << EOF
# Quartus Project File for Hydra
PROJECT_REVISION = hydra_synth
EOF

# Create Quartus settings file
cat > hydra_synth.qsf << EOF
# Quartus Settings File for Hydra

# Project settings
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name DEVICE_FAMILY "${DEVICE_FAMILY:-Arria 10}"
set_global_assignment -name DEVICE ${DEVICE:-10AX115S2F45I1SG}
set_global_assignment -name TOP_LEVEL_ENTITY voxel_framebuffer_top

# Timing constraints
set_global_assignment -name SDC_FILE ../../constraints/baseline.sdc

# Analysis & Synthesis settings
set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED
set_global_assignment -name SYNTHESIS_EFFORT FAST

# Fitter settings
set_global_assignment -name FITTER_EFFORT FAST_FIT
set_global_assignment -name OPTIMIZE_FOR_SPEED ON

# Enable timing-driven compilation
set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS ON
EOF

# Add RTL source files
echo "" >> hydra_synth.qsf
echo "# RTL Source Files" >> hydra_synth.qsf

for file in "$PROJECT_ROOT/rtl"/*.sv; do
    if [[ $(basename "$file") != "voxel_sim_harness.sv" ]]; then
        echo "set_global_assignment -name SYSTEMVERILOG_FILE $file" >> hydra_synth.qsf
    fi
done

echo ""
echo "Running analysis and synthesis..."
echo "---------------------------------"

# Run analysis and synthesis
quartus_sh --flow compile hydra_synth

echo ""
echo "Generating reports..."
echo "--------------------"

# Generate timing and utilization reports
quartus_sta -t <(echo "
project_open hydra_synth
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -to_clock * -npaths 100 -file timing.rpt
report_clocks -file clocks.rpt
report_ucp -file ucp.rpt
") hydra_synth

echo ""
echo "Synthesis flow completed!"
echo "Reports available in: $QUARTUS_DIR/output_files"
echo "Bitstream: output_files/hydra_synth.sof"
echo ""
echo "========================================"