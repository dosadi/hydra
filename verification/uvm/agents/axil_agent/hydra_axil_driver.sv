`ifndef HYDRA_AXIL_DRIVER_SV
`define HYDRA_AXIL_DRIVER_SV

class hydra_axil_driver extends uvm_driver#(hydra_axil_item);
  `uvm_component_utils(hydra_axil_driver)

  virtual hydra_axil_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual hydra_axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "AXI-Lite virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    hydra_axil_item req;

    // Wait for reset
    @(negedge vif.rst_n);
    @(posedge vif.rst_n);

    forever begin
      seq_item_port.get_next_item(req);
      drive_transaction(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_transaction(hydra_axil_item req);
    // Apply delay
    repeat(req.delay) @(posedge vif.clk);

    if (req.write) begin
      // Write transaction
      vif.awaddr <= req.addr;
      vif.awvalid <= 1'b1;
      vif.wdata <= req.data;
      vif.wvalid <= 1'b1;
      vif.bready <= 1'b1;

      // Wait for address handshake
      @(posedge vif.clk);
      while (!vif.awready) @(posedge vif.clk);
      vif.awvalid <= 1'b0;

      // Wait for data handshake
      while (!vif.wready) @(posedge vif.clk);
      vif.wvalid <= 1'b0;

      // Wait for response
      while (!vif.bvalid) @(posedge vif.clk);
      vif.bready <= 1'b0;

      `uvm_info("AXIL_DRIVER", $sformatf("WRITE: Addr=0x%08h Data=0x%08h", req.addr, req.data), UVM_MEDIUM)

    end else begin
      // Read transaction
      vif.araddr <= req.addr;
      vif.arvalid <= 1'b1;
      vif.rready <= 1'b1;

      // Wait for address handshake
      @(posedge vif.clk);
      while (!vif.arready) @(posedge vif.clk);
      vif.arvalid <= 1'b0;

      // Wait for data response
      while (!vif.rvalid) @(posedge vif.clk);
      vif.rready <= 1'b0;

      `uvm_info("AXIL_DRIVER", $sformatf("READ: Addr=0x%08h Data=0x%08h", req.addr, vif.rdata), UVM_MEDIUM)
    end
  endtask

endclass : hydra_axil_driver

`endif
