# Formal Verification Guide

This guide covers formal verification techniques used in the Hydra project, including SystemVerilog Assertions (SVA), formal property checking, and verification methodologies.

## Overview

Formal verification uses mathematical techniques to prove or disprove properties about hardware designs. Unlike simulation which tests specific scenarios, formal verification exhaustively checks all possible states and inputs.

## Formal Verification in Hydra

### Current Formal Coverage

Hydra uses SystemVerilog Assertions (SVA) for runtime verification and formal property checking. The RTL includes:

- **AXI-Lite protocol assertions** - Bus protocol compliance
- **Interrupt logic verification** - IRQ generation and masking
- **Reset behavior checking** - Proper initialization sequences
- **CDC (Clock Domain Crossing) properties** - Safe signal synchronization

### Assertion Categories

#### Protocol Assertions
```systemverilog
// AXI-Lite handshake stability
property awvalid_stable_during_handshake;
    @(posedge clk) disable iff (!rst_n)
    s_axil_awvalid && !s_axil_awready |=> s_axil_awvalid;
endproperty
assert property (awvalid_stable_during_handshake);

// Write data stability
property wdata_stable_during_handshake;
    @(posedge clk) disable iff (!rst_n)
    s_axil_wvalid && !s_axil_wready |=> $stable(s_axil_wdata);
endproperty
assert property (wdata_stable_during_handshake);
```

#### Data Integrity Assertions
```systemverilog
// Framebuffer base address non-zero when starting frame
property fb_base_nonzero_on_frame_start;
    @(posedge clk) disable iff (!rst_n)
    start_frame_pulse |-> (fb_base != 32'd0);
endproperty
assert property (fb_base_nonzero_on_frame_start);

// DMA alignment checking
property dma_addr_alignment;
    @(posedge clk) disable iff (!rst_n)
    dma_start_pulse |-> (dma_src[1:0] == 2'b00 && dma_dst[1:0] == 2'b00);
endproperty
assert property (dma_addr_alignment);
```

#### Temporal Assertions
```systemverilog
// Frame completion within timeout
property frame_completion_timeout;
    @(posedge clk) disable iff (!rst_n)
    start_frame_pulse |-> ##[1:1000000] frame_done_pulse;
endproperty
assert property (frame_completion_timeout);

// DMA operation bounded time
property dma_operation_bounded;
    @(posedge clk) disable iff (!rst_n)
    dma_start_pulse |-> ##[1:10000] (dma_done_in || dma_err_in);
endproperty
assert property (dma_operation_bounded);
```

## Formal Verification Tools

### Supported Tools

#### SymbiYosys
Open-source formal verification framework that supports:
- Bounded model checking (BMC)
- k-induction
- Unbounded verification
- Property checking

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install yosys symbiyosys

# Or build from source
git clone https://github.com/YosysHQ/SymbiYosys.git
cd SymbiYosys
make install
```

#### JasperGold
Commercial formal verification tool with advanced features:
- Formal verification planning
- Coverage analysis
- Abstraction and refinement
- Integration with simulation

#### Questa Formal

### Tool Setup

#### SymbiYosys Configuration
Create `formal.sby` configuration file:
```
[options]
mode bmc
depth 50

[engines]
smtbmc

[script]
read -formal rtl/voxel_axil_csr.sv
read -formal rtl/voxel_raycaster_core_pipelined.sv
prep -top voxel_axil_csr

[files]
rtl/voxel_axil_csr.sv
rtl/voxel_raycaster_core_pipelined.sv
```

#### Running Formal Verification
```bash
# Basic BMC check
sby -f formal.sby

# Unbounded verification (if supported)
sby -f formal_unbounded.sby

# Check results
sby -f formal.sby status
```

## Verification Methodologies

### Assertion-Based Verification (ABV)

#### Writing Effective Assertions
1. **Clear intent**: Each assertion should verify one specific behavior
2. **Minimal scope**: Focus on local properties rather than global system behavior
3. **Realistic assumptions**: Don't over-constrain the design
4. **Debuggable**: Include meaningful error messages

#### Assertion Patterns
```systemverilog
// Pattern 1: Immediate assertions
assert property (@(posedge clk) disable iff (!rst_n)
    condition |-> consequence);

// Pattern 2: Sequence-based assertions
sequence data_transfer;
    s_axil_awvalid && s_axil_awready ##1
    s_axil_wvalid && s_axil_wready ##1
    s_axil_bvalid && s_axil_bready;
endsequence

assert property (@(posedge clk) disable iff (!rst_n)
    data_transfer);

// Pattern 3: Cover properties for completeness
cover property (@(posedge clk) disable iff (!rst_n)
    frame_done_pulse);
```

### Coverage Metrics

#### Assertion Coverage
- **Assertion success rate**: Percentage of assertions that pass
- **Coverage holes**: Uncovered assertion conditions
- **Toggle coverage**: Signal value changes during formal analysis

#### Functional Coverage
```systemverilog
// Cover different DMA transfer sizes
covergroup dma_coverage @(posedge clk);
    cp_size: coverpoint dma_len {
        bins small = {[1:64]};
        bins medium = {[65:1024]};
        bins large = {[1025:65536]};
    }
endgroup
```

## Formal Verification Workflow

### 1. Property Specification
```systemverilog
// Specify what the design should do
property frame_start_implies_completion;
    @(posedge clk) disable iff (!rst_n)
    start_frame_pulse |-> s_eventually frame_done_pulse;
