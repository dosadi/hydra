`ifndef HYDRA_ENV_SV
`define HYDRA_ENV_SV

class hydra_env extends uvm_env;
  `uvm_component_utils(hydra_env)

  // Agent instances
  hydra_axil_agent axil_agent;

  // Environment components
  hydra_scoreboard scoreboard;
  hydra_coverage coverage;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create agents
    axil_agent = hydra_axil_agent::type_id::create("axil_agent", this);

    // Create environment components
    scoreboard = hydra_scoreboard::type_id::create("scoreboard", this);
    coverage = hydra_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect monitor to scoreboard and coverage
    axil_agent.monitor.ap.connect(scoreboard.axil_ap);
    axil_agent.monitor.ap.connect(coverage.analysis_export);
  endfunction

  function void report_phase(uvm_phase phase);
    hydra_coverage_report cov_report;

    super.report_phase(phase);

    // Generate coverage report
    cov_report = hydra_coverage_report::type_id::create("cov_report");
    cov_report.collect_coverage(coverage);
    cov_report.generate_report();
    cov_report.export_to_file();

    // Environment-level reporting
    `uvm_info("HYDRA_ENV", "Hydra UVM Environment Report Complete", UVM_LOW)
  endfunction

endclass : hydra_env

`endif
