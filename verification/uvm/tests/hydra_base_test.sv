`ifndef HYDRA_BASE_TEST_SV
`define HYDRA_BASE_TEST_SV

class hydra_base_test extends uvm_test;
  `uvm_component_utils(hydra_base_test)

  hydra_env env;
  uvm_table_printer printer;

  function new(string name = "hydra_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the environment
    env = hydra_env::type_id::create("env", this);

    // Configure printer for better reporting
    printer = new();
    printer.knobs.depth = 5;
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    // Print topology
    `uvm_info("TEST", "Test topology:", UVM_LOW)
    this.print(printer);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);

    `uvm_info("TEST", "Starting Hydra base test", UVM_LOW)

    // Raise objection to keep simulation running
    phase.raise_objection(this);

    // Wait for sequences to complete
    #100ns;  // Allow some time for initialization

    // Drop objection to end simulation
    phase.drop_objection(this);

    `uvm_info("TEST", "Hydra base test complete", UVM_LOW)
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    // Test-level reporting
    `uvm_info("TEST", "Test report phase", UVM_LOW)
  endfunction

endclass : hydra_base_test

`endif