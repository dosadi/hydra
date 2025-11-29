#!/bin/bash

# Hydra UVM Coverage Analysis Script
# Provides comprehensive coverage analysis using open source tools

set -e

echo "=== Hydra UVM Coverage Analysis ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFICATION_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$VERIFICATION_DIR/coverage_results"
mkdir -p "$OUTPUT_DIR"

# Coverage data files
COVERAGE_DATA="$OUTPUT_DIR/coverage.dat"
COVERAGE_REPORT="$OUTPUT_DIR/coverage_report.html"
COVERAGE_JSON="$OUTPUT_DIR/coverage_metrics.json"

echo "Analyzing UVM coverage data..."

# Check if we have coverage data from simulation
if [ -f "coverage_report.txt" ]; then
    echo "Found coverage report file, analyzing..."

    # Extract coverage metrics
    AXIL_COVERAGE=$(grep "AXI-Lite Transaction Coverage" coverage_report.txt | grep -o "[0-9.]*%")
    OPERATION_COVERAGE=$(grep "Hydra Operation Coverage" coverage_report.txt | grep -o "[0-9.]*%")
    TOTAL_COVERAGE=$(grep "Total Functional Coverage" coverage_report.txt | grep -o "[0-9.]*%")

    echo "Coverage Metrics:"
    echo "  AXI-Lite Transactions: $AXIL_COVERAGE"
    echo "  Hydra Operations: $OPERATION_COVERAGE"
    echo "  Total Functional: $TOTAL_COVERAGE"

    # Generate JSON output for CI/CD integration
    cat > "$COVERAGE_JSON" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "axil_transaction_coverage": "${AXIL_COVERAGE}",
  "hydra_operation_coverage": "${OPERATION_COVERAGE}",
  "total_functional_coverage": "${TOTAL_COVERAGE}",
  "test_status": "completed"
}
EOF

    # Generate HTML report
    generate_html_report "$AXIL_COVERAGE" "$OPERATION_COVERAGE" "$TOTAL_COVERAGE"

    echo "Coverage analysis complete!"
    echo "Results saved to: $OUTPUT_DIR"

else
    echo "No coverage data found. Run UVM tests first:"
    echo "  make test_integration"
    echo "  ./run_uvm_tests.sh +UVM_TESTNAME=hydra_integration_test"
    exit 1
fi

# Function to generate HTML coverage report
generate_html_report() {
    local axil_cov=$1
    local op_cov=$2
    local total_cov=$3

    cat > "$COVERAGE_REPORT" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Hydra UVM Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #2E7D32; color: white; padding: 20px; border-radius: 5px; }
        .metric { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .coverage-high { color: #2E7D32; font-weight: bold; }
        .coverage-medium { color: #FF9800; font-weight: bold; }
        .coverage-low { color: #F44336; font-weight: bold; }
        .summary { background: #E8F5E8; padding: 20px; border-radius: 5px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Hydra UVM Verification Coverage Report</h1>
        <p>Generated: $(date)</p>
    </div>

    <div class="metric">
        <h2>AXI-Lite Transaction Coverage</h2>
        <p class="$(get_coverage_class $axil_cov)">Coverage: $axil_cov</p>
        <p>Covers register access patterns and bus transactions</p>
    </div>

    <div class="metric">
        <h2>Hydra Operation Coverage</h2>
        <p class="$(get_coverage_class $op_cov)">Coverage: $op_cov</p>
        <p>Covers DMA, blitter, and rendering operations</p>
    </div>

    <div class="summary">
        <h2>Overall Assessment</h2>
        <p class="$(get_coverage_class $total_cov)">Total Functional Coverage: $total_cov</p>
        $(get_assessment_text $total_cov)
    </div>
</body>
</html>
EOF
}

# Function to determine CSS class based on coverage percentage
get_coverage_class() {
    local cov=$1
    local num_cov=${cov%\%}

    if (( $(echo "$num_cov >= 90" | bc -l) )); then
        echo "coverage-high"
    elif (( $(echo "$num_cov >= 75" | bc -l) )); then
        echo "coverage-medium"
    else
        echo "coverage-low"
    fi
}

# Function to generate assessment text
get_assessment_text() {
    local cov=$1
    local num_cov=${cov%\%}

    if (( $(echo "$num_cov >= 95" | bc -l) )); then
        echo "<p>🎉 Excellent coverage! Comprehensive verification achieved.</p>"
    elif (( $(echo "$num_cov >= 85" | bc -l) )); then
        echo "<p>✅ Good coverage with minor gaps to address.</p>"
    elif (( $(echo "$num_cov >= 70" | bc -l) )); then
        echo "<p>⚠️ Adequate coverage, additional testing recommended.</p>"
    else
        echo "<p>❌ Insufficient coverage, significant testing gaps exist.</p>"
    fi
}

echo "HTML report generated: $COVERAGE_REPORT"
echo "JSON metrics: $COVERAGE_JSON"