`ifndef HYDRA_SCOREBOARD_SV
`define HYDRA_SCOREBOARD_SV

class hydra_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(hydra_scoreboard)

  // Analysis ports for receiving transactions
  uvm_analysis_imp#(hydra_axil_item, hydra_scoreboard) axil_ap;

  // Expected vs actual data structures
  bit [31:0] csr_registers[bit [31:0]];  // Register address -> value
  bit [31:0] memory[bit [31:0]];         // Memory address -> value

  // Statistics
  int total_transactions;
  int passed_transactions;
  int failed_transactions;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    axil_ap = new("axil_ap", this);
    initialize_registers();
  endfunction

  function void initialize_registers();
    // Initialize CSR registers with default values
    csr_registers[`CTRL_OFFSET] = 32'h0;
    csr_registers[`INT_MASK_OFFSET] = 32'h0;
    csr_registers[`INT_STATUS_OFFSET] = 32'h0;
    csr_registers[`DMA_CMD_OFFSET] = 32'h0;
    csr_registers[`BLIT_CTRL_OFFSET] = 32'h0;
    csr_registers[`HDMI_CRC_OFFSET] = 32'h0;
  endfunction

  function void write_axil(hydra_axil_item item);
    total_transactions++;

    if (item.write) begin
      // Write transaction - update expected register/memory state
      if (is_csr_register(item.addr)) begin
        csr_registers[item.addr] = item.data;
        `uvm_info("SCOREBOARD", $sformatf("Updated CSR register 0x%08h = 0x%08h", item.addr, item.data), UVM_MEDIUM)
      end else begin
        memory[item.addr] = item.data;
        `uvm_info("SCOREBOARD", $sformatf("Updated memory 0x%08h = 0x%08h", item.addr, item.data), UVM_MEDIUM)
      end
      passed_transactions++;
    end else begin
      // Read transaction - compare with expected value
      bit [31:0] expected_data;
      if (is_csr_register(item.addr)) begin
        expected_data = csr_registers[item.addr];
      end else begin
        expected_data = memory[item.addr];
      end

      if (item.data == expected_data) begin
        `uvm_info("SCOREBOARD", $sformatf("READ MATCH: Addr=0x%08h Expected=0x%08h Actual=0x%08h",
                  item.addr, expected_data, item.data), UVM_MEDIUM)
        passed_transactions++;
      end else begin
        `uvm_error("SCOREBOARD", $sformatf("READ MISMATCH: Addr=0x%08h Expected=0x%08h Actual=0x%08h",
                  item.addr, expected_data, item.data))
        failed_transactions++;
      end
    end
  endfunction

  function bit is_csr_register(bit [31:0] addr);
    // Check if address is within CSR range
    return (addr >= `CTRL_OFFSET && addr <= `HDMI_CRC_OFFSET);
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCOREBOARD", $sformatf("Scoreboard Report:"), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Total transactions: %0d", total_transactions), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Passed: %0d", passed_transactions), UVM_LOW)
    `uvm_info("SCOREBOARD", $sformatf("  Failed: %0d", failed_transactions), UVM_LOW)

    if (failed_transactions > 0) begin
      `uvm_error("SCOREBOARD", $sformatf("SCOREBOARD FAILED: %0d/%0d transactions failed",
                failed_transactions, total_transactions))
    end else if (total_transactions > 0) begin
      `uvm_info("SCOREBOARD", "SCOREBOARD PASSED: All transactions matched", UVM_LOW)
    end
  endfunction

endclass : hydra_scoreboard

`endif
