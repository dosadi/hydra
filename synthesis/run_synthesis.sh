#!/bin/bash
# ============================================================================
# Hydra Unified Synthesis Interface
# Integrated synthesis flow supporting Vivado, Quartus, and Yosys
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load configuration
if [ -f "$SCRIPT_DIR/synthesis_config.sh" ]; then
    source "$SCRIPT_DIR/synthesis_config.sh"
fi

# Default configuration
TOOL="${TOOL:-auto}"  # auto, vivado, quartus, yosys, all
TARGET="${TARGET:-artix7}"  # artix7, kintex7, arria10, ecp5, ice40
CLOCK_PERIOD="${CLOCK_PERIOD:-10.0}"  # Clock period in ns
JOBS="${JOBS:-4}"  # Number of parallel jobs

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Tool detection
detect_tools() {
    log_info "Detecting available synthesis tools..."

    VIVADO_AVAILABLE=false
    QUARTUS_AVAILABLE=false
    YOSYS_AVAILABLE=false

    if command -v vivado >/dev/null 2>&1; then
        VIVADO_AVAILABLE=true
        log_success "Vivado detected"
    else
        log_warning "Vivado not found"
    fi

    if command -v quartus_sh >/dev/null 2>&1; then
        QUARTUS_AVAILABLE=true
        log_success "Quartus detected"
    else
        log_warning "Quartus not found"
    fi

    if command -v yosys >/dev/null 2>&1; then
        YOSYS_AVAILABLE=true
        log_success "Yosys detected"
    else
        log_warning "Yosys not found"
    fi
}

# Tool selection logic
select_tool() {
    case $TOOL in
        auto)
            # Auto-select based on availability and target
            case $TARGET in
                artix7|kintex7|virtex7)
                    if $VIVADO_AVAILABLE; then
                        TOOL="vivado"
                    elif $YOSYS_AVAILABLE; then
                        TOOL="yosys"
                    else
                        log_error "No suitable tool found for $TARGET"
                        exit 1
                    fi
                    ;;
                arria10|stratix*)
                    if $QUARTUS_AVAILABLE; then
                        TOOL="quartus"
                    elif $YOSYS_AVAILABLE; then
                        TOOL="yosys"
                    else
                        log_error "No suitable tool found for $TARGET"
                        exit 1
                    fi
                    ;;
                ecp5|ice40)
                    if $YOSYS_AVAILABLE; then
                        TOOL="yosys"
                    else
                        log_error "Yosys required for $TARGET"
                        exit 1
                    fi
                    ;;
                *)
                    if $VIVADO_AVAILABLE; then
                        TOOL="vivado"
                    elif $QUARTUS_AVAILABLE; then
                        TOOL="quartus"
                    elif $YOSYS_AVAILABLE; then
                        TOOL="yosys"
                    else
                        log_error "No synthesis tools available"
                        exit 1
                    fi
                    ;;
            esac
            log_info "Auto-selected tool: $TOOL for target $TARGET"
            ;;
        all)
            # Run all available tools
            run_all_tools
            exit 0
            ;;
        vivado)
            if ! $VIVADO_AVAILABLE; then
                log_error "Vivado not available"
                exit 1
            fi
            ;;
        quartus)
            if ! $QUARTUS_AVAILABLE; then
                log_error "Quartus not available"
                exit 1
            fi
            ;;
        yosys)
            if ! $YOSYS_AVAILABLE; then
                log_error "Yosys not available"
                exit 1
            fi
            ;;
        *)
            log_error "Unknown tool: $TOOL"
            log_info "Available tools: auto, vivado, quartus, yosys, all"
            exit 1
            ;;
    esac
}

# Run synthesis with selected tool
run_synthesis() {
    log_info "Starting synthesis with $TOOL for target $TARGET"

    case $TOOL in
        vivado)
            run_vivado_synthesis
            ;;
        quartus)
            run_quartus_synthesis
            ;;
        yosys)
            run_yosys_synthesis
            ;;
    esac
}

# Vivado synthesis
run_vivado_synthesis() {
    log_info "Running Vivado synthesis..."

    # Set target-specific device
    case $TARGET in
        artix7)
            DEVICE="xc7a200tfbg676-2"
            ;;
        kintex7)
            DEVICE="xc7k410tffg900-2"
            ;;
        virtex7)
            DEVICE="xc7v2000tfhg1761-2"
            ;;
        *)
            DEVICE="xc7a200tfbg676-2"  # Default to Artix-7
            ;;
    esac

    export DEVICE CLOCK_PERIOD JOBS
    cd "$SCRIPT_DIR/vivado"
    ./run_synthesis.sh
}

# Quartus synthesis
run_quartus_synthesis() {
    log_info "Running Quartus synthesis..."

    # Set target-specific device
    case $TARGET in
        arria10)
            DEVICE_FAMILY="Arria 10"
            DEVICE="10AX115S2F45I1SG"
            ;;
        stratix5)
            DEVICE_FAMILY="Stratix V"
            DEVICE="5SGXEA7N2F45C2"
            ;;
        *)
            DEVICE_FAMILY="Arria 10"
            DEVICE="10AX115S2F45I1SG"  # Default to Arria 10
            ;;
    esac

    export DEVICE_FAMILY DEVICE CLOCK_PERIOD JOBS
    cd "$SCRIPT_DIR/quartus"
    ./run_synthesis.sh
}

