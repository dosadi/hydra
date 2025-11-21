// ============================================================================
// axi_sdram_stub.sv
// - Minimal AXI4 memory model acting as a stand-in for SDRAM/DDR controllers.
// - Single-clock, synchronous; supports incremental bursts (AWLEN/ARLEN) with
//   fixed DATA_WIDTH and ADDR_WIDTH. No reordering; accepts one transaction at
//   a time on each channel.
// ============================================================================
`timescale 1ns/1ps

module axi_sdram_stub #(
    parameter integer ADDR_WIDTH = 28,  // byte address width
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter integer STRB_WIDTH = DATA_WIDTH/8,
    parameter integer MEM_WORDS  = 1 << 18  // default 256 KiB of DATA_WIDTH words
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Write address channel
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    // Write data channel
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    // Write response
    output reg  [ID_WIDTH-1:0]      s_axi_bid,
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,

    // Read address channel
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire                     s_axi_arvalid,
    output reg                      s_axi_arready,
    // Read data channel
    output reg  [ID_WIDTH-1:0]      s_axi_rid,
    output reg  [DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]               s_axi_rresp,
    output reg                      s_axi_rlast,
    output reg                      s_axi_rvalid,
    input  wire                     s_axi_rready
);

    localparam [1:0] RESP_OKAY = 2'b00;
    localparam [1:0] BURST_INCR = 2'b01;

    (* ram_style = "block", ram_decomp = "power" *)
    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    // Internal state for write bursts
    reg [ID_WIDTH-1:0] w_id;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg [7:0] w_beats;
    reg       w_active;

    // Internal state for read bursts
    reg [ID_WIDTH-1:0] r_id;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [7:0] r_beats;
    reg       r_active;

    integer i;
`ifndef SYNTHESIS
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
        s_axi_awready = 1'b0;
        s_axi_wready  = 1'b0;
        s_axi_bvalid  = 1'b0;
        s_axi_bresp   = RESP_OKAY;
        s_axi_arready = 1'b0;
        s_axi_rvalid  = 1'b0;
        s_axi_rresp   = RESP_OKAY;
        s_axi_rlast   = 1'b0;
        w_active      = 1'b0;
        r_active      = 1'b0;
    end
`endif

    wire [ADDR_WIDTH-1:0] w_addr_next = w_addr + (1 << s_axi_awsize);
    wire [ADDR_WIDTH-1:0] r_addr_next = r_addr + (1 << s_axi_arsize);

    // Write address acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            w_active      <= 1'b0;
        end else begin
            if (!w_active && !s_axi_awready)
                s_axi_awready <= s_axi_awvalid;
            if (s_axi_awready && s_axi_awvalid) begin
                w_id     <= s_axi_awid;
                w_addr   <= s_axi_awaddr;
                w_beats  <= s_axi_awlen;
                w_active <= 1'b1;
                s_axi_awready <= 1'b0;
            end
            if (w_active && w_beats == 0 && s_axi_wvalid && s_axi_wready)
                w_active <= 1'b0;
        end
    end

    // Write data + response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;
            s_axi_bid    <= {ID_WIDTH{1'b0}};
        end else begin
            if (w_active && !s_axi_wready)
                s_axi_wready <= 1'b1;

            if (s_axi_wready && s_axi_wvalid) begin
                // Write with strobes
                for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                    if (s_axi_wstrb[i])
                        mem[w_addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(MEM_WORDS)]][8*i +: 8] <= s_axi_wdata[8*i +: 8];
                end
                if (w_beats != 0)
                    w_beats <= w_beats - 1'b1;
                w_addr <= (s_axi_awburst == BURST_INCR) ? w_addr_next : w_addr;

                if (s_axi_wlast || (w_beats == 0)) begin
                    s_axi_bid    <= w_id;
                    s_axi_bresp  <= RESP_OKAY;
                    s_axi_bvalid <= 1'b1;
                    s_axi_wready <= 1'b0;
                end
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // Read address acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            r_active      <= 1'b0;
        end else begin
            if (!r_active && !s_axi_arready)
                s_axi_arready <= s_axi_arvalid;
            if (s_axi_arready && s_axi_arvalid) begin
                r_id     <= s_axi_arid;
                r_addr   <= s_axi_araddr;
                r_beats  <= s_axi_arlen;
                r_active <= 1'b1;
                s_axi_arready <= 1'b0;
            end
            if (r_active && s_axi_rvalid && s_axi_rready && s_axi_rlast)
                r_active <= 1'b0;
        end
    end

    // Read data channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rlast  <= 1'b0;
            s_axi_rresp  <= RESP_OKAY;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rid    <= {ID_WIDTH{1'b0}};
        end else begin
            if (r_active && (!s_axi_rvalid || (s_axi_rvalid && s_axi_rready))) begin
                s_axi_rid   <= r_id;
                s_axi_rdata <= mem[r_addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(MEM_WORDS)]];
                s_axi_rresp <= RESP_OKAY;
                s_axi_rlast <= (r_beats == 0);
                s_axi_rvalid<= 1'b1;

                if (r_beats != 0)
                    r_beats <= r_beats - 1'b1;
                r_addr <= (s_axi_arburst == BURST_INCR) ? r_addr_next : r_addr;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
