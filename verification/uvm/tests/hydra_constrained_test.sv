`ifndef HYDRA_CONSTRAINED_TEST_SV
`define HYDRA_CONSTRAINED_TEST_SV

// Constrained Random Test
// Runs constrained random sequences for comprehensive verification coverage

class hydra_constrained_test extends hydra_base_test;
  `uvm_component_utils(hydra_constrained_test)

  function new(string name = "hydra_constrained_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Configure test for constrained random testing
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.agent.sequencer.run_phase",
                                             "default_sequence",
                                             hydra_constrained_sequence::type_id::get());
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info("CONSTR_TEST", "Starting Hydra Constrained Random Test", UVM_LOW)

    // Let the sequence run
    phase.raise_objection(this);
    #1000ns;  // Wait for sequence to complete
    phase.drop_objection(this);

    `uvm_info("CONSTR_TEST", "Hydra Constrained Random Test Complete", UVM_LOW)
  endtask

endclass : hydra_constrained_test

`endif
