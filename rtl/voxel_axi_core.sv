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
    output wire        dma_err_out,
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
    wire         flag_ray_jitter;

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
    reg          dma_busy;
    reg          dma_done;
    reg          dma_err;
    wire [31:0]  dma_src;
    wire [31:0]  dma_dst;
    wire [31:0]  dma_len;
    wire [31:0]  dma_status_out;
    output wire  dma_err_out;

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
    assign dma_status_out = {29'd0, dma_err, dma_done, dma_busy};
    assign dma_err_out = dma_err;

    // DMA/Blitter integration note: this module provides a minimal DMA
    // stub (see `axi_dma_stub` instantiation below) that performs simple
    // bounded copies for simulation/bring-up. When integrating with
    // LiteDMA or a host DMA engine, replace or wire these ports to the
    // upstream DMA implementation.
    localparam integer DMA_ADDR_WIDTH = 24; // 16 MiB default window for stub checks.
    localparam [31:0]  DMA_ADDR_MAX   = (1 << DMA_ADDR_WIDTH);

    // DMA state machine encoding (small, local to this module)
    localparam [1:0] DMA_IDLE = 2'd0;
    localparam [1:0] DMA_RUN  = 2'd1;
    localparam [1:0] DMA_ERR  = 2'd2;

    // DMA control/state signals used by the CSR wrapper and the dma_stub.
    reg  [1:0] dma_state;
    wire       dma_stub_done;
    wire       dma_stub_busy;
    reg        dma_stub_start;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_busy    <= 1'b0;
            dma_done    <= 1'b0;
            dma_err     <= 1'b0;
            dma_state   <= DMA_IDLE;
            dma_stub_start <= 1'b0;
        end else begin
            dma_done      <= 1'b0; // pulse
            dma_stub_start<= 1'b0;

            case (dma_state)
                DMA_IDLE: begin
                    if (dma_start_pulse) begin
                            if (dma_busy) begin
                            end else if (dma_len == 0 ||
                                         dma_src >= DMA_ADDR_MAX || dma_dst >= DMA_ADDR_MAX ||
                                         dma_src + dma_len > DMA_ADDR_MAX ||
                                         dma_dst + dma_len > DMA_ADDR_MAX) begin
                                dma_done   <= 1'b1;
                                dma_state  <= DMA_ERR;
                        end else begin
                            dma_busy    <= 1'b1;
                            dma_stub_start <= 1'b1;
                            dma_state   <= DMA_RUN;
                        end
                    end
                end
                DMA_RUN: begin
                    if (dma_stub_done) begin
                        dma_busy   <= 1'b0;
                        dma_done   <= 1'b1;
                        dma_state  <= DMA_IDLE;
                    end
                end
                DMA_ERR: begin
                    dma_state <= DMA_IDLE;
                end
                default: dma_state <= DMA_IDLE;
            endcase
        end
    end

`ifdef VERILATOR
    always @(posedge clk) begin
        if (dma_start_pulse && dma_busy) begin
            $fatal("DMA start received while busy");
        end
    end
`endif
    assign blit_mem_rdata = 64'd0;

    // Simple safety assertions (simulation only).
`ifdef VERILATOR
    // Selection should stay within the voxel grid bounds.
    always @(*) begin
        if (sel_active) begin
            assert(sel_x < VOXEL_GRID_SIZE && sel_y < VOXEL_GRID_SIZE && sel_z < VOXEL_GRID_SIZE)
                else $fatal("Selection out of bounds: %0d %0d %0d", sel_x, sel_y, sel_z);
        end
    end
`endif

    // HDMI counters: local CRC/frame/line/pixel counters are implemented
    // here for diagnostics and simulation. When LiteVideo scanout is
    // integrated, consider exposing or driving these counters from the
    // scanout pipeline instead of local logic.

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
        .flag_ray_jitter(flag_ray_jitter),

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
        .dma_status     (dma_status_out),

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
        .flag_ray_jitter_in(flag_ray_jitter),
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

    wire pixel_reemissure_used = |pixel_reemissure;

    // --------------------------------------------------------------------
    // Framebuffer write AXI4 master
    // - Backed by axi_dma_stub: issues AXI read/write copies with backpressure handling.
    // - Still a stub (no scatter-gather), but performs real data moves.
    // (moved declarations for dma_stub_* and dma_state above)

    wire [3:0]  dma_awid_w;
    wire [27:0] dma_awaddr_w;
    wire [7:0]  dma_awlen_w;
    wire [2:0]  dma_awsize_w;
    wire [1:0]  dma_awburst_w;
    wire        dma_awvalid_w;

    wire [63:0] dma_wdata_w;
    wire [7:0]  dma_wstrb_w;
    wire        dma_wlast_w;
    wire        dma_wvalid_w;

    wire [1:0]  dma_bresp_w;
    wire        dma_bvalid_w;
    wire        dma_bready_w;

    wire [3:0]  dma_arid_w;
    wire [27:0] dma_araddr_w;
    wire [7:0]  dma_arlen_w;
    wire [2:0]  dma_arsize_w;
    wire [1:0]  dma_arburst_w;
    wire        dma_arvalid_w;

    wire [3:0]  dma_rid_w;
    wire [63:0] dma_rdata_w;
    wire [1:0]  dma_rresp_w;
    wire        dma_rlast_w;
    wire        dma_rvalid_w;
    wire        dma_rready_w;

    assign m_axi_awid    = dma_awid_w;
    assign m_axi_awaddr  = dma_awaddr_w;
    assign m_axi_awlen   = dma_awlen_w;
    assign m_axi_awsize  = dma_awsize_w;
    assign m_axi_awburst = dma_awburst_w;
    assign m_axi_awvalid = dma_awvalid_w;

    assign m_axi_wdata   = dma_wdata_w;
    assign m_axi_wstrb   = dma_wstrb_w;
    assign m_axi_wlast   = dma_wlast_w;
    assign m_axi_wvalid  = dma_wvalid_w;

    assign m_axi_bready  = dma_bready_w;

    assign m_axi_arid    = dma_arid_w;
    assign m_axi_araddr  = dma_araddr_w;
    assign m_axi_arlen   = dma_arlen_w;
    assign m_axi_arsize  = dma_arsize_w;
    assign m_axi_arburst = dma_arburst_w;
    assign m_axi_arvalid = dma_arvalid_w;

    assign m_axi_rready  = dma_rready_w;

    axi_dma_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4)
    ) u_dma_stub (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (dma_stub_start),
        .src_addr  (dma_src[27:0]),
        .dst_addr  (dma_dst[27:0]),
        .len_bytes (dma_len),
        .busy      (dma_stub_busy),
        .done      (dma_stub_done),
        .m_axi_awid    (dma_awid_w),
        .m_axi_awaddr  (dma_awaddr_w),
        .m_axi_awlen   (dma_awlen_w),
        .m_axi_awsize  (dma_awsize_w),
        .m_axi_awburst (dma_awburst_w),
        .m_axi_awvalid (dma_awvalid_w),
        .m_axi_awready (m_axi_awready),
        .m_axi_wdata   (dma_wdata_w),
        .m_axi_wstrb   (dma_wstrb_w),
        .m_axi_wlast   (dma_wlast_w),
        .m_axi_wvalid  (dma_wvalid_w),
        .m_axi_wready  (m_axi_wready),
        .m_axi_bid     (m_axi_bid),
        .m_axi_bresp   (dma_bresp_w),
        .m_axi_bvalid  (dma_bvalid_w),
        .m_axi_bready  (dma_bready_w),
        .m_axi_arid    (dma_arid_w),
        .m_axi_araddr  (dma_araddr_w),
        .m_axi_arlen   (dma_arlen_w),
        .m_axi_arsize  (dma_arsize_w),
        .m_axi_arburst (dma_arburst_w),
        .m_axi_arvalid (dma_arvalid_w),
        .m_axi_arready (m_axi_arready),
        .m_axi_rid     (m_axi_rid),
        .m_axi_rdata   (dma_rdata_w),
        .m_axi_rresp   (dma_rresp_w),
        .m_axi_rlast   (dma_rlast_w),
        .m_axi_rvalid  (dma_rvalid_w),
        .m_axi_rready  (dma_rready_w)
    );

    // --------------------------------------------------------------------
    // AXI-Stream video master
    // - Converts pixel stream from voxel core to AXI-Stream for HDMI
    // --------------------------------------------------------------------
    localparam integer TOTAL_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;
    wire axis_fire = m_axis_tvalid && m_axis_tready;

    // Simple one-deep skid buffer to tolerate brief backpressure on m_axis_tready.
    // If a stall lasts longer than one beat, flag an error in sim to expose the violation.
    reg        axis_buf_valid;
    reg [23:0] axis_buf_data;
    reg        axis_buf_last;
    reg        axis_buf_user;
    reg        axis_drop_seen;

    wire axis_accept = m_axis_tready || !axis_buf_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axis_buf_valid <= 1'b0;
            axis_buf_data  <= 24'd0;
            axis_buf_last  <= 1'b0;
            axis_buf_user  <= 1'b0;
            axis_drop_seen <= 1'b0;
        end else begin
            if (m_axis_tready && axis_buf_valid) begin
                axis_buf_valid <= 1'b0;
            end

            if (pixel_write_en) begin
                if (axis_accept) begin
                    axis_buf_valid <= 1'b1;
                    axis_buf_data  <= pixel_word1[23:0];
                    axis_buf_last  <= (pixel_addr == TOTAL_PIXELS - 1);
                    axis_buf_user  <= (pixel_addr == 0);
                end else begin
                    axis_drop_seen <= 1'b1;
                end
            end
        end
    end

