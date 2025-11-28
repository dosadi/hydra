# FPGA Synthesis Constraints

This directory contains Synopsys Design Constraint (SDC) files for FPGA synthesis targets.

## Files

- `baseline.sdc` - Baseline timing constraints for reference FPGA targets
  - 100MHz system clock assumption
  - Basic I/O timing for PCIe, AXI-Lite, AXI-Stream interfaces
  - False paths for async resets and debug signals
  - Multicycle paths for DMA and raycaster pipelines

## Usage

### Xilinx Vivado
```tcl
read_xdc constraints/baseline.sdc
```

### Intel Quartus
Convert SDC to QSF format or use TimeQuest constraints.

### Other Tools
Import as SDC file or adapt to tool-specific constraint format.

## Target-Specific Customization

Copy `baseline.sdc` and modify for specific targets:

- Adjust clock periods based on device capabilities
- Add target-specific false paths for unused interfaces
- Set device-specific input/output delays
- Configure PLL/MMCM generated clocks

## Clock Domains

- `clk` - Main system clock (default 100MHz)
- Add generated clocks for pixel clocks, PCIe reference, etc.

## Notes

- These are baseline constraints for initial synthesis
- Timing closure may require target-specific tuning
- Review and adjust multicycle paths based on actual design requirements