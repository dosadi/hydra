// SPDX-License-Identifier: BSD-3-Clause
// Simple AXI-Lite CSR smoke test for voxel_axil_csr.sv
// Drives a few writes/reads and checks reset defaults + RW1C INT_STATUS.
`timescale 1ns/1ps

module test_voxel_axil_csr_simple;

    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 32;

    reg clk = 0;
    reg rst_n = 0;

    // AXI-Lite signals
    reg [ADDR_WIDTH-1:0] s_axil_awaddr = 0;
    reg                  s_axil_awvalid = 0;
    wire                 s_axil_awready;
    reg [DATA_WIDTH-1:0] s_axil_wdata = 0;
    reg [(DATA_WIDTH/8)-1:0] s_axil_wstrb = 0;
    reg                  s_axil_wvalid = 0;
    wire                 s_axil_wready;
    wire [1:0]           s_axil_bresp;
    wire                 s_axil_bvalid;
    reg                  s_axil_bready = 0;
    reg [ADDR_WIDTH-1:0] s_axil_araddr = 0;
    reg                  s_axil_arvalid = 0;
    wire                 s_axil_arready;
    wire [DATA_WIDTH-1:0] s_axil_rdata;
    wire [1:0]            s_axil_rresp;
    wire                  s_axil_rvalid;
    reg                   s_axil_rready = 0;

    // Outputs (ignored in this stub test)
    wire cam_load_pulse;
    wire signed [15:0] cam_x, cam_y, cam_z;
    wire signed [15:0] cam_dir_x, cam_dir_y, cam_dir_z;
    wire signed [15:0] cam_plane_x, cam_plane_y;
    wire flags_load_pulse;
    wire flag_smooth, flag_curvature, flag_extra_light, flag_diag_slice;
    wire sel_load_pulse, sel_active;
    wire [5:0] sel_x, sel_y, sel_z;
    wire dbg_we_pulse;
    wire [17:0] dbg_addr;
    wire [63:0] dbg_wdata;
    wire frame_done_pulse, core_busy;
    wire soft_reset_pulse, start_frame_pulse;
    wire dma_start_pulse;
    reg  dma_busy_in = 0, dma_done_in = 0;
    wire [31:0] dma_src, dma_dst, dma_len;
    wire [31:0] dma_status;
    wire blit_mem_we, blit_mem_re;
    wire [27:0] blit_mem_addr;
    wire [63:0] blit_mem_wdata;
    reg  [63:0] blit_mem_rdata = 64'd0;
    reg  [31:0] hdmi_crc_in = 32'd0, hdmi_frames_in = 32'd0;
    reg  [15:0] hdmi_line_in = 16'd0, hdmi_pix_in = 16'd0;
    wire irq_out;
    reg  [31:0] rd;

    voxel_axil_csr #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .SCREEN_WIDTH(480),
        .SCREEN_HEIGHT(360),
        .VOXEL_GRID_SIZE(64)
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
        .cam_load_pulse(cam_load_pulse),
        .cam_x(cam_x),
        .cam_y(cam_y),
        .cam_z(cam_z),
        .cam_dir_x(cam_dir_x),
        .cam_dir_y(cam_dir_y),
        .cam_dir_z(cam_dir_z),
        .cam_plane_x(cam_plane_x),
        .cam_plane_y(cam_plane_y),
        .flags_load_pulse(flags_load_pulse),
        .flag_smooth(flag_smooth),
        .flag_curvature(flag_curvature),
        .flag_extra_light(flag_extra_light),
        .flag_diag_slice(flag_diag_slice),
        .sel_load_pulse(sel_load_pulse),
        .sel_active(sel_active),
        .sel_x(sel_x),
        .sel_y(sel_y),
        .sel_z(sel_z),
        .dbg_we_pulse(dbg_we_pulse),
        .dbg_addr(dbg_addr),
        .dbg_wdata(dbg_wdata),
        .frame_done_pulse(frame_done_pulse),
        .core_busy(core_busy),
        .soft_reset_pulse(soft_reset_pulse),
        .start_frame_pulse(start_frame_pulse),
        .dma_start_pulse(dma_start_pulse),
        .dma_busy_in(dma_busy_in),
        .dma_done_in(dma_done_in),
        .dma_src(dma_src),
        .dma_dst(dma_dst),
        .dma_len(dma_len),
        .dma_status(dma_status),
        .blit_mem_we(blit_mem_we),
        .blit_mem_re(blit_mem_re),
        .blit_mem_addr(blit_mem_addr),
        .blit_mem_wdata(blit_mem_wdata),
        .blit_mem_rdata(blit_mem_rdata),
        .hdmi_crc_in(hdmi_crc_in),
        .hdmi_frames_in(hdmi_frames_in),
        .hdmi_line_in(hdmi_line_in),
        .hdmi_pix_in(hdmi_pix_in),
        .irq_out(irq_out)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("test_voxel_axil_csr_simple.vcd");
        $dumpvars(0, test_voxel_axil_csr_simple);
    end

    task automatic axil_write(input [ADDR_WIDTH-1:0] addr, input [31:0] data, input [3:0] wstrb);
        integer wait_b;
    begin
        $display("axil_write kick addr=0x%04h data=0x%08x", addr, data);
        s_axil_awaddr  = addr;
        s_axil_wdata   = data;
        s_axil_wstrb   = wstrb;
        s_axil_awvalid = 1'b1;
        s_axil_wvalid  = 1'b1;
        s_axil_bready  = 1'b1;
        @(posedge clk);
        @(posedge clk);
        s_axil_awvalid = 1'b0;
        s_axil_wvalid  = 1'b0;
        wait_b = 0;
        // Wait for bvalid
        while (!s_axil_bvalid) begin
            @(posedge clk);
            wait_b = wait_b + 1;
            if (wait_b > 1000) $fatal(1, "axil_write timeout waiting for bvalid");
        end
        @(posedge clk);
        s_axil_bready  = 1'b0;
    end
    endtask

    task automatic axil_read(input [ADDR_WIDTH-1:0] addr, output [31:0] data);
        integer wait_r;
    begin
        s_axil_araddr  = addr;
        s_axil_arvalid = 1'b1;
        s_axil_rready  = 1'b1;
        $display("axil_read kick addr=0x%04h araddr_reg=0x%04h", addr, s_axil_araddr);
        @(posedge clk);
        wait_r = 0;
        while (!s_axil_rvalid) begin
            @(posedge clk);
            wait_r = wait_r + 1;
            if (wait_r > 1000) $fatal(1, "axil_read timeout waiting for rvalid");
        end
        data = s_axil_rdata;
        $display("axil_read addr=0x%04h data=0x%08x", addr, data);
        s_axil_arvalid = 1'b0;
        @(posedge clk);
        s_axil_rready = 1'b0;
    end
    endtask

    initial begin
        $display("Testing CSR with SCREEN_WIDTH=480 SCREEN_HEIGHT=360 VOXEL_GRID_SIZE=64");
        // Apply reset
        repeat (4) @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);

        // Check all CSR reset defaults explicitly
        axil_read(16'h0040, rd); if (rd !== 32'h00000003) $fatal(1, "FLAGS reset mismatch: %08x", rd);
        axil_read(16'h0044, rd); if (rd !== 32'h00000000) $fatal(1, "SEL_ACTIVE reset mismatch: %08x", rd);
        axil_read(16'h0048, rd); if (rd !== 32'h00000000) $fatal(1, "SEL_X reset mismatch: %08x", rd);
        axil_read(16'h004C, rd); if (rd !== 32'h00000000) $fatal(1, "SEL_Y reset mismatch: %08x", rd);
        axil_read(16'h0050, rd); if (rd !== 32'h00000000) $fatal(1, "SEL_Z reset mismatch: %08x", rd);
        axil_read(16'h0080, rd); if (rd !== 32'h00000000) $fatal(1, "INT_STATUS reset mismatch: %08x", rd);
        axil_read(16'h0084, rd); if (rd !== 32'h00000000) $fatal(1, "INT_MASK reset mismatch: %08x", rd);
        axil_read(16'h0090, rd); if (rd !== 32'h00000000) $fatal(1, "CTRL reset mismatch: %08x", rd);
        axil_read(16'h0020, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_X reset mismatch: %08x", rd);
        axil_read(16'h0024, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_Y reset mismatch: %08x", rd);
        axil_read(16'h0028, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_Z reset mismatch: %08x", rd);
        axil_read(16'h002C, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_DIR_X reset mismatch: %08x", rd);
        axil_read(16'h0030, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_DIR_Y reset mismatch: %08x", rd);
        axil_read(16'h0034, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_DIR_Z reset mismatch: %08x", rd);
        axil_read(16'h0038, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_PLANE_X reset mismatch: %08x", rd);
        axil_read(16'h003C, rd); if (rd !== 32'h00000000) $fatal(1, "CAM_PLANE_Y reset mismatch: %08x", rd);

        // INT_STATUS RW1C behavior: set bit then clear
        axil_write(16'h0088, 32'h1, 4'hF); // IRQ_TEST
        @(posedge clk);
        if (dut.int_status[3] !== 1'b1) begin
            $fatal(1, "INT_STATUS[3] not set after IRQ_TEST write: %08x", dut.int_status);
        end
        axil_read(16'h0080, rd);
        if ((rd & 32'h8) == 0) $fatal(1, "INT_STATUS did not latch TEST bit");
        axil_write(16'h0080, 32'h8, 4'hF); // clear
        axil_read(16'h0080, rd);
        if (rd != 0) $fatal(1, "INT_STATUS did not clear: %08x", rd);

        // Write camera X and read back
        axil_write(16'h0020, 32'h00010002, 4'hF);
        axil_read(16'h0020, rd);
        if (rd != 32'h00000002) $fatal(1, "CAM_X readback mismatch: %08x", rd);

        $display("test_voxel_axil_csr_simple: PASS");
        $finish;
    end

endmodule
