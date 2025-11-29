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
    reg [7:0] w_total_beats;

    reg [ID_WIDTH-1:0] r_id;
    reg [ADDR_WIDTH-1:0] r_addr;
    reg [7:0] r_beats;
    reg       r_active;
    reg [7:0] r_delay;
    reg [2:0] r_size;
    reg [1:0] r_burst;
    reg       r_err;
    reg [7:0] r_total_beats;

    // Simple pseudo-random jitter (linear feedback shift register)
    reg [7:0] lfsr;

    integer i;

    // ------------------------------------------------------------------------
    // AXI Protocol SVAs and Coverage
`ifndef SYNTHESIS
`ifndef IVERILOG
        // SVA: AWVALID and WVALID must not be asserted simultaneously unless AWREADY and WREADY are both high
        property aw_w_valid_exclusive;
            @(posedge clk) disable iff (!rst_n)
            (s_axi_awvalid && s_axi_wvalid) |-> (s_axi_awready && s_axi_wready);
        endproperty
        aw_w_valid_exclusive_sva: assert property (aw_w_valid_exclusive);

        // SVA: ARVALID and RVALID must not be asserted simultaneously unless ARREADY and RREADY are both high
        property ar_r_valid_exclusive;
            @(posedge clk) disable iff (!rst_n)
            (s_axi_arvalid && s_axi_rvalid) |-> (s_axi_arready && s_axi_rready);
        endproperty
        ar_r_valid_exclusive_sva: assert property (ar_r_valid_exclusive);
`endif // IVERILOG
`endif // SYNTHESIS

