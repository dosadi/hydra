# Hydra FPGA Synthesis Guide

This directory contains FPGA synthesis flows and scripts for the Hydra FPGA accelerator project. The synthesis infrastructure supports multiple FPGA vendors and provides a unified interface for easy tool selection and configuration.

## Unified Synthesis Interface

The `run_synthesis.sh` script provides a unified interface to all synthesis tools:

```bash
# Auto-select best tool for target
make synth

# Specify tool explicitly
make synth-vivado
make synth-quartus
make synth-yosys

# Run all available tools for comparison
make synth-all
```

### Command Line Options

```bash
cd synthesis
./run_synthesis.sh [OPTIONS]

Options:
    -t, --tool TOOL        Synthesis tool (auto, vivado, quartus, yosys, all)
    --target TARGET        Target device/family (artix7, kintex7, arria10, ecp5, ice40)
    --clock CLOCK          Clock period in ns (default: 10.0)
    --jobs JOBS           Number of parallel jobs (default: 4)
    -h, --help            Show help message
```

### Environment Variables

```bash
# Tool selection
export TOOL=vivado          # vivado, quartus, yosys, auto, all
export TARGET=artix7        # artix7, kintex7, arria10, etc.
export CLOCK_PERIOD=10.0    # Clock period in ns
export JOBS=8              # Parallel jobs

# Run synthesis
make synth
```

### Configuration File

Advanced settings can be configured in `synthesis_config.sh`:

```bash
# Edit synthesis_config.sh
TOOL=vivado
TARGET=kintex7
CLOCK_PERIOD=8.0  # 125MHz
JOBS=8
STRATEGY=speed
EFFORT=high
```

## Supported Synthesis Tools

### 1. Xilinx Vivado
- **Target Devices**: Artix-7, Kintex-7, Virtex-7, UltraScale/UltraScale+
- **Directory**: `synthesis/vivado/`
- **Requirements**: Xilinx Vivado Design Suite

### 2. Intel Quartus Prime
- **Target Devices**: Arria, Stratix, Cyclone series
- **Directory**: `synthesis/quartus/`
- **Requirements**: Intel Quartus Prime

### 3. Yosys (Open Source)
- **Target Devices**: iCE40, ECP5, and other open-source FPGA families
- **Directory**: `synthesis/yosys/`
- **Requirements**: Yosys + nextpnr

## Quick Start

### Vivado Synthesis
```bash
make synth-vivado
```

### Quartus Synthesis
```bash
make synth-quartus
```

### Yosys Synthesis
```bash
make synth-yosys
```

### Analyze Results
```bash
make synth-analyze
```

## Cross-Tool Comparison

The unified interface supports running synthesis with multiple tools simultaneously for comparison:

```bash
# Run all available tools
TOOL=all make synth

# Or use the dedicated target
make synth-all
```

This generates a comparison report showing resource utilization, timing, and other metrics across all available tools.

### Comparison Report

When running with `TOOL=all`, a comparison report is automatically generated in `synthesis/results_YYYYMMDD_HHMMSS/comparison_report.md` containing:

- **Resource Utilization**: LUTs, FFs, BRAM, DSP blocks
- **Timing Analysis**: Slack, critical paths, clock domains
- **Power Consumption**: Dynamic and static power estimates
- **Build Time**: Synthesis and implementation duration
- **Tool-Specific Metrics**: Vendor-specific optimization results

### Example Comparison Output

```
# Hydra Synthesis Comparison Report

## Configuration
- Target: artix7
- Clock Period: 10.0ns
- Parallel Jobs: 4

## Tool Results

### Vivado
#### Resource Utilization
Slice LUTs     15,420 / 134,600 (11.46%)
Slice Registers  8,920 / 269,200 (3.31%)
Block RAM       45 / 365 (12.33%)

#### Timing Summary
Worst Negative Slack: -0.125ns
Total Negative Slack: -2.340ns

### Quartus
#### Resource Utilization
ALMs            12,450 / 115,840 (10.74%)
Registers       9,120 / 115,840 (7.87%)
M20Ks           38 / 1,440 (2.64%)

#### Timing Summary
Setup Slack: 1.245ns
Hold Slack: 0.089ns

### Yosys
#### Synthesis Statistics
Number of cells: 18,450
Chip area: 2.34 mm²
Max frequency: 125MHz
```

