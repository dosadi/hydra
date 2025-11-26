// ============================================================================
// voxel_axil_csr.sv
// - AXI4-Lite CSR block for voxel core control aligned to hydra BAR0 sketch.
// - Provides camera, flags, selection, DMA stub control, debug writes, status,
//   and simple interrupt aggregation.
// ============================================================================
`timescale 1ns/1ps

module voxel_axil_csr #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32,
    parameter [15:0]  VENDOR_ID  = 16'h1BAD,
    parameter [15:0]  DEVICE_ID  = 16'h2024,
    parameter [7:0]   REV_ID     = 8'h02,
    parameter [7:0]   BUILD_ID   = 8'h01
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // AXI-Lite slave
    input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
    input  wire                     s_axil_awvalid,
    output reg                      s_axil_awready,
    input  wire [DATA_WIDTH-1:0]    s_axil_wdata,
    input  wire [(DATA_WIDTH/8)-1:0]s_axil_wstrb,
    input  wire                     s_axil_wvalid,
    output reg                      s_axil_wready,
    output reg  [1:0]               s_axil_bresp,
    output reg                      s_axil_bvalid,
    input  wire                     s_axil_bready,
    input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
    input  wire                     s_axil_arvalid,
    output reg                      s_axil_arready,
    output reg [DATA_WIDTH-1:0]     s_axil_rdata,
    output reg [1:0]                s_axil_rresp,
    output reg                      s_axil_rvalid,
    input  wire                     s_axil_rready,

    // Camera outputs (signed 16-bit)
    output reg                      cam_load_pulse,
    output reg signed [15:0]        cam_x,
    output reg signed [15:0]        cam_y,
    output reg signed [15:0]        cam_z,
    output reg signed [15:0]        cam_dir_x,
    output reg signed [15:0]        cam_dir_y,
    output reg signed [15:0]        cam_dir_z,
    output reg signed [15:0]        cam_plane_x,
    output reg signed [15:0]        cam_plane_y,

    // Flags
    output reg                      flags_load_pulse,
    output reg                      flag_smooth,
    output reg                      flag_curvature,
    output reg                      flag_extra_light,
    output reg                      flag_diag_slice,
    output reg                      flag_ray_jitter,

    // Selection
    output reg                      sel_load_pulse,
    output reg                      sel_active,
    output reg [5:0]                sel_x,
    output reg [5:0]                sel_y,
    output reg [5:0]                sel_z,

    // Debug BRAM write (voxel mem)
    output reg                      dbg_we_pulse,
    output reg [17:0]               dbg_addr,
    output reg [63:0]               dbg_wdata,

    // Core status inputs
    input  wire                     frame_done_pulse,
    input  wire                     core_busy,

    // Control pulses derived from CTRL register
    output reg                      soft_reset_pulse,
    output reg                      start_frame_pulse,

    // Simple DMA stub control
    output reg                      dma_start_pulse,
    input  wire                     dma_busy_in,
    input  wire                     dma_done_in,
    output reg [31:0]               dma_src,
    output reg [31:0]               dma_dst,
    output reg [31:0]               dma_len,
    output reg [31:0]               dma_status, // bit0=done sticky, bit1=busy

    // Blitter memory debug path (to SDRAM stub)
    output reg                      blit_mem_we,
    output reg                      blit_mem_re,
    output reg [27:0]               blit_mem_addr,
    output reg [63:0]               blit_mem_wdata,
    input  wire [63:0]              blit_mem_rdata,
    input  wire [31:0]              hdmi_crc_in,
    input  wire [31:0]              hdmi_frames_in,
    input  wire [15:0]              hdmi_line_in,
    input  wire [15:0]              hdmi_pix_in,

    // Interrupt out (level)
    output wire                     irq_out
);

    localparam [1:0] RESP_OKAY = 2'b00;

    // Register/state shadows
    reg [31:0] ctrl_shadow;
    reg [31:0] int_status;
    reg [31:0] int_mask;
    reg        frame_done_latched;
    reg [31:0] fb_base;
    reg [31:0] fb_stride;
    reg [31:0] dbg_data_lo;
    reg [31:0] dbg_data_hi;
    reg [17:0] dbg_addr_reg;
    reg        dma_done_d;
    reg        soft_reset_req;
    reg [31:0] blit_ctrl;
    reg [31:0] blit_status;
    reg [31:0] blit_src;
    reg [31:0] blit_dst;
    reg [31:0] blit_len;
    reg [31:0] blit_stride;
    reg [31:0] surf_base;
    reg [31:0] surf_len;
    reg [31:0] surf_stats;
    reg [15:0] blit_pix_addr;
    reg [31:0] blit_pix_data;
    reg [5:0]  blit_obj_idx;
    reg [31:0] blit_obj_attr;
    reg        blit_busy;
    reg        blit_done;
    reg [31:0] blit_counter;
    reg [15:0] blit_idx;
    reg [3:0]  blit_fifo_wr;
    reg [3:0]  blit_fifo_rd;
    reg [4:0]  blit_fifo_count;
    reg [31:0] blit_fifo_data_out;

    reg [31:0] blit_pix_mem [0:1023];
    reg [31:0] blit_obj_mem [0:63];
    reg [31:0] blit_fifo_mem[0:15];

    wire [ADDR_WIDTH-1:0] awaddr_aligned = {s_axil_awaddr[ADDR_WIDTH-1:2], 2'b00};
    wire [ADDR_WIDTH-1:0] araddr_aligned = {s_axil_araddr[ADDR_WIDTH-1:2], 2'b00};
    wire [31:0] aw_word = awaddr_aligned >> 2; // 256B window (word addressed)
    wire [31:0] ar_word = araddr_aligned >> 2;
    wire [2:0] blit_op = blit_ctrl[5:3];

    function automatic [31:0] merge_wstrb(input [31:0] cur,
                                          input [31:0] wdata,
                                          input [3:0]  wstrb);
        integer j;
        begin
            merge_wstrb = cur;
            for (j = 0; j < 4; j = j + 1) begin
                if (wstrb[j])
                    merge_wstrb[8*j +: 8] = wdata[8*j +: 8];
            end
        end
    endfunction

    function automatic [31:0] pack_s16(input signed [15:0] v);
        begin
            pack_s16 = { {16{v[15]}}, v };
        end
    endfunction

    // BAR0 word offsets (offset >> 2)
    localparam integer W_ID         = 32'h00000000; // 0x0000
    localparam integer W_REV        = 32'h00000001; // 0x0004
    localparam integer W_CTRL       = 32'h00000004; // 0x0010
    localparam integer W_STATUS     = 32'h00000005; // 0x0014
    localparam integer W_INT_STATUS = 32'h00000020; // 0x0080
    localparam integer W_INT_MASK   = 32'h00000021; // 0x0084
    localparam integer W_CAM_X      = 32'h00000008; // 0x0020
    localparam integer W_CAM_Y      = 32'h00000009; // 0x0024
    localparam integer W_CAM_Z      = 32'h0000000A; // 0x0028
    localparam integer W_CAM_DIR_X  = 32'h0000000B; // 0x002C
    localparam integer W_CAM_DIR_Y  = 32'h0000000C; // 0x0030
    localparam integer W_CAM_DIR_Z  = 32'h0000000D; // 0x0034
    localparam integer W_CAM_PLANE_X= 32'h0000000E; // 0x0038
    localparam integer W_CAM_PLANE_Y= 32'h0000000F; // 0x003C
    localparam integer W_FLAGS      = 32'h00000010; // 0x0040
    localparam integer W_SEL_ACTIVE = 32'h00000011; // 0x0044
    localparam integer W_SEL_X      = 32'h00000012; // 0x0048
    localparam integer W_SEL_Y      = 32'h00000013; // 0x004C
    localparam integer W_SEL_Z      = 32'h00000014; // 0x0050
    localparam integer W_FB_BASE    = 32'h00000015; // 0x0054
    localparam integer W_FB_STRIDE  = 32'h00000016; // 0x0058

    localparam integer W_DMA_SRC    = 32'h00000018; // 0x0060
    localparam integer W_DMA_DST    = 32'h00000019; // 0x0064
    localparam integer W_DMA_LEN    = 32'h0000001A; // 0x0068
    localparam integer W_DMA_CTRL   = 32'h0000001B; // 0x006C
    localparam integer W_DMA_STATUS = 32'h0000001C; // 0x0070
    localparam integer W_IRQ_TEST   = 32'h00000022; // 0x0088

    localparam integer W_DBG_ADDR   = 32'h00000028; // 0x00A0
    localparam integer W_DBG_DATA_L = 32'h00000029; // 0x00A4
    localparam integer W_DBG_DATA_H = 32'h0000002A; // 0x00A8
    localparam integer W_DBG_CTRL   = 32'h0000002B; // 0x00AC
    localparam integer W_HDMI_CRC   = 32'h0000002C; // 0x00B0
    localparam integer W_HDMI_FR    = 32'h0000002D; // 0x00B4
    localparam integer W_HDMI_LINE  = 32'h0000002E; // 0x00B8
    localparam integer W_HDMI_PIX   = 32'h0000002F; // 0x00BC

    // 3D blitter stub (0x0100 region)
    localparam integer W_BLIT_CTRL      = 32'h00000040; // 0x0100
    localparam integer W_BLIT_STATUS    = 32'h00000041; // 0x0104
    localparam integer W_BLIT_SRC       = 32'h00000042; // 0x0108
    localparam integer W_BLIT_DST       = 32'h00000043; // 0x010C
    localparam integer W_BLIT_LEN       = 32'h00000044; // 0x0110
    localparam integer W_BLIT_STRIDE    = 32'h00000045; // 0x0114
    localparam integer W_SURF_BASE      = 32'h00000046; // 0x0118
    localparam integer W_SURF_LEN       = 32'h00000047; // 0x011C
    localparam integer W_BLIT_PIX_ADDR  = 32'h00000048; // 0x0120
    localparam integer W_BLIT_PIX_DATA  = 32'h00000049; // 0x0124
    localparam integer W_BLIT_PIX_CMD   = 32'h0000004A; // 0x0128
    localparam integer W_BLIT_OBJ_IDX   = 32'h0000004C; // 0x0130
    localparam integer W_BLIT_OBJ_ATTR  = 32'h0000004D; // 0x0134
    localparam integer W_SURF_STATS     = 32'h0000004E; // 0x0138
    localparam integer W_BLIT_FIFO_DATA = 32'h00000050; // 0x0140
    localparam integer W_BLIT_FIFO_STATUS = 32'h00000051; // 0x0144

    // Automatic region-0 extractor (0x0150 region)
    localparam integer W_REGION0_CFG        = 32'h00000054; // 0x0150
    localparam integer W_REGION0_MIN        = 32'h00000055; // 0x0154
    localparam integer W_REGION0_MAX        = 32'h00000056; // 0x0158
    localparam integer W_REGION0_STATUS     = 32'h00000057; // 0x015C
    localparam integer W_REGION0_SURF_STATS = 32'h00000058; // 0x0160

    assign irq_out  = |(int_status & int_mask);

    wire dma_done_pulse = dma_done_in & ~dma_done_d;
    wire dma_busy_fall  = dma_busy_d  & ~dma_busy_in;
    wire status_read    = s_axil_arready && s_axil_arvalid && !s_axil_rvalid && (ar_word == W_STATUS);
    wire [31:0] status_word = {26'd0, blit_done, blit_busy, dma_status[0], dma_status[1], frame_done_latched, core_busy};

    integer pi;
    integer oi;
    integer fi;

    // Automatic region-0 surface extractor (experimental)
    reg [31:0] region0_cfg;
    reg [31:0] region0_min;
    reg [31:0] region0_max;
    reg [31:0] region0_status;
    reg [31:0] region0_surf_stats;
    reg [31:0] region0_counter;
    reg [1:0]  region0_state;
    reg        dma_busy_d;

    localparam [1:0] REGION0_IDLE = 2'd0;
    localparam [1:0] REGION0_RUN  = 2'd1;

    // Write channel and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bresp   <= RESP_OKAY;
            s_axil_bvalid  <= 1'b0;
            s_axil_arready <= 1'b0;
            s_axil_rdata   <= 32'd0;
            s_axil_rresp   <= RESP_OKAY;
            s_axil_rvalid  <= 1'b0;

            cam_load_pulse   <= 1'b0;
            flags_load_pulse <= 1'b0;
            sel_load_pulse   <= 1'b0;
            dbg_we_pulse     <= 1'b0;
            soft_reset_pulse <= 1'b0;
            start_frame_pulse<= 1'b0;
            dma_start_pulse  <= 1'b0;

            cam_x <= 16'sd0;
            cam_y <= 16'sd0;
            cam_z <= 16'sd0;
            cam_dir_x   <= 16'sd0;
            cam_dir_y   <= 16'sd0;
            cam_dir_z   <= 16'sd0;
            cam_plane_x <= 16'sd0;
            cam_plane_y <= 16'sd0;

            flag_smooth      <= 1'b1;
            flag_curvature   <= 1'b1;
            flag_extra_light <= 1'b0;
            flag_diag_slice  <= 1'b0;
            flag_ray_jitter  <= 1'b0;

            sel_active <= 1'b0;
            sel_x <= 6'd0;
            sel_y <= 6'd0;
            sel_z <= 6'd0;
            dbg_addr  <= 18'd0;
            dbg_wdata <= 64'd0;

            ctrl_shadow        <= 32'd0;
            int_status         <= 32'd0;
            int_mask           <= 32'd0;
            frame_done_latched <= 1'b0;
            region0_cfg        <= 32'd0;
            region0_min        <= 32'd0;
            region0_max        <= 32'd0;
            region0_status     <= 32'd0;
            region0_surf_stats <= 32'd0;
            region0_counter    <= 32'd0;
            region0_state      <= REGION0_IDLE;
            fb_base            <= 32'd0;
            fb_stride          <= 32'd0;
            dbg_data_lo        <= 32'd0;
            dbg_data_hi        <= 32'd0;
            dbg_addr_reg       <= 18'd0;
            dma_src            <= 32'd0;
            dma_dst            <= 32'd0;
            dma_len            <= 32'd0;
            dma_status         <= 32'd0;
            dma_done_d         <= 1'b0;
            soft_reset_req     <= 1'b0;
            blit_ctrl          <= 32'd0;
            blit_status        <= 32'd0;
            blit_src           <= 32'd0;
            blit_dst           <= 32'd0;
            blit_len           <= 32'd0;
            blit_stride        <= 32'd0;
            surf_base          <= 32'd0;
            surf_len           <= 32'd0;
            surf_stats         <= 32'd0;
            blit_pix_addr      <= 16'd0;
            blit_pix_data      <= 32'd0;
            blit_obj_idx       <= 6'd0;
            blit_obj_attr      <= 32'd0;
            blit_busy          <= 1'b0;
            blit_done          <= 1'b0;
            blit_counter       <= 32'd0;
            blit_idx           <= 16'd0;
            blit_fifo_wr       <= 4'd0;
            blit_fifo_rd       <= 4'd0;
            blit_fifo_count    <= 5'd0;
            blit_fifo_data_out <= 32'd0;
            blit_mem_we       <= 1'b0;
            blit_mem_re       <= 1'b0;
            blit_mem_addr     <= 28'd0;
            blit_mem_wdata    <= 64'd0;
            dma_busy_d         <= 1'b0;
            for (pi = 0; pi < 1024; pi = pi + 1)
                blit_pix_mem[pi] = 32'd0;
            for (oi = 0; oi < 64; oi = oi + 1)
                blit_obj_mem[oi] = 32'd0;
            for (fi = 0; fi < 16; fi = fi + 1)
                blit_fifo_mem[fi] = 32'd0;
        end else begin
            cam_load_pulse    <= 1'b0;
            flags_load_pulse  <= 1'b0;
            sel_load_pulse    <= 1'b0;
            dbg_we_pulse      <= 1'b0;
            soft_reset_pulse  <= 1'b0;
            start_frame_pulse <= 1'b0;
            dma_start_pulse   <= 1'b0;
            blit_mem_we       <= 1'b0;
            blit_mem_re       <= 1'b0;
            blit_mem_we       <= 1'b0;
            blit_mem_re       <= 1'b0;

            if (status_read)
                frame_done_latched <= 1'b0;

            // Honor deferred soft reset requests
            if (soft_reset_req) begin
                soft_reset_req     <= 1'b0;
                frame_done_latched <= 1'b0;
                int_status         <= 32'd0;
                dma_status         <= 32'd0;
                flag_extra_light   <= 1'b0;
                flag_diag_slice    <= 1'b0;
                flag_ray_jitter    <= 1'b0;
                flag_smooth        <= 1'b1;
                flag_curvature     <= 1'b1;
                ctrl_shadow[3:2]   <= 2'b00;
                blit_ctrl          <= 32'd0;
                blit_status        <= 32'd0;
                blit_src           <= 32'd0;
                blit_dst           <= 32'd0;
                blit_len           <= 32'd0;
                blit_stride        <= 32'd0;
                surf_base          <= 32'd0;
                surf_len           <= 32'd0;
                surf_stats         <= 32'd0;
                blit_pix_addr      <= 16'd0;
                blit_pix_data      <= 32'd0;
                blit_obj_idx       <= 6'd0;
                blit_obj_attr      <= 32'd0;
                blit_busy          <= 1'b0;
                blit_done          <= 1'b0;
                blit_counter       <= 32'd0;
                blit_idx           <= 16'd0;
                blit_fifo_wr       <= 4'd0;
                blit_fifo_rd       <= 4'd0;
                blit_fifo_count    <= 5'd0;
                blit_mem_we        <= 1'b0;
                blit_mem_re        <= 1'b0;
            end

            // Event capture
            dma_status[1] <= dma_busy_in;
            dma_done_d    <= dma_done_in;
            dma_busy_d    <= dma_busy_in;
            if (frame_done_pulse)
                frame_done_latched <= 1'b1;
            if (frame_done_pulse)
                int_status[0] <= 1'b1; // frame done
            if (dma_done_pulse || dma_busy_fall) begin
                int_status[1] <= 1'b1; // dma done
                dma_status[0] <= 1'b1;
            end
            blit_status[0] <= blit_busy;
            blit_status[1] <= blit_done;
            blit_status[2] <= (blit_fifo_count == 0);
            blit_status[3] <= (blit_fifo_count == 16);

            // Region-0 auto extractor stub: simple delay then synthesized stats.
            case (region0_state)
                REGION0_IDLE: begin
                    region0_status[0] <= 1'b0;
                    if (region0_cfg[0] && region0_cfg[1]) begin
                        region0_state     <= REGION0_RUN;
                        region0_status[0] <= 1'b1; // busy
                        region0_status[1] <= 1'b0; // valid clear
                        region0_counter   <= 32'd64;
                        int_status[5]     <= 1'b0;
                    end
                end
                REGION0_RUN: begin
                    region0_status[0] <= 1'b1;
                    if (region0_counter != 0) begin
                        region0_counter <= region0_counter - 1'b1;
                    end else begin
                        reg [11:0] voxels_stub;
                        reg [11:0] patches_stub;
                        voxels_stub  = (region0_max[11:0] ^ region0_min[11:0]) + 12'd16;
                        if (voxels_stub == 0)
                            voxels_stub = 12'd16;
                        patches_stub = (voxels_stub >> 4);
                        if (patches_stub == 0)
                            patches_stub = 12'd2;

                        region0_status[0]  <= 1'b0;
                        region0_status[1]  <= 1'b1; // valid/done
                        region0_state      <= REGION0_IDLE;
                        region0_cfg[1]     <= 1'b0; // auto-clear kick bit
                        region0_surf_stats <= {8'd0, patches_stub, voxels_stub};
                        int_status[5]      <= 1'b1;
                    end
                end
                default: begin
                    region0_state  <= REGION0_IDLE;
                    region0_status <= 32'd0;
                end
            endcase

            // AXI-Lite write: simple, always-ready single-beat model for simulation.
            s_axil_awready <= 1'b1;
            s_axil_wready  <= 1'b1;

            if (s_axil_awvalid && s_axil_wvalid) begin
                `ifdef CSR_DEBUG
                    $display("CSR: write aw_word=0x%02h addr=0x%04h data=0x%08x", aw_word, awaddr_aligned, s_axil_wdata);
                `endif
                case (aw_word)
                    W_CTRL: begin
                        ctrl_shadow <= merge_wstrb(ctrl_shadow, s_axil_wdata, s_axil_wstrb);
                        if (s_axil_wdata[0]) begin
                            soft_reset_pulse <= 1'b1;
                            soft_reset_req   <= 1'b1;
                        end
                        if (s_axil_wdata[1]) begin
                            start_frame_pulse  <= 1'b1;
                            frame_done_latched <= 1'b0;
                            int_status[0]      <= 1'b0;
                        end
                        if (s_axil_wdata[2] | s_axil_wdata[3]) begin
                            flag_diag_slice  <= s_axil_wdata[2];
                            flag_extra_light <= s_axil_wdata[3];
                            flags_load_pulse <= 1'b1;
                            ctrl_shadow[3:2] <= s_axil_wdata[3:2];
                        end
                    end
                    W_CAM_X:       begin cam_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_Y:       begin cam_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_Z:       begin cam_z <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_X:   begin cam_dir_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_Y:   begin cam_dir_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_Z:   begin cam_dir_z <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_PLANE_X: begin cam_plane_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_PLANE_Y: begin cam_plane_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_FLAGS: begin
                        flag_smooth      <= s_axil_wdata[0];
                        flag_curvature   <= s_axil_wdata[1];
                        flag_extra_light <= s_axil_wdata[2];
                        flag_diag_slice  <= s_axil_wdata[3];
                        flag_ray_jitter  <= s_axil_wdata[4];
                        flags_load_pulse <= 1'b1;
                        ctrl_shadow[3:2] <= s_axil_wdata[3:2];
                    end
                    W_SEL_ACTIVE: begin sel_active <= s_axil_wdata[0]; sel_load_pulse <= 1'b1; end
                    W_SEL_X:      begin sel_x      <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_SEL_Y:      begin sel_y      <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_SEL_Z:      begin sel_z      <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_FB_BASE:    fb_base   <= merge_wstrb(fb_base,   s_axil_wdata, s_axil_wstrb);
                    W_FB_STRIDE:  fb_stride <= merge_wstrb(fb_stride, s_axil_wdata, s_axil_wstrb);
                    W_DMA_SRC:    dma_src   <= merge_wstrb(dma_src,   s_axil_wdata, s_axil_wstrb);
                    W_DMA_DST:    dma_dst   <= merge_wstrb(dma_dst,   s_axil_wdata, s_axil_wstrb);
                    W_DMA_LEN:    dma_len   <= merge_wstrb(dma_len,   s_axil_wdata, s_axil_wstrb);
                    W_DMA_CTRL: begin
                        if (s_axil_wdata[0]) begin
                            `ifdef CSR_DEBUG
                                $display("CSR: DMA_CTRL write @0x%04h src=0x%08x dst=0x%08x len=0x%08x busy_in=%0b", awaddr_aligned, dma_src, dma_dst, dma_len, dma_busy_in);
                            `endif
                            // Require 8-byte alignment on SRC/DST/LEN; flag DMA_ERR on violation.
                            if (dma_src[2:0] != 3'b000 || dma_dst[2:0] != 3'b000 || dma_len[2:0] != 3'b000) begin
                                dma_status[2] <= 1'b1; // err
                                dma_status[0] <= 1'b0; // clear done
                                int_status[2] <= 1'b1; // HYDRA_INT_DMA_ERR
                            end else begin
                                dma_start_pulse <= 1'b1;
                                dma_status[0]   <= 1'b0; // clear done
                                dma_status[2]   <= 1'b0; // clear err
                            end
                        end
                    end
                    W_DMA_STATUS: begin
                        // W1C for done (bit0) and err (bit2); busy (bit1) is read-only mirror of dma_busy_in.
                        if (s_axil_wdata[0])
                            dma_status[0] <= 1'b0; // clear done
                        if (s_axil_wdata[2])
                            dma_status[2] <= 1'b0; // clear err
                    end
                    W_INT_STATUS: begin
                        int_status <= int_status & ~s_axil_wdata; // w1c
                        if (s_axil_wdata[5]) begin
                            region0_status[1] <= 1'b0;
                        end
                    end
                    W_INT_MASK:   int_mask   <= s_axil_wdata;
                    W_IRQ_TEST: begin
                        if (s_axil_wdata[0])
                            int_status[3] <= 1'b1;
                    end
                    W_DBG_ADDR: begin
                        dbg_addr     <= s_axil_wdata[17:0];
                        dbg_addr_reg <= s_axil_wdata[17:0];
                    end
                    W_DBG_DATA_L: begin
                        dbg_wdata[31:0] <= s_axil_wdata;
                        dbg_data_lo     <= s_axil_wdata;
                    end
                    W_DBG_DATA_H: begin
                        dbg_wdata[63:32] <= s_axil_wdata;
                        dbg_data_hi      <= s_axil_wdata;
                    end
                    W_DBG_CTRL: if (s_axil_wdata[0]) dbg_we_pulse <= 1'b1;
                    W_HDMI_CRC: ; // read-only
                    W_HDMI_FR:  ; // read-only
                    W_BLIT_CTRL: begin
                        blit_ctrl <= merge_wstrb(blit_ctrl, s_axil_wdata, s_axil_wstrb);
                        if (s_axil_wdata[0] && !blit_busy) begin
                            blit_busy     <= 1'b1;
                            blit_done     <= 1'b0;
                            blit_status[0]<= 1'b1; // busy
                            blit_status[1]<= 1'b0; // done clear
                            blit_counter  <= (blit_len >> 2);
                            blit_idx      <= 16'd0;
                            if ((blit_len >> 2) == 0)
                                blit_counter <= 32'd32;
                        end
                    end
                    W_BLIT_STATUS: begin
                        if (s_axil_wdata[1]) begin
                            blit_done      <= 1'b0;
                            blit_status[1] <= 1'b0;
                        end
                        if (s_axil_wdata[0] == 1'b0)
                            blit_status[0] <= blit_busy;
                    end
                    W_BLIT_SRC:    blit_src    <= merge_wstrb(blit_src,    s_axil_wdata, s_axil_wstrb);
                    W_BLIT_DST:    blit_dst    <= merge_wstrb(blit_dst,    s_axil_wdata, s_axil_wstrb);
                    W_BLIT_LEN:    blit_len    <= merge_wstrb(blit_len,    s_axil_wdata, s_axil_wstrb);
                    W_BLIT_STRIDE: blit_stride <= merge_wstrb(blit_stride, s_axil_wdata, s_axil_wstrb);
                    W_BLIT_PIX_ADDR: blit_pix_addr <= s_axil_wdata[15:0];
                    W_BLIT_PIX_DATA: begin
                        blit_pix_data <= s_axil_wdata;
                        blit_pix_mem[blit_pix_addr[9:0]] <= s_axil_wdata;
                        blit_mem_addr  <= {blit_pix_addr, 2'b00};
                        blit_mem_wdata <= {32'd0, s_axil_wdata};
                        blit_mem_we    <= 1'b1;
                    end
                    W_BLIT_PIX_CMD: begin
                        if (s_axil_wdata[0]) begin
                            blit_pix_mem[blit_pix_addr[9:0]] <= blit_pix_data;
                            blit_mem_addr  <= {blit_pix_addr, 2'b00};
                            blit_mem_wdata <= {32'd0, blit_pix_data};
                            blit_mem_we    <= 1'b1;
                        end
                        if (s_axil_wdata[1]) begin
                            blit_mem_addr <= {blit_pix_addr, 2'b00};
                            blit_mem_re   <= 1'b1;
                            blit_pix_data <= blit_mem_rdata[31:0];
                        end
                    end
                    W_BLIT_OBJ_IDX:  blit_obj_idx  <= s_axil_wdata[5:0];
                    W_BLIT_OBJ_ATTR: begin
                        blit_obj_attr <= s_axil_wdata;
                        blit_obj_mem[blit_obj_idx] <= s_axil_wdata;
                    end
                    W_BLIT_FIFO_DATA: begin
                        if (blit_fifo_count < 16) begin
                            blit_fifo_mem[blit_fifo_wr] <= s_axil_wdata;
                            blit_fifo_wr <= blit_fifo_wr + 1'b1;
                            blit_fifo_count <= blit_fifo_count + 1'b1;
                        end
                    end
                    W_REGION0_CFG: begin
                        region0_cfg <= merge_wstrb(region0_cfg, s_axil_wdata, s_axil_wstrb);
                        if (s_axil_wdata[1])
                            region0_status[1] <= 1'b0; // clear valid on new kick
                    end
                    W_REGION0_MIN:    region0_min   <= merge_wstrb(region0_min,   s_axil_wdata, s_axil_wstrb);
                    W_REGION0_MAX:    region0_max   <= merge_wstrb(region0_max,   s_axil_wdata, s_axil_wstrb);
                    W_REGION0_STATUS: region0_status<= region0_status & ~s_axil_wdata; // W1C for busy/valid bits
                    default: ;
                endcase

                s_axil_bresp   <= RESP_OKAY;
                s_axil_bvalid  <= 1'b1;
                s_axil_awready <= 1'b0;
                s_axil_wready  <= 1'b0;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end

            // Blitter progress
            if (blit_busy) begin
                if (blit_ctrl[2] && blit_fifo_count == 0 && blit_op == 3'b000) begin
                    // wait for FIFO data in MEMCPY mode
                end else if (blit_counter != 0) begin
                    if (blit_op == 3'b000) begin
                        // MEMCPY: simple copy loop from fifo or local pix mem
                        reg [31:0] src_word;
                        reg [9:0]  src_idx;
                        reg [9:0]  dst_idx;
                        src_idx = (blit_src[11:2] + blit_idx[9:0]) & 10'h3FF;
                        dst_idx = (blit_dst[11:2] + blit_idx[9:0]) & 10'h3FF;
                        if (blit_ctrl[2]) begin
                            src_word = blit_fifo_mem[blit_fifo_rd];
                            if (blit_fifo_count != 0) begin
                                blit_fifo_rd    <= blit_fifo_rd + 1'b1;
                                blit_fifo_count <= blit_fifo_count - 1'b1;
                            end
                        end else begin
                            src_word = blit_pix_mem[src_idx];
                        end
                        blit_pix_mem[dst_idx] <= src_word;
                        blit_mem_addr  <= {dst_idx, 2'b00};
                        blit_mem_wdata <= {32'd0, src_word};
                        blit_mem_we    <= 1'b1;
                        blit_idx       <= blit_idx + 1'b1;
                    end else begin
                        // Other ops (e.g. SURFACE_EXTRACT) stub: just burn through blit_counter.
                        blit_idx <= blit_idx + 1'b1;
                    end
                    blit_counter <= blit_counter - 1'b1;
                end else begin
                    // Common completion path
                    blit_busy      <= 1'b0;
                    blit_status[0] <= 1'b0;
                    blit_done      <= 1'b1;
                    blit_status[1] <= 1'b1;
                    int_status[4]  <= 1'b1;

                    // For SURFACE_EXTRACT stub, synthesize a simple stats word.
                    if (blit_op == 3'b011) begin
                        // Interpret blit_len as a byte count; approximate voxel and patch counts.
                        reg [11:0] voxels;
                        reg [11:0] patches;
                        voxels  = (blit_len[13:2] > 12'hFFF) ? 12'hFFF : blit_len[13:2];
                        patches = (voxels >> 4);
                        if (patches > 12'hFFF)
                            patches = 12'hFFF;
                        surf_stats <= {8'd0, patches, voxels};
                    end
                end
            end
        end
    end

    // Read channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rdata   <= 32'd0;
            s_axil_rresp   <= RESP_OKAY;
        end else begin
            if (!s_axil_arready)
                s_axil_arready <= s_axil_arvalid;

            if (s_axil_arready && s_axil_arvalid && !s_axil_rvalid) begin
                `ifdef CSR_DEBUG
                    $display("CSR: read ar_word=0x%0h araddr=0x%04h", ar_word, araddr_aligned);
                `endif
                case (ar_word)
                    W_ID:      s_axil_rdata <= {VENDOR_ID, DEVICE_ID};
                    W_REV:     s_axil_rdata <= {16'd0, BUILD_ID, REV_ID};
                    W_CTRL:    s_axil_rdata <= {ctrl_shadow[31:4], 2'b00, ctrl_shadow[3:2], 2'b00};
                    W_STATUS:  s_axil_rdata <= status_word;
                    W_CAM_X:   s_axil_rdata <= pack_s16(cam_x);
                    W_CAM_Y:   s_axil_rdata <= pack_s16(cam_y);
                    W_CAM_Z:   s_axil_rdata <= pack_s16(cam_z);
                    W_CAM_DIR_X: s_axil_rdata <= pack_s16(cam_dir_x);
                    W_CAM_DIR_Y: s_axil_rdata <= pack_s16(cam_dir_y);
                    W_CAM_DIR_Z: s_axil_rdata <= pack_s16(cam_dir_z);
                    W_CAM_PLANE_X: s_axil_rdata <= pack_s16(cam_plane_x);
                    W_CAM_PLANE_Y: s_axil_rdata <= pack_s16(cam_plane_y);
                    W_FLAGS:   s_axil_rdata <= {27'd0, flag_ray_jitter, flag_diag_slice, flag_extra_light, flag_curvature, flag_smooth};
                    W_SEL_ACTIVE: s_axil_rdata <= {31'd0, sel_active};
                    W_SEL_X:   s_axil_rdata <= {26'd0, sel_x};
                    W_SEL_Y:   s_axil_rdata <= {26'd0, sel_y};
                    W_SEL_Z:   s_axil_rdata <= {26'd0, sel_z};
                    W_FB_BASE:   s_axil_rdata <= fb_base;
                    W_FB_STRIDE: s_axil_rdata <= fb_stride;
                    W_SURF_BASE: s_axil_rdata <= surf_base;
                    W_SURF_LEN:  s_axil_rdata <= surf_len;
                    W_SURF_STATS:s_axil_rdata <= surf_stats;
                    W_DMA_SRC:   s_axil_rdata <= dma_src;
                    W_DMA_DST:   s_axil_rdata <= dma_dst;
                    W_DMA_LEN:   s_axil_rdata <= dma_len;
                    W_DMA_CTRL:  s_axil_rdata <= 32'd0;
                    W_DMA_STATUS:s_axil_rdata <= dma_status;
                    W_INT_STATUS:s_axil_rdata <= int_status;
                    W_INT_MASK:  s_axil_rdata <= int_mask;
                    W_DBG_ADDR:  s_axil_rdata <= {14'd0, dbg_addr_reg};
                    W_DBG_DATA_L:s_axil_rdata <= dbg_data_lo;
                    W_DBG_DATA_H:s_axil_rdata <= dbg_data_hi;
                    W_DBG_CTRL:  s_axil_rdata <= 32'd0;
                    W_HDMI_CRC:  s_axil_rdata <= hdmi_crc_in;
                    W_HDMI_FR:   s_axil_rdata <= hdmi_frames_in;
                    W_HDMI_LINE: s_axil_rdata <= {16'd0, hdmi_line_in};
                    W_HDMI_PIX:  s_axil_rdata <= {16'd0, hdmi_pix_in};
                    W_BLIT_CTRL:   s_axil_rdata <= blit_ctrl;
                    W_BLIT_STATUS: s_axil_rdata <= {28'd0, blit_status[3], blit_status[2], blit_status[1], blit_status[0]};
                    W_BLIT_SRC:    s_axil_rdata <= blit_src;
                    W_BLIT_DST:    s_axil_rdata <= blit_dst;
                    W_BLIT_LEN:    s_axil_rdata <= blit_len;
                    W_BLIT_STRIDE: s_axil_rdata <= blit_stride;
                    W_BLIT_PIX_ADDR: s_axil_rdata <= {16'd0, blit_pix_addr};
                    W_BLIT_PIX_DATA: begin
                        s_axil_rdata <= blit_pix_mem[blit_pix_addr[9:0]];
                    end
                    W_BLIT_PIX_CMD: s_axil_rdata <= 32'd0;
                    W_BLIT_OBJ_IDX: s_axil_rdata <= {26'd0, blit_obj_idx};
                    W_BLIT_OBJ_ATTR: begin
                        s_axil_rdata <= blit_obj_mem[blit_obj_idx];
                    end
                    W_BLIT_FIFO_DATA: begin
                        s_axil_rdata <= blit_fifo_count ? blit_fifo_mem[blit_fifo_rd] : 32'd0;
                        if (blit_fifo_count != 0) begin
                            blit_fifo_rd    <= blit_fifo_rd + 1'b1;
                            blit_fifo_count <= blit_fifo_count - 1'b1;
                        end
                    end
                    W_BLIT_FIFO_STATUS: s_axil_rdata <= {24'd0, blit_fifo_count, blit_status[3], blit_status[2]};
                    W_REGION0_CFG:        s_axil_rdata <= region0_cfg;
                    W_REGION0_MIN:        s_axil_rdata <= region0_min;
                    W_REGION0_MAX:        s_axil_rdata <= region0_max;
                    W_REGION0_STATUS:     s_axil_rdata <= region0_status;
                    W_REGION0_SURF_STATS: s_axil_rdata <= region0_surf_stats;
                    default:     s_axil_rdata <= 32'd0;
                endcase
                s_axil_rresp   <= RESP_OKAY;
                s_axil_rvalid  <= 1'b1;
                s_axil_arready <= 1'b0;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

`ifdef VERILATOR
    // AXI-Lite stability checks: hold address/data/strobes steady while VALID && !READY.
    always @(posedge clk) begin
        if (s_axil_awvalid && !s_axil_awready) begin
            assert($stable(s_axil_awaddr)) else $fatal("AWADDR changed while AWVALID held high");
        end
        if (s_axil_wvalid && !s_axil_wready) begin
            assert($stable(s_axil_wdata)) else $fatal("WDATA changed while WVALID held high");
            assert($stable(s_axil_wstrb)) else $fatal("WSTRB changed while WVALID held high");
        end
        if (s_axil_arvalid && !s_axil_arready) begin
            assert($stable(s_axil_araddr)) else $fatal("ARADDR changed while ARVALID held high");
        end
    end

    // Check reset defaults on rst_n deassertion.
    reg rst_n_d;
    always @(posedge clk) begin
        rst_n_d <= rst_n;
        if (!rst_n_d && rst_n) begin
            assert(ctrl_shadow  == 32'd0) else $fatal("CTRL reset default mismatch");
            assert(int_status   == 32'd0) else $fatal("INT_STATUS reset default mismatch");
            assert(int_mask     == 32'd0) else $fatal("INT_MASK reset default mismatch");
            assert(flag_smooth  == 1'b1)  else $fatal("flag_smooth reset default mismatch");
            assert(flag_curvature == 1'b1) else $fatal("flag_curvature reset default mismatch");
            assert(flag_extra_light == 1'b0) else $fatal("flag_extra_light reset default mismatch");
            assert(flag_diag_slice  == 1'b0) else $fatal("flag_diag_slice reset default mismatch");
            assert(flag_ray_jitter == 1'b0) else $fatal("flag_ray_jitter reset default mismatch");
            assert(sel_active   == 1'b0) else $fatal("sel_active reset default mismatch");
            assert(sel_x        == 6'd0) else $fatal("sel_x reset default mismatch");
            assert(sel_y        == 6'd0) else $fatal("sel_y reset default mismatch");
            assert(sel_z        == 6'd0) else $fatal("sel_z reset default mismatch");
            assert(fb_base      == 32'd0) else $fatal("fb_base reset default mismatch");
            assert(fb_stride    == 32'd0) else $fatal("fb_stride reset default mismatch");
            assert(dma_status   == 32'd0) else $fatal("dma_status reset default mismatch");
        end
    end

    covergroup cg_axi_lite @(posedge clk);
        coverpoint int_status {
            bins frame_done = {32'h1};
        }
        coverpoint dma_status;
        coverpoint {frame_done_latched, dma_busy_in, core_busy};
    endgroup
    cg_axi_lite axi_cover = new();
    always @(posedge clk) begin
        if (!rst_n)
            axi_cover.sample();
    end
`endif

endmodule
