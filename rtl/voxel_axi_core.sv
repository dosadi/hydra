// ============================================================================
// voxel_axi_core.sv
// - Clean FPGA integration wrapper for voxel_framebuffer_top.
// - Exposes standard AXI-Lite (CSR), AXI4 (memory), and AXI-Stream (video)
//   interfaces for LiteX/LitePCIe/LiteDRAM/LiteVideo integration.
// - NO stubs, NO address decoding, NO internal crossbars.
// - Upstream logic (LiteX SoC) is responsible for:
//     * BAR0/BAR1 address mapping (via LitePCIe)
//     * Memory arbitration (via LiteX AXIInterconnect)
//     * Clock domain crossing if needed
// - For simulation testing, use voxel_sim_harness.sv instead.
// ============================================================================
`timescale 1ns/1ps

module voxel_axi_core #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64,
    parameter integer TEST_FORCE_WORLD_READY = 0,
    parameter integer AUTO_START_FRAMES = 1
)(
    input  wire clk,
    input  wire rst_n,

    // ========================================================================
    // AXI-Lite CSR slave (connect to PCIe BAR0 or other control fabric)
    // ========================================================================
    input  wire [15:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    input  wire [15:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    output wire [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready,

    // ========================================================================
    // AXI4 master (framebuffer writes to DRAM)
    // ========================================================================
    output wire [3:0]  m_axi_awid,
    output wire [27:0] m_axi_awaddr,
    output wire [7:0]  m_axi_awlen,
    output wire [2:0]  m_axi_awsize,
    output wire [1:0]  m_axi_awburst,
    output wire        m_axi_awvalid,
    input  wire        m_axi_awready,
    output wire [63:0] m_axi_wdata,
    output wire [7:0]  m_axi_wstrb,
    output wire        m_axi_wlast,
    output wire        m_axi_wvalid,
    input  wire        m_axi_wready,
    input  wire [3:0]  m_axi_bid,
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output wire        m_axi_bready,
    output wire [3:0]  m_axi_arid,
    output wire [27:0] m_axi_araddr,
    output wire [7:0]  m_axi_arlen,
    output wire [2:0]  m_axi_arsize,
    output wire [1:0]  m_axi_arburst,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    input  wire [3:0]  m_axi_rid,
    input  wire [63:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rlast,
    input  wire        m_axi_rvalid,
    output wire        m_axi_rready,

    // ========================================================================
    // AXI-Stream master (video output to HDMI/DVI encoder)
    // ========================================================================
    output wire [23:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    output wire        m_axis_tlast,
    output wire        m_axis_tuser,
    input  wire        m_axis_tready,

    // ========================================================================
    // Sideband signals (status, interrupts, debug counters)
    // ========================================================================
    output wire        irq_out,
    output wire        msi_pulse,
    output wire        frame_done,
    output wire        core_busy
);

    // --------------------------------------------------------------------
    // CSR block (AXI-Lite slave)
    // --------------------------------------------------------------------
    wire         cam_load_pulse;
    wire signed [15:0] cam_x;
    wire signed [15:0] cam_y;
    wire signed [15:0] cam_z;
    wire signed [15:0] cam_dir_x;
    wire signed [15:0] cam_dir_y;
    wire signed [15:0] cam_dir_z;
    wire signed [15:0] cam_plane_x;
    wire signed [15:0] cam_plane_y;

    wire         flags_load_pulse;
    wire         flag_smooth;
    wire         flag_curvature;
    wire         flag_extra_light;
    wire         flag_diag_slice;

    wire         sel_load_pulse;
    wire         sel_active;
    wire [5:0]   sel_x;
    wire [5:0]   sel_y;
    wire [5:0]   sel_z;

    wire         dbg_we_pulse;
    wire [17:0]  dbg_addr;
    wire [63:0]  dbg_wdata;

    wire         soft_reset_pulse;
    wire         start_frame_pulse;

    // DMA CSRs (for future LiteDMA integration)
    wire         dma_start_pulse;
    wire         dma_busy;
    wire         dma_done;
    wire [31:0]  dma_src;
    wire [31:0]  dma_dst;
    wire [31:0]  dma_len;
    wire [31:0]  dma_status;

    // Blitter memory access (for 3D blitter bring-up)
    wire         blit_mem_we;
    wire         blit_mem_re;
    wire [27:0]  blit_mem_addr;
    wire [63:0]  blit_mem_wdata;
    wire [63:0]  blit_mem_rdata;

    // HDMI counters (for diagnostics)
    wire [31:0]  hdmi_crc_last;
    wire [31:0]  hdmi_frame_count;
    wire [15:0]  hdmi_line_count;
    wire [15:0]  hdmi_pixel_in_line;

    reg          irq_out_d;
    assign msi_pulse = irq_out & ~irq_out_d;

    // TODO: Wire DMA/blitter ports to LiteDMA or leave stubbed for now.
    // For initial bring-up, tie off DMA status and blitter readback:
    assign dma_busy   = 1'b0;
    assign dma_done   = 1'b0;
    assign dma_status = 32'd0;
    assign blit_mem_rdata = 64'd0;

    // TODO: Wire HDMI counters once LiteVideo scanout is integrated
    assign hdmi_crc_last      = 32'd0;
    assign hdmi_frame_count   = 32'd0;
    assign hdmi_line_count    = 16'd0;
    assign hdmi_pixel_in_line = 16'd0;

    voxel_axil_csr #(
        .ADDR_WIDTH(16),
        .DATA_WIDTH(32)
    ) u_csr (
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

        .cam_load_pulse (cam_load_pulse),
        .cam_x          (cam_x),
        .cam_y          (cam_y),
        .cam_z          (cam_z),
        .cam_dir_x      (cam_dir_x),
        .cam_dir_y      (cam_dir_y),
        .cam_dir_z      (cam_dir_z),
        .cam_plane_x    (cam_plane_x),
        .cam_plane_y    (cam_plane_y),

        .flags_load_pulse(flags_load_pulse),
        .flag_smooth    (flag_smooth),
        .flag_curvature (flag_curvature),
        .flag_extra_light(flag_extra_light),
        .flag_diag_slice(flag_diag_slice),

        .sel_load_pulse (sel_load_pulse),
        .sel_active     (sel_active),
        .sel_x          (sel_x),
        .sel_y          (sel_y),
        .sel_z          (sel_z),

        .dbg_we_pulse   (dbg_we_pulse),
        .dbg_addr       (dbg_addr),
        .dbg_wdata      (dbg_wdata),

        .frame_done_pulse(frame_done),
        .core_busy      (core_busy),

        .soft_reset_pulse(soft_reset_pulse),
        .start_frame_pulse(start_frame_pulse),

        .dma_start_pulse(dma_start_pulse),
        .dma_busy_in    (dma_busy),
        .dma_done_in    (dma_done),
        .dma_src        (dma_src),
        .dma_dst        (dma_dst),
        .dma_len        (dma_len),
        .dma_status     (dma_status),

        .blit_mem_we    (blit_mem_we),
        .blit_mem_re    (blit_mem_re),
        .blit_mem_addr  (blit_mem_addr),
        .blit_mem_wdata (blit_mem_wdata),
        .blit_mem_rdata (blit_mem_rdata),

        .hdmi_crc_in    (hdmi_crc_last),
        .hdmi_frames_in (hdmi_frame_count),
        .hdmi_line_in   (hdmi_line_count),
        .hdmi_pix_in    (hdmi_pixel_in_line),

        .irq_out        (irq_out)
    );

    // --------------------------------------------------------------------
    // Voxel framebuffer core
    // --------------------------------------------------------------------
    wire         pixel_write_en;
    wire [31:0]  pixel_addr;
    wire [31:0]  pixel_word0, pixel_word1, pixel_word2;
    wire [31:0]  pixel_reemissure;

    voxel_framebuffer_top #(
        .SCREEN_WIDTH   (SCREEN_WIDTH),
        .SCREEN_HEIGHT  (SCREEN_HEIGHT),
        .VOXEL_GRID_SIZE(VOXEL_GRID_SIZE),
        .TEST_FORCE_WORLD_READY(TEST_FORCE_WORLD_READY),
        .AUTO_START_FRAMES(AUTO_START_FRAMES)
    ) u_voxel (
        .clk            (clk),
        .rst_n          (rst_n),
        .pixel_write_en (pixel_write_en),
        .pixel_addr     (pixel_addr),
        .pixel_word0    (pixel_word0),
        .pixel_word1    (pixel_word1),
        .pixel_word2    (pixel_word2),
        .pixel_reemissure(pixel_reemissure),
        .frame_done     (frame_done),
        .core_busy      (core_busy),
        .cam_load       (cam_load_pulse),
        .cam_x_in       (cam_x),
        .cam_y_in       (cam_y),
        .cam_z_in       (cam_z),
        .cam_dir_x_in   (cam_dir_x),
        .cam_dir_y_in   (cam_dir_y),
        .cam_dir_z_in   (cam_dir_z),
        .cam_plane_x_in (cam_plane_x),
        .cam_plane_y_in (cam_plane_y),
        .flags_load     (flags_load_pulse),
        .flag_smooth_in (flag_smooth),
        .flag_curvature_in(flag_curvature),
        .flag_extra_light_in(flag_extra_light),
        .flag_diag_slice_in(flag_diag_slice),
        .sel_load       (sel_load_pulse),
        .sel_active_in  (sel_active),
        .sel_voxel_x_in (sel_x),
        .sel_voxel_y_in (sel_y),
        .sel_voxel_z_in (sel_z),
        .dbg_ext_write_en  (dbg_we_pulse),
        .dbg_ext_write_addr(dbg_addr),
        .dbg_ext_write_data(dbg_wdata),
        .start_frame_ext (start_frame_pulse),
        .soft_reset_ext  (soft_reset_pulse)
    );

    // --------------------------------------------------------------------
    // Framebuffer write AXI4 master
    // - Converts pixel stream from voxel core to AXI4 writes to DRAM
    // - Simple burst writer: each pixel is one 64-bit word (RGBA32 + reemissure32)
    // --------------------------------------------------------------------
    // TODO: Replace this placeholder with a proper AXI4 burst writer.
    // For now, stub out the master interface (no actual writes).
    // LiteX integration will require:
    //   1. Buffering pixel stream into bursts (e.g., 16-beat AXI4 bursts)
    //   2. Address management (framebuffer base from CSR + pixel offset)
    //   3. Backpressure handling (stall voxel core if DRAM is slow)

    assign m_axi_awid    = 4'd0;
    assign m_axi_awaddr  = 28'd0;
    assign m_axi_awlen   = 8'd0;
    assign m_axi_awsize  = 3'b011; // 8 bytes
    assign m_axi_awburst = 2'b01;  // INCR
    assign m_axi_awvalid = 1'b0;

    assign m_axi_wdata   = 64'd0;
    assign m_axi_wstrb   = 8'hFF;
    assign m_axi_wlast   = 1'b0;
    assign m_axi_wvalid  = 1'b0;

    assign m_axi_bready  = 1'b1;

    assign m_axi_arid    = 4'd0;
    assign m_axi_araddr  = 28'd0;
    assign m_axi_arlen   = 8'd0;
    assign m_axi_arsize  = 3'b011;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arvalid = 1'b0;

    assign m_axi_rready  = 1'b1;

    // --------------------------------------------------------------------
    // AXI-Stream video master
    // - Converts pixel stream from voxel core to AXI-Stream for HDMI
    // --------------------------------------------------------------------
    localparam integer TOTAL_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;
    wire axis_fire = m_axis_tvalid && m_axis_tready;

    reg [31:0] hdmi_crc_accum;
    reg [31:0] hdmi_frame_count_r;
    reg [15:0] hdmi_line_count_r;
    reg [15:0] hdmi_pixel_in_line_r;

    assign hdmi_crc_last      = hdmi_crc_accum;
    assign hdmi_frame_count   = hdmi_frame_count_r;
    assign hdmi_line_count    = hdmi_line_count_r;
    assign hdmi_pixel_in_line = hdmi_pixel_in_line_r;

    assign m_axis_tdata  = pixel_word1[23:0]; // RGB888
    assign m_axis_tvalid = pixel_write_en;
    assign m_axis_tuser  = (pixel_addr == 0); // Start of frame
    assign m_axis_tlast  = (pixel_addr == TOTAL_PIXELS - 1); // End of frame

    // Lightweight CRC/counter tracking for HDMI/AXI-Stream output.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdmi_crc_accum       <= 32'd0;
            hdmi_frame_count_r   <= 32'd0;
            hdmi_line_count_r    <= 16'd0;
            hdmi_pixel_in_line_r <= 16'd0;
        end else begin
            if (axis_fire) begin
                hdmi_crc_accum <= hdmi_crc_accum ^ {8'd0, m_axis_tdata};
                if (m_axis_tlast) begin
                    hdmi_frame_count_r   <= hdmi_frame_count_r + 1'b1;
                    hdmi_line_count_r    <= 16'd0;
                    hdmi_pixel_in_line_r <= 16'd0;
                end else if (hdmi_pixel_in_line_r == SCREEN_WIDTH-1) begin
                    hdmi_pixel_in_line_r <= 16'd0;
                    hdmi_line_count_r    <= hdmi_line_count_r + 1'b1;
                end else begin
                    hdmi_pixel_in_line_r <= hdmi_pixel_in_line_r + 1'b1;
                end
            end
            if (m_axis_tuser && axis_fire) begin
                hdmi_crc_accum       <= 32'd0; // reset CRC at SOF
                hdmi_line_count_r    <= 16'd0;
                hdmi_pixel_in_line_r <= 16'd0;
            end
        end
    end

    // IRQ edge detection for MSI pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_out_d <= 1'b0;
        else
            irq_out_d <= irq_out;
    end

endmodule
