// Simple SV bench: run a few frames and check HDMI CRC is nonzero and stable.
`timescale 1ns/1ps

module test_hdmi_crc_golden;
    reg clk = 0;
    reg rst_n = 0;

    // AXI-Lite minimal signals to pulse start_frame
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

    // Unused AXI external ports
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
    assign s_axis_tready = 1'b1;
    wire [31:0] hdmi_beat_count;
    wire [31:0] hdmi_frame_count;
    wire [31:0] hdmi_crc_last;
    wire [15:0] hdmi_line_count;
    wire [15:0] hdmi_pixel_in_line;
    wire        irq_out;
    wire        msi_pulse;

    localparam [31:0] GOLDEN_CRC = 32'h00020500;

    voxel_axil_shell #(
        .SCREEN_WIDTH(32),
        .SCREEN_HEIGHT(24),
        .TEST_FORCE_WORLD_READY(1),
        .AUTO_START_FRAMES(1)
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

    always #5 clk = ~clk;

    integer to;

    initial begin
        $display("Starting HDMI CRC golden test...");
        #20 rst_n = 1;
        // Soft reset then start a frame (manual start required in this bench)
        axil_write(16'h04, 32'h0000_0001); // soft_reset
        axil_write(16'h04, 32'h0000_0000); // clear ctrl
        axil_write(16'h04, 32'h0000_0002); // CTRL start_frame

        // Wait until a frame appears or timeout
        to = 2_000_000;
        while (hdmi_frame_count == 0 && to > 0) begin
            @(posedge clk);
            to = to - 1;
        end
        $display("Frames: %0d, CRC: %h", hdmi_frame_count, hdmi_crc_last);
        if (hdmi_frame_count == 0)
            $error("No frames observed (crc=%h)", hdmi_crc_last);
        if (hdmi_crc_last === 32'd0)
            $error("CRC is zero (frame_count=%0d)", hdmi_frame_count);
        if (hdmi_crc_last !== GOLDEN_CRC)
            $error("CRC mismatch: got %h expected %h", hdmi_crc_last, GOLDEN_CRC);
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
endmodule