## Directory Structure

```
synthesis/
├── vivado/                    # Xilinx Vivado flow
│   ├── create_project.tcl    # Vivado project creation script
│   └── run_synthesis.sh      # Synthesis execution script
├── quartus/                  # Intel Quartus flow
│   └── run_synthesis.sh      # Synthesis execution script
├── yosys/                    # Open-source flow
│   └── run_synthesis.sh      # Synthesis execution script
└── README.md                 # This file

constraints/                  # Timing and physical constraints
├── baseline.sdc             # Generic SDC constraints
├── artix7.xdc              # Artix-7 specific constraints
└── README.md               # Constraints documentation
```

## Target Device Configuration

### Artix-7 (Recommended for Development)
- **Device**: xc7a200tfbg676-2 (Nexys Video)
- **Clock**: 100MHz system clock
- **Memory**: DDR3 via AXI interface
- **Interfaces**: PCIe, HDMI, USB

### Kintex-7 (High Performance)
- **Device**: xc7k410tffg900-2
- **Clock**: 150MHz+ system clock
- **Memory**: DDR3/DDR4 via AXI interface
- **Interfaces**: PCIe Gen2/3, multiple HDMI

### Arria 10 (Intel Alternative)
- **Device**: 10AX115S2F45I1SG
- **Clock**: 100MHz system clock
- **Memory**: DDR4 via AXI interface
- **Interfaces**: PCIe Gen3, HDMI

## Synthesis Flow Details

### Vivado Flow
1. **Project Creation**: `create_project.tcl` generates Vivado project
2. **RTL Import**: All SystemVerilog files from `rtl/` directory
3. **Constraints**: SDC/XDC files from `constraints/` directory
4. **Synthesis**: Out-of-context or full synthesis
5. **Implementation**: Place and route with timing closure
6. **Bitstream Generation**: Programming file creation

### Quartus Flow
1. **Project Setup**: QPF/QSF project files
2. **RTL Import**: SystemVerilog files
3. **Constraints**: SDC constraints
4. **Analysis & Synthesis**: Logic synthesis
5. **Fitter**: Place and route
6. **Assembler**: Bitstream generation

### Yosys Flow
1. **RTL Import**: SystemVerilog files
2. **Synthesis**: Yosys synthesis to generic netlist
3. **Technology Mapping**: Target-specific cell mapping
4. **Place & Route**: nextpnr for supported devices
5. **Bitstream**: Device-specific bitstream generation

## Constraints

### Timing Constraints
- **System Clock**: 100MHz default (configurable)
- **AXI Interfaces**: 100MHz timing
- **Video Interfaces**: Pixel clock timing
- **PCIe**: Reference clock timing

### Physical Constraints
- **Pin Assignments**: Device-specific I/O mapping
- **I/O Standards**: LVCMOS33, LVDS, TMDS
- **Configuration**: Bitstream settings

### False Paths
- Asynchronous resets
- Debug signals
- Level-sensitive interrupts

### Multicycle Paths
- DMA operations (4 cycles)
- Raycaster pipeline (8 cycles)
- Complex arithmetic operations

## Performance Optimization

### Synthesis Options
- **Flatten Hierarchy**: Control module boundaries
- **Resource Sharing**: Arithmetic operator sharing
- **Retiming**: Register balancing for timing
- **Incremental Synthesis**: Faster iterations

### Implementation Strategies
- **Placement**: Spread/compact/balanced
- **Routing**: Explore for timing closure
- **Physical Optimization**: Post-route optimization

