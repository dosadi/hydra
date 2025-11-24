// BAR1 + DMA loopback test for voxel_axil_shell.
// Writes a pattern into SDRAM via BAR1 (external AXI), kicks the DMA stub
// to copy it elsewhere in SDRAM, then reads back via BAR1 and checks INT_STATUS
// and irq_out behavior. Intended to stay entirely in simulation.
`timescale 1ns/1ps

module test_bar1_dma_loopback;
    reg clk   = 0;
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

    // External AXI (BAR1 window master)
    reg  [3:0]  ext_axi_awid   = 4'd0;
    reg  [27:0] ext_axi_awaddr = 28'd0;
    reg  [7:0]  ext_axi_awlen  = 8'd0;
    reg  [2:0]  ext_axi_awsize = 3'd3;   // 8-byte beats
    reg  [1:0]  ext_axi_awburst= 2'd1;   // INCR
    reg         ext_axi_awvalid= 1'b0;
    wire        ext_axi_awready;
    reg  [63:0] ext_axi_wdata  = 64'd0;
    reg  [7:0]  ext_axi_wstrb  = 8'hFF;
    reg         ext_axi_wlast  = 1'b0;
    reg         ext_axi_wvalid = 1'b0;
    wire        ext_axi_wready;
    wire [3:0]  ext_axi_bid;
    wire [1:0]  ext_axi_bresp;
    wire        ext_axi_bvalid;
    reg         ext_axi_bready = 1'b0;
    reg  [3:0]  ext_axi_arid   = 4'd0;
    reg  [27:0] ext_axi_araddr = 28'd0;
    reg  [7:0]  ext_axi_arlen  = 8'd0;
    reg  [2:0]  ext_axi_arsize = 3'd3;
    reg  [1:0]  ext_axi_arburst= 2'd1;
    reg         ext_axi_arvalid= 1'b0;
    wire        ext_axi_arready;
    wire [3:0]  ext_axi_rid;
    wire [63:0] ext_axi_rdata;
    wire [1:0]  ext_axi_rresp;
    wire        ext_axi_rlast;
    wire        ext_axi_rvalid;
    reg         ext_axi_rready = 1'b0;

    // HDMI / IRQ sideband
    wire [23:0] s_axis_tdata;
    wire        s_axis_tvalid;
    wire        s_axis_tlast;
    wire        s_axis_tuser;
    wire        s_axis_tready;
    assign s_axis_tready = 1'b1;
    wire [31:0] hdmi_beat_count;
    wire [31:0] hdmi_frame_count;
    wire [31:0] hdmi_crc_last;
    wire [15:0] hdmi_line_count;
    wire [15:0] hdmi_pixel_in_line;
    wire        irq_out;
    wire        msi_pulse;

    // Under-test shell
    voxel_axil_shell #(
        .SCREEN_WIDTH (32),
        .SCREEN_HEIGHT(24)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axil_awaddr  (s_axil_awaddr),
        .s_axil_awvalid (s_axil_awvalid),
        .s_axil_awready (s_axil_awready),
        .s_axil_wdata   (s_axil_wdata),
        .s_axil_wstrb   (s_axil_wstrb),
        .s_axil_wvalid  (s_axil_wvalid),
        .s_axil_wready  (s_axil_wready),
        .s_axil_bresp   (s_axil_bresp),
        .s_axil_bvalid  (s_axil_bvalid),
        .s_axil_bready  (s_axil_bready),
        .s_axil_araddr  (s_axil_araddr),
        .s_axil_arvalid (s_axil_arvalid),
        .s_axil_arready (s_axil_arready),
        .s_axil_rdata   (s_axil_rdata),
        .s_axil_rresp   (s_axil_rresp),
        .s_axil_rvalid  (s_axil_rvalid),
        .s_axil_rready  (s_axil_rready),
        .ext_axi_awid   (ext_axi_awid),
        .ext_axi_awaddr (ext_axi_awaddr),
        .ext_axi_awlen  (ext_axi_awlen),
        .ext_axi_awsize (ext_axi_awsize),
        .ext_axi_awburst(ext_axi_awburst),
        .ext_axi_awvalid(ext_axi_awvalid),
        .ext_axi_awready(ext_axi_awready),
        .ext_axi_wdata  (ext_axi_wdata),
        .ext_axi_wstrb  (ext_axi_wstrb),
        .ext_axi_wlast  (ext_axi_wlast),
        .ext_axi_wvalid (ext_axi_wvalid),
        .ext_axi_wready (ext_axi_wready),
        .ext_axi_bid    (ext_axi_bid),
        .ext_axi_bresp  (ext_axi_bresp),
        .ext_axi_bvalid (ext_axi_bvalid),
        .ext_axi_bready (ext_axi_bready),
        .ext_axi_arid   (ext_axi_arid),
        .ext_axi_araddr (ext_axi_araddr),
        .ext_axi_arlen  (ext_axi_arlen),
        .ext_axi_arsize (ext_axi_arsize),
        .ext_axi_arburst(ext_axi_arburst),
        .ext_axi_arvalid(ext_axi_arvalid),
        .ext_axi_arready(ext_axi_arready),
        .ext_axi_rid    (ext_axi_rid),
        .ext_axi_rdata  (ext_axi_rdata),
        .ext_axi_rresp  (ext_axi_rresp),
        .ext_axi_rlast  (ext_axi_rlast),
        .ext_axi_rvalid (ext_axi_rvalid),
        .ext_axi_rready (ext_axi_rready),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tuser   (s_axis_tuser),
        .s_axis_tready  (s_axis_tready),
        .hdmi_beat_count(hdmi_beat_count),
        .hdmi_frame_count(hdmi_frame_count),
        .hdmi_crc_last  (hdmi_crc_last),
        .hdmi_line_count(hdmi_line_count),
        .hdmi_pixel_in_line(hdmi_pixel_in_line),
        .irq_out        (irq_out),
        .msi_pulse      (msi_pulse)
    );

    // Clock
    always #5 clk = ~clk;

    localparam [27:0] BAR1_BASE = 28'h1000_000; // matches voxel_axil_shell
    localparam [27:0] SRC_ADDR  = 28'h0000_0100;
    localparam [27:0] DST_ADDR  = 28'h0000_0200;

    // AXI-Lite helpers (byte offsets encoded as 16-bit addresses in benches)
    task axil_write(input [15:0] word_addr, input [31:0] wdata);
    begin
        s_axil_awaddr  = word_addr;
        s_axil_wdata   = wdata;
        s_axil_awvalid = 1;
        s_axil_wvalid  = 1;
        s_axil_bready  = 1;
        @(posedge clk);
        while (!s_axil_awready || !s_axil_wready) @(posedge clk);
        s_axil_awvalid = 0;
        s_axil_wvalid  = 0;
        @(posedge clk);
        s_axil_bready  = 0;
    end
    endtask

    task axil_read(input [15:0] word_addr);
    begin
        s_axil_araddr  = word_addr;
        s_axil_arvalid = 1;
        s_axil_rready  = 1;
        @(posedge clk);
        while (!s_axil_arready) @(posedge clk);
        s_axil_arvalid = 0;
        while (!s_axil_rvalid) @(posedge clk);
        @(posedge clk);
        s_axil_rready  = 0;
    end
    endtask

    // Simple single-beat BAR1 write/read tasks (64-bit)
    task bar1_write64(input [27:0] byte_addr, input [63:0] data);
    begin
        ext_axi_awaddr  <= BAR1_BASE + byte_addr;
        ext_axi_awlen   <= 8'd0;
        ext_axi_awsize  <= 3'd3; // 8 bytes
        ext_axi_awburst <= 2'd1;
        ext_axi_wdata   <= data;
        ext_axi_wstrb   <= 8'hFF;
        ext_axi_wlast   <= 1'b1;
        ext_axi_awvalid <= 1'b1;
        ext_axi_wvalid  <= 1'b1;
        ext_axi_bready  <= 1'b1;
        @(posedge clk);
        while (!(ext_axi_awready && ext_axi_wready)) @(posedge clk);
        ext_axi_awvalid <= 1'b0;
        ext_axi_wvalid  <= 1'b0;
        // Wait for write response
        while (!ext_axi_bvalid) @(posedge clk);
        @(posedge clk);
        ext_axi_bready  <= 1'b0;
    end
    endtask

    task bar1_read64(input [27:0] byte_addr, output [63:0] data);
    begin
        ext_axi_araddr  <= BAR1_BASE + byte_addr;
        ext_axi_arlen   <= 8'd0;
        ext_axi_arsize  <= 3'd3;
        ext_axi_arburst <= 2'd1;
        ext_axi_arvalid <= 1'b1;
        ext_axi_rready  <= 1'b1;
        @(posedge clk);
        while (!ext_axi_arready) @(posedge clk);
        ext_axi_arvalid <= 1'b0;
        while (!ext_axi_rvalid) @(posedge clk);
        data = ext_axi_rdata;
        @(posedge clk);
        ext_axi_rready  <= 1'b0;
    end
    endtask

    integer i;
    reg [63:0] tmp64;

    initial begin
        $display("Starting BAR1 + DMA loopback test...");
        rst_n = 0;
        ext_axi_awvalid = 0;
        ext_axi_wvalid  = 0;
        ext_axi_bready  = 0;
        ext_axi_arvalid = 0;
        ext_axi_rready  = 0;
        #40 rst_n = 1;

        // Seed SRC region via BAR1 and clear DST region.
        for (i = 0; i < 4; i = i + 1) begin
            bar1_write64(SRC_ADDR + (i*8), {32'hDEAD_0000 | i[31:0], 32'hBEEF_0000 | i[31:0]});
            bar1_write64(DST_ADDR + (i*8), 64'd0);
        end

        // Enable only DMA_DONE interrupt (bit1) in INT_MASK.
        axil_write(16'h21, 32'h0000_0002);
        // Program DMA SRC/DST/LEN in byte addresses (match SRC_ADDR/DST_ADDR).
        axil_write(16'h18, {4'd0, SRC_ADDR}); // DMA_SRC
        axil_write(16'h19, {4'd0, DST_ADDR}); // DMA_DST
        axil_write(16'h1A, 32'd32);           // 4 beats * 8 bytes
        axil_write(16'h1B, 32'h0000_0001);    // start

        // Wait for dma_done in INT_STATUS[1].
        repeat (2000) @(posedge clk);
        axil_read(16'h20); // INT_STATUS
        if (s_axil_rdata[1] !== 1'b1)
            $error("Expected INT_STATUS dma_done bit set in BAR1+DMA loopback");
        if (irq_out !== 1'b1)
            $error("Expected irq_out high when dma_done interrupt is set in BAR1+DMA loopback");

        // Clear dma_done via W1C and ensure irq_out drops.
        axil_write(16'h20, 32'h0000_0002);
        repeat (10) @(posedge clk);
        if (irq_out !== 1'b0)
            $error("Expected irq_out low after clearing dma_done interrupt in BAR1+DMA loopback");

        // Read back DST region via BAR1 and compare to SRC pattern.
        for (i = 0; i < 4; i = i + 1) begin
            bar1_read64(DST_ADDR + (i*8), tmp64);
            if (tmp64 !== {32'hDEAD_0000 | i[31:0], 32'hBEEF_0000 | i[31:0]}) begin
                $error("BAR1+DMA data mismatch at word %0d: got %h", i, tmp64);
            end
        end

        $display("BAR1 + DMA loopback test completed. HDMI CRC=%h frames=%0d", hdmi_crc_last, hdmi_frame_count);
        $finish;
    end

endmodule
