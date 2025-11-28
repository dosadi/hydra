# ============================================================================
# Hydra FPGA Constraints (baseline.sdc)
# Baseline Synopsys Design Constraints for FPGA synthesis targets
# ============================================================================

# Clock definitions
# Main system clock (assume 100MHz for baseline)
create_clock -name clk -period 10.0 [get_ports clk]

# Generated clocks (if any PLLs/MMCMs are instantiated)
# create_generated_clock -name clk_pixel -source [get_pins pll_inst/clk_out] -divide_by 2 [get_pins pll_inst/clk_pixel_out]

# Clock groups for asynchronous clock domains
# set_clock_groups -asynchronous -group {clk} -group {clk_pixel}

# Input delays (relative to clock)
# PCIe interface (assume 250MHz reference, but constrain to system clock)
set_input_delay -clock clk -max 2.0 [get_ports s_pcie_*]
set_input_delay -clock clk -min 0.5 [get_ports s_pcie_*]

# AXI-Lite interface
set_input_delay -clock clk -max 2.0 [get_ports s_axil_*]
set_input_delay -clock clk -min 0.5 [get_ports s_axil_*]

# AXI-Stream video interface
set_input_delay -clock clk -max 2.0 [get_ports s_axis_*]
set_input_delay -clock clk -min 0.5 [get_ports s_axis_*]

# Output delays
set_output_delay -clock clk -max 2.0 [get_ports m_axil_*]
set_output_delay -clock clk -min 0.5 [get_ports m_axil_*]

set_output_delay -clock clk -max 2.0 [get_ports m_axis_*]
set_output_delay -clock clk -min 0.5 [get_ports m_axis_*]

# False paths
# Asynchronous resets
set_false_path -from [get_ports rst_n] -to [all_registers]

# IRQ output (level signal, no tight timing required)
set_false_path -from [all_registers] -to [get_ports irq_out]

# Debug ports (no timing requirements)
set_false_path -from [all_registers] -to [get_ports debug_*]
set_false_path -from [get_ports debug_*] -to [all_registers]

# Multicycle paths
# DMA operations (can tolerate multiple cycles)
set_multicycle_path -from [get_cells *dma*] -to [get_cells *dma*] 4
set_multicycle_path -from [get_cells *dma*] -to [get_cells *dma*] 4 -hold

# Raycaster pipeline (deep pipeline, multicycle okay)
set_multicycle_path -from [get_cells *raycaster*] -to [get_cells *raycaster*] 8
set_multicycle_path -from [get_cells *raycaster*] -to [get_cells *raycaster*] 8 -hold

# Maximum delay constraints
# Critical paths that must be fast
set_max_delay -from [get_cells *csr*] -to [get_cells *irq*] 5.0

# Minimum delay constraints (hold time)
set_min_delay -from [all_registers] -to [all_registers] 0.1

# Clock uncertainty (jitter, skew)
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]

# Input transition time
set_input_transition -max 0.5 [all_inputs]
set_input_transition -min 0.1 [all_inputs]

# Output load
set_load 10 [all_outputs]

# Operating conditions (if applicable)
# set_operating_conditions -library <library> <condition>

# Area constraints (if needed for specific targets)
# set_max_area 50000

# Comments for target-specific overrides:
# - For Xilinx Vivado: Use this SDC as XDC input
# - For Intel Quartus: Convert to QSF constraints
# - Adjust clock periods based on target device capabilities
# - Add target-specific false paths for unused interfaces