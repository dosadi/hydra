`ifndef HYDRA_DMA_TEST_SV
`define HYDRA_DMA_TEST_SV

class hydra_dma_test extends hydra_base_test;
  `uvm_component_utils(hydra_dma_test)

  function new(string name = "hydra_dma_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    hydra_dma_sequence dma_seq;

    super.run_phase(phase);

    `uvm_info("DMA_TEST", "Starting Hydra DMA test", UVM_LOW)

    phase.raise_objection(this);

    // Create and start DMA sequence
    dma_seq = hydra_dma_sequence::type_id::create("dma_seq");
    dma_seq.start(env.axil_agent.sequencer);

    phase.drop_objection(this);

    `uvm_info("DMA_TEST", "Hydra DMA test complete", UVM_LOW)
  endtask

endclass : hydra_dma_test

`endif