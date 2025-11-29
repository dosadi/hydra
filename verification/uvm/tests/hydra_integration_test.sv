`ifndef HYDRA_INTEGRATION_TEST_SV
`define HYDRA_INTEGRATION_TEST_SV

class hydra_integration_test extends hydra_base_test;
  `uvm_component_utils(hydra_integration_test)

  function new(string name = "hydra_integration_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    hydra_csr_sequence csr_seq;
    hydra_dma_sequence dma_seq;
    hydra_blit_sequence blit_seq;
    hydra_frame_sequence frame_seq;

    super.run_phase(phase);

    `uvm_info("INT_TEST", "Starting Hydra Integration test", UVM_LOW)

    phase.raise_objection(this);

    // Run CSR test
    `uvm_info("INT_TEST", "Running CSR operations", UVM_MEDIUM)
    csr_seq = hydra_csr_sequence::type_id::create("csr_seq");
    csr_seq.start(env.axil_agent.sequencer);

    // Run DMA test
    `uvm_info("INT_TEST", "Running DMA operations", UVM_MEDIUM)
    dma_seq = hydra_dma_sequence::type_id::create("dma_seq");
    dma_seq.start(env.axil_agent.sequencer);

    // Run Blitter test
    `uvm_info("INT_TEST", "Running Blitter operations", UVM_MEDIUM)
    blit_seq = hydra_blit_sequence::type_id::create("blit_seq");
    blit_seq.start(env.axil_agent.sequencer);

    // Run Frame rendering test
    `uvm_info("INT_TEST", "Running Frame rendering operations", UVM_MEDIUM)
    frame_seq = hydra_frame_sequence::type_id::create("frame_seq");
    frame_seq.start(env.axil_agent.sequencer);

    phase.drop_objection(this);

    `uvm_info("INT_TEST", "Hydra Integration test complete", UVM_LOW)
  endtask

endclass : hydra_integration_test

`endif