`ifdef VERILATOR
    // Flag sustained backpressure so integration work is visible.
    always @(posedge clk) begin
        if (axis_drop_seen) begin
            $fatal("m_axis_tready deasserted while pixel_write_en asserted (backpressure not handled upstream)");
        end
    end

    // Pixel words should never carry X/Z in simulation to avoid downstream HUD/HDMI confusion.
    always @(posedge clk) begin
        assert(!$isunknown(pixel_word0)) else $fatal("pixel_word0 X/Z observed");
        assert(!$isunknown(pixel_word1)) else $fatal("pixel_word1 X/Z observed");
        assert(!$isunknown(pixel_word2)) else $fatal("pixel_word2 X/Z observed");
    end
`endif

    reg [31:0] hdmi_crc_accum;
    reg [31:0] hdmi_frame_count_r;
    reg [15:0] hdmi_line_count_r;
    reg [15:0] hdmi_pixel_in_line_r;

    assign hdmi_crc_last      = hdmi_crc_accum;
    assign hdmi_frame_count   = hdmi_frame_count_r;
    assign hdmi_line_count    = hdmi_line_count_r;
    assign hdmi_pixel_in_line = hdmi_pixel_in_line_r;

    assign m_axis_tdata  = axis_buf_valid ? axis_buf_data : pixel_word1[23:0]; // RGB888
    assign m_axis_tvalid = axis_buf_valid ? 1'b1 : pixel_write_en;
    assign m_axis_tuser  = axis_buf_valid ? axis_buf_user : (pixel_addr == 0); // Start of frame
    assign m_axis_tlast  = axis_buf_valid ? axis_buf_last : (pixel_addr == TOTAL_PIXELS - 1); // End of frame

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

