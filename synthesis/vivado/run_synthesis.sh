#!/bin/bash
# ============================================================================
# Hydra Vivado Synthesis Runner
# Automated synthesis execution script
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
VIVADO_DIR="$SCRIPT_DIR/vivado_project"

echo "========================================"
echo "    HYDRA VIVADO SYNTHESIS FLOW"
echo "========================================"

# Check if Vivado is available
if ! command -v vivado >/dev/null 2>&1; then
    echo "Error: Vivado not found in PATH"
    echo "Please ensure Xilinx Vivado is installed and in your PATH"
    echo "For Ubuntu/Debian: source /opt/Xilinx/Vivado/<version>/settings64.sh"
    exit 1
fi

# Check if project exists, create if not
if [ ! -d "$VIVADO_DIR" ]; then
    echo "Creating Vivado project..."
    cd "$SCRIPT_DIR"
    vivado -mode batch -source create_project.tcl
fi

cd "$VIVADO_DIR"

echo ""
echo "Running synthesis..."
echo "-------------------"

# Run synthesis
vivado -mode batch -source <(echo "
open_project hydra_synth.xpr
reset_run synth_1
launch_runs synth_1 -jobs [expr {[info exists ::env(JOBS)] ? \$::env(JOBS) : 4}]
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] != \"synth_design Complete!\"} {
    puts \"ERROR: Synthesis failed!\"
    exit 1
}
puts \"Synthesis completed successfully!\"
exit 0
")

echo ""
echo "Running implementation..."
echo "------------------------"

# Run implementation
vivado -mode batch -source <(echo "
open_project hydra_synth.xpr
reset_run impl_1
launch_runs impl_1 -jobs [expr {[info exists ::env(JOBS)] ? \$::env(JOBS) : 4}]
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] != \"write_bitstream Complete!\"} {
    puts \"ERROR: Implementation failed!\"
    exit 1
}
puts \"Implementation completed successfully!\"
exit 0
")

echo ""
echo "Generating reports..."
echo "--------------------"

# Generate utilization and timing reports
vivado -mode batch -source <(echo "
open_project hydra_synth.xpr
open_run impl_1
report_utilization -file utilization.rpt
report_timing -file timing.rpt -max_paths 100
report_timing_summary -file timing_summary.rpt
report_power -file power.rpt
puts \"Reports generated successfully!\"
exit 0
")

echo ""
echo "Synthesis flow completed!"
echo "Reports available in: $VIVADO_DIR"
echo "Bitstream: hydra_synth.runs/impl_1/voxel_framebuffer_top.bit"
echo ""
echo "========================================"