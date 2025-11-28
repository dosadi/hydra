`timescale 1ns/1ps


module axi_sdram_stub (
    input  wire                     clk,
    input  wire                     rst_n,

    // Write address channel
    input  wire [3:0]               s_axi_awid,
    input  wire [27:0]              s_axi_awaddr,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire                     s_axi_awvalid,
    output reg                      s_axi_awready,
    // Write data channel
    input  wire [63:0]              s_axi_wdata,
    input  wire [7:0]               s_axi_wstrb,
    input  wire                     s_axi_wlast,
    input  wire                     s_axi_wvalid,
    output reg                      s_axi_wready,
    // Write response
    output reg  [3:0]               s_axi_bid,
    output reg  [1:0]               s_axi_bresp,
    output reg                      s_axi_bvalid,
    input  wire                     s_axi_bready,

    // Debug port
    input  wire                     dbg_we,
    input  wire [27:0]              dbg_addr,
    input  wire [63:0]              dbg_wdata,
    input  wire                     dbg_re,
    output reg  [63:0]              dbg_rdata
);

    localparam MEM_WORDS = 1024;
    reg [63:0] mem [0:MEM_WORDS-1];
    reg bvalid_pending;
    reg active_aw;
    reg [27:0] cur_awaddr;
    reg [7:0]  cur_awlen;
    reg [2:0]  cur_awsize;
    reg [1:0]  cur_awburst;
    reg [7:0]  beat_count;
    // AXI response pending flag

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

    // AW acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 0;
            active_aw <= 0;
        end else begin
            if (!active_aw && !s_axi_bvalid && s_axi_awvalid) begin
                s_axi_awready <= 1;
                cur_awaddr  <= s_axi_awaddr;
                cur_awlen   <= s_axi_awlen;
                cur_awsize  <= s_axi_awsize;
                cur_awburst <= s_axi_awburst;
                active_aw   <= 1;
                beat_count  <= 0;
            end else begin
                s_axi_awready <= 0;
            end
        end
    end

    // Write data handling and response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 0;
            bvalid_pending <= 0;
            beat_count <= 0;
        end else begin
            if (dbg_we) begin
                mem[(dbg_addr >> 3) % MEM_WORDS] <= dbg_wdata;
            end
            if (active_aw && !s_axi_bvalid) begin
                s_axi_wready <= 1;
                if (s_axi_wvalid && s_axi_wready) begin
                    mem[(cur_awaddr >> 3) % MEM_WORDS] <= s_axi_wdata;
                    cur_awaddr <= next_addr(cur_awaddr, cur_awburst, cur_awlen + 1'b1, cur_awsize);
                    // Assert bvalid_pending when last beat is accepted
                    if ((beat_count == cur_awlen) && s_axi_wlast) begin
                        bvalid_pending <= 1;
                        s_axi_bid <= 4'd0;
                        active_aw <= 0;
                    end
                    beat_count <= beat_count + 1'b1;
                end
            end else begin
                s_axi_wready <= 0;
            end
        end
    end


    // Response channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 0;
            beat_count <= 0;
        end else begin
            if (bvalid_pending) begin
                s_axi_bvalid <= 1;
                bvalid_pending <= 0;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
                beat_count <= 0;
            end
        end
    end

    // next address helper (supports INCR and WRAP)
    function automatic [27:0] next_addr;
        input [27:0] addr;
        input [1:0] burst;
        input [7:0] total_beats;
        input [2:0] size;
        reg [27:0] beat_bytes;
        reg [27:0] wrap_size;
        reg [27:0] base;
        reg [27:0] offset;
    begin
        beat_bytes = (1 << size);
        if (burst == 2'b01) begin // INCR
            next_addr = addr + beat_bytes;
        end else if (burst == 2'b10) begin // WRAP
            wrap_size = beat_bytes * total_beats;
            base = addr - (addr % wrap_size);
            offset = (addr - base + beat_bytes) % wrap_size;
            next_addr = base + offset;
        end else begin
            next_addr = addr + beat_bytes;
        end
    end
    endfunction

    // Debug read
    always @(posedge clk) begin
        if (dbg_re) begin
            dbg_rdata <= mem[(dbg_addr >> 3) % MEM_WORDS];
        end
    end

endmodule
