`timescale 1ns/1ps

// Minimal Verilator-friendly AXI SDRAM stub (clean file).
module axi_sdram_stub(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [3:0]   s_axi_awid,
    input  wire [27:0]  s_axi_awaddr,
    input  wire [7:0]   s_axi_awlen,
    input  wire [2:0]   s_axi_awsize,
    input  wire [1:0]   s_axi_awburst,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    input  wire [63:0]  s_axi_wdata,
    input  wire [7:0]   s_axi_wstrb,
    input  wire         s_axi_wlast,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    output reg [3:0]    s_axi_bid,
    output reg [1:0]    s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    input  wire         dbg_we,
    input  wire [27:0]  dbg_addr,
    input  wire [63:0]  dbg_wdata,
    input  wire         dbg_re,
    output reg [63:0]   dbg_rdata
);

    localparam MEM_WORDS = 1024;
    reg [63:0] mem [0:MEM_WORDS-1];

    reg active_aw;
    reg [27:0] cur_awaddr;
    reg [7:0]  cur_awlen;
    reg [2:0]  cur_awsize;
    reg [1:0]  cur_awburst;
    reg [7:0]  beat_count;

    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) mem[i] = 64'h0;
        s_axi_awready = 0;
        s_axi_wready  = 0;
        s_axi_bvalid  = 0;
        s_axi_bresp   = 2'b00;
        s_axi_bid     = 4'd0;
        active_aw     = 0;
        beat_count    = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 0;
            active_aw <= 0;
        end else begin
            if (!active_aw && s_axi_awvalid) begin
                s_axi_awready <= 1;
                cur_awaddr <= s_axi_awaddr;
                cur_awlen  <= s_axi_awlen;
                cur_awsize <= s_axi_awsize;
                cur_awburst<= s_axi_awburst;
                active_aw  <= 1;
                beat_count <= 0;
            end else begin
                s_axi_awready <= 0;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 0;
            s_axi_bvalid <= 0;
        end else begin
            if (dbg_we) mem[(dbg_addr >> 3) % MEM_WORDS] <= dbg_wdata;
            if (active_aw && !s_axi_bvalid) begin
                s_axi_wready <= 1;
                if (s_axi_wvalid && s_axi_wready) begin
                    mem[(cur_awaddr >> 3) % MEM_WORDS] <= s_axi_wdata;
                    cur_awaddr <= cur_awaddr + (1 << cur_awsize);
                    if (s_axi_wlast || beat_count == cur_awlen) begin
                        s_axi_bvalid <= 1;
                        s_axi_bid <= 4'd0;
                        active_aw <= 0;
                    end else begin
                        beat_count <= beat_count + 1;
                    end
                end
            end else begin
                s_axi_wready <= 0;
                if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (dbg_re) dbg_rdata <= mem[(dbg_addr >> 3) % MEM_WORDS];
    end

endmodule