### Timing Closure Techniques
1. **Pipeline Addition**: Break critical paths
2. **Logic Replication**: Reduce fanout
3. **Register Balancing**: Move registers for timing
4. **Multi-cycle Paths**: Relax constraints where safe

## Resource Utilization Targets

### Artix-7 200T Goals
- **LUTs**: < 50% (50,000 / 134,600)
- **Flip-Flops**: < 30% (30,000 / 269,200)
- **BRAM**: < 60% (60 / 365)
- **DSP**: < 20% (20 / 740)

### Performance Targets
- **Fmax**: > 100MHz system clock
- **Setup Slack**: > 0.5ns
- **Hold Slack**: > 0.1ns

## Analysis and Reporting

### Automated Analysis
```bash
python3 scripts/analyze_synthesis.py --tool vivado --output report.md
```

### Manual Analysis
- **Utilization Report**: Resource usage breakdown
- **Timing Report**: Slack analysis and critical paths
- **Power Report**: Power consumption estimates
- ** DRC Report**: Design rule check violations

### Key Metrics
- **Worst Negative Slack (WNS)**: Must be positive
- **Total Negative Slack (TNS)**: Should be close to zero
- **Resource Utilization**: Stay within device limits
- **Power Consumption**: Thermal constraints

## Troubleshooting

### Common Issues

#### Timing Violations
- **Cause**: Critical paths too long
- **Solution**: Add pipeline stages, optimize logic

#### Resource Exhaustion
- **Cause**: Design too large for target device
- **Solution**: Optimize code, use larger device

#### Routing Congestion
- **Cause**: Poor placement, high utilization
- **Solution**: Adjust placement strategy, reduce utilization

#### DRC Violations
- **Cause**: Constraint conflicts, illegal connections
- **Solution**: Fix constraints, check RTL

### Debug Techniques
1. **Isolate Critical Paths**: Focus on failing timing paths
2. **Use Timing Constraints**: Guide tools with accurate constraints
3. **Iterative Optimization**: Small changes, frequent synthesis
4. **Cross-Probing**: Between RTL and implemented design

## Advanced Features

### Incremental Synthesis
- Faster iterations for small changes
- Preserves previous synthesis results
- Enabled by default in Vivado flow

### Out-of-Context Synthesis
- Synthesize modules independently
- Faster compile times
- Requires black-box constraints

### Hierarchical Design
- Partition design into smaller modules
- Team-based development
- IP protection through black-boxing

## Integration with CI/CD

### Automated Synthesis
```yaml
# GitHub Actions example
- name: FPGA Synthesis
  run: make synth-vivado

- name: Analyze Results
  run: make synth-analyze
```

### Quality Gates
- Timing closure verification
- Resource utilization checks
- DRC compliance
- Power budget validation

## Future Enhancements

### Planned Features
- **Multi-device Support**: Automated device selection
- **Advanced Timing Analysis**: Statistical timing analysis
- **Power Optimization**: Dynamic power management
- **Formal Verification**: Equivalence checking
- **Machine Learning**: Automated optimization suggestions

### ASIC Preparation
- **Synthesis for ASIC**: Standard cell library mapping
- **STA Integration**: Static timing analysis
- **DFT Insertion**: Scan chain insertion
- **Physical Design**: Floorplanning and routing

## Support

### Documentation
- [Vivado User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2020_2/ug904-vivado-implementation.pdf)
- [Quartus Handbook](https://www.intel.com/content/www/us/en/programmable/documentation/lit-quartus.html)
- [Yosys Manual](http://www.clifford.at/yosys/files/yosys_manual.pdf)

### Community Resources
- [FPGA Subreddit](https://www.reddit.com/r/FPGA/)
- [Vivado Forums](https://forums.xilinx.com/)
- [Intel Forums](https://forums.intel.com/)

For project-specific issues, please check the main README.md and create an issue on GitHub.