# ============================================================================
# Hydra Synthesis Configuration
# User-configurable synthesis settings
# ============================================================================

# Default synthesis settings
# These can be overridden by environment variables or command line options

# Synthesis Tool Selection
# Options: auto, vivado, quartus, yosys, all
# Default: auto (automatically selects best tool for target)
TOOL="${TOOL:-auto}"

# Target Device/Family
# Options: artix7, kintex7, virtex7, arria10, stratix5, ecp5, ice40
# Default: artix7 (Xilinx Artix-7)
TARGET="${TARGET:-artix7}"

# Clock Configuration
# System clock period in nanoseconds
# Default: 10.0 (100MHz)
CLOCK_PERIOD="${CLOCK_PERIOD:-10.0}"

# Parallel Processing
# Number of parallel jobs for synthesis
# Default: 4
JOBS="${JOBS:-4}"

# Synthesis Strategy
# Options: speed, area, balanced, timing
# Default: speed
STRATEGY="${STRATEGY:-speed}"

# Effort Level
# Options: fast, medium, high
# Default: medium
EFFORT="${EFFORT:-medium}"

# Target-Specific Device Configuration

# Xilinx Artix-7
ARTIX7_DEVICE="${ARTIX7_DEVICE:-xc7a200tfbg676-2}"
ARTIX7_PACKAGE="${ARTIX7_PACKAGE:-fbg676}"
ARTIX7_SPEED="${ARTIX7_SPEED:-2}"

# Xilinx Kintex-7
KINTEX7_DEVICE="${KINTEX7_DEVICE:-xc7k410tffg900-2}"
KINTEX7_PACKAGE="${KINTEX7_PACKAGE:-ffg900}"
KINTEX7_SPEED="${KINTEX7_SPEED:-2}"

# Xilinx Virtex-7
VIRTEX7_DEVICE="${VIRTEX7_DEVICE:-xc7v2000tfhg1761-2}"
VIRTEX7_PACKAGE="${VIRTEX7_PACKAGE:-fhg1761}"
VIRTEX7_SPEED="${VIRTEX7_SPEED:-2}"

# Intel Arria 10
ARRIA10_DEVICE="${ARRIA10_DEVICE:-10AX115S2F45I1SG}"
ARRIA10_FAMILY="${ARRIA10_FAMILY:-Arria 10}"

# Intel Stratix V
STRATIX5_DEVICE="${STRATIX5_DEVICE:-5SGXEA7N2F45C2}"
STRATIX5_FAMILY="${STRATIX5_FAMILY:-Stratix V}"

# Lattice ECP5
ECP5_DEVICE="${ECP5_DEVICE:-LFE5U-85F-6BG381C}"

# Lattice iCE40
ICE40_DEVICE="${ICE40_DEVICE:-iCE40UP5K-SG48}"

# Timing Constraints
# Input delay (as percentage of clock period)
INPUT_DELAY_PCT="${INPUT_DELAY_PCT:-20}"

# Output delay (as percentage of clock period)
OUTPUT_DELAY_PCT="${OUTPUT_DELAY_PCT:-20}"

# Multicycle path constraints
MULTICYCLE_DMA="${MULTICYCLE_DMA:-4}"
MULTICYCLE_RAYCASTER="${MULTICYCLE_RAYCASTER:-8}"

# Optimization Settings

# Enable retiming
RETIMING="${RETIMING:-true}"

# Enable register balancing
REGISTER_BALANCING="${REGISTER_BALANCING:-true}"

# Enable resource sharing
RESOURCE_SHARING="${RESOURCE_SHARING:-false}"

# Maximum fanout
MAX_FANOUT="${MAX_FANOUT:-100}"

# Output Configuration

# Generate reports
GENERATE_REPORTS="${GENERATE_REPORTS:-true}"

# Generate bitstream
GENERATE_BITSTREAM="${GENERATE_BITSTREAM:-true}"

# Generate programming file
GENERATE_PROGRAMMING_FILE="${GENERATE_PROGRAMMING_FILE:-true}"

# Report Configuration

# Maximum timing paths to report
MAX_TIMING_PATHS="${MAX_TIMING_PATHS:-100}"

# Include power analysis
INCLUDE_POWER="${INCLUDE_POWER:-true}"

# Include utilization details
INCLUDE_UTILIZATION="${INCLUDE_UTILIZATION:-true}"

# Debug and Development

# Enable verbose logging
VERBOSE="${VERBOSE:-false}"

# Keep intermediate files
KEEP_INTERMEDIATE="${KEEP_INTERMEDIATE:-false}"

# Enable incremental synthesis
INCREMENTAL_SYNTHESIS="${INCREMENTAL_SYNTHESIS:-true}"

# Cross-Tool Comparison

# Enable comparison mode
COMPARISON_MODE="${COMPARISON_MODE:-false}"

# Comparison output directory
COMPARISON_DIR="${COMPARISON_DIR:-synthesis_comparison}"

# Export configuration as environment variables
export TOOL TARGET CLOCK_PERIOD JOBS STRATEGY EFFORT
export ARTIX7_DEVICE KINTEX7_DEVICE VIRTEX7_DEVICE
export ARRIA10_DEVICE STRATIX5_DEVICE ECP5_DEVICE ICE40_DEVICE
export INPUT_DELAY_PCT OUTPUT_DELAY_PCT
export MULTICYCLE_DMA MULTICYCLE_RAYCASTER
export RETIMING REGISTER_BALANCING RESOURCE_SHARING MAX_FANOUT
export GENERATE_REPORTS GENERATE_BITSTREAM GENERATE_PROGRAMMING_FILE
export MAX_TIMING_PATHS INCLUDE_POWER INCLUDE_UTILIZATION
export VERBOSE KEEP_INTERMEDIATE INCREMENTAL_SYNTHESIS
export COMPARISON_MODE COMPARISON_DIR