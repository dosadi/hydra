`ifndef HYDRA_AXIL_IF_SV
`define HYDRA_AXIL_IF_SV

interface hydra_axil_if(input logic clk, input logic rst_n);

  // AXI-Lite signals
  logic [31:0] awaddr;   // Write address
  logic        awvalid;  // Write address valid
  logic        awready;  // Write address ready

  logic [31:0] wdata;    // Write data
  logic [3:0]  wstrb;    // Write strobe
  logic        wvalid;   // Write valid
  logic        wready;   // Write ready

  logic [1:0]  bresp;    // Write response
  logic        bvalid;   // Write response valid
  logic        bready;   // Write response ready

  logic [31:0] araddr;   // Read address
  logic        arvalid;  // Read address valid
  logic        arready;  // Read address ready

  logic [31:0] rdata;    // Read data
  logic [1:0]  rresp;    // Read response
  logic        rvalid;   // Read valid
  logic        rready;   // Read ready

  // Clocking blocks for driver and monitor
  clocking driver_cb @(posedge clk);
    default input #1ns output #1ns;
    output awaddr, awvalid, wdata, wstrb, wvalid, bready;
    output araddr, arvalid, rready;
    input awready, wready, bresp, bvalid;
    input arready, rdata, rresp, rvalid;
  endclocking

  clocking monitor_cb @(posedge clk);
    default input #1ns;
    input awaddr, awvalid, awready, wdata, wstrb, wvalid, wready;
    input bresp, bvalid, bready;
    input araddr, arvalid, arready, rdata, rresp, rvalid, rready;
  endclocking

  // Modports
  modport driver(clocking driver_cb, input clk, input rst_n);
  modport monitor(clocking monitor_cb, input clk, input rst_n);
  modport dut(
    input clk, input rst_n,
    input awaddr, awvalid, output awready,
    input wdata, wstrb, wvalid, output wready,
    output bresp, bvalid, input bready,
    input araddr, arvalid, output arready,
    output rdata, rresp, rvalid, input rready
  );

  // Assertions for protocol checking
  // Write address handshake
  property write_addr_handshake;
    @(posedge clk) disable iff (!rst_n)
    awvalid && !awready |=> awvalid;
  endproperty

  // Write data handshake
  property write_data_handshake;
    @(posedge clk) disable iff (!rst_n)
    wvalid && !wready |=> wvalid;
  endproperty

  // Write response handshake
  property write_resp_handshake;
    @(posedge clk) disable iff (!rst_n)
    bvalid && !bready |=> bvalid;
  endproperty

  // Read address handshake
  property read_addr_handshake;
    @(posedge clk) disable iff (!rst_n)
    arvalid && !arready |=> arvalid;
  endproperty

  // Read response handshake
  property read_resp_handshake;
    @(posedge clk) disable iff (!rst_n)
    rvalid && !rready |=> rvalid;
  endproperty

  // Assert protocol properties
  assert property (write_addr_handshake) else `uvm_error("AXIL_IF", "Write address handshake violation")
  assert property (write_data_handshake) else `uvm_error("AXIL_IF", "Write data handshake violation")
  assert property (write_resp_handshake) else `uvm_error("AXIL_IF", "Write response handshake violation")
  assert property (read_addr_handshake) else `uvm_error("AXIL_IF", "Read address handshake violation")
  assert property (read_resp_handshake) else `uvm_error("AXIL_IF", "Read response handshake violation")

endinterface : hydra_axil_if

`endif
