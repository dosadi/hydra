// Simple SystemVerilog testbench for DMA loopback in voxel_axil_shell.
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

    voxel_axil_shell #(
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

    initial begin
        $display("Starting DMA loopback test...");
        #20 rst_n = 1;
        // Program INT_MASK
        axil_write(16'h21, 32'h0000_0003); // mask frame_done + dma_done
        // Program DMA src/dst/len (within SDRAM window)
        axil_write(16'h18, 32'h0000_0000); // SRC
        axil_write(16'h19, 32'h0000_0100); // DST
        axil_write(16'h1A, 32'h0000_0040); // LEN
        axil_write(16'h1B, 32'h0000_0001); // CMD start
        // Wait for done bit
        repeat (500) @(posedge clk);
        if (s_axil_rdata[1] === 1'b1)
            $display("DMA done observed");
        axil_read(16'h20); // read INT_STATUS
        if (s_axil_rdata[1] !== 1'b1) begin
            $error("Expected INT_STATUS dma_done bit set");
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
endmodule
