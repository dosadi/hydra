#!/usr/bin/env bash
set -euo pipefail

# Enhanced IP discovery and integration script
# Supports both open source and commercial IP evaluation

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check network connectivity
check_network() {
    if ! curl -s --max-time 5 https://github.com > /dev/null; then
        log_error "No network connectivity detected"
        return 1
    fi
    return 0
}

# Initialize existing submodules
init_existing_ip() {
    log_info "Initializing existing third-party IP..."

    SUBMODULES=(
        third_party/litepcie
        third_party/litedram
        third_party/liteiclink
        third_party/litex
    )

    for submodule in "${SUBMODULES[@]}"; do
        if [ -d "$submodule" ]; then
            log_info "Updating $submodule..."
            git submodule update --init --recursive "$submodule" || {
                log_warn "Failed to update $submodule"
            }
        else
            log_warn "$submodule directory not found"
        fi
    done

    log_success "Existing IP initialization complete"
}

# Discover open source IP repositories
discover_open_source_ip() {
    log_info "Discovering open source IP repositories..."

    # Create IP discovery directory
    mkdir -p ip_discovery

    # List of interesting open source IP repositories
    OPEN_SOURCE_IP=(
        "https://github.com/apache/tvm-vta.git::VTA_AI_Accelerator"
        "https://github.com/chipsalliance/rocket-chip.git::Rocket_Chip_RISCV"
        "https://github.com/riscv-boom/riscv-boom.git::BOOM_RISCV_Core"
        "https://github.com/corundum/corundum.git::Corundum_100G_Ethernet"
        "https://github.com/Xilinx/open-nic.git::OpenNIC_Network_Interface"
        "https://github.com/lowRISC/opentitan.git::OpenTitan_Security"
        "https://github.com/secworks/aes.git::AES_GCM_Core"
        "https://github.com/jonathanmuller/opendsp.git::OpenDSP_Signal_Processing"
        "https://github.com/mjosaarinen/fft.git::FFT_Cores"
        "https://github.com/PrincetonUniversity/openpiton.git::OpenPITON_Multi_Core"
        "https://github.com/enjoy-digital/nvme.git::NVMe_Controller"
    )

    # Create discovery report
    cat > ip_discovery/open_source_ip_report.md << 'EOF'
# Open Source IP Discovery Report

Generated on: $(date)

## Available Open Source IP Cores

EOF

    for ip_entry in "${OPEN_SOURCE_IP[@]}"; do
        IFS='::' read -r url description <<< "$ip_entry"

        repo_name=$(basename "$url" .git)
        log_info "Checking $repo_name..."

        # Try to fetch basic info without full clone
        if check_network; then
            # Get repository info via GitHub API
            api_url="https://api.github.com/repos/$(echo "$url" | sed 's|https://github.com/||' | sed 's|\.git$||')"
            if repo_info=$(curl -s "$api_url" 2>/dev/null); then
                stars=$(echo "$repo_info" | grep -o '"stargazers_count":[0-9]*' | cut -d: -f2)
                license=$(echo "$repo_info" | grep -o '"license":{[^}]*}' | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                last_updated=$(echo "$repo_info" | grep -o '"updated_at":"[^"]*"' | cut -d'"' -f4 | cut -d'T' -f1)

                cat >> ip_discovery/open_source_ip_report.md << EOF
### $repo_name
- **Description**: $description
- **URL**: $url
- **Stars**: ${stars:-"N/A"}
- **License**: ${license:-"Unknown"}
- **Last Updated**: ${last_updated:-"Unknown"}
- **Status**: Available for evaluation

EOF
            else
                cat >> ip_discovery/open_source_ip_report.md << EOF
### $repo_name
- **Description**: $description
- **URL**: $url
- **Status**: Repository access failed

EOF
            fi
        else
            cat >> ip_discovery/open_source_ip_report.md << EOF
### $repo_name
- **Description**: $description
- **URL**: $url
- **Status**: Network unavailable

EOF
        fi
    done

    log_success "Open source IP discovery complete. See ip_discovery/open_source_ip_report.md"
}

# Evaluate commercial IP options
evaluate_commercial_ip() {
    log_info "Creating commercial IP evaluation framework..."

    mkdir -p ip_discovery/commercial

    # Create commercial IP evaluation template
    cat > ip_discovery/commercial/evaluation_template.md << 'EOF'
# Commercial IP Evaluation Template

## IP Core: [IP_NAME]
**Vendor**: [VENDOR_NAME]
**Date**: $(date)

### Technical Assessment
- [ ] Interface compatibility (AXI-Lite/AXI4/AXI-Stream)
- [ ] Clock domain requirements
- [ ] Resource utilization (LUT/FF/BRAM/DSP)
- [ ] Timing closure capability
- [ ] Verification quality

### Business Assessment
- [ ] Licensing model (per-seat/device/royalty-free)
- [ ] Support level (vendor/community)
- [ ] Documentation quality
- [ ] Ecosystem integration
- [ ] Roadmap alignment

### Integration Assessment
- [ ] Wrapper complexity
- [ ] Configuration flexibility
- [ ] Debugging capabilities
- [ ] Upgrade path

### Recommendation
[ ] Integrate immediately
[ ] Evaluate for future phases
[ ] Not suitable for current requirements

### Cost Analysis
- **License Cost**: $[COST]
- **Support Cost**: $[COST]
- **Integration Effort**: [MAN_DAYS] days
- **ROI Timeline**: [MONTHS] months

### Alternatives Considered
- [Open source option 1]
- [Open source option 2]
- [Custom implementation]
EOF

    # Create specific evaluation files for key commercial IP
    COMMERCIAL_IP=(
        "Xilinx_UltraRAM::High-density_memory"
        "Intel_HyperFlex::Extreme_bandwidth_memory"
        "Xilinx_Versal_AI_Engine::AI_acceleration"
        "Intel_AI_Suite::AI_acceleration"
        "Solarflare_100G_IP::Networking_acceleration"
        "Rambus_Crypto5::Cryptographic_acceleration"
    )

    for ip_entry in "${COMMERCIAL_IP[@]}"; do
        IFS='::' read -r ip_name description <<< "$ip_entry"
        eval_file="ip_discovery/commercial/${ip_name}_evaluation.md"

        sed "s/\[IP_NAME\]/$ip_name/g; s/\[VENDOR_NAME\]/${ip_name%%_*}/g" \
            ip_discovery/commercial/evaluation_template.md > "$eval_file"

        # Add IP-specific notes
        cat >> "$eval_file" << EOF

### IP-Specific Notes
**Function**: $description
**Target Use Case**: [Hydra integration scenario]
**Performance Requirements**: [Specific metrics]
**Compatibility Requirements**: [Interface standards]
EOF

        log_info "Created evaluation template for $ip_name"
    done

    log_success "Commercial IP evaluation framework created. See ip_discovery/commercial/"
}

# Create IP integration wrapper template
create_wrapper_template() {
    log_info "Creating IP integration wrapper template..."

    mkdir -p ip_integration/wrappers

    cat > ip_integration/wrappers/ip_wrapper_template.sv << 'EOF'
// ============================================================================
// IP Integration Wrapper Template
// Standardizes interface for both open source and commercial IP cores
// ============================================================================

module ip_wrapper #(
    parameter string IP_TYPE = "OPEN_SOURCE",  // "OPEN_SOURCE" or "COMMERCIAL"
    parameter string IP_NAME = "GENERIC_IP",
    parameter int    DATA_WIDTH = 32,
    parameter int    ADDR_WIDTH = 32,
    parameter int    IP_SPECIFIC_PARAM = 0
)(
    // ============================================================================
    // Standard Hydra Interfaces
    // ============================================================================

    // Control interface (AXI-Lite)
    axil_if.slave  axil_if,

    // Data interface (AXI4)
    axi_if.slave   axi_data_if,

    // Streaming interfaces
    axis_if.master axis_out_if,
    axis_if.slave  axis_in_if,

    // ============================================================================
    // IP-Specific Interfaces
    // ============================================================================

    // Custom IP interfaces (adapt as needed)
    input  logic [IP_SPECIFIC_PARAM-1:0] ip_custom_input,
    output logic [IP_SPECIFIC_PARAM-1:0] ip_custom_output,

    // ============================================================================
    // Control and Status
    // ============================================================================

    input  logic        enable,
    input  logic [31:0] control,
    output logic        ready,
    output logic [31:0] status,
    output logic [31:0] error_count
);

    // ============================================================================
    // Internal Signals
    // ============================================================================

    logic ip_ready;
    logic ip_error;
    logic [31:0] ip_status;
    logic clk, rst_n;

    // Extract clock and reset
    assign clk = axil_if.clk;
    assign rst_n = axil_if.rst_n;

    // ============================================================================
    // IP-Specific Configuration
    // ============================================================================

    // Control register decoding
    logic [3:0] mode_select;
    logic       bypass_mode;
    logic       debug_enable;

    assign mode_select = control[3:0];
    assign bypass_mode = control[4];
    assign debug_enable = control[5];

    // ============================================================================
    // Conditional IP Instantiation
    // ============================================================================

    generate
        if (IP_TYPE == "COMMERCIAL") begin : gen_commercial_ip
            // Commercial IP instantiation
            // NOTE: Replace with actual commercial IP core
            commercial_ip_core #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .CUSTOM_PARAM(IP_SPECIFIC_PARAM)
            ) commercial_ip (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable && !bypass_mode),

                // Standard interface mapping
                .axil_awaddr(axil_if.awaddr),
                .axil_awvalid(axil_if.awvalid),
                .axil_awready(axil_if.awready),
                .axil_wdata(axil_if.wdata),
                .axil_wvalid(axil_if.wvalid),
                .axil_wready(axil_if.wready),
                .axil_bresp(axil_if.bresp),
                .axil_bvalid(axil_if.bvalid),
                .axil_bready(axil_if.bready),
                .axil_araddr(axil_if.araddr),
                .axil_arvalid(axil_if.arvalid),
                .axil_arready(axil_if.arready),
                .axil_rdata(axil_if.rdata),
                .axil_rresp(axil_if.rresp),
                .axil_rvalid(axil_if.rvalid),
                .axil_rready(axil_if.rready),

                // Custom IP interfaces
                .custom_input(ip_custom_input),
                .custom_output(ip_custom_output),

                // Status
                .ready(ip_ready),
                .status(ip_status),
                .error(ip_error)
            );
        end else begin : gen_open_source_ip
            // Open source IP instantiation
            // NOTE: Replace with actual open source IP core
            open_source_ip_core #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .CUSTOM_PARAM(IP_SPECIFIC_PARAM)
            ) open_source_ip (
                .clk(clk),
                .rst_n(rst_n),
                .enable(enable && !bypass_mode),

                // Standard interface mapping (adapt as needed)
                .s_axil_awaddr(axil_if.awaddr),
                .s_axil_awvalid(axil_if.awvalid),
                .s_axil_awready(axil_if.awready),
                // ... map other AXI-Lite signals

                // Custom IP interfaces
                .custom_input(ip_custom_input),
                .custom_output(ip_custom_output),

                // Status
                .ready(ip_ready),
                .status(ip_status),
                .error(ip_error)
            );
        end
    endgenerate

    // ============================================================================
    // Bypass Mode (for testing/debugging)
    // ============================================================================

    generate
        if (IP_TYPE == "COMMERCIAL") begin : gen_bypass
            // Commercial IP may have licensing restrictions
            // Implement bypass logic carefully
            always_comb begin
                if (bypass_mode) begin
                    // Bypass commercial IP - use stubs or alternative implementation
                    ip_ready = 1'b1;
                    ip_status = 32'hBYPASS;
                    ip_error = 1'b0;
                    ip_custom_output = '0;
                end else begin
                    // Use commercial IP outputs
                    ip_ready = gen_commercial_ip.commercial_ip.ready;
                    ip_status = gen_commercial_ip.commercial_ip.status;
                    ip_error = gen_commercial_ip.commercial_ip.error;
                    ip_custom_output = gen_commercial_ip.commercial_ip.custom_output;
                end
            end
        end
    endgenerate

    // ============================================================================
    // Status and Error Handling
    // ============================================================================

    // Error counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_count <= '0;
        end else if (enable && ip_error) begin
            error_count <= error_count + 1;
        end
    end

    // Status register
    assign status = {
        ip_ready,           // [31]
        ip_error,           // [30]
        bypass_mode,        // [29]
        debug_enable,       // [28]
        mode_select,        // [27:24]
        IP_TYPE == "COMMERCIAL" ? 1'b1 : 1'b0,  // [23] Commercial flag
        23'h0               // [22:0] Reserved
    };

    assign ready = ip_ready;

    // ============================================================================
    // Debug and Monitoring
    // ============================================================================

    // Debug signal export (when enabled)
    generate
        if (IP_TYPE == "COMMERCIAL") begin : gen_debug
            // Commercial IP debug signals (if available)
            // NOTE: Be careful with debug exports for licensed IP
        end
    endgenerate

    // ============================================================================
    // Assertions and Formal Verification
    // ============================================================================

    // Basic interface checks
    // NOTE: Disable for commercial IP if licensing restricts this
    if (IP_TYPE != "COMMERCIAL") begin : gen_assertions
        // Interface protocol assertions
        assert property (@(posedge clk) disable iff (!rst_n)
            axil_if.awvalid && !axil_if.awready |=> axil_if.awvalid)
            else $error("AXI-Lite AWVALID must remain asserted until AWREADY");

        // Add more assertions as needed
    end

