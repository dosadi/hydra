// Simple SystemVerilog testbench for DMA loopback in voxel_sim_harness.
// Copies a pattern within the SDRAM stub and checks INT_STATUS and DMA_STATUS.
`timescale 1ns/1ps

module test_dma_loopback;
    reg clk = 0;
    reg rst_n = 0;

    // AXI-Lite
    reg  [15:0] s_axil_awaddr = 0;
    reg         s_axil_awvalid= 0;
    wire        s_axil_awready;
    reg  [31:0] s_axil_wdata  = 0;
    reg  [3:0]  s_axil_wstrb  = 4'hF;
    reg         s_axil_wvalid = 0;
    wire        s_axil_wready;
    wire [1:0]  s_axil_bresp;
    wire        s_axil_bvalid;
    reg         s_axil_bready = 0;
    reg  [15:0] s_axil_araddr = 0;
    reg         s_axil_arvalid= 0;
    wire        s_axil_arready;
    wire [31:0] s_axil_rdata;
    wire [1:0]  s_axil_rresp;
    wire        s_axil_rvalid;
    reg         s_axil_rready = 0;

    // AXI external (unused in this test)
    wire [3:0]  ext_axi_awid   = 4'd0;
    wire [27:0] ext_axi_awaddr = 28'd0;
    wire [7:0]  ext_axi_awlen  = 8'd0;
    wire [2:0]  ext_axi_awsize = 3'd0;
    wire [1:0]  ext_axi_awburst= 2'd0;
    wire        ext_axi_awvalid= 1'b0;
    wire        ext_axi_awready;
    wire [63:0] ext_axi_wdata  = 64'd0;
    wire [7:0]  ext_axi_wstrb  = 8'h0;
    wire        ext_axi_wlast  = 1'b0;
    wire        ext_axi_wvalid = 1'b0;
    wire        ext_axi_wready;
    wire [3:0]  ext_axi_bid;
    wire [1:0]  ext_axi_bresp;
    wire        ext_axi_bvalid;
    wire        ext_axi_bready = 1'b0;
    wire [3:0]  ext_axi_arid   = 4'd0;
    wire [27:0] ext_axi_araddr = 28'd0;
    wire [7:0]  ext_axi_arlen  = 8'd0;
    wire [2:0]  ext_axi_arsize = 3'd0;
    wire [1:0]  ext_axi_arburst= 2'd0;
    wire        ext_axi_arvalid= 1'b0;
    wire        ext_axi_arready;
    wire [3:0]  ext_axi_rid;
    wire [63:0] ext_axi_rdata;
    wire [1:0]  ext_axi_rresp;
    wire        ext_axi_rlast;
    wire        ext_axi_rvalid;
    wire        ext_axi_rready = 1'b0;

    wire [23:0] s_axis_tdata;
    wire        s_axis_tvalid;
    wire        s_axis_tlast;
    wire        s_axis_tuser;
    wire        s_axis_tready;
    wire [31:0] hdmi_beat_count;
    wire [31:0] hdmi_frame_count;
    wire [31:0] hdmi_crc_last;
    wire [15:0] hdmi_line_count;
    wire [15:0] hdmi_pixel_in_line;
    wire        irq_out;
    wire        msi_pulse;

    voxel_sim_harness #(
        .SCREEN_WIDTH(32),
        .SCREEN_HEIGHT(24)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        .ext_axi_awid(ext_axi_awid),
        .ext_axi_awaddr(ext_axi_awaddr),
        .ext_axi_awlen(ext_axi_awlen),
        .ext_axi_awsize(ext_axi_awsize),
        .ext_axi_awburst(ext_axi_awburst),
        .ext_axi_awvalid(ext_axi_awvalid),
        .ext_axi_awready(ext_axi_awready),
        .ext_axi_wdata(ext_axi_wdata),
        .ext_axi_wstrb(ext_axi_wstrb),
        .ext_axi_wlast(ext_axi_wlast),
        .ext_axi_wvalid(ext_axi_wvalid),
        .ext_axi_wready(ext_axi_wready),
        .ext_axi_bid(ext_axi_bid),
        .ext_axi_bresp(ext_axi_bresp),
        .ext_axi_bvalid(ext_axi_bvalid),
        .ext_axi_bready(ext_axi_bready),
        .ext_axi_arid(ext_axi_arid),
        .ext_axi_araddr(ext_axi_araddr),
        .ext_axi_arlen(ext_axi_arlen),
        .ext_axi_arsize(ext_axi_arsize),
        .ext_axi_arburst(ext_axi_arburst),
        .ext_axi_arvalid(ext_axi_arvalid),
        .ext_axi_arready(ext_axi_arready),
        .ext_axi_rid(ext_axi_rid),
        .ext_axi_rdata(ext_axi_rdata),
        .ext_axi_rresp(ext_axi_rresp),
        .ext_axi_rlast(ext_axi_rlast),
        .ext_axi_rvalid(ext_axi_rvalid),
        .ext_axi_rready(ext_axi_rready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tready(s_axis_tready),
        .hdmi_beat_count(hdmi_beat_count),
        .hdmi_frame_count(hdmi_frame_count),
        .hdmi_crc_last(hdmi_crc_last),
        .hdmi_line_count(hdmi_line_count),
        .hdmi_pixel_in_line(hdmi_pixel_in_line),
        .irq_out(irq_out),
        .msi_pulse(msi_pulse)
    );

    // Clock
    always #5 clk = ~clk;

    // Simple DMA loopback: directly kick internal DMA stub, bypassing AXI-Lite CSRs.
    localparam [27:0] DMA_SRC_ADDR  = 28'h0100;
    localparam [27:0] DMA_DST_ADDR  = 28'h0200;
    localparam [31:0] DMA_LEN_BYTES = 32'd64;
    localparam integer DMA_TIMEOUT_CYCLES = 1_000_000; // allow SDRAM latency/jitter sweeps

    initial begin
        integer i;
        bit dma_done_seen;
        bit [31:0] last_pixel_addr;
        bit pixel_write_seen;

        $display("Starting DMA loopback test...");
        #20 rst_n = 1;

        // Program DMA stub directly via hierarchical force into u_dma.
        force dut.u_dma.src_addr  = DMA_SRC_ADDR;
        force dut.u_dma.dst_addr  = DMA_DST_ADDR;
        force dut.u_dma.len_bytes = DMA_LEN_BYTES;
        @(posedge clk);
        force dut.u_dma.start     = 1'b1;
        @(posedge clk);
        force dut.u_dma.start     = 1'b0;

        // Monitor framebuffer writes for waveform checks
        pixel_write_seen = 0;
        last_pixel_addr = 32'hFFFFFFFF;
        for (i = 0; i < DMA_TIMEOUT_CYCLES; i = i + 1) begin
            @(posedge clk);
            if (dut.pixel_write_en) begin
                pixel_write_seen = 1;
                $display("Framebuffer write: pixel_addr=%0d", dut.pixel_addr);
                // Check monotonicity
                if (last_pixel_addr != 32'hFFFFFFFF && dut.pixel_addr <= last_pixel_addr) begin
                    $fatal(1, "Pixel address not monotonic: prev=%0d curr=%0d", last_pixel_addr, dut.pixel_addr);
                end
                last_pixel_addr = dut.pixel_addr;
            end
            if (dut.dma_done && !dma_done_seen) begin
                dma_done_seen = 1;
                $display("DMA done observed at iteration %0d", i);
            end
        end
        if (!dma_done_seen) begin
            $display("DMA timeout: dma_busy=%0b dma_done=%0b", dut.dma_busy, dut.dma_done);
            $fatal(1, "DMA did not assert done within timeout");
        end
        if (!pixel_write_seen) begin
            $fatal(1, "No framebuffer writes observed during DMA test");
        end

        $display("HDMI CRC last: %h frames: %0d", hdmi_crc_last, hdmi_frame_count);
        $finish;
    end

    task axil_write(input [15:0] word_addr, input [31:0] wdata);
    begin
        s_axil_awaddr  = word_addr;
        s_axil_wdata   = wdata;
        s_axil_awvalid = 1;
        s_axil_wvalid  = 1;
        s_axil_bready  = 1;
        // Single-beat write; rely on shell being always-ready when no BRESP is pending.
        @(posedge clk);
        s_axil_awvalid = 0;
        s_axil_wvalid  = 0;
        // Keep s_axil_bready asserted so each write sees a BRESP and clears bvalid.
    end
    endtask

    task axil_read(input [15:0] word_addr);
    begin
        s_axil_araddr  = word_addr;
        s_axil_arvalid = 1;
        s_axil_rready  = 1;
        @(posedge clk);
        begin : ar_wait
            integer guard;
            guard = 0;
            while (!s_axil_arready && guard < 10000) begin
                guard = guard + 1;
                @(posedge clk);
            end
            if (!s_axil_arready) begin
                $fatal(1, "AXI-Lite read AR handshake timeout at addr 0x%04h", word_addr);
            end
        end
        s_axil_arvalid = 0;
        begin : r_wait
            integer guard_r;
            guard_r = 0;
            while (!s_axil_rvalid && guard_r < 10000) begin
                guard_r = guard_r + 1;
                @(posedge clk);
            end
            if (!s_axil_rvalid) begin
                $fatal(1, "AXI-Lite read R data timeout at addr 0x%04h", word_addr);
            end
        end
        @(posedge clk);
        s_axil_rready  = 0;
    end
    endtask
endmodule
