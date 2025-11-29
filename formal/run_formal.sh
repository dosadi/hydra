#!/bin/bash
# ============================================================================
# Hydra Formal Verification Runner
# Automated formal verification using SymbiYosys and other tools
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "    HYDRA FORMAL VERIFICATION"
echo "========================================"

# Check if formal tools are available
if ! command -v sby >/dev/null 2>&1; then
    echo "Error: SymbiYosys (sby) not found"
    echo "Install with: pip install symbiyosys"
    echo "Or from: https://github.com/YosysHQ/SymbiYosys"
    exit 1
fi

# Create output directory
OUTPUT_DIR="$SCRIPT_DIR/results"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Running formal verification..."
echo "-----------------------------"

# Create SymbiYosys configuration
cat > "$OUTPUT_DIR/hydra.sby" << EOF
[tasks]
bmc
prove
cover

[options]
bmc: mode bmc
prove: mode prove
cover: mode cover

[engines]
bmc: abc pdr
prove: abc pdr
cover: abc

[script]
read -sv $PROJECT_ROOT/rtl/voxel_axil_csr.sv
read -sv $PROJECT_ROOT/rtl/cdc_synchronizer.sv
prep -top voxel_axil_csr

[files]
$PROJECT_ROOT/rtl/voxel_axil_csr.sv
$PROJECT_ROOT/rtl/cdc_synchronizer.sv
EOF

# Run bounded model checking
echo "Running BMC (Bounded Model Checking)..."
sby -f "$OUTPUT_DIR/hydra.sby" bmc > "$OUTPUT_DIR/bmc.log" 2>&1

# Run k-induction proofs
echo "Running k-induction proofs..."
sby -f "$OUTPUT_DIR/hydra.sby" prove > "$OUTPUT_DIR/prove.log" 2>&1

# Run coverage analysis
echo "Running coverage analysis..."
sby -f "$OUTPUT_DIR/hydra.sby" cover > "$OUTPUT_DIR/cover.log" 2>&1

echo ""
echo "Formal verification completed!"
echo "Results in: $OUTPUT_DIR"
echo ""

# Check results
if grep -q "PASS" "$OUTPUT_DIR/bmc.log"; then
    echo "✅ BMC: PASSED"
else
    echo "❌ BMC: FAILED"
fi

if grep -q "PASS" "$OUTPUT_DIR/prove.log"; then
    echo "✅ PROVE: PASSED"
else
    echo "❌ PROVE: FAILED"
fi

if grep -q "PASS" "$OUTPUT_DIR/cover.log"; then
    echo "✅ COVER: PASSED"
else
    echo "❌ COVER: FAILED"
fi

echo ""
echo "========================================"