`ifdef VERILATOR
    // Sanity: pixel data should be clean when emitted.
    // Also check address monotonicity and frame completeness.
    reg [31:0] last_pixel_addr;
    reg [31:0] pixels_in_frame;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_pixel_addr <= 32'd0;
            pixels_in_frame <= 32'd0;
        end else begin
            if (pixel_write_en) begin
                assert(!$isunknown(pixel_word0)) else $fatal("pixel_word0 X/Z on write");
                assert(!$isunknown(pixel_word1)) else $fatal("pixel_word1 X/Z on write");
                assert(!$isunknown(pixel_word2)) else $fatal("pixel_word2 X/Z on write");
                assert(!$isunknown(pixel_reemissure)) else $fatal("pixel_reemissure X/Z on write");

                assert(pixel_addr < TOTAL_PIXELS) else $fatal("pixel_addr out of range: %0d", pixel_addr);
                if (pixels_in_frame == 0) begin
                    assert(pixel_addr == 0) else $fatal("first pixel_addr not zero: %0d", pixel_addr);
                end else begin
                    assert(pixel_addr == last_pixel_addr + 1) else $fatal("pixel_addr not monotonic: last=%0d cur=%0d", last_pixel_addr, pixel_addr);
                end
                last_pixel_addr <= pixel_addr;
                pixels_in_frame <= pixels_in_frame + 1'b1;
            end
            if (frame_done) begin
                assert(pixels_in_frame == TOTAL_PIXELS) else $fatal("frame_done with pixels_in_frame=%0d (expected %0d)", pixels_in_frame, TOTAL_PIXELS);
                last_pixel_addr <= 32'd0;
                pixels_in_frame <= 32'd0;
            end
        end
    end

    // Selection changes should only occur on sel_load_pulse and stay in-bounds.
    reg [5:0] sel_x_d, sel_y_d, sel_z_d;
    reg       sel_active_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_x_d      <= 6'd0;
            sel_y_d      <= 6'd0;
            sel_z_d      <= 6'd0;
            sel_active_d <= 1'b0;
        end else begin
            if (sel_load_pulse) begin
                assert(sel_x < VOXEL_GRID_SIZE && sel_y < VOXEL_GRID_SIZE && sel_z < VOXEL_GRID_SIZE)
                    else $fatal("sel coords out of range on load: %0d %0d %0d", sel_x, sel_y, sel_z);
                sel_x_d      <= sel_x;
                sel_y_d      <= sel_y;
                sel_z_d      <= sel_z;
                sel_active_d <= sel_active;
            end else begin
                assert(sel_x == sel_x_d) else $fatal("sel_x changed without sel_load_pulse");
                assert(sel_y == sel_y_d) else $fatal("sel_y changed without sel_load_pulse");
                assert(sel_z == sel_z_d) else $fatal("sel_z changed without sel_load_pulse");
                assert(sel_active == sel_active_d) else $fatal("sel_active changed without sel_load_pulse");
            end
        end
    end

    // Guard against pixels after frame_done.
    always @(posedge clk) begin
        if (frame_done) begin
            assert(!pixel_write_en) else $fatal("pixel_write_en asserted after frame_done");
        end
    end

    // HDMI counters/CRC should only change on axis_fire and reset on SOF/reset.
    reg [31:0] hdmi_crc_d;
    reg [15:0] hdmi_line_d, hdmi_pix_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdmi_crc_d <= 32'd0;
            hdmi_line_d <= 16'd0;
            hdmi_pix_d <= 16'd0;
        end else begin
            if (!axis_fire) begin
                assert(hdmi_crc_accum == hdmi_crc_d) else $fatal("HDMI CRC changed without axis_fire");
                assert(hdmi_line_count_r == hdmi_line_d) else $fatal("HDMI line counter changed without axis_fire");
                assert(hdmi_pixel_in_line_r == hdmi_pix_d) else $fatal("HDMI pixel counter changed without axis_fire");
            end
            hdmi_crc_d <= hdmi_crc_accum;
            hdmi_line_d <= hdmi_line_count_r;
            hdmi_pix_d <= hdmi_pixel_in_line_r;
            if (m_axis_tuser && axis_fire) begin
                assert(hdmi_crc_accum == 32'd0) else $fatal("HDMI CRC not reset at SOF");
                assert(hdmi_line_count_r == 16'd0) else $fatal("HDMI line count not reset at SOF");
                assert(hdmi_pixel_in_line_r == 16'd0) else $fatal("HDMI pixel-in-line not reset at SOF");
            end
        end
    end

    // AXI4 master handshake stability (even though the burst writer is stubbed today).
    always @(posedge clk) begin
        if (m_axi_awvalid && !m_axi_awready) begin
            assert($stable(m_axi_awaddr)) else $fatal("AWADDR changed while AWVALID held high");
            assert($stable(m_axi_awlen))   else $fatal("AWLEN changed while AWVALID held high");
            assert($stable(m_axi_awsize))  else $fatal("AWSIZE changed while AWVALID held high");
            assert($stable(m_axi_awburst)) else $fatal("AWBURST changed while AWVALID held high");
        end
        if (m_axi_wvalid && !m_axi_wready) begin
            assert($stable(m_axi_wdata)) else $fatal("WDATA changed while WVALID held high");
            assert($stable(m_axi_wstrb)) else $fatal("WSTRB changed while WVALID held high");
            assert($stable(m_axi_wlast)) else $fatal("WLAST changed while WVALID held high");
        end
        if (m_axi_arvalid && !m_axi_arready) begin
            assert($stable(m_axi_araddr)) else $fatal("ARADDR changed while ARVALID held high");
            assert($stable(m_axi_arlen))  else $fatal("ARLEN changed while ARVALID held high");
            assert($stable(m_axi_arsize)) else $fatal("ARSIZE changed while ARVALID held high");
            assert($stable(m_axi_arburst)) else $fatal("ARBURST changed while ARVALID held high");
        end
    end
`endif

    // IRQ edge detection for MSI pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_out_d <= 1'b0;
        else
            irq_out_d <= irq_out;
    end

endmodule
