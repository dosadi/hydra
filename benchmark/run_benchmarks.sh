#!/bin/bash
# ============================================================================
# Hydra Performance Benchmark Suite
# Comprehensive performance testing and benchmarking
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "    HYDRA PERFORMANCE BENCHMARK"
echo "========================================"

OUTPUT_DIR="$SCRIPT_DIR/results/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "Running performance benchmarks..."
echo "--------------------------------"

# Initialize benchmark report
cat > "$OUTPUT_DIR/benchmark_report.md" << EOF
# Hydra Performance Benchmark Report

## Benchmark Date
$(date)

## System Information
- **Host**: $(hostname)
- **OS**: $(uname -s) $(uname -r)
- **CPU**: $(nproc) cores
- **Memory**: $(free -h | grep '^Mem:' | awk '{print $2}')
EOF

# 1. Simulation Performance Benchmark
echo "1. Simulation Performance..."
if [ -x "$PROJECT_ROOT/sim/sim_voxel" ]; then
    echo "Running simulation benchmark..."

    # Time simulation startup
    START_TIME=$(date +%s.%3N)
    timeout 30s "$PROJECT_ROOT/sim/sim_voxel" --benchmark > "$OUTPUT_DIR/sim_benchmark.log" 2>&1 || true
    END_TIME=$(date +%s.%3N)
    SIM_TIME=$(echo "$END_TIME - $START_TIME" | bc)

    echo "Simulation startup time: ${SIM_TIME}s" >> "$OUTPUT_DIR/benchmark_report.md"

    # Extract frame rate if available
    if grep -q "FPS" "$OUTPUT_DIR/sim_benchmark.log"; then
        FPS=$(grep "FPS" "$OUTPUT_DIR/sim_benchmark.log" | tail -1 | grep -o '[0-9.]*')
        echo "Simulation frame rate: ${FPS} FPS" >> "$OUTPUT_DIR/benchmark_report.md"
    fi
else
    echo "Simulation binary not found. Run 'make sim' first."
fi

# 2. Synthesis Performance Benchmark
echo "2. Synthesis Performance..."
if [ -d "$PROJECT_ROOT/synthesis/yosys/output" ]; then
    echo "Analyzing synthesis performance..."

    # Extract synthesis statistics
    if [ -f "$PROJECT_ROOT/synthesis/yosys/output/synth.log" ]; then
        LUT_COUNT=$(grep -o "LUTs.*[0-9]" "$PROJECT_ROOT/synthesis/yosys/output/synth.log" | tail -1 || echo "N/A")
        FF_COUNT=$(grep -o "DFFs.*[0-9]" "$PROJECT_ROOT/synthesis/yosys/output/synth.log" | tail -1 || echo "N/A")

        echo "Post-synthesis LUT count: $LUT_COUNT" >> "$OUTPUT_DIR/benchmark_report.md"
        echo "Post-synthesis FF count: $FF_COUNT" >> "$OUTPUT_DIR/benchmark_report.md"
    fi
fi

# 3. Memory Usage Benchmark
echo "3. Memory Usage..."
if command -v valgrind >/dev/null 2>&1 && [ -x "$PROJECT_ROOT/sim/sim_voxel" ]; then
    echo "Running memory analysis..."
    valgrind --tool=massif --massif-out-file="$OUTPUT_DIR/massif.out" \
             "$PROJECT_ROOT/sim/sim_voxel" --quick-test 2>/dev/null || true

    if [ -f "$OUTPUT_DIR/massif.out" ]; then
        PEAK_MEM=$(ms_print "$OUTPUT_DIR/massif.out" 2>/dev/null | grep "peak" | head -1 | awk '{print $2}' || echo "N/A")
        echo "Peak memory usage: $PEAK_MEM" >> "$OUTPUT_DIR/benchmark_report.md"
    fi
fi

# 4. Build Performance
echo "4. Build Performance..."
echo "Measuring build times..."

# Clean build
make -C "$PROJECT_ROOT" clean >/dev/null 2>&1

# Time full rebuild
START_TIME=$(date +%s.%3N)
make -C "$PROJECT_ROOT" sim >/dev/null 2>&1
END_TIME=$(date +%s.%3N)
BUILD_TIME=$(echo "$END_TIME - $START_TIME" | bc)

echo "Full build time: ${BUILD_TIME}s" >> "$OUTPUT_DIR/benchmark_report.md"

# 5. Code Quality Metrics
echo "5. Code Quality Metrics..."

# Count lines of code
RTL_LINES=$(find "$PROJECT_ROOT/rtl" -name "*.sv" -exec wc -l {} \; | awk '{sum += $1} END {print sum}')
SIM_LINES=$(find "$PROJECT_ROOT/sim" -name "*.cpp" -o -name "*.h" | xargs wc -l | awk '{sum += $1} END {print sum}')

echo "RTL lines of code: $RTL_LINES" >> "$OUTPUT_DIR/benchmark_report.md"
echo "Simulation lines of code: $SIM_LINES" >> "$OUTPUT_DIR/benchmark_report.md"

# 6. Test Coverage (if available)
echo "6. Test Coverage..."
if [ -d "$PROJECT_ROOT/verification/uvm" ]; then
    TEST_FILES=$(find "$PROJECT_ROOT/verification/uvm" -name "*.sv" | wc -l)
    echo "UVM test files: $TEST_FILES" >> "$OUTPUT_DIR/benchmark_report.md"
fi

# Generate summary
cat >> "$OUTPUT_DIR/benchmark_report.md" << EOF

## Performance Summary

### Key Metrics
- **Build Time**: ${BUILD_TIME}s
- **RTL Size**: $RTL_LINES lines
- **Simulation Size**: $SIM_LINES lines

### Performance Targets
- **Build Time**: < 60 seconds
- **Simulation Startup**: < 5 seconds
- **Memory Usage**: < 500MB peak

### Recommendations
EOF

# Add recommendations based on results
if (( $(echo "$BUILD_TIME > 60" | bc -l) )); then
    echo "- Optimize build process (parallel compilation, incremental builds)" >> "$OUTPUT_DIR/benchmark_report.md"
fi

if [ "$RTL_LINES" -gt 10000 ]; then
    echo "- Consider modularizing large RTL files" >> "$OUTPUT_DIR/benchmark_report.md"
fi

echo "- Regular performance monitoring recommended" >> "$OUTPUT_DIR/benchmark_report.md"

echo ""
echo "Benchmark completed!"
echo "Results: $OUTPUT_DIR/benchmark_report.md"
echo ""
echo "========================================"