endproperty
```

### 2. Assumption Definition
```systemverilog
// Define reasonable input constraints
assume property (@(posedge clk) disable iff (!rst_n)
    fb_base[1:0] == 2'b00); // Word-aligned framebuffer

assume property (@(posedge clk) disable iff (!rst_n)
    cam_x inside {[-16'sd1000:16'sd1000]}); // Reasonable camera bounds
```

### 3. Verification Execution
```bash
# Run formal verification
sby -f formal.sby

# Check for counterexamples
sby -f formal.sby prove
```

### 4. Debug and Refine
```systemverilog
// If verification fails, add debug assertions
assert property (@(posedge clk) disable iff (!rst_n)
    start_frame_pulse |-> ##[1:10] core_busy) else
    $error("Core should become busy after frame start");
```

## Common Formal Verification Issues

### Over-Constrained Properties
**Problem:** Properties that are too restrictive fail unnecessarily
```systemverilog
// Too restrictive - assumes immediate response
assert property (req |-> next ack); // FAILS

// Better - allows reasonable latency
assert property (req |-> ##[1:5] ack); // PASSES
```

### Missing Assumptions
**Problem:** Design can behave incorrectly due to unconstrained inputs
```systemverilog
// Missing assumption about reset
assert property (rst_n |-> !core_busy); // May fail if reset isn't assumed stable

// Add proper assumption
assume property ($rose(rst_n) |-> ##[1:10] $stable(rst_n));
```

### State Space Explosion
**Problem:** Large designs create too many states to check
**Solutions:**
- Abstract away irrelevant details
- Use bounded verification for large designs
- Decompose verification into smaller modules

## Formal Verification in CI

### Automated Formal Checks
```yaml
# .github/workflows/formal.yml
name: Formal Verification
on: [push, pull_request]

jobs:
  formal:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup formal tools
        run: |
          sudo apt-get update
          sudo apt-get install -y yosys symbiyosys
      - name: Run formal verification
        run: |
          cd formal
          sby -f voxel_axil_csr.sby
      - name: Upload results
        uses: actions/upload-artifact@v3
        with:
          name: formal-results
          path: formal/
```

### Regression Testing
```bash
# Run formal checks on every commit
make formal-check

# Generate formal coverage report
make formal-coverage
```

## Advanced Formal Techniques

### Abstraction and Refinement
```systemverilog
// Abstract complex computation
function automatic logic compute_pixel_valid(input [9:0] x, y);
    // Simplified validity check
    return (x < 480) && (y < 360);
endfunction

assert property (@(posedge clk)
    pixel_valid |-> compute_pixel_valid(pixel_x, pixel_y));
```

### Compositional Verification
Break large designs into smaller, verifiable components:
1. Verify individual modules in isolation
2. Verify module interfaces
3. Compose verified modules with interface contracts

### Temporal Logic Extensions
```systemverilog
// Fairness properties
fairness: assume property (s_eventually frame_done_pulse);

// Liveness properties
liveness: assert property (s_eventually frame_done_pulse);

// Safety properties
safety: assert property (always !(error_condition));
```

## Debugging Formal Failures

### Counterexample Analysis
When formal verification finds a failure:

1. **Examine the counterexample trace**
2. **Identify the exact failure point**
3. **Check if it's a real bug or over-constrained property**
4. **Refine assumptions or fix the design**

### Common Debugging Techniques
```systemverilog
// Add debug assertions
assert property (@(posedge clk)
    condition |-> debug_signal) else
    $error("Debug: condition=%b, debug_signal=%b", condition, debug_signal);

// Use cover properties to understand execution paths
cover property (@(posedge clk)
    start_frame_pulse ##[1:100] frame_done_pulse);
```

## Best Practices

### Property Writing Guidelines
1. **One property, one behavior**: Don't combine multiple checks
2. **Clear naming**: Use descriptive names for properties
3. **Document intent**: Comment what each property verifies
4. **Test properties**: Verify they work with known good/bad cases

### Verification Planning
1. **Start small**: Verify simple properties first
2. **Build incrementally**: Add complexity gradually
3. **Document assumptions**: Clearly state verification assumptions
4. **Review regularly**: Reassess properties as design evolves

### Tool-Specific Tips
- **SymbiYosys**: Use `--dump-vcd` for waveform debugging
- **JasperGold**: Leverage formal verification plans
- **Questa**: Use built-in coverage metrics

## Integration with Simulation

### Hybrid Verification
Combine formal and simulation:
1. Use formal to prove properties
2. Use simulation to validate performance
3. Cross-check results between methods

### Assertion Reuse
```systemverilog
// Same assertions work in simulation and formal
`ifdef FORMAL
    // Formal-specific properties
`elsif SIMULATION
    // Simulation-specific checks
`else
    // Common assertions
`endif
```

## Resources

### Learning Materials
- **SystemVerilog Assertions**: IEEE 1800-2017 standard
- **Formal Verification Book**: "Formal Verification" by Erik Seligman
- **Online Tutorials**: SymbiYosys documentation

### Tool Documentation
- **SymbiYosys**: https://symbiyosys.readthedocs.io/
- **Yosys**: https://yosyshq.net/yosys/
- **SVA Reference**: SystemVerilog LRM Chapter 16

### Community Resources
- **Formal Verification Forums**: Verification Academy, ASIC World
- **Open Source Projects**: YosysHQ ecosystem
- **Academic Papers**: Formal verification research

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**Related Files:**
- `rtl/voxel_axil_csr.sv` - Contains SVA assertions
- `rtl/voxel_raycaster_core_pipelined.sv` - Ray caster formal properties
- `formal/` - Formal verification testbenches