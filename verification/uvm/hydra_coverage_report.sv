`ifndef HYDRA_COVERAGE_REPORT_SV
`define HYDRA_COVERAGE_REPORT_SV

// Hydra Coverage Report Generator
// Provides detailed coverage analysis and reporting

class hydra_coverage_report extends uvm_object;
  `uvm_object_utils(hydra_coverage_report)

  // Coverage data
  real axil_transaction_coverage;
  real hydra_operation_coverage;
  real total_functional_coverage;

  // Detailed metrics
  int total_axil_transactions;
  int covered_axil_transactions;
  int total_hydra_operations;
  int covered_hydra_operations;

  // Coverage holes
  string uncovered_axil_addresses[];
  string uncovered_operations[];

  function new(string name = "hydra_coverage_report");
    super.new(name);
  endfunction

  // Collect coverage data from coverage groups
  function void collect_coverage(hydra_coverage cov);
    axil_transaction_coverage = cov.axil_transaction_cg.get_coverage();
    hydra_operation_coverage = cov.hydra_operation_cg.get_coverage();

    // Calculate weighted total coverage
    total_functional_coverage = (axil_transaction_coverage * 0.6) +
                               (hydra_operation_coverage * 0.4);

    // Collect detailed metrics
    collect_detailed_metrics(cov);
  endfunction

  function void collect_detailed_metrics(hydra_coverage cov);
    // Get coverage statistics
    total_axil_transactions = cov.axil_transaction_cg.get_total_bins();
    covered_axil_transactions = cov.axil_transaction_cg.get_covered_bins();
    total_hydra_operations = cov.hydra_operation_cg.get_total_bins();
    covered_hydra_operations = cov.hydra_operation_cg.get_covered_bins();

    // Identify coverage holes
    identify_coverage_holes(cov);
  endfunction

  function void identify_coverage_holes(hydra_coverage cov);
    // Check for uncovered AXI-Lite addresses
    if (cov.axil_transaction_cg.get_coverage() < 100.0) begin
      uncovered_axil_addresses = new[1];
      uncovered_axil_addresses[0] = "Some CSR registers not accessed";
    end

    // Check for uncovered operations
    if (cov.hydra_operation_cg.get_coverage() < 100.0) begin
      uncovered_operations = new[1];
      uncovered_operations[0] = "Some Hydra operations not tested";
    end
  endfunction

  // Generate detailed coverage report
  function void generate_report();
    `uvm_info("COV_REPORT", "========================================", UVM_LOW)
    `uvm_info("COV_REPORT", "     HYDRA UVM COVERAGE REPORT", UVM_LOW)
    `uvm_info("COV_REPORT", "========================================", UVM_LOW)
    `uvm_info("COV_REPORT", "", UVM_LOW)

    `uvm_info("COV_REPORT", "AXI-Lite Transaction Coverage:", UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Coverage: %.2f%%", axil_transaction_coverage), UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Total bins: %0d", total_axil_transactions), UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Covered bins: %0d", covered_axil_transactions), UVM_LOW)
    `uvm_info("COV_REPORT", "", UVM_LOW)

    `uvm_info("COV_REPORT", "Hydra Operation Coverage:", UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Coverage: %.2f%%", hydra_operation_coverage), UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Total bins: %0d", total_hydra_operations), UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Covered bins: %0d", covered_hydra_operations), UVM_LOW)
    `uvm_info("COV_REPORT", "", UVM_LOW)

    `uvm_info("COV_REPORT", "Overall Functional Coverage:", UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Total Coverage: %.2f%%", total_functional_coverage), UVM_LOW)
    `uvm_info("COV_REPORT", "", UVM_LOW)

    // Report coverage holes
    if (uncovered_axil_addresses.size() > 0) begin
      `uvm_info("COV_REPORT", "Coverage Holes - AXI-Lite:", UVM_LOW)
      foreach (uncovered_axil_addresses[i]) begin
        `uvm_info("COV_REPORT", $sformatf("  - %s", uncovered_axil_addresses[i]), UVM_LOW)
      end
      `uvm_info("COV_REPORT", "", UVM_LOW)
    end

    if (uncovered_operations.size() > 0) begin
      `uvm_info("COV_REPORT", "Coverage Holes - Operations:", UVM_LOW)
      foreach (uncovered_operations[i]) begin
        `uvm_info("COV_REPORT", $sformatf("  - %s", uncovered_operations[i]), UVM_LOW)
      end
      `uvm_info("COV_REPORT", "", UVM_LOW)
    end

    // Coverage quality assessment
    generate_coverage_assessment();

    `uvm_info("COV_REPORT", "========================================", UVM_LOW)
  endfunction

  function void generate_coverage_assessment();
    string assessment;

    if (total_functional_coverage >= 95.0) begin
      assessment = "EXCELLENT: Comprehensive coverage achieved";
    end else if (total_functional_coverage >= 85.0) begin
      assessment = "GOOD: Solid coverage with minor gaps";
    end else if (total_functional_coverage >= 70.0) begin
      assessment = "ADEQUATE: Basic coverage achieved";
    end else begin
      assessment = "INSUFFICIENT: Additional testing required";
    end

    `uvm_info("COV_REPORT", "Coverage Assessment:", UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  %s", assessment), UVM_LOW)
    `uvm_info("COV_REPORT", "", UVM_LOW)

    // Recommendations
    if (total_functional_coverage < 90.0) begin
      `uvm_info("COV_REPORT", "Recommendations:", UVM_LOW)
      if (axil_transaction_coverage < 90.0) begin
        `uvm_info("COV_REPORT", "  - Add more AXI-Lite address coverage", UVM_LOW)
      end
      if (hydra_operation_coverage < 90.0) begin
        `uvm_info("COV_REPORT", "  - Add more Hydra operation scenarios", UVM_LOW)
      end
      `uvm_info("COV_REPORT", "  - Consider constrained random testing", UVM_LOW)
    end
  endfunction

  // Export coverage data to file
  function void export_to_file(string filename = "coverage_report.txt");
    int fd = $fopen(filename, "w");

    if (fd) begin
      $fdisplay(fd, "Hydra UVM Coverage Report");
      $fdisplay(fd, "Generated: %0t", $time);
      $fdisplay(fd, "");
      $fdisplay(fd, "AXI-Lite Transaction Coverage: %.2f%%", axil_transaction_coverage);
      $fdisplay(fd, "Hydra Operation Coverage: %.2f%%", hydra_operation_coverage);
      $fdisplay(fd, "Total Functional Coverage: %.2f%%", total_functional_coverage);
      $fclose(fd);
      `uvm_info("COV_REPORT", $sformatf("Coverage report exported to %s", filename), UVM_LOW)
    end else begin
      `uvm_error("COV_REPORT", "Failed to open coverage report file")
    end
  endfunction

endclass : hydra_coverage_report

`endif