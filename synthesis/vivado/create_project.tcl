#!/usr/bin/env tcl
# ============================================================================
# Hydra Vivado Synthesis Script
# Automated FPGA synthesis flow for Xilinx Vivado
# ============================================================================

# Set project parameters
set project_name "hydra_synth"
set project_dir "./vivado_project"
set top_module "voxel_framebuffer_top"

# Get configuration from environment variables
set device_part [expr {[info exists ::env(DEVICE)] ? $::env(DEVICE) : "xc7a200tfbg676-2"}]
set clk_period [expr {[info exists ::env(CLOCK_PERIOD)] ? $::env(CLOCK_PERIOD) : 10.0}]
set jobs [expr {[info exists ::env(JOBS)] ? $::env(JOBS) : 4}]

# Source directories
set rtl_dir "../../rtl"
set constraints_dir "../../constraints"

# Create project directory
file mkdir $project_dir
cd $project_dir

# Create Vivado project
create_project $project_name -part $device_part -force

# Add RTL source files
set rtl_files [glob -directory $rtl_dir *.sv]
foreach file $rtl_files {
    if {[file tail $file] != "voxel_sim_harness.sv"} {
        add_files $file
    }
}

# Add IP cores if any
# add_files [glob -directory ../../third_party/ip/*.xci]

# Set top module
set_property top $top_module [current_fileset]

# Add constraints
if {[file exists "$constraints_dir/baseline.sdc"]} {
    add_files -fileset constrs_1 "$constraints_dir/baseline.sdc"
}

# Set synthesis and implementation strategies
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]

# Enable incremental synthesis for faster iterations
set_property STEPS.SYNTH_DESIGN.ARGS.INCREMENTAL_SYNTHESIS {true} [get_runs synth_1]

# Configure synthesis options
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {rebuilt} [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS {true} [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING {off} [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.CONTROL_SET_OPT_THRESHOLD {16} [get_runs synth_1]

# Configure implementation options
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE {Explore} [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE {Explore} [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE {Explore} [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE {Explore} [get_runs impl_1]

# Enable timing closure effort
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE {MoreGlobalIterations} [get_runs impl_1]

# Generate bitstream
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE {true} [get_runs impl_1]

# Save project
save_project

puts "Vivado project created successfully!"
puts "To run synthesis:"
puts "  cd $project_dir"
puts "  launch_runs synth_1 -jobs 4"
puts "  wait_on_run synth_1"
puts ""
puts "To run implementation:"
puts "  launch_runs impl_1 -jobs 4"
puts "  wait_on_run impl_1"
puts ""
puts "To generate bitstream:"
puts "  launch_runs impl_1 -to_step write_bitstream"
puts ""
puts "To open GUI:"
puts "  start_gui"