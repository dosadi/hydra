// ============================================================================
// axi_crossbar_stub.sv
// - 2x2 AXI crossbar stub for simulation/bring-up (external + DMA masters to
//   voxel-window BRAM (s0) and SDRAM stub (s1)).
// - Single outstanding write and read transaction at a time (per channel);
//   round-robin arbitration between masters.
// - Write path: AW arbitrates, then locks W/B to that master until WLAST.
// - Read path: AR arbitrates, then locks R to that master until RLAST.
// - Decode: address mask/base selects s0; otherwise s1.
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
    output reg                   m0_awready,
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input  wire                  m0_wlast,
    input  wire                  m0_wvalid,
    output reg                   m0_wready,
    output reg [ID_WIDTH-1:0]    m0_bid,
    output reg [1:0]             m0_bresp,
    output reg                   m0_bvalid,
    input  wire                  m0_bready,
    input  wire [ID_WIDTH-1:0]   m0_arid,
    input  wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]            m0_arlen,
    input  wire [2:0]            m0_arsize,
    input  wire [1:0]            m0_arburst,
    input  wire                  m0_arvalid,
    output reg                   m0_arready,
    output reg [ID_WIDTH-1:0]    m0_rid,
    output reg [DATA_WIDTH-1:0]  m0_rdata,
    output reg [1:0]             m0_rresp,
    output reg                   m0_rlast,
    output reg                   m0_rvalid,
    input  wire                  m0_rready,

    // Master 1 (DMA)
    input  wire [ID_WIDTH-1:0]   m1_awid,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]            m1_awlen,
    input  wire [2:0]            m1_awsize,
    input  wire [1:0]            m1_awburst,
    input  wire                  m1_awvalid,
    output reg                   m1_awready,
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input  wire                  m1_wlast,
    input  wire                  m1_wvalid,
    output reg                   m1_wready,
    output reg [ID_WIDTH-1:0]    m1_bid,
    output reg [1:0]             m1_bresp,
    output reg                   m1_bvalid,
    input  wire                  m1_bready,
    input  wire [ID_WIDTH-1:0]   m1_arid,
    input  wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]            m1_arlen,
    input  wire [2:0]            m1_arsize,
    input  wire [1:0]            m1_arburst,
    input  wire                  m1_arvalid,
    output reg                   m1_arready,
    output reg [ID_WIDTH-1:0]    m1_rid,
    output reg [DATA_WIDTH-1:0]  m1_rdata,
    output reg [1:0]             m1_rresp,
    output reg                   m1_rlast,
    output reg                   m1_rvalid,
    input  wire                  m1_rready,

    // Slave 0 (voxel BRAM window)
    output reg  [ID_WIDTH-1:0]   s0_awid,
    output reg  [ADDR_WIDTH-1:0] s0_awaddr,
    output reg  [7:0]            s0_awlen,
    output reg  [2:0]            s0_awsize,
    output reg  [1:0]            s0_awburst,
    output reg                   s0_awvalid,
    input  wire                  s0_awready,
    output reg  [DATA_WIDTH-1:0] s0_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] s0_wstrb,
    output reg                   s0_wlast,
    output reg                   s0_wvalid,
    input  wire                  s0_wready,
    input  wire [ID_WIDTH-1:0]   s0_bid,
    input  wire [1:0]            s0_bresp,
    input  wire                  s0_bvalid,
    output reg                   s0_bready,
    output reg  [ID_WIDTH-1:0]   s0_arid,
    output reg  [ADDR_WIDTH-1:0] s0_araddr,
    output reg  [7:0]            s0_arlen,
    output reg  [2:0]            s0_arsize,
    output reg  [1:0]            s0_arburst,
    output reg                   s0_arvalid,
    input  wire                  s0_arready,
    input  wire [ID_WIDTH-1:0]   s0_rid,
    input  wire [DATA_WIDTH-1:0] s0_rdata,
    input  wire [1:0]            s0_rresp,
    input  wire                  s0_rlast,
    input  wire                  s0_rvalid,
    output reg                   s0_rready,

    // Slave 1 (SDRAM stub)
    output reg  [ID_WIDTH-1:0]   s1_awid,
    output reg  [ADDR_WIDTH-1:0] s1_awaddr,
    output reg  [7:0]            s1_awlen,
    output reg  [2:0]            s1_awsize,
    output reg  [1:0]            s1_awburst,
    output reg                   s1_awvalid,
    input  wire                  s1_awready,
    output reg  [DATA_WIDTH-1:0] s1_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] s1_wstrb,
    output reg                   s1_wlast,
    output reg                   s1_wvalid,
    input  wire                  s1_wready,
    input  wire [ID_WIDTH-1:0]   s1_bid,
    input  wire [1:0]            s1_bresp,
    input  wire                  s1_bvalid,
    output reg                   s1_bready,
    output reg  [ID_WIDTH-1:0]   s1_arid,
    output reg  [ADDR_WIDTH-1:0] s1_araddr,
    output reg  [7:0]            s1_arlen,
    output reg  [2:0]            s1_arsize,
    output reg  [1:0]            s1_arburst,
    output reg                   s1_arvalid,
    input  wire                  s1_arready,
    input  wire [ID_WIDTH-1:0]   s1_rid,
    input  wire [DATA_WIDTH-1:0] s1_rdata,
    input  wire [1:0]            s1_rresp,
    input  wire                  s1_rlast,
    input  wire                  s1_rvalid,
    output reg                   s1_rready
);

    wire m0_aw_s0 = ((m0_awaddr & S0_MASK) == S0_BASE);
    wire m0_ar_s0 = ((m0_araddr & S0_MASK) == S0_BASE);
    wire m1_aw_s0 = ((m1_awaddr & S0_MASK) == S0_BASE);
    wire m1_ar_s0 = ((m1_araddr & S0_MASK) == S0_BASE);

    // Write channel arbitration/state
    reg w_owner; // 0=m0,1=m1
    reg w_owner_valid;
    reg w_owner_s0;
    reg last_aw_grant;

    // Read channel arbitration/state
    reg r_owner;
    reg r_owner_valid;
    reg r_owner_s0;
    reg last_ar_grant;

    // ---------------- Write address arbitration ----------------
    always @(*) begin
        s0_awvalid = 1'b0;
        s1_awvalid = 1'b0;
        s0_awid    = {ID_WIDTH{1'b0}};
        s1_awid    = {ID_WIDTH{1'b0}};
        s0_awaddr  = {ADDR_WIDTH{1'b0}};
        s1_awaddr  = {ADDR_WIDTH{1'b0}};
        s0_awlen   = 8'd0; s1_awlen = 8'd0;
        s0_awsize  = 3'd0; s1_awsize = 3'd0;
        s0_awburst = 2'd0; s1_awburst= 2'd0;

        m0_awready = 1'b0;
        m1_awready = 1'b0;

        if (!w_owner_valid) begin
            // choose among valid masters (RR)
            if (m0_awvalid && m1_awvalid) begin
                if (last_aw_grant == 1'b0) begin
                    // grant m1
                    if (m1_aw_s0) begin
                        s0_awvalid = 1'b1; s0_awid = m1_awid; s0_awaddr = m1_awaddr; s0_awlen = m1_awlen; s0_awsize = m1_awsize; s0_awburst = m1_awburst;
                        m1_awready = s0_awready;
                    end else begin
                        s1_awvalid = 1'b1; s1_awid = m1_awid; s1_awaddr = m1_awaddr; s1_awlen = m1_awlen; s1_awsize = m1_awsize; s1_awburst = m1_awburst;
                        m1_awready = s1_awready;
                    end
                end else begin
                    // grant m0
                    if (m0_aw_s0) begin
                        s0_awvalid = 1'b1; s0_awid = m0_awid; s0_awaddr = m0_awaddr; s0_awlen = m0_awlen; s0_awsize = m0_awsize; s0_awburst = m0_awburst;
                        m0_awready = s0_awready;
                    end else begin
                        s1_awvalid = 1'b1; s1_awid = m0_awid; s1_awaddr = m0_awaddr; s1_awlen = m0_awlen; s1_awsize = m0_awsize; s1_awburst = m0_awburst;
                        m0_awready = s1_awready;
                    end
                end
            end else if (m1_awvalid) begin
                if (m1_aw_s0) begin
                    s0_awvalid = 1'b1; s0_awid = m1_awid; s0_awaddr = m1_awaddr; s0_awlen = m1_awlen; s0_awsize = m1_awsize; s0_awburst = m1_awburst;
                    m1_awready = s0_awready;
                end else begin
                    s1_awvalid = 1'b1; s1_awid = m1_awid; s1_awaddr = m1_awaddr; s1_awlen = m1_awlen; s1_awsize = m1_awsize; s1_awburst = m1_awburst;
                    m1_awready = s1_awready;
                end
            end else if (m0_awvalid) begin
                if (m0_aw_s0) begin
                    s0_awvalid = 1'b1; s0_awid = m0_awid; s0_awaddr = m0_awaddr; s0_awlen = m0_awlen; s0_awsize = m0_awsize; s0_awburst = m0_awburst;
                    m0_awready = s0_awready;
                end else begin
                    s1_awvalid = 1'b1; s1_awid = m0_awid; s1_awaddr = m0_awaddr; s1_awlen = m0_awlen; s1_awsize = m0_awsize; s1_awburst = m0_awburst;
                    m0_awready = s1_awready;
                end
            end
        end
    end

    // Lock write ownership
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_owner_valid <= 1'b0;
            w_owner       <= 1'b0;
            w_owner_s0    <= 1'b0;
            last_aw_grant <= 1'b0;
        end else begin
            if (!w_owner_valid) begin
                // capture AW handshake
                if (m0_awready && m0_awvalid) begin
                    w_owner_valid <= 1'b1;
                    w_owner       <= 1'b0;
                    w_owner_s0    <= m0_aw_s0;
                    last_aw_grant <= 1'b0;
                end else if (m1_awready && m1_awvalid) begin
                    w_owner_valid <= 1'b1;
                    w_owner       <= 1'b1;
                    w_owner_s0    <= m1_aw_s0;
                    last_aw_grant <= 1'b1;
                end
            end else begin
                // release on wlast handshake
                if (w_owner_s0 ? (s0_wvalid && s0_wready && s0_wlast) :
                                 (s1_wvalid && s1_wready && s1_wlast))
                    w_owner_valid <= 1'b0;
            end
        end
    end

    // W channel routing
    always @(*) begin
        s0_wvalid = 1'b0; s1_wvalid = 1'b0;
        s0_wdata  = {DATA_WIDTH{1'b0}}; s1_wdata = {DATA_WIDTH{1'b0}};
        s0_wstrb  = {DATA_WIDTH/8{1'b0}}; s1_wstrb = {DATA_WIDTH/8{1'b0}};
        s0_wlast  = 1'b0; s1_wlast = 1'b0;
        m0_wready = 1'b0; m1_wready = 1'b0;

        if (w_owner_valid) begin
            if (w_owner == 1'b0) begin
                if (w_owner_s0) begin
                    s0_wvalid = m0_wvalid;
                    s0_wdata  = m0_wdata;
                    s0_wstrb  = m0_wstrb;
                    s0_wlast  = m0_wlast;
                    m0_wready = s0_wready;
                end else begin
                    s1_wvalid = m0_wvalid;
                    s1_wdata  = m0_wdata;
                    s1_wstrb  = m0_wstrb;
                    s1_wlast  = m0_wlast;
                    m0_wready = s1_wready;
                end
            end else begin
                if (w_owner_s0) begin
                    s0_wvalid = m1_wvalid;
                    s0_wdata  = m1_wdata;
                    s0_wstrb  = m1_wstrb;
                    s0_wlast  = m1_wlast;
                    m1_wready = s0_wready;
                end else begin
                    s1_wvalid = m1_wvalid;
                    s1_wdata  = m1_wdata;
                    s1_wstrb  = m1_wstrb;
                    s1_wlast  = m1_wlast;
                    m1_wready = s1_wready;
                end
            end
        end
    end

    // B channel routing
    always @(*) begin
        m0_bvalid = 1'b0; m1_bvalid = 1'b0;
        m0_bresp  = 2'b00; m1_bresp = 2'b00;
        m0_bid    = {ID_WIDTH{1'b0}}; m1_bid = {ID_WIDTH{1'b0}};
        s0_bready = 1'b0; s1_bready = 1'b0;
        if (w_owner_valid) begin
            if (w_owner == 1'b0) begin
                if (w_owner_s0) begin
                    m0_bvalid = s0_bvalid; m0_bresp = s0_bresp; m0_bid = s0_bid;
                    s0_bready = m0_bready;
                end else begin
                    m0_bvalid = s1_bvalid; m0_bresp = s1_bresp; m0_bid = s1_bid;
                    s1_bready = m0_bready;
                end
            end else begin
                if (w_owner_s0) begin
                    m1_bvalid = s0_bvalid; m1_bresp = s0_bresp; m1_bid = s0_bid;
                    s0_bready = m1_bready;
                end else begin
                    m1_bvalid = s1_bvalid; m1_bresp = s1_bresp; m1_bid = s1_bid;
                    s1_bready = m1_bready;
                end
            end
        end
    end

    // ---------------- Read address arbitration ----------------
    always @(*) begin
        s0_arvalid = 1'b0;
        s1_arvalid = 1'b0;
        s0_arid    = {ID_WIDTH{1'b0}};
        s1_arid    = {ID_WIDTH{1'b0}};
        s0_araddr  = {ADDR_WIDTH{1'b0}};
        s1_araddr  = {ADDR_WIDTH{1'b0}};
        s0_arlen   = 8'd0; s1_arlen = 8'd0;
        s0_arsize  = 3'd0; s1_arsize = 3'd0;
        s0_arburst = 2'd0; s1_arburst= 2'd0;
        m0_arready = 1'b0; m1_arready = 1'b0;

        if (!r_owner_valid) begin
            if (m0_arvalid && m1_arvalid) begin
                if (last_ar_grant == 1'b0) begin
                    // grant m1
                    if (m1_ar_s0) begin
                        s0_arvalid = 1'b1; s0_arid = m1_arid; s0_araddr = m1_araddr; s0_arlen = m1_arlen; s0_arsize = m1_arsize; s0_arburst = m1_arburst;
                        m1_arready = s0_arready;
                    end else begin
                        s1_arvalid = 1'b1; s1_arid = m1_arid; s1_araddr = m1_araddr; s1_arlen = m1_arlen; s1_arsize = m1_arsize; s1_arburst = m1_arburst;
                        m1_arready = s1_arready;
                    end
                end else begin
                    // grant m0
                    if (m0_ar_s0) begin
                        s0_arvalid = 1'b1; s0_arid = m0_arid; s0_araddr = m0_araddr; s0_arlen = m0_arlen; s0_arsize = m0_arsize; s0_arburst = m0_arburst;
                        m0_arready = s0_arready;
                    end else begin
                        s1_arvalid = 1'b1; s1_arid = m0_arid; s1_araddr = m0_araddr; s1_arlen = m0_arlen; s1_arsize = m0_arsize; s1_arburst = m0_arburst;
                        m0_arready = s1_arready;
                    end
                end
            end else if (m1_arvalid) begin
                if (m1_ar_s0) begin
                    s0_arvalid = 1'b1; s0_arid = m1_arid; s0_araddr = m1_araddr; s0_arlen = m1_arlen; s0_arsize = m1_arsize; s0_arburst = m1_arburst;
                    m1_arready = s0_arready;
                end else begin
                    s1_arvalid = 1'b1; s1_arid = m1_arid; s1_araddr = m1_araddr; s1_arlen = m1_arlen; s1_arsize = m1_arsize; s1_arburst = m1_arburst;
                    m1_arready = s1_arready;
                end
            end else if (m0_arvalid) begin
                if (m0_ar_s0) begin
                    s0_arvalid = 1'b1; s0_arid = m0_arid; s0_araddr = m0_araddr; s0_arlen = m0_arlen; s0_arsize = m0_arsize; s0_arburst = m0_arburst;
                    m0_arready = s0_arready;
                end else begin
                    s1_arvalid = 1'b1; s1_arid = m0_arid; s1_araddr = m0_araddr; s1_arlen = m0_arlen; s1_arsize = m0_arsize; s1_arburst = m0_arburst;
                    m0_arready = s1_arready;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_owner_valid <= 1'b0;
            r_owner       <= 1'b0;
            r_owner_s0    <= 1'b0;
            last_ar_grant <= 1'b0;
        end else begin
            if (!r_owner_valid) begin
                if (m0_arready && m0_arvalid) begin
                    r_owner_valid <= 1'b1;
                    r_owner       <= 1'b0;
                    r_owner_s0    <= m0_ar_s0;
                    last_ar_grant <= 1'b0;
                end else if (m1_arready && m1_arvalid) begin
                    r_owner_valid <= 1'b1;
                    r_owner       <= 1'b1;
                    r_owner_s0    <= m1_ar_s0;
                    last_ar_grant <= 1'b1;
                end
            end else begin
                if (r_owner_s0 ? (s0_rvalid && s0_rready && s0_rlast) :
                                 (s1_rvalid && s1_rready && s1_rlast))
                    r_owner_valid <= 1'b0;
            end
        end
    end

    // R channel routing
    always @(*) begin
        m0_rvalid = 1'b0; m1_rvalid = 1'b0;
        m0_rdata  = {DATA_WIDTH{1'b0}}; m1_rdata = {DATA_WIDTH{1'b0}};
        m0_rresp  = 2'b00; m1_rresp = 2'b00;
        m0_rid    = {ID_WIDTH{1'b0}}; m1_rid = {ID_WIDTH{1'b0}};
        m0_rlast  = 1'b0; m1_rlast = 1'b0;
        s0_rready = 1'b0; s1_rready = 1'b0;

        if (r_owner_valid) begin
            if (r_owner == 1'b0) begin
                if (r_owner_s0) begin
                    m0_rvalid = s0_rvalid; m0_rdata = s0_rdata; m0_rresp = s0_rresp; m0_rid = s0_rid; m0_rlast = s0_rlast;
                    s0_rready = m0_rready;
                end else begin
                    m0_rvalid = s1_rvalid; m0_rdata = s1_rdata; m0_rresp = s1_rresp; m0_rid = s1_rid; m0_rlast = s1_rlast;
                    s1_rready = m0_rready;
                end
            end else begin
                if (r_owner_s0) begin
                    m1_rvalid = s0_rvalid; m1_rdata = s0_rdata; m1_rresp = s0_rresp; m1_rid = s0_rid; m1_rlast = s0_rlast;
                    s0_rready = m1_rready;
                end else begin
                    m1_rvalid = s1_rvalid; m1_rdata = s1_rdata; m1_rresp = s1_rresp; m1_rid = s1_rid; m1_rlast = s1_rlast;
                    s1_rready = m1_rready;
                end
            end
        end
    end

endmodule
