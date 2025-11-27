// ============================================================================
// axi_sdram_stub.sv
// Minimal AXI4 memory model acting as a stand-in for SDRAM/DDR controllers.
// Single-clock, synchronous; supports incremental bursts (AWLEN/ARLEN) with fixed DATA_WIDTH and ADDR_WIDTH.
// No reordering; accepts one transaction at a time on each channel.
// NOTE: This is a stub for simulation and integration. For full SDRAM/DDR support, extend with timing, refresh, and error handling.
// TODO: Add support for advanced AXI features, timing closure, and real memory backends.
`timescale 1ns/1ps

module axi_sdram_stub #(
    parameter integer ADDR_WIDTH = 28,  // byte address width
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4,
    parameter integer STRB_WIDTH = DATA_WIDTH/8,
    parameter integer MEM_WORDS  = 1 << 18, // default 256 KiB of DATA_WIDTH words
    parameter integer READ_LATENCY   = 0,   // fixed cycles after AR handshake before first RVALID
    parameter integer WRITE_LATENCY  = 0,   // fixed cycles after AW handshake before WREADY
    parameter integer MAX_OUTSTANDING = 2,  // outstanding transactions per channel (simple queue)
    parameter integer WAIT_JITTER    = 0,   // 0=no jitter, N=max extra cycles of random stall
    parameter         POISON_ON_UNINIT = 0   // return X when reading unwritten words
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
    input  wire                     s_axi_rready,

    // Optional debug port for single-beat read/write (synchronous)
    input  wire                     dbg_we,
    input  wire [ADDR_WIDTH-1:0]    dbg_addr,
    input  wire [DATA_WIDTH-1:0]    dbg_wdata,
    input  wire                     dbg_re,
    output reg  [DATA_WIDTH-1:0]    dbg_rdata
);

    localparam [1:0] RESP_OKAY = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] BURST_INCR = 2'b01;
    localparam integer MEM_WORD_ADDR_BITS = $clog2(MEM_WORDS);

    (* ram_style = "block", ram_decomp = "power" *)
    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];
    reg                 mem_valid [0:MEM_WORDS-1];

    // Simple FIFOs for outstanding transactions (depth = MAX_OUTSTANDING)
    reg [ID_WIDTH-1:0]    w_id_q     [0:MAX_OUTSTANDING-1];
    reg [ADDR_WIDTH-1:0]  w_addr_q   [0:MAX_OUTSTANDING-1];
    reg [7:0]             w_beats_q  [0:MAX_OUTSTANDING-1];
    reg [7:0]             w_delay_q  [0:MAX_OUTSTANDING-1];
    reg [2:0]             w_size_q   [0:MAX_OUTSTANDING-1];
    reg [1:0]             w_burst_q  [0:MAX_OUTSTANDING-1];
    reg                   w_err_q    [0:MAX_OUTSTANDING-1];
    reg                   w_valid_q  [0:MAX_OUTSTANDING-1];
    reg [ID_WIDTH-1:0]    r_id_q     [0:MAX_OUTSTANDING-1];
    reg [ADDR_WIDTH-1:0]  r_addr_q   [0:MAX_OUTSTANDING-1];
    reg [7:0]             r_beats_q  [0:MAX_OUTSTANDING-1];
    reg [7:0]             r_delay_q  [0:MAX_OUTSTANDING-1];
    reg [2:0]             r_size_q   [0:MAX_OUTSTANDING-1];
    reg [1:0]             r_burst_q  [0:MAX_OUTSTANDING-1];
    reg                   r_err_q    [0:MAX_OUTSTANDING-1];
    reg                   r_valid_q  [0:MAX_OUTSTANDING-1];
    integer w_head, w_tail, r_head, r_tail;

    // Active burst trackers
    reg [ID_WIDTH-1:0] w_id;
    reg [ADDR_WIDTH-1:0] w_addr;
    reg [7:0] w_beats;
    reg       w_active;
    reg [7:0] w_delay;
    reg [2:0] w_size;
    reg [1:0] w_burst;
    reg       w_err;

    reg [ID_WIDTH-1:0] r_id;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [7:0] r_beats;
    reg       r_active;
    reg [7:0] r_delay;
    reg [2:0] r_size;
    reg [1:0] r_burst;
    reg       r_err;

    // Simple pseudo-random jitter (linear feedback shift register)
    reg [7:0] lfsr;

    integer i;

    // ------------------------------------------------------------------------
    // AXI Protocol SVAs and Coverage
    // ------------------------------------------------------------------------
    // Outstanding transaction counters
    wire [31:0] aw_outstanding = (w_tail >= w_head) ? (w_tail - w_head) : (MAX_OUTSTANDING + w_tail - w_head);
    wire [31:0] ar_outstanding = (r_tail >= r_head) ? (r_tail - r_head) : (MAX_OUTSTANDING + r_tail - r_head);
    wire aw_active = w_active;
    wire ar_active = r_active;

    // SVA: AWREADY only high when not exceeding MAX_OUTSTANDING
    property awready_limit;
        @(posedge clk) disable iff (!rst_n)
        s_axi_awready |-> (aw_outstanding < MAX_OUTSTANDING);
    endproperty
    awready_limit_sva: assert property (awready_limit);

    // SVA: WREADY only high when a valid AW transaction is active
    property wready_awactive;
        @(posedge clk) disable iff (!rst_n)
        s_axi_wready |-> aw_active;
    endproperty
    wready_awactive_sva: assert property (wready_awactive);

    // SVA: ARREADY only high when not exceeding MAX_OUTSTANDING
    property arready_limit;
        @(posedge clk) disable iff (!rst_n)
        s_axi_arready |-> (ar_outstanding < MAX_OUTSTANDING);
    endproperty
    arready_limit_sva: assert property (arready_limit);

    // SVA: RVALID only high when a read transaction is active
    property rvalid_aractive;
        @(posedge clk) disable iff (!rst_n)
        s_axi_rvalid |-> ar_active;
    endproperty
    rvalid_aractive_sva: assert property (rvalid_aractive);

    // Covergroup: Burst lengths and wait states
    covergroup cg_axi_burst @(posedge clk);
        burst_len: coverpoint s_axi_awlen {
            bins short[] = {[0:3]};
            bins medium[] = {[4:15]};
            bins long[] = {[16:255]};
        }
        wait_jitter: coverpoint WAIT_JITTER {
            bins none = {0};
            bins low = {[1:2]};
            bins high = {[3:8]};
        }
    endgroup
    cg_axi_burst_inst = new();

    // Covergroup: Backpressure events (AWREADY/WREADY/ARREADY/RREADY stalls)
    covergroup cg_axi_backpressure @(posedge clk);
        aw_stall: coverpoint !s_axi_awready;
        w_stall:  coverpoint !s_axi_wready;
        ar_stall: coverpoint !s_axi_arready;
        r_stall:  coverpoint !s_axi_rready;
    endgroup
    cg_axi_backpressure_inst = new();

`ifndef SYNTHESIS
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem_valid[i] = 1'b0;
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
            w_delay       = 8'd0;
            r_delay       = 8'd0;
        w_size        = 3'd0;
        w_burst       = BURST_INCR;
        r_size        = 3'd0;
        r_burst       = BURST_INCR;
        w_head        = 0;
        w_tail        = 0;
        r_head        = 0;
        r_tail        = 0;
        lfsr          = 8'hA5;
        for (i = 0; i < MAX_OUTSTANDING; i = i + 1) begin
            w_valid_q[i] = 1'b0;
            r_valid_q[i] = 1'b0;
        end
    end
