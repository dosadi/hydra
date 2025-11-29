`ifndef HYDRA_AXIL_MONITOR_SV
`define HYDRA_AXIL_MONITOR_SV

class hydra_axil_monitor extends uvm_monitor;
  `uvm_component_utils(hydra_axil_monitor)

  virtual hydra_axil_if vif;
  uvm_analysis_port#(hydra_axil_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual hydra_axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "AXI-Lite virtual interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    hydra_axil_item item;

    // Wait for reset
    @(negedge vif.rst_n);
    @(posedge vif.rst_n);

    forever begin
      // Monitor write transactions
      fork
        monitor_writes();
        monitor_reads();
      join_any
      disable fork;
    end
  endtask

  task monitor_writes();
    hydra_axil_item item;
    forever begin
      // Wait for write address valid
      @(posedge vif.clk);
      if (vif.awvalid && vif.awready) begin
        item = hydra_axil_item::type_id::create("item");

        item.addr = vif.awaddr;
        item.write = 1'b1;

        // Wait for write data
        @(posedge vif.clk);
        if (vif.wvalid && vif.wready) begin
          item.data = vif.wdata;
          item.delay = 0; // Not applicable for monitoring

          // Wait for response
          while (!(vif.bvalid && vif.bready)) @(posedge vif.clk);

          ap.write(item);
          `uvm_info("AXIL_MONITOR", $sformatf("Captured WRITE: Addr=0x%08h Data=0x%08h", item.addr, item.data), UVM_MEDIUM)
        end
      end
    end
  endtask

  task monitor_reads();
    hydra_axil_item item;
    forever begin
      // Wait for read address valid
      @(posedge vif.clk);
      if (vif.arvalid && vif.arready) begin
        item = hydra_axil_item::type_id::create("item");

        item.addr = vif.araddr;
        item.write = 1'b0;

        // Wait for read data
        while (!(vif.rvalid && vif.rready)) @(posedge vif.clk);

        item.data = vif.rdata;
        item.delay = 0; // Not applicable for monitoring

        ap.write(item);
        `uvm_info("AXIL_MONITOR", $sformatf("Captured READ: Addr=0x%08h Data=0x%08h", item.addr, item.data), UVM_MEDIUM)
      end
    end
  endtask

endclass : hydra_axil_monitor

`endif