# Yosys synthesis
run_yosys_synthesis() {
    log_info "Running Yosys synthesis..."

    # Set target-specific configuration
    case $TARGET in
        ecp5)
            YOSYS_TARGET="ecp5"
            ;;
        ice40)
            YOSYS_TARGET="ice40"
            ;;
        *)
            YOSYS_TARGET="generic"
            ;;
    esac

    export YOSYS_TARGET CLOCK_PERIOD JOBS
    cd "$SCRIPT_DIR/yosys"
    ./run_synthesis.sh
}

# Run all available tools for comparison
run_all_tools() {
    log_info "Running synthesis with all available tools for comparison"

    RESULTS_DIR="$SCRIPT_DIR/results_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$RESULTS_DIR"

    # Run each tool if available
    if $VIVADO_AVAILABLE; then
        log_info "Running Vivado synthesis..."
        TOOL="vivado" run_synthesis 2>&1 | tee "$RESULTS_DIR/vivado.log"
        cp -r vivado/vivado_project "$RESULTS_DIR/" 2>/dev/null || true
    fi

    if $QUARTUS_AVAILABLE; then
        log_info "Running Quartus synthesis..."
        TOOL="quartus" run_synthesis 2>&1 | tee "$RESULTS_DIR/quartus.log"
        cp -r quartus/quartus_project "$RESULTS_DIR/" 2>/dev/null || true
    fi

    if $YOSYS_AVAILABLE; then
        log_info "Running Yosys synthesis..."
        TOOL="yosys" run_synthesis 2>&1 | tee "$RESULTS_DIR/yosys.log"
        cp -r yosys/output "$RESULTS_DIR/" 2>/dev/null || true
    fi

    # Generate comparison report
    generate_comparison_report "$RESULTS_DIR"
}

# Generate comparison report across tools
generate_comparison_report() {
    RESULTS_DIR="$1"
    REPORT_FILE="$RESULTS_DIR/comparison_report.md"

    log_info "Generating comparison report..."

    cat > "$REPORT_FILE" << EOF
# Hydra Synthesis Comparison Report
Generated: $(date)

## Configuration
- Target: $TARGET
- Clock Period: ${CLOCK_PERIOD}ns
- Parallel Jobs: $JOBS

## Tool Results

EOF

    # Add results for each tool
    for tool in vivado quartus yosys; do
        if [ -f "$RESULTS_DIR/${tool}.log" ]; then
            echo "### $tool" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"

            # Extract key metrics from logs
            case $tool in
                vivado)
                    # Extract utilization and timing from Vivado reports
                    if [ -f "$RESULTS_DIR/vivado_project/utilization.rpt" ]; then
                        echo "#### Resource Utilization" >> "$REPORT_FILE"
                        grep -A 10 "Slice LUTs" "$RESULTS_DIR/vivado_project/utilization.rpt" >> "$REPORT_FILE" 2>/dev/null || true
                        echo "" >> "$REPORT_FILE"
                    fi
                    if [ -f "$RESULTS_DIR/vivado_project/timing_summary.rpt" ]; then
                        echo "#### Timing Summary" >> "$REPORT_FILE"
                        grep -A 5 "Design Timing Summary" "$RESULTS_DIR/vivado_project/timing_summary.rpt" >> "$REPORT_FILE" 2>/dev/null || true
                        echo "" >> "$REPORT_FILE"
                    fi
                    ;;
                quartus)
                    # Extract utilization and timing from Quartus reports
                    if [ -f "$RESULTS_DIR/quartus_project/timing.rpt" ]; then
                        echo "#### Timing Analysis" >> "$REPORT_FILE"
                        head -20 "$RESULTS_DIR/quartus_project/timing.rpt" >> "$REPORT_FILE" 2>/dev/null || true
                        echo "" >> "$REPORT_FILE"
                    fi
                    ;;
                yosys)
                    # Extract statistics from Yosys log
                    echo "#### Synthesis Statistics" >> "$REPORT_FILE"
                    grep -E "(Number of cells|Chip area|Max frequency)" "$RESULTS_DIR/yosys.log" >> "$REPORT_FILE" 2>/dev/null || true
                    echo "" >> "$REPORT_FILE"
                    ;;
            esac
        fi
    done

    log_success "Comparison report generated: $REPORT_FILE"
}

# Print usage information
usage() {
    cat << EOF
Hydra Unified Synthesis Interface

Usage: $0 [OPTIONS]

Options:
    -t, --tool TOOL        Synthesis tool (auto, vivado, quartus, yosys, all)
    --target TARGET        Target device/family (artix7, kintex7, arria10, ecp5, ice40)
    --clock CLOCK          Clock period in ns (default: 10.0)
    --jobs JOBS           Number of parallel jobs (default: 4)
    -h, --help            Show this help message

Environment Variables:
    TOOL                  Same as --tool
    TARGET                Same as --target
    CLOCK_PERIOD          Same as --clock
    JOBS                  Same as --jobs

Examples:
    $0 --tool vivado --target artix7
    $0 --tool all --target kintex7
    TOOL=quartus TARGET=arria10 $0

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tool)
            TOOL="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --clock)
            CLOCK_PERIOD="$2"
            shift 2
            ;;
        --jobs)
            JOBS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo "========================================"
    echo "    HYDRA UNIFIED SYNTHESIS INTERFACE"
    echo "========================================"
    echo "Tool: $TOOL"
    echo "Target: $TARGET"
    echo "Clock: ${CLOCK_PERIOD}ns"
    echo "Jobs: $JOBS"
    echo "========================================"

    detect_tools
    select_tool
    run_synthesis

    log_success "Synthesis completed successfully!"
    echo "========================================"
}

# Run main function
main "$@"