`endif

    wire [ADDR_WIDTH-1:0] w_addr_next = w_addr + (1 << w_size);
    wire [ADDR_WIDTH-1:0] r_addr_next = r_addr + (1 << r_size);
    localparam integer MEM_ADDR_SHIFT = 3;
    wire [7:0] jitter = (WAIT_JITTER == 0) ? 8'd0 : (lfsr & {8{(WAIT_JITTER!=0)}}) % (WAIT_JITTER+1);

    // Write address acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            w_head        <= 0;
            w_tail        <= 0;
            for (i = 0; i < MAX_OUTSTANDING; i = i + 1)
                w_valid_q[i] <= 1'b0;
        end else begin
            if (!w_active && !s_axi_awready && ((w_tail + 1) % MAX_OUTSTANDING != w_head)) begin
                if (s_axi_awvalid === 1'b1)
                    s_axi_awready <= 1'b1;
            end
            if (s_axi_awready && s_axi_awvalid) begin
                w_id_q[w_tail]    <= s_axi_awid;
                w_addr_q[w_tail]  <= s_axi_awaddr;
                w_beats_q[w_tail] <= s_axi_awlen;
                w_delay_q[w_tail] <= WRITE_LATENCY[7:0] + jitter;
                w_size_q[w_tail]  <= s_axi_awsize;
                w_burst_q[w_tail] <= s_axi_awburst;
                w_err_q[w_tail]   <= (s_axi_awaddr >> MEM_ADDR_SHIFT) >= MEM_WORDS;
                w_valid_q[w_tail] <= 1'b1;
                w_tail            <= (w_tail + 1) % MAX_OUTSTANDING;
                s_axi_awready     <= 1'b0;
            end
        end
    end

    // Write data + response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;
            s_axi_bid    <= {ID_WIDTH{1'b0}};
            w_active     <= 1'b0;
            w_delay      <= 8'd0;
            w_size       <= 3'd0;
            w_burst      <= BURST_INCR;
            w_err        <= 1'b0;
        end else begin
            if (!w_active && w_valid_q[w_head]) begin
                w_id    <= w_id_q[w_head];
                w_addr  <= w_addr_q[w_head];
                w_beats <= w_beats_q[w_head];
                w_delay <= w_delay_q[w_head];
                w_size  <= w_size_q[w_head];
                w_burst <= w_burst_q[w_head];
                w_err   <= w_err_q[w_head];
                w_active<= 1'b1;
                w_valid_q[w_head] <= 1'b0;
                w_head  <= (w_head + 1) % MAX_OUTSTANDING;
            end

            if (w_active) begin
                if (w_delay != 0) begin
                    s_axi_wready <= 1'b0;
                    w_delay <= w_delay - 1'b1;
                end else begin
                    s_axi_wready <= 1'b1;
                end
            end

            if (s_axi_wready && s_axi_wvalid) begin
                // Write with strobes
                if (!w_err) begin
                    for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                    if (s_axi_wstrb[i])
                        mem[w_addr[$clog2(MEM_WORDS)+2:3]][8*i +: 8] <= s_axi_wdata[8*i +: 8];
                end
                if (POISON_ON_UNINIT)
                    mem_valid[w_addr[$clog2(MEM_WORDS)+2:3]] <= 1'b1;
                end

                if (w_beats != 0)
                    w_beats <= w_beats - 1'b1;
                w_addr <= (w_burst == BURST_INCR) ? w_addr_next : w_addr;

                if (s_axi_wlast || (w_beats == 0)) begin
                    s_axi_bid    <= w_id;
                    s_axi_bresp  <= w_err ? RESP_SLVERR : RESP_OKAY;
                    s_axi_bvalid <= 1'b1;
                    s_axi_wready <= 1'b0;
                    w_active     <= 1'b0;
                    w_err        <= 1'b0;
                end
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
        end
    end

    // LFSR advancement for jitter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr <= 8'hA5;
        else
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5]};
    end

    // Read address acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            r_head        <= 0;
            r_tail        <= 0;
            for (i = 0; i < MAX_OUTSTANDING; i = i + 1)
                r_valid_q[i] <= 1'b0;
        end else begin
            if (!r_active && !s_axi_arready && ((r_tail + 1) % MAX_OUTSTANDING != r_head)) begin
                if (s_axi_arvalid === 1'b1)
                    s_axi_arready <= 1'b1;
            end
            if (s_axi_arready && s_axi_arvalid) begin
                r_id_q[r_tail]    <= s_axi_arid;
                r_addr_q[r_tail]  <= s_axi_araddr;
                r_beats_q[r_tail] <= s_axi_arlen;
                r_delay_q[r_tail] <= READ_LATENCY[7:0];
                r_size_q[r_tail]  <= s_axi_arsize;
                r_burst_q[r_tail] <= s_axi_arburst;
                r_err_q[r_tail]   <= (s_axi_araddr >> MEM_ADDR_SHIFT) >= MEM_WORDS;
                r_valid_q[r_tail] <= 1'b1;
                r_tail            <= (r_tail + 1) % MAX_OUTSTANDING;
                s_axi_arready     <= 1'b0;
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
            dbg_rdata    <= {DATA_WIDTH{1'b0}};
            r_delay      <= 8'd0;
            r_active     <= 1'b0;
            r_size       <= 3'd0;
            r_burst      <= BURST_INCR;
            r_err        <= 1'b0;
        end else begin
            if (dbg_we) begin
                mem[dbg_addr[$clog2(MEM_WORDS)+2:3]] <= dbg_wdata;
            end
            if (dbg_re) begin
                dbg_rdata <= mem[dbg_addr[$clog2(MEM_WORDS)+2:3]];
            end

            if (!r_active && r_valid_q[r_head]) begin
                r_id    <= r_id_q[r_head];
                r_addr  <= r_addr_q[r_head];
                r_beats <= r_beats_q[r_head];
                r_delay <= r_delay_q[r_head] + jitter;
                r_size  <= r_size_q[r_head];
                r_burst <= r_burst_q[r_head];
                r_err   <= r_err_q[r_head];
                r_active<= 1'b1;
                r_valid_q[r_head] <= 1'b0;
                r_head  <= (r_head + 1) % MAX_OUTSTANDING;
            end

            if (r_active && (!s_axi_rvalid || (s_axi_rvalid && s_axi_rready))) begin
                if (r_delay != 0) begin
                    s_axi_rvalid <= 1'b0;
                    r_delay      <= r_delay - 1'b1;
                end else begin
                    s_axi_rid   <= r_id;
                    if (POISON_ON_UNINIT && !r_err && !mem_valid[r_addr[$clog2(MEM_WORDS)+2:3]]) begin
                        s_axi_rdata <= {DATA_WIDTH{1'bx}};
                    end else begin
                        s_axi_rdata <= r_err ? {DATA_WIDTH{1'b0}} : mem[r_addr[$clog2(MEM_WORDS)+2:3]];
                    end
                    s_axi_rresp <= r_err ? RESP_SLVERR : RESP_OKAY;
                    s_axi_rlast <= (r_beats == 0);
                    s_axi_rvalid<= 1'b1;

                    if (r_beats != 0)
                        r_beats <= r_beats - 1'b1;
                    r_addr <= (r_burst == BURST_INCR) ? r_addr_next : r_addr;
                end
            end
            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                if (s_axi_rlast)
                    r_active <= 1'b0;
                    r_err    <= 1'b0;
            end
        end
    end

endmodule
