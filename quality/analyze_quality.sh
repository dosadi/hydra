#!/bin/bash
# ============================================================================
# Hydra Code Quality Analysis
# Comprehensive code quality checking and metrics
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "     HYDRA CODE QUALITY ANALYSIS"
echo "========================================"

OUTPUT_DIR="$SCRIPT_DIR/results"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Running code quality analysis..."
echo "-------------------------------"

# Initialize quality report
cat > "$OUTPUT_DIR/quality_report.md" << EOF
# Hydra Code Quality Report

## Analysis Date
$(date)

## Quality Metrics Overview

This report provides comprehensive code quality metrics for the Hydra project.

## Language Breakdown
EOF

# Analyze SystemVerilog files
echo "Analyzing SystemVerilog files..."
SV_FILES=$(find "$PROJECT_ROOT/rtl" -name "*.sv")
SV_COUNT=$(echo "$SV_FILES" | wc -l)
SV_LINES=$(echo "$SV_FILES" | xargs wc -l | tail -1 | awk '{print $1}')

echo "- **SystemVerilog**: $SV_COUNT files, $SV_LINES lines" >> "$OUTPUT_DIR/quality_report.md"

# Analyze C/C++ files
echo "Analyzing C/C++ files..."
CPP_FILES=$(find "$PROJECT_ROOT/sim" "$PROJECT_ROOT/drivers" -name "*.cpp" -o -name "*.c" -o -name "*.h" 2>/dev/null)
CPP_COUNT=$(echo "$CPP_FILES" | wc -l)
CPP_LINES=$(echo "$CPP_FILES" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

echo "- **C/C++**: $CPP_COUNT files, $CPP_LINES lines" >> "$OUTPUT_DIR/quality_report.md"

# Analyze Python files
echo "Analyzing Python files..."
PY_FILES=$(find "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/docs" -name "*.py" 2>/dev/null)
PY_COUNT=$(echo "$PY_FILES" | wc -l)
PY_LINES=$(echo "$PY_FILES" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

echo "- **Python**: $PY_COUNT files, $PY_LINES lines" >> "$OUTPUT_DIR/quality_report.md"

# Analyze shell scripts
echo "Analyzing shell scripts..."
SH_FILES=$(find "$PROJECT_ROOT/scripts" -name "*.sh" 2>/dev/null)
SH_COUNT=$(echo "$SH_FILES" | wc -l)

echo "- **Shell Scripts**: $SH_COUNT files" >> "$OUTPUT_DIR/quality_report.md"

# Code complexity analysis
echo "Analyzing code complexity..."
cat >> "$OUTPUT_DIR/quality_report.md" << EOF

## Complexity Analysis

### SystemVerilog Complexity
EOF

# Check for complex constructs
COMPLEX_MODULES=$(grep -r "always" "$PROJECT_ROOT/rtl" --include="*.sv" | wc -l)
NESTED_IFS=$(grep -r "if.*if" "$PROJECT_ROOT/rtl" --include="*.sv" | wc -l)
LONG_FUNCTIONS=$(find "$PROJECT_ROOT/rtl" -name "*.sv" -exec awk '/^(module|function)/{f=1} /^endmodule|^endfunction/{f=0; if (NR > 100) print FILENAME} f{lines++}' {} \; | wc -l)

echo "- **Always blocks**: $COMPLEX_MODULES" >> "$OUTPUT_DIR/quality_report.md"
echo "- **Nested conditionals**: $NESTED_IFS" >> "$OUTPUT_DIR/quality_report.md"
echo "- **Long functions/modules**: $LONG_FUNCTIONS" >> "$OUTPUT_DIR/quality_report.md"

# Linting results
echo "Running linting checks..."
cat >> "$OUTPUT_DIR/quality_report.md" << EOF

## Linting Results
EOF

# Verilator linting
if command -v verilator >/dev/null 2>&1; then
    echo "Running Verilator linting..."
    verilator --lint-only "$PROJECT_ROOT/rtl/voxel_framebuffer_top.sv" > "$OUTPUT_DIR/verilator_lint.log" 2>&1
    LINT_ERRORS=$(grep -c "Error" "$OUTPUT_DIR/verilator_lint.log" || echo "0")
    LINT_WARNINGS=$(grep -c "Warning" "$OUTPUT_DIR/verilator_lint.log" || echo "0")

    echo "- **Verilator Errors**: $LINT_ERRORS" >> "$OUTPUT_DIR/quality_report.md"
    echo "- **Verilator Warnings**: $LINT_WARNINGS" >> "$OUTPUT_DIR/quality_report.md"
else
    echo "- Verilator not available" >> "$OUTPUT_DIR/quality_report.md"
fi

# Shell script linting
if command -v shellcheck >/dev/null 2>&1; then
    echo "Running shellcheck..."
    find "$PROJECT_ROOT/scripts" -name "*.sh" -exec shellcheck {} \; > "$OUTPUT_DIR/shellcheck.log" 2>&1
    SHELL_ERRORS=$(grep -c "error" "$OUTPUT_DIR/shellcheck.log" || echo "0")
    SHELL_WARNINGS=$(grep -c "warning" "$OUTPUT_DIR/shellcheck.log" || echo "0")

    echo "- **Shell Errors**: $SHELL_ERRORS" >> "$OUTPUT_DIR/quality_report.md"
    echo "- **Shell Warnings**: $SHELL_WARNINGS" >> "$OUTPUT_DIR/quality_report.md"
else
    echo "- Shellcheck not available" >> "$OUTPUT_DIR/quality_report.md"
fi

# Documentation quality
echo "Analyzing documentation..."
DOC_FILES=$(find "$PROJECT_ROOT/docs" -name "*.md" | wc -l)
README_EXISTS=$(test -f "$PROJECT_ROOT/README.md" && echo "Yes" || echo "No")

cat >> "$OUTPUT_DIR/quality_report.md" << EOF

## Documentation Quality
- **Documentation files**: $DOC_FILES
- **README present**: $README_EXISTS
EOF

# Code coverage estimation
echo "Estimating test coverage..."
cat >> "$OUTPUT_DIR/quality_report.md" << EOF

## Test Coverage Estimation
EOF

if [ -d "$PROJECT_ROOT/verification/uvm" ]; then
    TEST_FILES=$(find "$PROJECT_ROOT/verification/uvm" -name "*test*.sv" | wc -l)
    SEQ_FILES=$(find "$PROJECT_ROOT/verification/uvm" -name "*sequence*.sv" | wc -l)

    echo "- **UVM Test files**: $TEST_FILES" >> "$OUTPUT_DIR/quality_report.md"
    echo "- **Test sequences**: $SEQ_FILES" >> "$OUTPUT_DIR/quality_report.md"
    echo "- **Coverage estimation**: Moderate (UVM framework present)" >> "$OUTPUT_DIR/quality_report.md"
else
    echo "- **Coverage estimation**: Basic (simulation tests only)" >> "$OUTPUT_DIR/quality_report.md"
fi

# Quality score calculation
echo "Calculating quality score..."
TOTAL_FILES=$((SV_COUNT + CPP_COUNT + PY_COUNT + SH_COUNT))
QUALITY_SCORE=100

# Deduct points for issues
if [ "$LINT_ERRORS" -gt 0 ]; then
    QUALITY_SCORE=$((QUALITY_SCORE - LINT_ERRORS * 5))
fi
if [ "$SHELL_ERRORS" -gt 0 ]; then
    QUALITY_SCORE=$((QUALITY_SCORE - SHELL_ERRORS * 3))
fi
if [ "$README_EXISTS" = "No" ]; then
    QUALITY_SCORE=$((QUALITY_SCORE - 10))
fi

# Ensure score doesn't go below 0
if [ $QUALITY_SCORE -lt 0 ]; then
    QUALITY_SCORE=0
fi

cat >> "$OUTPUT_DIR/quality_report.md" << EOF

## Quality Score
**Overall Quality Score: $QUALITY_SCORE/100**

### Scoring Breakdown
- Linting errors: -$((LINT_ERRORS * 5)) points
- Shell script errors: -$((SHELL_ERRORS * 3)) points
- Missing README: -10 points (if applicable)

### Recommendations
EOF

# Add recommendations
if [ $QUALITY_SCORE -lt 70 ]; then
    echo "- Address critical linting errors" >> "$OUTPUT_DIR/quality_report.md"
fi
if [ "$README_EXISTS" = "No" ]; then
    echo "- Create comprehensive README.md" >> "$OUTPUT_DIR/quality_report.md"
fi
if [ $TOTAL_FILES -gt 50 ]; then
    echo "- Consider modularizing large files" >> "$OUTPUT_DIR/quality_report.md"
fi

echo "- Regular code quality monitoring recommended" >> "$OUTPUT_DIR/quality_report.md"

echo ""
echo "Quality analysis completed!"
echo "Report: $OUTPUT_DIR/quality_report.md"
echo "Quality Score: $QUALITY_SCORE/100"
echo ""
echo "========================================"