`ifndef HYDRA_PERFORMANCE_TEST_SV
`define HYDRA_PERFORMANCE_TEST_SV

// Performance Test
// Runs performance profiling sequences to measure system throughput and latency

class hydra_performance_test extends hydra_base_test;
  `uvm_component_utils(hydra_performance_test)

  function new(string name = "hydra_performance_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Configure test for performance measurement
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.agent.sequencer.run_phase",
                                             "default_sequence",
                                             hydra_performance_sequence::type_id::get());
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info("PERF_TEST", "Starting Hydra Performance Test", UVM_LOW)

    // Let the sequence run
    phase.raise_objection(this);
    #1000ns;  // Wait for sequence to complete
    phase.drop_objection(this);

    `uvm_info("PERF_TEST", "Hydra Performance Test Complete", UVM_LOW)
  endtask

endclass : hydra_performance_test

`endif