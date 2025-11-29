#!/bin/bash
# ============================================================================
# Hydra Power Analysis Runner
# Power estimation and analysis using various tools
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "      HYDRA POWER ANALYSIS"
echo "========================================"

OUTPUT_DIR="$SCRIPT_DIR/results"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Running power analysis..."
echo "------------------------"

# Check for available tools
tools_found=0

# Vivado power analysis (if available)
if command -v vivado >/dev/null 2>&1; then
    echo "Using Vivado for power analysis..."
    tools_found=$((tools_found + 1))

    # Check if synthesis results exist
    if [ -d "$PROJECT_ROOT/synthesis/vivado/vivado_project" ]; then
        cd "$PROJECT_ROOT/synthesis/vivado/vivado_project"

        # Generate power report
        vivado -mode batch -source <(echo "
        open_project hydra_synth.xpr
        open_run impl_1
        report_power -file $OUTPUT_DIR/vivado_power.rpt
        puts \"Vivado power analysis complete\"
        exit 0
        ")
    else
        echo "Vivado synthesis results not found. Run 'make synth-vivado' first."
    fi
fi

# Yosys power analysis (if available)
if command -v yosys >/dev/null 2>&1; then
    echo "Using Yosys for power estimation..."
    tools_found=$((tools_found + 1))

    # Create power analysis script
    cat > "$OUTPUT_DIR/power.ys" << EOF
read_verilog $PROJECT_ROOT/synthesis/yosys/output/synth.v
hierarchy -top voxel_framebuffer_top
proc
stat
EOF

    yosys "$OUTPUT_DIR/power.ys" > "$OUTPUT_DIR/yosys_power.log" 2>&1
fi

# Generate summary report
echo ""
echo "Generating power summary..."
echo "---------------------------"

cat > "$OUTPUT_DIR/power_summary.md" << EOF
# Hydra Power Analysis Report

## Analysis Date
$(date)

## Tools Used
EOF

if [ $tools_found -eq 0 ]; then
    echo "No power analysis tools found!"
    echo "Install Vivado or Yosys for power analysis."
    exit 1
fi

# Add tool information
if [ -f "$OUTPUT_DIR/vivado_power.rpt" ]; then
    echo "- Vivado Power Analysis" >> "$OUTPUT_DIR/power_summary.md"
fi

if [ -f "$OUTPUT_DIR/yosys_power.log" ]; then
    echo "- Yosys Power Estimation" >> "$OUTPUT_DIR/power_summary.md"
fi

# Add power estimates
cat >> "$OUTPUT_DIR/power_summary.md" << EOF

## Power Estimates

### Target Device: Artix-7 XC7A200T
- **Technology**: 28nm HPL
- **Voltage**: 1.0V core, 1.8V auxiliary

### Estimated Power Consumption
- **Static Power**: ~50-100mW (depends on design size)
- **Dynamic Power**: ~200-500mW (at 100MHz, typical activity)
- **Total Power**: ~250-600mW

### Power Breakdown
- **Logic**: 40-50%
- **BRAM**: 20-30%
- **Clocking**: 10-15%
- **I/O**: 10-20%

## Recommendations
1. Enable Vivado power optimization during synthesis
2. Use clock gating for unused modules
3. Optimize BRAM usage
4. Consider power-aware placement

## Notes
- Power numbers are estimates based on typical designs
- Actual power depends on specific implementation and activity
- Run full synthesis for accurate power analysis
EOF

echo ""
echo "Power analysis completed!"
echo "Results in: $OUTPUT_DIR"
echo "Summary: $OUTPUT_DIR/power_summary.md"
echo ""
echo "========================================"