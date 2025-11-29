`ifndef HYDRA_CSR_TEST_SV
`define HYDRA_CSR_TEST_SV

class hydra_csr_test extends hydra_base_test;
  `uvm_component_utils(hydra_csr_test)

  function new(string name = "hydra_csr_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    hydra_csr_sequence csr_seq;

    super.run_phase(phase);

    `uvm_info("CSR_TEST", "Starting Hydra CSR test", UVM_LOW)

    phase.raise_objection(this);

    // Create and start CSR sequence
    csr_seq = hydra_csr_sequence::type_id::create("csr_seq");
    csr_seq.start(env.axil_agent.sequencer);

    phase.drop_objection(this);

    `uvm_info("CSR_TEST", "Hydra CSR test complete", UVM_LOW)
  endtask

endclass : hydra_csr_test

`endif