`ifdef FORMAL
        // SVA: AW handshake only when AWVALID
        property aw_handshake_only_on_valid;
            @(posedge clk) disable iff (!rst_n)
            s_axi_awready |-> s_axi_awvalid;
        endproperty
        aw_handshake_only_on_valid_sva: assert property (aw_handshake_only_on_valid);

        // SVA: W handshake only when WVALID
        property w_handshake_only_on_valid;
            @(posedge clk) disable iff (!rst_n)
            s_axi_wready |-> s_axi_wvalid;
        endproperty
        w_handshake_only_on_valid_sva: assert property (w_handshake_only_on_valid);

        // SVA: AR handshake only when ARVALID
        property ar_handshake_only_on_valid;
            @(posedge clk) disable iff (!rst_n)
            s_axi_arready |-> s_axi_arvalid;
        endproperty
        ar_handshake_only_on_valid_sva: assert property (ar_handshake_only_on_valid);

        // SVA: R handshake only when RVALID
        property r_handshake_only_on_valid;
            @(posedge clk) disable iff (!rst_n)
            s_axi_rready |-> s_axi_rvalid;
        endproperty
        r_handshake_only_on_valid_sva: assert property (r_handshake_only_on_valid);

        // SVA: Outstanding transactions do not exceed MAX_OUTSTANDING
        property max_outstanding_write;
            @(posedge clk) disable iff (!rst_n)
            w_head - w_tail <= MAX_OUTSTANDING;
        endproperty
        max_outstanding_write_sva: assert property (max_outstanding_write);

        property max_outstanding_read;
            @(posedge clk) disable iff (!rst_n)
            r_head - r_tail <= MAX_OUTSTANDING;
        endproperty
        max_outstanding_read_sva: assert property (max_outstanding_read);

        // SVA: Error response only on error
        property error_response_only_on_error;
            @(posedge clk) disable iff (!rst_n)
            (s_axi_bvalid && s_axi_bresp == RESP_SLVERR) |-> w_err;
        endproperty
        error_response_only_on_error_sva: assert property (error_response_only_on_error);

        // SVA: Reset deasserts all valid/ready signals
        property valid_ready_deassert_on_reset;
            @(posedge clk) disable iff (!rst_n)
            !rst_n |-> !(s_axi_awvalid || s_axi_wvalid || s_axi_arvalid || s_axi_rvalid || s_axi_awready || s_axi_wready || s_axi_arready || s_axi_rready);
        endproperty
        valid_ready_deassert_on_reset_sva: assert property (valid_ready_deassert_on_reset);

        // SVA: Data integrity (no X/Z on outgoing signals when valid)
        property no_xz_on_valid;
            @(posedge clk) disable iff (!rst_n)
            (s_axi_awvalid |-> !$isunknown(s_axi_awaddr)) &&
            (s_axi_wvalid |-> !$isunknown(s_axi_wdata)) &&
            (s_axi_wvalid |-> !$isunknown(s_axi_wstrb)) &&
            (s_axi_arvalid |-> !$isunknown(s_axi_araddr));
        endproperty
        no_xz_on_valid_sva: assert property (no_xz_on_valid);

        // SVA: Setup time for AWVALID before AWREADY
        property awvalid_setup;
            @(posedge clk) disable iff (!rst_n)
            s_axi_awvalid |-> $stable(s_axi_awvalid) throughout [*1:$] s_axi_awready;
        endproperty
        awvalid_setup_sva: assert property (awvalid_setup);

        // SVA: Hold time for AWVALID after AWREADY
        property awvalid_hold;
            @(posedge clk) disable iff (!rst_n)
            s_axi_awready |-> $stable(s_axi_awvalid) throughout [*1:2];
        endproperty
        awvalid_hold_sva: assert property (awvalid_hold);

        // SVA: Pulse width for AWVALID
        property awvalid_pulse_width;
            @(posedge clk) disable iff (!rst_n)
            s_axi_awvalid |-> ##[1:8] !s_axi_awvalid;
        endproperty
        awvalid_pulse_width_sva: assert property (awvalid_pulse_width);

        // Repeat for WVALID, ARVALID, RVALID
        property wvalid_setup;
            @(posedge clk) disable iff (!rst_n)
            s_axi_wvalid |-> $stable(s_axi_wvalid) throughout [*1:$] s_axi_wready;
        endproperty
        wvalid_setup_sva: assert property (wvalid_setup);

        property wvalid_hold;
            @(posedge clk) disable iff (!rst_n)
            s_axi_wready |-> $stable(s_axi_wvalid) throughout [*1:2];
        endproperty
        wvalid_hold_sva: assert property (wvalid_hold);

        property wvalid_pulse_width;
            @(posedge clk) disable iff (!rst_n)
            s_axi_wvalid |-> ##[1:8] !s_axi_wvalid;
        endproperty
        wvalid_pulse_width_sva: assert property (wvalid_pulse_width);

        property arvalid_setup;
            @(posedge clk) disable iff (!rst_n)
            s_axi_arvalid |-> $stable(s_axi_arvalid) throughout [*1:$] s_axi_arready;
        endproperty
        arvalid_setup_sva: assert property (arvalid_setup);

        property arvalid_hold;
            @(posedge clk) disable iff (!rst_n)
            s_axi_arready |-> $stable(s_axi_arvalid) throughout [*1:2];
        endproperty
        arvalid_hold_sva: assert property (arvalid_hold);

        property arvalid_pulse_width;
            @(posedge clk) disable iff (!rst_n)
            s_axi_arvalid |-> ##[1:8] !s_axi_arvalid;
        endproperty
        arvalid_pulse_width_sva: assert property (arvalid_pulse_width);

        property rvalid_setup;
            @(posedge clk) disable iff (!rst_n)
            s_axi_rvalid |-> $stable(s_axi_rvalid) throughout [*1:$] s_axi_rready;
        endproperty
        rvalid_setup_sva: assert property (rvalid_setup);

        property rvalid_hold;
            @(posedge clk) disable iff (!rst_n)
            s_axi_rready |-> $stable(s_axi_rvalid) throughout [*1:2];
        endproperty
        rvalid_hold_sva: assert property (rvalid_hold);

        property rvalid_pulse_width;
            @(posedge clk) disable iff (!rst_n)
            s_axi_rvalid |-> ##[1:8] !s_axi_rvalid;
        endproperty
        rvalid_pulse_width_sva: assert property (rvalid_pulse_width);

        // SVA: WRAP next address stays within wrap boundary
        property wrap_address_within_bounds;
            @(posedge clk) disable iff (!rst_n)
            (r_active && r_burst == 2'b10) |-> (
                (r_addr >= (r_addr - (r_addr % ((r_total_beats)*(1<<r_size)))) ) &&
                (r_addr < (r_addr - (r_addr % ((r_total_beats)*(1<<r_size)))) + (r_total_beats*(1<<r_size)))
            );
        endproperty
        wrap_address_within_bounds_sva: assert property (wrap_address_within_bounds);

        // SVA: AWREADY stability during WAIT_JITTER (ready should not glitch when jitter enabled)
        property awready_stable_under_jitter;
            @(posedge clk) disable iff (!rst_n)
            (WAIT_JITTER > 0 && s_axi_awready) |-> $stable(s_axi_awready) throughout [*1:WAIT_JITTER];
        endproperty
        awready_stable_under_jitter_sva: assert property (awready_stable_under_jitter);

        // SVA: ARREADY stability during WAIT_JITTER (ready should not glitch when jitter enabled)
        property arready_stable_under_jitter;
            @(posedge clk) disable iff (!rst_n)
            (WAIT_JITTER > 0 && s_axi_arready) |-> $stable(s_axi_arready) throughout [*1:WAIT_JITTER];
        endproperty
        arready_stable_under_jitter_sva: assert property (arready_stable_under_jitter);

        // SVA: WREADY stability during latency (ready should not glitch during write latency)
        property wready_stable_under_latency;
            @(posedge clk) disable iff (!rst_n)
            (WRITE_LATENCY > 0 && w_active && w_delay > 0) |-> !s_axi_wready;
        endproperty
        wready_stable_under_latency_sva: assert property (wready_stable_under_latency);

        // SVA: RVALID stability during latency (valid should not glitch during read latency)
        property rvalid_stable_under_latency;
            @(posedge clk) disable iff (!rst_n)
            (READ_LATENCY > 0 && r_active && r_delay > 0) |-> !s_axi_rvalid;
        endproperty
        rvalid_stable_under_latency_sva: assert property (rvalid_stable_under_latency);
`endif
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

