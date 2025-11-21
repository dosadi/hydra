// ============================================================================
// axi_crossbar_stub.sv
// - Simple 2x2 fixed-priority AXI crossbar for simulation/bring-up.
// - Masters: m0 (external), m1 (DMA). Slaves: s0 (voxel window -> BRAM), s1 (SDRAM stub).
// - Decode: low address window to s0, everything else to s1. m1 has priority.
// ============================================================================
`timescale 1ns/1ps

module axi_crossbar_stub #(
    parameter integer ADDR_WIDTH = 28,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter [ADDR_WIDTH-1:0] S0_BASE = 28'h000_0000,
    parameter [ADDR_WIDTH-1:0] S0_MASK = 28'h0FF_F000
)(
    input  wire clk,
    input  wire rst_n,

    // Master 0 (external)
    input  wire [ID_WIDTH-1:0]   m0_awid,
    input  wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire [7:0]            m0_awlen,
    input  wire [2:0]            m0_awsize,
    input  wire [1:0]            m0_awburst,
    input  wire                  m0_awvalid,
    output wire                  m0_awready,
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input  wire                  m0_wlast,
    input  wire                  m0_wvalid,
    output wire                  m0_wready,
    output wire [ID_WIDTH-1:0]   m0_bid,
    output wire [1:0]            m0_bresp,
    output wire                  m0_bvalid,
    input  wire                  m0_bready,
    input  wire [ID_WIDTH-1:0]   m0_arid,
    input  wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]            m0_arlen,
    input  wire [2:0]            m0_arsize,
    input  wire [1:0]            m0_arburst,
    input  wire                  m0_arvalid,
    output wire                  m0_arready,
    output wire [ID_WIDTH-1:0]   m0_rid,
    output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [1:0]            m0_rresp,
    output wire                  m0_rlast,
    output wire                  m0_rvalid,
    input  wire                  m0_rready,

    // Master 1 (DMA)
    input  wire [ID_WIDTH-1:0]   m1_awid,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]            m1_awlen,
    input  wire [2:0]            m1_awsize,
    input  wire [1:0]            m1_awburst,
    input  wire                  m1_awvalid,
    output wire                  m1_awready,
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input  wire                  m1_wlast,
    input  wire                  m1_wvalid,
    output wire                  m1_wready,
    output wire [ID_WIDTH-1:0]   m1_bid,
    output wire [1:0]            m1_bresp,
    output wire                  m1_bvalid,
    input  wire                  m1_bready,
    input  wire [ID_WIDTH-1:0]   m1_arid,
    input  wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]            m1_arlen,
    input  wire [2:0]            m1_arsize,
    input  wire [1:0]            m1_arburst,
    input  wire                  m1_arvalid,
    output wire                  m1_arready,
    output wire [ID_WIDTH-1:0]   m1_rid,
    output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [1:0]            m1_rresp,
    output wire                  m1_rlast,
    output wire                  m1_rvalid,
    input  wire                  m1_rready,

    // Slave 0 (voxel window / BRAM)
    output wire [ID_WIDTH-1:0]   s0_awid,
    output wire [ADDR_WIDTH-1:0] s0_awaddr,
    output wire [7:0]            s0_awlen,
    output wire [2:0]            s0_awsize,
    output wire [1:0]            s0_awburst,
    output wire                  s0_awvalid,
    input  wire                  s0_awready,
    output wire [DATA_WIDTH-1:0] s0_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s0_wstrb,
    output wire                  s0_wlast,
    output wire                  s0_wvalid,
    input  wire                  s0_wready,
    input  wire [ID_WIDTH-1:0]   s0_bid,
    input  wire [1:0]            s0_bresp,
    input  wire                  s0_bvalid,
    output wire                  s0_bready,
    output wire [ID_WIDTH-1:0]   s0_arid,
    output wire [ADDR_WIDTH-1:0] s0_araddr,
    output wire [7:0]            s0_arlen,
    output wire [2:0]            s0_arsize,
    output wire [1:0]            s0_arburst,
    output wire                  s0_arvalid,
    input  wire                  s0_arready,
    input  wire [ID_WIDTH-1:0]   s0_rid,
    input  wire [DATA_WIDTH-1:0] s0_rdata,
    input  wire [1:0]            s0_rresp,
    input  wire                  s0_rlast,
    input  wire                  s0_rvalid,
    output wire                  s0_rready,

    // Slave 1 (SDRAM stub)
    output wire [ID_WIDTH-1:0]   s1_awid,
    output wire [ADDR_WIDTH-1:0] s1_awaddr,
    output wire [7:0]            s1_awlen,
    output wire [2:0]            s1_awsize,
    output wire [1:0]            s1_awburst,
    output wire                  s1_awvalid,
    input  wire                  s1_awready,
    output wire [DATA_WIDTH-1:0] s1_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s1_wstrb,
    output wire                  s1_wlast,
    output wire                  s1_wvalid,
    input  wire                  s1_wready,
    input  wire [ID_WIDTH-1:0]   s1_bid,
    input  wire [1:0]            s1_bresp,
    input  wire                  s1_bvalid,
    output wire                  s1_bready,
    output wire [ID_WIDTH-1:0]   s1_arid,
    output wire [ADDR_WIDTH-1:0] s1_araddr,
    output wire [7:0]            s1_arlen,
    output wire [2:0]            s1_arsize,
    output wire [1:0]            s1_arburst,
    output wire                  s1_arvalid,
    input  wire                  s1_arready,
    input  wire [ID_WIDTH-1:0]   s1_rid,
    input  wire [DATA_WIDTH-1:0] s1_rdata,
    input  wire [1:0]            s1_rresp,
    input  wire                  s1_rlast,
    input  wire                  s1_rvalid,
    output wire                  s1_rready
);

    // Decode helpers
    wire m0_to_s0 = ((m0_awaddr & S0_MASK) == S0_BASE);
    wire m0_ar_s0 = ((m0_araddr & S0_MASK) == S0_BASE);
    wire m1_to_s0 = ((m1_awaddr & S0_MASK) == S0_BASE);
    wire m1_ar_s0 = ((m1_araddr & S0_MASK) == S0_BASE);

    wire grant_m1 = m1_awvalid | m1_wvalid | m1_arvalid; // crude priority
    wire m0_active = ~grant_m1;

    // AW channel
    assign s0_awid    = grant_m1 ? m1_awid   : m0_awid;
    assign s0_awaddr  = grant_m1 ? m1_awaddr : m0_awaddr;
    assign s0_awlen   = grant_m1 ? m1_awlen  : m0_awlen;
    assign s0_awsize  = grant_m1 ? m1_awsize : m0_awsize;
    assign s0_awburst = grant_m1 ? m1_awburst: m0_awburst;
    assign s0_awvalid = grant_m1 ? (m1_awvalid && m1_to_s0) : (m0_awvalid && m0_to_s0);

    assign s1_awid    = grant_m1 ? m1_awid   : m0_awid;
    assign s1_awaddr  = grant_m1 ? m1_awaddr : m0_awaddr;
    assign s1_awlen   = grant_m1 ? m1_awlen  : m0_awlen;
    assign s1_awsize  = grant_m1 ? m1_awsize : m0_awsize;
    assign s1_awburst = grant_m1 ? m1_awburst: m0_awburst;
    assign s1_awvalid = grant_m1 ? (m1_awvalid && !m1_to_s0) : (m0_awvalid && !m0_to_s0);

    assign m0_awready = m0_to_s0 ? s0_awready : s1_awready;
    assign m1_awready = m1_to_s0 ? s0_awready : s1_awready;

    // W channel
    assign s0_wdata   = grant_m1 ? m1_wdata  : m0_wdata;
    assign s0_wstrb   = grant_m1 ? m1_wstrb  : m0_wstrb;
    assign s0_wlast   = grant_m1 ? m1_wlast  : m0_wlast;
    assign s0_wvalid  = grant_m1 ? (m1_wvalid && m1_to_s0) : (m0_wvalid && m0_to_s0);

    assign s1_wdata   = grant_m1 ? m1_wdata  : m0_wdata;
    assign s1_wstrb   = grant_m1 ? m1_wstrb  : m0_wstrb;
    assign s1_wlast   = grant_m1 ? m1_wlast  : m0_wlast;
    assign s1_wvalid  = grant_m1 ? (m1_wvalid && !m1_to_s0) : (m0_wvalid && !m0_to_s0);

    assign m0_wready  = m0_to_s0 ? s0_wready : s1_wready;
    assign m1_wready  = m1_to_s0 ? s0_wready : s1_wready;

    // B channel
    assign m0_bid     = m0_to_s0 ? s0_bid    : s1_bid;
    assign m0_bresp   = m0_to_s0 ? s0_bresp  : s1_bresp;
    assign m0_bvalid  = m0_to_s0 ? s0_bvalid : s1_bvalid;
    assign s0_bready  = m0_to_s0 ? m0_bready : 1'b0;
    assign s1_bready  = m0_to_s0 ? 1'b0      : m0_bready;

    assign m1_bid     = m1_to_s0 ? s0_bid    : s1_bid;
    assign m1_bresp   = m1_to_s0 ? s0_bresp  : s1_bresp;
    assign m1_bvalid  = m1_to_s0 ? s0_bvalid : s1_bvalid;

    // AR channel
    assign s0_arid    = grant_m1 ? m1_arid   : m0_arid;
    assign s0_araddr  = grant_m1 ? m1_araddr : m0_araddr;
    assign s0_arlen   = grant_m1 ? m1_arlen  : m0_arlen;
    assign s0_arsize  = grant_m1 ? m1_arsize : m0_arsize;
    assign s0_arburst = grant_m1 ? m1_arburst: m0_arburst;
    assign s0_arvalid = grant_m1 ? (m1_arvalid && m1_ar_s0) : (m0_arvalid && m0_ar_s0);

    assign s1_arid    = grant_m1 ? m1_arid   : m0_arid;
    assign s1_araddr  = grant_m1 ? m1_araddr : m0_araddr;
    assign s1_arlen   = grant_m1 ? m1_arlen  : m0_arlen;
    assign s1_arsize  = grant_m1 ? m1_arsize : m0_arsize;
    assign s1_arburst = grant_m1 ? m1_arburst: m0_arburst;
    assign s1_arvalid = grant_m1 ? (m1_arvalid && !m1_ar_s0) : (m0_arvalid && !m0_ar_s0);

    assign m0_arready = m0_ar_s0 ? s0_arready : s1_arready;
    assign m1_arready = m1_ar_s0 ? s0_arready : s1_arready;

    // R channel
    assign m0_rid     = m0_ar_s0 ? s0_rid    : s1_rid;
    assign m0_rdata   = m0_ar_s0 ? s0_rdata  : s1_rdata;
    assign m0_rresp   = m0_ar_s0 ? s0_rresp  : s1_rresp;
    assign m0_rlast   = m0_ar_s0 ? s0_rlast  : s1_rlast;
    assign m0_rvalid  = m0_ar_s0 ? s0_rvalid : s1_rvalid;
    assign s0_rready  = m0_ar_s0 ? m0_rready : 1'b0;
    assign s1_rready  = m0_ar_s0 ? 1'b0      : m0_rready;

    assign m1_rid     = m1_ar_s0 ? s0_rid    : s1_rid;
    assign m1_rdata   = m1_ar_s0 ? s0_rdata  : s1_rdata;
    assign m1_rresp   = m1_ar_s0 ? s0_rresp  : s1_rresp;
    assign m1_rlast   = m1_ar_s0 ? s0_rlast  : s1_rlast;
    assign m1_rvalid  = m1_ar_s0 ? s0_rvalid : s1_rvalid;

endmodule
