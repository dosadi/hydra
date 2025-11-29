# Hydra UVM Verification Framework

This directory contains the Universal Verification Methodology (UVM) testbench for the Hydra FPGA accelerator.

## Overview

The UVM framework provides comprehensive verification coverage for the Hydra system, including:
- AXI-Lite register interface testing
- DMA operations verification
- Blitter engine validation
- Frame rendering pipeline testing
- **Constrained Random Testing**: Advanced verification with randomization constraints
- **Performance Profiling**: Throughput and latency measurements
- Functional coverage collection

## Directory Structure

```
verification/uvm/
├── hydra_uvm_pkg.sv              # Main UVM package with all components
├── hydra_axil_if.sv              # AXI-Lite virtual interface
├── hydra_testbench.sv            # Top-level testbench module
├── hydra_uvm_defines.svh         # UVM defines and macros
├── hydra_types.svh               # Type definitions and enums
├── hydra_uvm_config.sv           # UVM configuration classes
├── hydra_coverage_report.sv      # Coverage reporting utilities
├── hydra_product_config.sv       # Product configuration classes
├── run_uvm_tests.sh              # Basic test execution script
├── run_performance_tests.sh      # Performance test runner
├── run_constrained_tests.sh      # Constrained random test runner
├── agents/                       # UVM agent components
│   └── axil_agent/               # AXI-Lite agent
├── env/                          # Environment components
│   ├── hydra_env.sv              # Main test environment
│   ├── hydra_scoreboard.sv       # Transaction scoreboard
│   └── hydra_coverage.sv         # Coverage collector
├── sequences/                    # Test sequences
│   ├── hydra_base_sequence.sv
│   ├── hydra_csr_sequence.sv
│   ├── hydra_dma_sequence.sv
│   ├── hydra_blit_sequence.sv
│   ├── hydra_frame_sequence.sv
│   ├── hydra_constrained_sequence.sv
│   └── hydra_performance_sequence.sv
└── tests/                        # Test cases
    ├── hydra_base_test.sv
    ├── hydra_csr_test.sv
    ├── hydra_dma_test.sv
    ├── hydra_blit_test.sv
    ├── hydra_integration_test.sv
    ├── hydra_performance_test.sv
    └── hydra_constrained_test.sv
```

## Running Tests

### Prerequisites

- SystemVerilog simulator with UVM support (VCS, Questa, ModelSim)
- UVM 1.2 library

### Basic Test Execution

```bash
# Run all UVM tests
make uvm-test

# Run performance profiling tests
make uvm-perf

# Run constrained random tests
make uvm-constr

# Or use direct commands
./run_uvm_tests.sh +UVM_TESTNAME=hydra_csr_test
./run_performance_tests.sh +UVM_TESTNAME=hydra_performance_test
./run_constrained_tests.sh +UVM_TESTNAME=hydra_constrained_test
```

### Command Line Options

- `+UVM_TESTNAME=<test_name>`: Specify which test to run
- `+UVM_VERBOSITY=<level>`: Set UVM verbosity (LOW, MEDIUM, HIGH, FULL)
- `+UVM_LOG=<filename>`: Redirect log output to file

### Example

```bash
./run_uvm_tests.sh +UVM_TESTNAME=hydra_integration_test +UVM_VERBOSITY=HIGH
```

## Test Descriptions

### hydra_csr_test
Tests all CSR (Control and Status Register) operations:
- Control register read/write
- Interrupt mask/status registers
- DMA command register
- Blitter control register
- HDMI CRC register

### hydra_dma_test
Tests DMA (Direct Memory Access) operations:
- DMA source/destination address configuration
- Transfer length setup
- DMA command execution
- Completion polling

### hydra_blit_test
Tests blitter engine operations:
- Source region configuration
- Destination setup
- Dimension settings
- Operation execution and completion

### hydra_integration_test
Runs all test sequences in order for comprehensive verification.

### hydra_performance_test
Measures system performance metrics:
- DMA throughput and latency
- Blitter operation throughput
- Frame rendering FPS
- Overall system performance assessment

### hydra_constrained_test
Runs constrained random verification:
- Randomized test scenarios with constraints
- Coverage-driven stimulus generation
- Advanced verification coverage

## Coverage Analysis with Open Source Tools

The framework includes comprehensive coverage analysis using open source tools:

### Coverage Metrics Collected

- **AXI-Lite Transaction Coverage**: Register access patterns and bus operations
- **Hydra Operation Coverage**: DMA, blitter, and rendering operations
- **Protocol Coverage**: AXI-Lite protocol compliance
- **Functional Coverage**: Overall verification completeness

### Open Source Tools Integration

#### Setup
```bash
# Install coverage tools
./setup_coverage_tools.sh

# Run full coverage analysis workflow
./coverage_workflow.sh
```

#### Tools Used
- **LCOV/GenHTML**: Line and branch coverage with HTML reports
- **gcovr**: Alternative coverage analysis with JSON output
- **Verilator**: SystemVerilog simulation with coverage support

#### Coverage Reports Generated
- `coverage_html/index.html` - Detailed HTML coverage report
- `coverage_gcovr.html` - gcovr HTML report
- `coverage_gcovr.json` - JSON metrics for CI/CD
- `coverage_summary.txt` - Text summary
- `coverage_metrics.json` - UVM-specific metrics

### Coverage Quality Gates

The framework enforces these minimum coverage requirements:
- AXI-Lite Transactions: 90%
- Hydra Operations: 85%
- Total Functional: 88%