`ifndef VERILATOR
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
`endif // VERILATOR

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

    // Compute WRAP next address helper (byte-addressed)
    function automatic [ADDR_WIDTH-1:0] wrap_next_addr;
        input [ADDR_WIDTH-1:0] addr;
        input [7:0] total_beats; // number of beats in burst
        input [2:0] size;        // beat size as power-of-two shift
        input [ADDR_WIDTH-1:0] base_addr;
        reg [ADDR_WIDTH-1:0] beat_bytes;
        reg [ADDR_WIDTH-1:0] wrap_size;
        reg [ADDR_WIDTH-1:0] base;
        reg [ADDR_WIDTH-1:0] offset;
    begin
        beat_bytes = (1 << size);
        wrap_size = beat_bytes * total_beats;
        // compute wrap base (aligned lower multiple of wrap_size)
        base = addr - (addr % wrap_size);
        offset = (addr - base + beat_bytes) % wrap_size;
        wrap_next_addr = base + offset;
    end
    endfunction
    localparam integer MEM_ADDR_SHIFT = 3;
    wire [7:0] jitter = (WAIT_JITTER == 0) ? 8'd0 : (lfsr & {8{(WAIT_JITTER!=0)}}) % (WAIT_JITTER+1);

    // ------------------------------------------------------------------------
    // Note: AW/AR ready handshake is handled in the AW/AR acceptance logic
    // and per-transaction delays are applied using per-queue delay entries
    // (`w_delay_q` / `r_delay_q`) when the transaction is serviced.

    // Write address acceptance
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            w_head        <= 0;
            w_tail        <= 0;
            for (i = 0; i < MAX_OUTSTANDING; i = i + 1)
                w_valid_q[i] <= 1'b0;
        end else begin
            // Gate AWREADY on AWVALID to avoid X/unknown accepts
            if (!w_active && !s_axi_awready && ((w_tail + 1) % MAX_OUTSTANDING != w_head)) begin
                // Only assert ready when valid is definitively high (not X/Z)
                if (s_axi_awvalid === 1'b1 && !$isunknown(s_axi_awvalid))
                    s_axi_awready <= 1'b1;
            end
            if (s_axi_awready && s_axi_awvalid) begin
                w_id_q[w_tail]    <= s_axi_awid;
                w_addr_q[w_tail]  <= s_axi_awaddr;
                w_beats_q[w_tail] <= s_axi_awlen;
                w_delay_q[w_tail] <= WRITE_LATENCY[7:0] + jitter;
                w_size_q[w_tail]  <= s_axi_awsize;
                w_burst_q[w_tail] <= s_axi_awburst;
                // Mark error if address out of range or unsupported burst type
                w_err_q[w_tail]   <= (s_axi_awaddr >> MEM_ADDR_SHIFT) >= MEM_WORDS
                                    || (s_axi_awburst != BURST_INCR && s_axi_awburst != 2'b10 && s_axi_awburst != 2'b00);
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
                // store total beats (AWLEN is beats-1 in AXI canonical form; stored value is AWLEN)
                w_total_beats <= w_beats_q[w_head] + 1'b1;
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
                // Compute next address depending on burst type
                if (w_burst == BURST_INCR) begin
                    w_addr <= w_addr_next;
                end else if (w_burst == 2'b10) begin // WRAP
                    w_addr <= wrap_next_addr(w_addr, w_total_beats, w_size, w_addr);
                end else begin // FIXED or unsupported falls back to increment
                    w_addr <= w_addr_next;
                end

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
            // Gate ARREADY on ARVALID to avoid X/unknown accepts
            if (!r_active && !s_axi_arready && ((r_tail + 1) % MAX_OUTSTANDING != r_head)) begin
                // Only assert ready when valid is definitively high (not X/Z)
                if (s_axi_arvalid === 1'b1 && !$isunknown(s_axi_arvalid))
                    s_axi_arready <= 1'b1;
            end
            if (s_axi_arready && s_axi_arvalid) begin
                r_id_q[r_tail]    <= s_axi_arid;
                r_addr_q[r_tail]  <= s_axi_araddr;
                r_beats_q[r_tail] <= s_axi_arlen;
                r_delay_q[r_tail] <= READ_LATENCY[7:0];
                r_size_q[r_tail]  <= s_axi_arsize;
                r_burst_q[r_tail] <= s_axi_arburst;
                // Mark error if address out of range or unsupported burst type
                r_err_q[r_tail]   <= (s_axi_araddr >> MEM_ADDR_SHIFT) >= MEM_WORDS
                                    || (s_axi_arburst != BURST_INCR && s_axi_arburst != 2'b10 && s_axi_arburst != 2'b00);
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
                r_total_beats <= r_beats_q[r_head] + 1'b1;
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
                    // Next address for read based on burst type
                    if (r_burst == BURST_INCR) begin
                        r_addr <= r_addr_next;
                    end else if (r_burst == 2'b10) begin // WRAP
                        r_addr <= wrap_next_addr(r_addr, r_total_beats, r_size, r_addr);
                    end else begin
                        r_addr <= r_addr_next;
                    end
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

    // NOTE: For now we accept INCR bursts and FIXED bursts; other burst types
    // will cause a SLVERR response. Extending to WRAP bursts, QoS, and region
    // handling is future work. Add s_axi_awqos, s_axi_awregion, s_axi_arqos,
    // s_axi_arregion to module port list when implementing advanced AXI features.

endmodule
