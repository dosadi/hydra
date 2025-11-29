`ifndef HYDRA_BLIT_TEST_SV
`define HYDRA_BLIT_TEST_SV

class hydra_blit_test extends hydra_base_test;
  `uvm_component_utils(hydra_blit_test)

  function new(string name = "hydra_blit_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    hydra_blit_sequence blit_seq;

    super.run_phase(phase);

    `uvm_info("BLIT_TEST", "Starting Hydra Blitter test", UVM_LOW)

    phase.raise_objection(this);

    // Create and start blitter sequence
    blit_seq = hydra_blit_sequence::type_id::create("blit_seq");
    blit_seq.start(env.axil_agent.sequencer);

    phase.drop_objection(this);

    `uvm_info("BLIT_TEST", "Hydra Blitter test complete", UVM_LOW)
  endtask

endclass : hydra_blit_test

`endif
