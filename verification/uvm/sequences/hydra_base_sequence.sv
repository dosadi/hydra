`ifndef HYDRA_BASE_SEQUENCE_SV
`define HYDRA_BASE_SEQUENCE_SV

class hydra_base_sequence extends uvm_sequence#(hydra_axil_item);
  `uvm_object_utils(hydra_base_sequence)

  function new(string name = "hydra_base_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("BASE_SEQ", "Starting Hydra base sequence", UVM_LOW)

    // Base sequence - override in derived classes
    // This provides common functionality for all Hydra sequences

    `uvm_info("BASE_SEQ", "Hydra base sequence complete", UVM_LOW)
  endtask

  // Utility tasks for common operations
  task axil_write(bit [31:0] addr, bit [31:0] data, int delay = 0);
    hydra_axil_item req;
    req = hydra_axil_item::type_id::create("req");

    start_item(req);
    req.write = 1'b1;
    req.addr = addr;
    req.data = data;
    req.delay = delay;
    finish_item(req);

    `uvm_info("BASE_SEQ", $sformatf("AXI-Lite WRITE: addr=0x%08h data=0x%08h",
              addr, data), UVM_MEDIUM)
  endtask

  task axil_read(bit [31:0] addr, output bit [31:0] data, int delay = 0);
    hydra_axil_item req;
    req = hydra_axil_item::type_id::create("req");

    start_item(req);
    req.write = 1'b0;
    req.addr = addr;
    req.delay = delay;
    finish_item(req);

    data = req.data;  // Response data from driver/monitor

    `uvm_info("BASE_SEQ", $sformatf("AXI-Lite READ: addr=0x%08h data=0x%08h",
              addr, data), UVM_MEDIUM)
  endtask

  task wait_cycles(int cycles);
    repeat (cycles) @(posedge m_sequencer.vif.clk);
  endtask

endclass : hydra_base_sequence

`endif
