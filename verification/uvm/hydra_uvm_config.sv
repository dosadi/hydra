`ifndef HYDRA_UVM_CONFIG_SV
`define HYDRA_UVM_CONFIG_SV

// Hydra UVM Configuration Class
// This class contains all configurable parameters for the UVM testbench

class hydra_uvm_config extends uvm_object;
  `uvm_object_utils(hydra_uvm_config)

  // Testbench configuration
  bit enable_coverage = 1;           // Enable functional coverage
  bit enable_scoreboard = 1;         // Enable scoreboard checking
  bit enable_protocol_checks = 1;    // Enable protocol assertions

  // Timing configuration
  time clock_period = 10ns;          // Clock period (100MHz default)
  time reset_duration = 100ns;       // Reset duration
  time default_timeout = 1ms;        // Default timeout for operations

  // AXI-Lite configuration
  int axil_addr_width = 32;          // Address width
  int axil_data_width = 32;          // Data width

  // Test configuration
  int num_sequences = 10;            // Number of sequences to run
  bit random_seed_enable = 0;        // Enable random seed
  int random_seed = 12345;           // Random seed value

  // DMA configuration
  bit dma_enable = 1;                // Enable DMA testing
  int dma_max_transfer_size = 4096;  // Maximum DMA transfer size
  bit dma_random_sizes = 1;          // Use random DMA sizes

  // Blitter configuration
  bit blitter_enable = 1;            // Enable blitter testing
  int blitter_max_width = 1920;      // Maximum blitter width
  int blitter_max_height = 1080;     // Maximum blitter height

  // Frame rendering configuration
  bit frame_render_enable = 1;       // Enable frame rendering testing
  int frame_timeout_cycles = 100000; // Frame rendering timeout

  // Reporting configuration
  bit detailed_logging = 0;          // Enable detailed logging
  string log_filename = "hydra_uvm.log"; // Log file name
  bit waveform_enable = 0;           // Enable waveform dumping
  string waveform_filename = "hydra_uvm.vcd"; // Waveform file name

  function new(string name = "hydra_uvm_config");
    super.new(name);
    // Set default values based on environment variables if available
    if ($test$plusargs("COVERAGE_DISABLE")) enable_coverage = 0;
    if ($test$plusargs("SCOREBOARD_DISABLE")) enable_scoreboard = 0;
    if ($test$plusargs("PROTOCOL_CHECKS_DISABLE")) enable_protocol_checks = 0;
    if ($test$plusargs("WAVEFORM_ENABLE")) waveform_enable = 1;
    if ($test$plusargs("DETAILED_LOG")) detailed_logging = 1;
  endfunction

  // Utility function to print configuration
  function void print_config();
    `uvm_info("CONFIG", "Hydra UVM Configuration:", UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Coverage enabled: %0d", enable_coverage), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Scoreboard enabled: %0d", enable_scoreboard), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Protocol checks: %0d", enable_protocol_checks), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Clock period: %0t", clock_period), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  DMA enabled: %0d", dma_enable), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Blitter enabled: %0d", blitter_enable), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Frame render enabled: %0d", frame_render_enable), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Waveform dumping: %0d", waveform_enable), UVM_LOW)
  endfunction

endclass : hydra_uvm_config

`endif
