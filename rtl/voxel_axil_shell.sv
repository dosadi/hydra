// ============================================================================
// voxel_axil_shell.sv
// - AXI-Lite + AXI stub shell around voxel_framebuffer_top for simulation/bring-up.
// - Instantiates:
//     * voxel_axil_csr      : AXI4-Lite CSR block driving voxel controls.
//     * axi_sdram_stub      : BRAM-backed AXI memory (stand-in for SDRAM/DDR).
//     * axi_stream_sink_stub: captures pixel stream (stand-in for HDMI sink).
// - Connects voxel_framebuffer_top pixel writes into the AXI-Stream sink and
//   exposes a simple AXI-Lite/AXI presence for early fabric testing.
// ============================================================================
`timescale 1ns/1ps

module voxel_axil_shell #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64,
    parameter        TEST_FORCE_WORLD_READY = 0,
    parameter        AUTO_START_FRAMES = 1
)(
    input  wire clk,
    input  wire rst_n,

    // AXI-Lite slave (BAR0 placeholder)
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

    // AXI (placeholder SDRAM port) exposed externally
    input  wire [3:0]  ext_axi_awid,
    input  wire [27:0] ext_axi_awaddr,
    input  wire [7:0]  ext_axi_awlen,
    input  wire [2:0]  ext_axi_awsize,
    input  wire [1:0]  ext_axi_awburst,
    input  wire        ext_axi_awvalid,
    output wire        ext_axi_awready,
    input  wire [63:0] ext_axi_wdata,
    input  wire [7:0]  ext_axi_wstrb,
    input  wire        ext_axi_wlast,
    input  wire        ext_axi_wvalid,
    output wire        ext_axi_wready,
    output wire [3:0]  ext_axi_bid,
    output wire [1:0]  ext_axi_bresp,
    output wire        ext_axi_bvalid,
    input  wire        ext_axi_bready,
    input  wire [3:0]  ext_axi_arid,
    input  wire [27:0] ext_axi_araddr,
    input  wire [7:0]  ext_axi_arlen,
    input  wire [2:0]  ext_axi_arsize,
    input  wire [1:0]  ext_axi_arburst,
    input  wire        ext_axi_arvalid,
    output wire        ext_axi_arready,
    output wire [3:0]  ext_axi_rid,
    output wire [63:0] ext_axi_rdata,
    output wire [1:0]  ext_axi_rresp,
    output wire        ext_axi_rlast,
    output wire        ext_axi_rvalid,
    input  wire        ext_axi_rready,

    // AXI-Stream sink (HDMI placeholder)
    output wire [23:0] s_axis_tdata,
    output wire        s_axis_tvalid,
    output wire        s_axis_tlast,
    output wire        s_axis_tuser,
    input  wire        s_axis_tready,
    output wire [31:0] hdmi_beat_count,
    output wire [31:0] hdmi_frame_count,
    output wire [31:0] hdmi_crc_last,
    output wire [15:0] hdmi_line_count,
    output wire [15:0] hdmi_pixel_in_line,

    // Interrupt output
    output wire        irq_out,
    output wire        msi_pulse
);

    // --------------------------------------------------------------------
    // CSR block (AXI-Lite) driving voxel controls
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
    reg          ext_dbg_we;
    reg  [17:0]  ext_dbg_addr;
    reg  [63:0]  ext_dbg_data;
    wire         soft_reset_pulse;
    wire         start_frame_pulse;
    wire         dma_start_pulse;
    wire         dma_busy;
    wire         dma_done;
    wire [31:0]  dma_src;
    wire [31:0]  dma_dst;
    wire [31:0]  dma_len;
    wire [31:0]  dma_status;
    wire         use_dma = dma_busy;
    wire         blit_mem_we;
    wire         blit_mem_re;
    wire [27:0]  blit_mem_addr;
    wire [63:0]  blit_mem_wdata;
    reg          irq_out_d;
    assign msi_pulse = irq_out & ~irq_out_d;

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
        .blit_mem_rdata (sdram_dbg_rdata),

        .hdmi_crc_in    (hdmi_crc_last),
        .hdmi_frames_in (hdmi_frame_count),
        .hdmi_line_in   (hdmi_line_count),
        .hdmi_pix_in    (hdmi_pixel_in_line),

        .irq_out        (irq_out)
    );

    // --------------------------------------------------------------------
    // SDRAM + voxel window crossbar (2x2 stub)
    localparam [27:0] VOXEL_WIN_MASK = 28'h0FF_F000; // 256 KiB window
    localparam [27:0] VOXEL_WIN_BASE = 28'h000_0000;
    localparam [27:0] BAR1_BASE      = 28'h100_0000;
    // Decode voxel window on external AXI port (maps to debug write path, not SDRAM)
    wire ext_voxel_aw = ((ext_axi_awaddr & VOXEL_WIN_MASK) == VOXEL_WIN_BASE);
    wire ext_voxel_ar = ((ext_axi_araddr & VOXEL_WIN_MASK) == VOXEL_WIN_BASE);

    // DMA master wires
    wire [3:0]  m1_awid;
    wire [27:0] m1_awaddr;
    wire [7:0]  m1_awlen;
    wire [2:0]  m1_awsize;
    wire [1:0]  m1_awburst;
    wire        m1_awvalid;
    wire [63:0] m1_wdata;
    wire [7:0]  m1_wstrb;
    wire        m1_wlast;
    wire        m1_wvalid;
    wire        m1_bready;
    wire [3:0]  m1_arid;
    wire [27:0] m1_araddr;
    wire [7:0]  m1_arlen;
    wire [2:0]  m1_arsize;
    wire [1:0]  m1_arburst;
    wire        m1_arvalid;
    wire        m1_rready;

    wire target_bar1 = (ext_axi_awaddr >= BAR1_BASE);
    wire [3:0]  s_axi_awid   = use_dma               ? m1_awid   :
                               (ext_voxel_aw ? 4'd0  : ext_axi_awid);
    wire [27:0] s_axi_awaddr = use_dma               ? m1_awaddr :
                               (target_bar1 ? ext_axi_awaddr - BAR1_BASE : ext_axi_awaddr);
    wire [7:0]  s_axi_awlen  = use_dma               ? m1_awlen  :
                               ext_axi_awlen;
    wire [2:0]  s_axi_awsize = use_dma               ? m1_awsize :
                               ext_axi_awsize;
    wire [1:0]  s_axi_awburst= use_dma               ? m1_awburst:
                               ext_axi_awburst;
    wire        s_axi_awvalid= use_dma               ? m1_awvalid:
                               (ext_voxel_aw ? 1'b0 : ext_axi_awvalid);
    wire [63:0] s_axi_wdata  = use_dma               ? m1_wdata  :
                               ext_axi_wdata;
    wire [7:0]  s_axi_wstrb  = use_dma               ? m1_wstrb  :
                               ext_axi_wstrb;
    wire        s_axi_wlast  = use_dma               ? m1_wlast  :
                               ext_axi_wlast;
    wire        s_axi_wvalid = use_dma               ? m1_wvalid :
                               (ext_voxel_aw ? 1'b0 : ext_axi_wvalid);
    wire        s_axi_bready = use_dma               ? m1_bready :
                               (ext_voxel_aw ? 1'b0 : ext_axi_bready);
    wire target_bar1_r = (ext_axi_araddr >= BAR1_BASE);
    wire [3:0]  s_axi_arid   = use_dma               ? m1_arid   :
                               (ext_voxel_ar ? 4'd0 : ext_axi_arid);
    wire [27:0] s_axi_araddr = use_dma               ? m1_araddr :
                               (target_bar1_r ? ext_axi_araddr - BAR1_BASE : ext_axi_araddr);
    wire [7:0]  s_axi_arlen  = use_dma               ? m1_arlen  :
                               ext_axi_arlen;
    wire [2:0]  s_axi_arsize = use_dma               ? m1_arsize :
                               ext_axi_arsize;
    wire [1:0]  s_axi_arburst= use_dma               ? m1_arburst:
                               ext_axi_arburst;
    wire        s_axi_arvalid= use_dma               ? m1_arvalid:
                               (ext_voxel_ar ? 1'b0 : ext_axi_arvalid);
    wire        s_axi_rready = use_dma               ? m1_rready :
                               (ext_voxel_ar ? 1'b0 : ext_axi_rready);

    // External handshakes/responses, gated when DMA owns the bus.
    reg ext_bvalid_voxel;
    reg [1:0] ext_bresp_voxel;
    reg ext_rvalid_voxel;
    reg [1:0] ext_rresp_voxel;
    reg [63:0] ext_rdata_voxel;
    reg [3:0] ext_rid_voxel;
    reg ext_rlast_voxel;

    // Accept voxel-window writes when DMA not active
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_bvalid_voxel <= 1'b0;
            ext_bresp_voxel  <= 2'b00;
            ext_dbg_we       <= 1'b0;
            ext_dbg_addr     <= 18'd0;
            ext_dbg_data     <= 64'd0;
        end else begin
            if (!use_dma && ext_voxel_aw &&
                ext_axi_awvalid && ext_axi_wvalid) begin
                // Map byte address to voxel word address (ignore low 3 bits)
                ext_dbg_we       <= 1'b1;
                ext_dbg_addr     <= ext_axi_awaddr[20:3];
                ext_dbg_data     <= ext_axi_wdata;
                ext_bvalid_voxel   <= 1'b1;
                ext_bresp_voxel    <= 2'b00;
            end else begin
                ext_dbg_we <= 1'b0;
            end

            if (ext_bvalid_voxel && ext_axi_bready)
                ext_bvalid_voxel <= 1'b0;
        end
    end

    // Accept voxel-window reads as zero/OKAY (DMA cannot target voxel window)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_rvalid_voxel <= 1'b0;
            ext_rresp_voxel  <= 2'b00;
            ext_rdata_voxel  <= 64'd0;
            ext_rid_voxel    <= 4'd0;
            ext_rlast_voxel  <= 1'b0;
        end else begin
            if (!use_dma && ext_voxel_ar && ext_axi_arvalid) begin
                ext_rvalid_voxel <= 1'b1;
                ext_rresp_voxel  <= 2'b00;
                ext_rdata_voxel  <= 64'd0;
                ext_rid_voxel    <= ext_axi_arid;
                ext_rlast_voxel  <= 1'b1;
            end else if (ext_rvalid_voxel && ext_axi_rready) begin
                ext_rvalid_voxel <= 1'b0;
            end
        end
    end

    // External responses: allow voxel window even while DMA active; gate SDRAM path when DMA owns bus.
    assign ext_axi_awready = ext_voxel_aw ? 1'b1 : (use_dma ? 1'b0 : sdram_awready_int);
    assign ext_axi_wready  = ext_voxel_aw ? 1'b1 : (use_dma ? 1'b0 : sdram_wready_int);
    assign ext_axi_bresp   = ext_voxel_aw ? ext_bresp_voxel : (use_dma ? 2'b00 : sdram_bresp_int);
    assign ext_axi_bvalid  = ext_voxel_aw ? ext_bvalid_voxel : (use_dma ? 1'b0 : sdram_bvalid_int);
    assign ext_axi_bid     = ext_voxel_aw ? 4'd0 : (use_dma ? 4'd0 : sdram_bid_int);

    assign ext_axi_arready = ext_voxel_ar ? 1'b1 : (use_dma ? 1'b0 : sdram_arready_int);
    assign ext_axi_rdata   = ext_voxel_ar ? ext_rdata_voxel : (use_dma ? 64'd0 : sdram_rdata_int);
    assign ext_axi_rresp   = ext_voxel_ar ? ext_rresp_voxel : (use_dma ? 2'b00 : sdram_rresp_int);
    assign ext_axi_rlast   = ext_voxel_ar ? ext_rlast_voxel : (use_dma ? 1'b0 : sdram_rlast_int);
    assign ext_axi_rvalid  = ext_voxel_ar ? ext_rvalid_voxel : (use_dma ? 1'b0 : sdram_rvalid_int);
    assign ext_axi_rid     = ext_voxel_ar ? ext_rid_voxel : (use_dma ? 4'd0 : sdram_rid_int);

    // Internal SDRAM stub signals
    wire sdram_awready_int, sdram_wready_int, sdram_bvalid_int, sdram_arready_int, sdram_rlast_int, sdram_rvalid_int;
    wire [3:0] sdram_bid_int, sdram_rid_int;
    wire [1:0] sdram_bresp_int, sdram_rresp_int;
    wire [63:0] sdram_rdata_int;
    wire [63:0] sdram_dbg_rdata;
    wire        sdram_dbg_we;
    wire        sdram_dbg_re;
    wire [27:0] sdram_dbg_addr;
    wire [63:0] sdram_dbg_wdata;
    assign sdram_dbg_we    = blit_mem_we;
    assign sdram_dbg_re    = blit_mem_re;
    assign sdram_dbg_addr  = blit_mem_addr;
    assign sdram_dbg_wdata = blit_mem_wdata;
    // Simple BAR1 range guard: limit external accesses to stub depth.
    wire bar1_out_of_range = target_bar1 && (ext_axi_awaddr[27:0] >= (1 << 16));
    wire bar1_r_out_of_range = target_bar1_r && (ext_axi_araddr[27:0] >= (1 << 16));

    axi_sdram_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4),
        .MEM_WORDS (1 << 16) // 64 KiB of 64-bit words for sim
    ) u_sdram (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_axi_awid   (s_axi_awid),
        .s_axi_awaddr (s_axi_awaddr),
        .s_axi_awlen  (s_axi_awlen),
        .s_axi_awsize (s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awvalid(s_axi_awvalid && !bar1_out_of_range),
        .s_axi_awready(sdram_awready_int),
        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wstrb  (s_axi_wstrb),
        .s_axi_wlast  (s_axi_wlast),
        .s_axi_wvalid (s_axi_wvalid && !bar1_out_of_range),
        .s_axi_wready (sdram_wready_int),
        .s_axi_bid    (sdram_bid_int),
        .s_axi_bresp  (sdram_bresp_int),
        .s_axi_bvalid (sdram_bvalid_int),
        .s_axi_bready (s_axi_bready),
        .s_axi_arid   (s_axi_arid),
        .s_axi_araddr (s_axi_araddr),
        .s_axi_arlen  (s_axi_arlen),
        .s_axi_arsize (s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arvalid(s_axi_arvalid && !bar1_r_out_of_range),
        .s_axi_arready(sdram_arready_int),
        .s_axi_rid    (sdram_rid_int),
        .s_axi_rdata  (sdram_rdata_int),
        .s_axi_rresp  (sdram_rresp_int),
        .s_axi_rlast  (sdram_rlast_int),
        .s_axi_rvalid (sdram_rvalid_int),
        .s_axi_rready (s_axi_rready),
        .dbg_we       (sdram_dbg_we),
        .dbg_addr     (sdram_dbg_addr),
        .dbg_wdata    (sdram_dbg_wdata),
        .dbg_re       (sdram_dbg_re),
        .dbg_rdata    (sdram_dbg_rdata)
    );

    // --------------------------------------------------------------------
    // DMA master stub (AXI master on same memory bus)
    axi_dma_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4)
    ) u_dma (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (dma_start_pulse),
        .src_addr      ({4'd0, dma_src[27:0]}),
        .dst_addr      ({4'd0, dma_dst[27:0]}),
        .len_bytes     (dma_len),
        .busy          (dma_busy),
        .done          (dma_done),

        .m_axi_awid    (m1_awid),
        .m_axi_awaddr  (m1_awaddr),
        .m_axi_awlen   (m1_awlen),
        .m_axi_awsize  (m1_awsize),
        .m_axi_awburst (m1_awburst),
        .m_axi_awvalid (m1_awvalid),
        .m_axi_awready (sdram_awready_int),

        .m_axi_wdata   (m1_wdata),
        .m_axi_wstrb   (m1_wstrb),
        .m_axi_wlast   (m1_wlast),
        .m_axi_wvalid  (m1_wvalid),
        .m_axi_wready  (sdram_wready_int),

        .m_axi_bid     (sdram_bid_int),
        .m_axi_bresp   (sdram_bresp_int),
        .m_axi_bvalid  (sdram_bvalid_int),
        .m_axi_bready  (m1_bready),

        .m_axi_arid    (m1_arid),
        .m_axi_araddr  (m1_araddr),
        .m_axi_arlen   (m1_arlen),
        .m_axi_arsize  (m1_arsize),
        .m_axi_arburst (m1_arburst),
        .m_axi_arvalid (m1_arvalid),
        .m_axi_arready (sdram_arready_int),

        .m_axi_rid     (sdram_rid_int),
        .m_axi_rdata   (sdram_rdata_int),
        .m_axi_rresp   (sdram_rresp_int),
        .m_axi_rlast   (sdram_rlast_int),
        .m_axi_rvalid  (sdram_rvalid_int),
        .m_axi_rready  (m1_rready)
    );

    // Voxel framebuffer + AXI-Stream bridge (HDMI placeholder)
    // --------------------------------------------------------------------
    wire         pixel_write_en;
    wire [31:0]  pixel_addr;
    wire [31:0]  pixel_word0, pixel_word1, pixel_word2;
    wire         frame_done;
    wire         core_busy;

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
        .dbg_ext_write_en  (dbg_we_pulse | ext_dbg_we),
        .dbg_ext_write_addr(ext_dbg_we ? ext_dbg_addr : dbg_addr),
        .dbg_ext_write_data(ext_dbg_we ? ext_dbg_data : dbg_wdata),
        .start_frame_ext (start_frame_pulse),
        .soft_reset_ext  (soft_reset_pulse)
    );

    localparam integer TOTAL_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;

    assign s_axis_tdata  = pixel_word1[23:0]; // RGB
    assign s_axis_tvalid = pixel_write_en;
    assign s_axis_tuser  = (pixel_addr == 0);
    assign s_axis_tlast  = (pixel_addr == TOTAL_PIXELS-1);

    axi_stream_sink_stub #(
        .DATA_WIDTH(24)
    ) u_sink (
        .clk            (clk),
        .rst_n          (rst_n),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tuser   (s_axis_tuser),
        .s_axis_tready  (s_axis_tready),
        .beat_count     (hdmi_beat_count),
        .frame_count    (hdmi_frame_count),
        .frame_crc      (),
        .last_frame_crc (hdmi_crc_last),
        .line_count     (hdmi_line_count),
        .pixel_in_line  (hdmi_pixel_in_line)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_out_d <= 1'b0;
        else
            irq_out_d <= irq_out;
    end

endmodule
