# ============================================================================
# Hydra Artix-7 Constraints (artix7.xdc)
# Xilinx Artix-7 specific timing and physical constraints
# ============================================================================

# Clock definitions
# Main system clock (assume 100MHz for Artix-7 200T)
create_clock -name clk -period 10.0 [get_ports clk]
set_property PACKAGE_PIN R4 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset input
set_property PACKAGE_PIN G4 [get_ports rst_n]
set_property IOSTANDARD LVCMOS15 [get_ports rst_n]

# PCIe interface (if used)
# set_property PACKAGE_PIN AB7 [get_ports pcie_refclk_p]
# set_property PACKAGE_PIN AB6 [get_ports pcie_refclk_n]
# set_property IOSTANDARD LVDS [get_ports {pcie_refclk_p pcie_refclk_n}]

# AXI-Lite interface (PMOD connectors for testing)
# PMOD JA
set_property PACKAGE_PIN Y11 [get_ports {s_axil_awaddr[0]}]
set_property PACKAGE_PIN AA11 [get_ports {s_axil_awaddr[1]}]
set_property PACKAGE_PIN Y10 [get_ports {s_axil_awaddr[2]}]
set_property PACKAGE_PIN AA9 [get_ports {s_axil_awaddr[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {s_axil_awaddr[*]}]

# PMOD JB
set_property PACKAGE_PIN W12 [get_ports {s_axil_wdata[0]}]
set_property PACKAGE_PIN W11 [get_ports {s_axil_wdata[1]}]
set_property PACKAGE_PIN V10 [get_ports {s_axil_wdata[2]}]
set_property PACKAGE_PIN W8 [get_ports {s_axil_wdata[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {s_axil_wdata[*]}]

# AXI-Stream video output (HDMI port)
# HDMI TX pins (example mapping)
# set_property PACKAGE_PIN V7 [get_ports hdmi_tx_p[0]]
# set_property PACKAGE_PIN W7 [get_ports hdmi_tx_p[1]]
# set_property PACKAGE_PIN Y7 [get_ports hdmi_tx_p[2]]
# set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_p[*] hdmi_tx_n[*]}]

# LED outputs for status
set_property PACKAGE_PIN T14 [get_ports {led[0]}]
set_property PACKAGE_PIN T15 [get_ports {led[1]}]
set_property PACKAGE_PIN T16 [get_ports {led[2]}]
set_property PACKAGE_PIN U16 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# Button inputs
set_property PACKAGE_PIN B22 [get_ports {btn[0]}]
set_property PACKAGE_PIN D22 [get_ports {btn[1]}]
set_property PACKAGE_PIN C22 [get_ports {btn[2]}]
set_property PACKAGE_PIN D14 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {btn[*]}]

# Switch inputs
set_property PACKAGE_PIN E22 [get_ports {sw[0]}]
set_property PACKAGE_PIN F21 [get_ports {sw[1]}]
set_property PACKAGE_PIN G21 [get_ports {sw[2]}]
set_property PACKAGE_PIN G22 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {sw[*]}]

# Timing constraints (inherited from baseline.sdc)
set_input_delay -clock clk -max 2.0 [get_ports s_axil_*]
set_input_delay -clock clk -min 0.5 [get_ports s_axil_*]
set_output_delay -clock clk -max 2.0 [get_ports m_axil_*]
set_output_delay -clock clk -min 0.5 [get_ports m_axil_*]

# False paths for async inputs
set_false_path -from [get_ports rst_n]
set_false_path -from [get_ports {btn[*]}]
set_false_path -from [get_ports {sw[*]}]

# Multicycle paths for complex operations
set_multicycle_path -from [get_cells *dma*] -to [get_cells *dma*] 4
set_multicycle_path -from [get_cells *raycaster*] -to [get_cells *raycaster*] 8

# Clock uncertainty for Artix-7
set_clock_uncertainty -setup 0.5 [get_clocks clk]
set_clock_uncertainty -hold 0.1 [get_clocks clk]

# Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# Bitstream configuration
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]