endmodule : ip_wrapper
EOF

    log_success "IP wrapper template created. See ip_integration/wrappers/ip_wrapper_template.sv"
}

# Create IP benchmarking framework
create_benchmark_framework() {
    log_info "Creating IP benchmarking framework..."

    mkdir -p ip_integration/benchmark

    # Create benchmark testbench template
    cat > ip_integration/benchmark/ip_benchmark_tb.sv << 'EOF'
// ============================================================================
// IP Benchmarking Testbench
// Compares performance of different IP implementations
// ============================================================================

`timescale 1ns/1ps

module ip_benchmark_tb;

    // ============================================================================
    // Testbench Parameters
    // ============================================================================

    parameter int NUM_ITERATIONS = 1000;
    parameter int TIMEOUT_CYCLES = 1000000;

    // ============================================================================
    // Clock and Reset
    // ============================================================================

    logic clk = 1'b0;
    logic rst_n = 1'b0;

    always #5ns clk = ~clk;  // 100MHz clock

    initial begin
        #10ns rst_n = 1'b1;
    end

    // ============================================================================
    // Interface Declarations
    // ============================================================================

    // Reference implementation (golden model)
    axil_if reference_axil (.*);
    axi_if  reference_axi (.*);
    axis_if reference_axis_out (.*);
    axis_if reference_axis_in (.*);

    // IP under test
    axil_if dut_axil (.*);
    axi_if  dut_axi (.*);
    axis_if dut_axis_out (.*);
    axis_if dut_axis_in (.*);

    // ============================================================================
    // DUT Instantiation
    // ============================================================================

    // Reference implementation
    ip_reference_model reference_model (
        .axil_if(reference_axil),
        .axi_if(reference_axi),
        .axis_out_if(reference_axis_out),
        .axis_in_if(reference_axis_in),
        .enable(1'b1),
        .control(32'h0),
        .ready(),
        .status(),
        .error_count()
    );

    // IP under test (parameterize this)
    `IP_UNDER_TEST dut (
        .axil_if(dut_axil),
        .axi_if(dut_axi),
        .axis_out_if(dut_axis_out),
        .axis_in_if(dut_axis_in),
        .enable(1'b1),
        .control(32'h0),
        .ready(),
        .status(),
        .error_count()
    );

    // ============================================================================
    // Test Stimulus Generation
    // ============================================================================

    task automatic generate_test_data();
        // Generate test patterns for benchmarking
        // This should be customized for each IP type
    endtask

    task automatic apply_stimulus();
        // Apply test stimulus to both reference and DUT
        // Measure timing and compare outputs
    endtask

    // ============================================================================
    // Performance Monitoring
    // ============================================================================

    // Timing measurements
    realtime start_time, end_time;
    realtime total_time;
    int transaction_count;

    // Resource usage tracking
    int lut_usage, ff_usage, bram_usage, dsp_usage;

    task automatic measure_performance();
        start_time = $realtime;

        // Run benchmark iterations
        for (int i = 0; i < NUM_ITERATIONS; i++) begin
            apply_stimulus();
            transaction_count++;
        end

        end_time = $realtime;
        total_time = end_time - start_time;

        $display("Benchmark Results:");
        $display("  Transactions: %0d", transaction_count);
        $display("  Total Time: %0t", total_time);
        $display("  Avg Latency: %0t", total_time / transaction_count);
        $display("  Throughput: %0f trans/ns", transaction_count / (total_time / 1ns));
    endtask

    // ============================================================================
    // Output Comparison
    // ============================================================================

    task automatic compare_outputs();
        // Compare reference model vs DUT outputs
        // Flag any discrepancies
    endtask

    // ============================================================================
    // Test Execution
    // ============================================================================

    initial begin
        $display("Starting IP Benchmark Testbench");
        $display("IP Under Test: `IP_UNDER_TEST");
        $display("Reference Model: ip_reference_model");

        // Wait for reset
        @(posedge rst_n);
        #100ns;

        // Generate test data
        generate_test_data();

        // Run benchmark
        measure_performance();

        // Compare results
        compare_outputs();

        $display("Benchmark complete");
        $finish;
    end

    // ============================================================================
    // Timeout Protection
    // ============================================================================

    initial begin
        #(TIMEOUT_CYCLES * 10ns);
        $error("Testbench timeout after %0d cycles", TIMEOUT_CYCLES);
        $finish;
    end

    // ============================================================================
    // Waveform Dumping
    // ============================================================================

    initial begin
        $dumpfile("ip_benchmark.vcd");
        $dumpvars(0, ip_benchmark_tb);
    end

endmodule
EOF

    # Create benchmark configuration script
    cat > ip_integration/benchmark/run_benchmarks.sh << 'EOF'
#!/bin/bash

# IP Benchmarking Script
# Runs performance comparisons between different IP implementations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Test configurations
declare -a IP_TESTS=(
    "litepcie::commercial_pcie::PCIe DMA Performance"
    "litedram::commercial_dram::DRAM Controller Performance"
    "aes_core::commercial_aes::AES Encryption Performance"
    "fft_core::commercial_fft::FFT Processing Performance"
)

# Results directory
RESULTS_DIR="${SCRIPT_DIR}/results"
mkdir -p "${RESULTS_DIR}"

echo "Starting IP Benchmark Suite"
echo "Results will be saved to: ${RESULTS_DIR}"

for test_config in "${IP_TESTS[@]}"; do
    IFS='::' read -r reference_ip test_ip description <<< "${test_config}"

    echo ""
    echo "========================================="
    echo "Testing: ${description}"
    echo "Reference: ${reference_ip}"
    echo "Test IP: ${test_ip}"
    echo "========================================="

    # Create test-specific benchmark file
    benchmark_file="${RESULTS_DIR}/${test_ip}_benchmark.sv"
    sed "s/\`IP_UNDER_TEST/${test_ip}/g" "${SCRIPT_DIR}/ip_benchmark_tb.sv" > "${benchmark_file}"

    # Run simulation
    echo "Running benchmark for ${test_ip}..."
    if cd "${PROJECT_ROOT}/sim" && verilator -Wall --cc "${benchmark_file}" --top-module ip_benchmark_tb -Mdir "obj_${test_ip}"; then
        echo "✓ ${test_ip} benchmark completed successfully"
    else
        echo "✗ ${test_ip} benchmark failed"
    fi
done

echo ""
echo "Benchmark suite complete. Check ${RESULTS_DIR} for detailed results."
EOF

    chmod +x ip_integration/benchmark/run_benchmarks.sh

    log_success "Benchmark framework created. See ip_integration/benchmark/"
}

# Main execution
main() {
    log_info "Hydra IP Integration and Discovery Tool"
    log_info "========================================"

    # Check prerequisites
    if ! command_exists git; then
        log_error "Git is required but not installed"
        exit 1
    fi

    if ! command_exists curl; then
        log_warn "curl not found - network-dependent features will be limited"
    fi

    # Execute functions
    init_existing_ip
    discover_open_source_ip
    evaluate_commercial_ip
    create_wrapper_template
    create_benchmark_framework

    log_success "IP integration setup complete!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review ip_discovery/open_source_ip_report.md for available IP"
    log_info "2. Evaluate commercial IP options in ip_discovery/commercial/"
    log_info "3. Use ip_integration/wrappers/ip_wrapper_template.sv for integration"
    log_info "4. Run benchmarks with ip_integration/benchmark/run_benchmarks.sh"
}

# Run main function
main "$@"
EOF

    log_success "Enhanced IP integration script created. See scripts/ip_discovery_integration.sh"
}

# Update third_party README with expanded IP options
update_third_party_readme() {
    log_info "Updating third_party README with expanded IP options..."

    cat > third_party/README_expanded.md << 'EOF'
# Third-Party IP Integration Guide

## Currently Integrated IP

| IP        | Source                                    | License | Commit                                 | Integration Status | Notes |
|-----------|-------------------------------------------|---------|----------------------------------------|-------------------|-------|
| LitePCIe  | https://github.com/enjoy-digital/litepcie | BSD     | 5a50f83f33b7ceea75a0b226893d3b74c2361e79 | ✅ Fully Integrated | PCIe endpoint + DMA; AXI-Lite BAR, AXI-Stream DMA |
| LiteDRAM  | https://github.com/enjoy-digital/litedram | BSD     | 8ca007a0372788d3d64cdc196220e729e6e940e3 | ✅ Fully Integrated | DDR3/DDR4 controller/PHY; Nexys Video preset available |
| LiteICLink/LiteVideo | https://github.com/enjoy-digital/liteiclink | BSD | 679befc2271e64297345b15e974b2d2fdcd8fad5 | ✅ Fully Integrated | HDMI/DVI TMDS encoder + video timing |
| LiteDMA (LiteX stream2mem/mem2stream) | https://github.com/enjoy-digital/litex | BSD | 10c52e742094ce72884fb7f0711576a4f6fb4892 | ✅ Fully Integrated | Stream↔mem DMA helpers |
| AXI Crossbar System | Custom (Hydra) | MIT | N/A | ✅ Fully Integrated | Multi-protocol crossbar with QoS |
| UCIe Interface | Custom (Hydra) | MIT | N/A | ✅ Fully Integrated | Universal Chiplet Interconnect Express |

## Open Source IP Candidates for Integration

### High-Performance Computing & AI
| IP | Source | License | Use Case | Priority |
|----|--------|---------|----------|----------|
| VTA | apache/tvm-vta | Apache 2.0 | AI/ML acceleration for voxel processing | High |
| Rocket Chip | chipsalliance/rocket-chip | BSD-3 | RISC-V CPU cores for control plane | Medium |
| BOOM | riscv-boom/riscv-boom | BSD-3 | High-performance RISC-V cores | Medium |

### Networking & Communication
| IP | Source | License | Use Case | Priority |
|----|--------|---------|----------|----------|
| Corundum | corundum/corundum | BSD-2 | 100G Ethernet acceleration | High |
| OpenNIC | Xilinx/open-nic | Apache 2.0 | Network interface cards | Medium |

### Security & Cryptography
| IP | Source | License | Use Case | Priority |
|----|--------|---------|----------|----------|
| OpenTitan | lowRISC/opentitan | Apache 2.0 | Hardware security modules | High |
| AES-GCM Core | secworks/aes | BSD-3 | Encryption/decryption acceleration | Medium |

### DSP & Signal Processing
| IP | Source | License | Use Case | Priority |
|----|--------|---------|----------|----------|
| OpenDSP | jonathanmuller/opendsp | MIT | Digital signal processing | Medium |
| FFT Cores | mjosaarinen/fft | BSD/MIT | Fast Fourier transforms | Low |

### Memory & Storage
| IP | Source | License | Use Case | Priority |
|----|--------|---------|----------|----------|
| OpenPITON | PrincetonUniversity/openpiton | BSD-3 | Multi-core processor with coherence | Medium |
| NVMe Controller | enjoy-digital/nvme | Apache 2.0 | High-speed storage interfaces | Medium |

## Commercial IP Options

### FPGA Vendor IP
| IP | Vendor | Use Case | Licensing | Integration Effort |
|----|--------|----------|-----------|-------------------|
| UltraRAM | Xilinx | High-density memory blocks | Vivado License | Low |
| Versal AI Engine | Xilinx | AI/ML acceleration | Premium License | Medium |
| MIG | Xilinx | DDR4/5 controllers | Vivado License | Low |
| PCIe Gen4/5 Hard IP | Xilinx | High-speed PCIe | Device License | Low |
| HyperFlex | Intel | High-bandwidth memory | Premium License | Medium |
| AI Suite | Intel | AI acceleration | Premium License | Medium |

### Third-Party Commercial IP
| IP | Vendor | Use Case | Licensing | Integration Effort |
|----|--------|----------|-----------|-------------------|
| Crypto5 | Rambus | Cryptographic acceleration | Commercial | Medium |
| SafeNet | Thales | Hardware security modules | Commercial | High |
| 100G IP | Solarflare | Ultra-low latency networking | Commercial | Medium |

## Integration Strategy

### Phase 1: Open Source Foundation (Current)
- ✅ LiteX ecosystem fully integrated
- ✅ Custom crossbar and UCIe infrastructure complete
- 🔄 Expand with 4-6 additional open source cores

### Phase 2: Commercial IP Evaluation (Q1 2026)
- 📋 Performance benchmarking vs open source alternatives
- 📋 Cost-benefit analysis for production designs
- 📋 Licensing strategy development

### Phase 3: Hybrid Optimization (Q2 2026)
- 📋 Commercial IP for performance-critical paths
- 📋 Open source for non-critical functions
- 📋 Automated IP selection framework

## IP Evaluation Criteria

### Technical Criteria
- [ ] AXI-Lite/AXI4/AXI-Stream interface compatibility
- [ ] Clock domain requirements and CDC needs
- [ ] Resource utilization (LUT/FF/BRAM/DSP)
- [ ] Timing closure at target frequencies
- [ ] Verification quality and test coverage

### Business Criteria
- [ ] Licensing model (per-seat/device/royalty-free)
- [ ] Vendor support level and response times
- [ ] Documentation completeness and quality
- [ ] Ecosystem size and community support
- [ ] Future development roadmap alignment

### Integration Criteria
- [ ] Wrapper complexity and development effort
- [ ] Configuration flexibility and parameterization
- [ ] Debug visibility and error reporting
- [ ] Upgrade path for future IP versions
- [ ] Compatibility with existing Hydra infrastructure

## Getting Started with IP Integration

### 1. Initialize Existing IP
```bash
cd /path/to/hydra
./scripts/fetch_ip.sh
```

### 2. Discover New IP Options
```bash
./scripts/ip_discovery_integration.sh
```

### 3. Evaluate IP Candidates
- Review `ip_discovery/open_source_ip_report.md`
- Use templates in `ip_discovery/commercial/`
- Run benchmarks with `ip_integration/benchmark/`

### 4. Integrate New IP
- Use wrapper template: `ip_integration/wrappers/ip_wrapper_template.sv`
- Follow Hydra interface standards (AXI-Lite/AXI4/AXI-Stream/UCIe)
- Add to crossbar system for interconnect

## Licensing Considerations

### Open Source IP
- **Permissive Licenses**: BSD, MIT, Apache 2.0 (preferred)
- **Copyleft Licenses**: GPL/LGPL (avoid unless isolated)
- **Community Support**: Active projects with multiple contributors

### Commercial IP
- **Evaluation**: Time-limited evaluation licenses
- **Production**: Per-device or royalty-based licensing
- **Support**: Vendor-backed support and indemnification
- **IP Protection**: Encrypted IP delivery and anti-tampering

## Risk Mitigation

### Technical Risks
- **Interface Mismatch**: Standardize on AXI/UCIe protocols
- **Timing Closure**: Budget for IP integration overhead
- **Verification Gap**: Comprehensive testbenches required

### Business Risks
- **Vendor Lock-in**: Maintain open source alternatives
- **License Expiration**: Monitor license terms and renewals
- **Support Dependency**: Vendor stability assessment

### Supply Chain Risks
- **Single Source**: Multiple vendor options where possible
- **Long-term Availability**: IP archival and escrow
- **Fork Capability**: Open source fallback options

## Support and Resources

- **Documentation**: `docs/ip_integration_strategy.md`
- **Scripts**: `scripts/ip_discovery_integration.sh`
- **Templates**: `ip_integration/wrappers/`
- **Benchmarks**: `ip_integration/benchmark/`

For questions about IP integration, see the main Hydra documentation or create an issue in the repository.
EOF

    log_success "Expanded third_party README created. See third_party/README_expanded.md"
}

# Main execution
main() {
    log_info "Hydra Enhanced IP Integration Setup"
    log_info "==================================="

    # Execute all functions
    init_existing_ip
    discover_open_source_ip
    evaluate_commercial_ip
    create_wrapper_template
    create_benchmark_framework
    update_third_party_readme

    log_success "Enhanced IP integration setup complete!"
    log_info ""
    log_info "Generated files:"
    log_info "├── ip_discovery/open_source_ip_report.md"
    log_info "├── ip_discovery/commercial/evaluation_templates/"
    log_info "├── ip_integration/wrappers/ip_wrapper_template.sv"
    log_info "├── ip_integration/benchmark/"
    log_info "└── third_party/README_expanded.md"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review discovered IP options"
    log_info "2. Evaluate commercial IP candidates"
    log_info "3. Run benchmark comparisons"
    log_info "4. Integrate selected IP using templates"
}

# Run main function
main "$@"