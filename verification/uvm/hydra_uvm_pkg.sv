`ifndef HYDRA_UVM_PKG_SV
`define HYDRA_UVM_PKG_SV

`include "uvm_macros.svh"
package hydra_uvm_pkg;
  import uvm_pkg::*;

  // Include all UVM verification components
  `include "hydra_uvm_defines.svh"
  `include "hydra_types.svh"
  `include "hydra_axil_if.sv"
  `include "hydra_uvm_config.sv"
  `include "hydra_coverage_report.sv"
  `include "hydra_product_config.sv"

  // Agent components
  `include "agents/axil_agent/hydra_axil_item.sv"
  `include "agents/axil_agent/hydra_axil_driver.sv"
  `include "agents/axil_agent/hydra_axil_monitor.sv"
  `include "agents/axil_agent/hydra_axil_sequencer.sv"
  `include "agents/axil_agent/hydra_axil_agent.sv"

  // TODO: Add AXI agent when AXI interfaces are defined
  // `include "agents/axi_agent/hydra_axi_item.sv"
  // `include "agents/axi_agent/hydra_axi_driver.sv"
  // `include "agents/axi_agent/hydra_axi_monitor.sv"
  // `include "agents/axi_agent/hydra_axi_sequencer.sv"
  // `include "agents/axi_agent/hydra_axi_agent.sv"

  // Environment
  `include "env/hydra_env.sv"
  `include "env/hydra_scoreboard.sv"
  `include "env/hydra_coverage.sv"

  // Sequences
  `include "sequences/hydra_base_sequence.sv"
  `include "sequences/hydra_csr_sequence.sv"
  `include "sequences/hydra_dma_sequence.sv"
  `include "sequences/hydra_blit_sequence.sv"
  `include "sequences/hydra_frame_sequence.sv"
  `include "sequences/hydra_constrained_sequence.sv"
  `include "sequences/hydra_performance_sequence.sv"

  // Tests
  `include "tests/hydra_base_test.sv"
  `include "tests/hydra_csr_test.sv"
  `include "tests/hydra_dma_test.sv"
  `include "tests/hydra_blit_test.sv"
  `include "tests/hydra_integration_test.sv"
  `include "tests/hydra_performance_test.sv"
  `include "tests/hydra_constrained_test.sv"

endpackage : hydra_uvm_pkg

`endif