### CI/CD Integration

Coverage results are exported in multiple formats:
- **JSON**: For custom dashboards and monitoring
- **Cobertura XML**: For Jenkins/GitLab CI
- **LCOV info**: For Coveralls/Codecov integration

### Coverage Analysis Commands

```bash
# Analyze existing coverage data
./analyze_coverage.sh

# Generate HTML coverage report
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html

# Generate JSON metrics
gcovr --json -o coverage_metrics.json
```

## Advanced Verification Features

### Constrained Random Testing

The framework includes advanced constrained random testing capabilities:

#### Features
- **Randomization Constraints**: Configurable constraints on test parameters
- **Coverage-Driven Generation**: Stimulus generation based on coverage goals
- **Operation Sequencing**: Randomized sequences of DMA, blitter, and rendering operations
- **Error Injection**: Controlled error scenario testing

#### Running Constrained Tests
```bash
# Run constrained random tests
make uvm-constr

# Or directly
./run_constrained_tests.sh +UVM_TESTNAME=hydra_constrained_test
```

#### Constraint Configuration
Constraints can be modified in `hydra_constrained_sequence.sv`:
- Transfer size limits
- Operation type probabilities
- Timing constraints
- Error injection rates

### Performance Profiling

Comprehensive performance measurement and analysis:

#### Metrics Measured
- **DMA Throughput**: Memory transfer bandwidth (MB/s)
- **Blitter Throughput**: 2D graphics operations (MPixels/s)
- **Frame Rendering**: Frames per second and latency
- **System Latency**: End-to-end operation timing

#### Performance Assessment
Results include quality assessments:
- **Excellent**: >1000 MB/s DMA, >60 FPS rendering
- **Good**: >500 MB/s DMA, >30 FPS rendering
- **Adequate**: >100 MB/s DMA, >15 FPS rendering
- **Poor**: Below adequate thresholds

#### Running Performance Tests
```bash
# Run performance profiling
make uvm-perf

# Or directly
./run_performance_tests.sh +UVM_TESTNAME=hydra_performance_test
```

#### Performance Report Format
```
=======================================
     HYDRA PERFORMANCE REPORT
=======================================

DMA Performance:
  Average Latency: 45.2 ns
  Throughput: 234.5 Mbps

Blitter Performance:
  Average Latency: 125.8 ns
  Throughput: 45.2 MPixels/sec

Frame Rendering Performance:
  Average Latency: 16.7 ms
  Frame Rate: 60.0 FPS

Performance Assessment:
  DMA: GOOD (234.5 Mbps)
  Blitter: ADEQUATE (45.2 MPixels/sec)
  Frame Render: EXCELLENT (60.0 FPS)
=======================================
```

## Product Configuration Testing

The framework supports testing diverse product lines with different feature sets:

### Supported Product Configurations

- **hydra_usb_product**: USB graphics output, basic features
- **hydra_hdmi_product**: HDMI output, higher resolution support
- **hydra_enterprise_product**: Full feature set with PCIe, Ethernet, USB, HDMI

### Running Product-Specific Tests

```bash
# Test USB graphics product
make test_usb_product

# Test HDMI product
make test_hdmi_product

# Test enterprise product
make test_enterprise_product

# Or use direct command
./run_uvm_tests.sh +UVM_TESTNAME=hydra_config_test +PRODUCT_CONFIG=hydra_usb_product
```

### Product Feature Matrix

| Feature | USB Product | HDMI Product | Enterprise Product |
|---------|-------------|--------------|-------------------|
| USB Graphics | ✅ | ❌ | ✅ |
| HDMI Output | ❌ | ✅ | ✅ |
| PCIe Interface | ❌ | ❌ | ✅ |
| Ethernet | ❌ | ❌ | ✅ |
| DDR Memory | ❌ | ❌ | ✅ |
| Max Resolution | 1920x1080 | 3840x2160 | 7680x4320 |
| Framebuffer | 8MB | 16MB | 64MB |

## Adding New Tests

1. Create a new sequence class extending `hydra_base_sequence`
2. Implement the `body()` task with your test logic
3. Create a test class extending `hydra_base_test`
4. Override `run_phase()` to execute your sequence
5. Add the test to the package includes
6. Update this README

## Debugging

### Common Issues

1. **Virtual interface not found**: Ensure the interface is properly set in the config DB
2. **UVM macro errors**: Check that UVM is properly included and imported
3. **Timing issues**: Adjust delays in sequences if handshake timing is problematic

### Debug Options

```bash
# Enable waveform dumping
./run_uvm_tests.sh +UVM_TESTNAME=hydra_csr_test +DUMP_WAVES

# Enable detailed logging
./run_uvm_tests.sh +UVM_TESTNAME=hydra_csr_test +UVM_VERBOSITY=FULL
```

## Integration with RTL Simulation

To connect this testbench to the actual Hydra RTL:

1. Uncomment the DUT instantiation in `hydra_testbench.sv`
2. Update the DUT port connections to match the actual interface
3. Ensure clock and reset signals are properly connected
4. Run the tests with the RTL included in compilation

## Future Enhancements

- ✅ **Constrained Random Testing**: Implemented with randomization constraints
- ✅ **Performance Profiling**: Implemented with throughput and latency measurements
- Add more protocol agents (AXI, PCIe)
- Integrate with cocotb for mixed-language testing
- Implement machine learning-based test generation
- Add cloud-based verification farm support