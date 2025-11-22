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
    parameter [7:0]   REV_ID     = 8'h01,
    parameter [7:0]   BUILD_ID   = 8'h00
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
    wire [7:0] aw_word = awaddr_aligned[9:2]; // 256B window (word addressed)
    wire [7:0] ar_word = araddr_aligned[9:2];

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
    localparam integer W_ID         = 8'h00; // 0x0000
    localparam integer W_REV        = 8'h01; // 0x0004
    localparam integer W_CTRL       = 8'h04; // 0x0010
    localparam integer W_STATUS     = 8'h05; // 0x0014
    localparam integer W_CAM_X      = 8'h08; // 0x0020
    localparam integer W_CAM_Y      = 8'h09; // 0x0024
    localparam integer W_CAM_Z      = 8'h0A; // 0x0028
    localparam integer W_CAM_DIR_X  = 8'h0B; // 0x002C
    localparam integer W_CAM_DIR_Y  = 8'h0C; // 0x0030
    localparam integer W_CAM_DIR_Z  = 8'h0D; // 0x0034
    localparam integer W_CAM_PLANE_X= 8'h0E; // 0x0038
    localparam integer W_CAM_PLANE_Y= 8'h0F; // 0x003C
    localparam integer W_FLAGS      = 8'h10; // 0x0040
    localparam integer W_SEL_ACTIVE = 8'h11; // 0x0044
    localparam integer W_SEL_X      = 8'h12; // 0x0048
    localparam integer W_SEL_Y      = 8'h13; // 0x004C
    localparam integer W_SEL_Z      = 8'h14; // 0x0050
    localparam integer W_FB_BASE    = 8'h15; // 0x0054
    localparam integer W_FB_STRIDE  = 8'h16; // 0x0058

    localparam integer W_DMA_SRC    = 8'h18; // 0x0060
    localparam integer W_DMA_DST    = 8'h19; // 0x0064
    localparam integer W_DMA_LEN    = 8'h1A; // 0x0068
    localparam integer W_DMA_CTRL   = 8'h1B; // 0x006C
    localparam integer W_DMA_STATUS = 8'h1C; // 0x0070

    localparam integer W_INT_STATUS = 8'h20; // 0x0080
    localparam integer W_INT_MASK   = 8'h21; // 0x0084
    localparam integer W_IRQ_TEST   = 8'h22; // 0x0088

    localparam integer W_DBG_ADDR   = 8'h28; // 0x00A0
    localparam integer W_DBG_DATA_L = 8'h29; // 0x00A4
    localparam integer W_DBG_DATA_H = 8'h2A; // 0x00A8
    localparam integer W_DBG_CTRL   = 8'h2B; // 0x00AC
    localparam integer W_HDMI_CRC   = 8'h2C; // 0x00B0
    localparam integer W_HDMI_FR    = 8'h2D; // 0x00B4
    localparam integer W_HDMI_LINE  = 8'h2E; // 0x00B8
    localparam integer W_HDMI_PIX   = 8'h2F; // 0x00BC

    // 3D blitter stub (0x0100 region)
    localparam integer W_BLIT_CTRL      = 8'h40; // 0x0100
    localparam integer W_BLIT_STATUS    = 8'h41; // 0x0104
    localparam integer W_BLIT_SRC       = 8'h42; // 0x0108
    localparam integer W_BLIT_DST       = 8'h43; // 0x010C
    localparam integer W_BLIT_LEN       = 8'h44; // 0x0110
    localparam integer W_BLIT_STRIDE    = 8'h45; // 0x0114
    localparam integer W_BLIT_PIX_ADDR  = 8'h48; // 0x0120
    localparam integer W_BLIT_PIX_DATA  = 8'h49; // 0x0124
    localparam integer W_BLIT_PIX_CMD   = 8'h4A; // 0x0128
    localparam integer W_BLIT_OBJ_IDX   = 8'h4C; // 0x0130
    localparam integer W_BLIT_OBJ_ATTR  = 8'h4D; // 0x0134
    localparam integer W_BLIT_FIFO_DATA = 8'h50; // 0x0140
    localparam integer W_BLIT_FIFO_STATUS = 8'h51; // 0x0144

    assign irq_out  = |(int_status & int_mask);

    wire dma_done_pulse = dma_done_in & ~dma_done_d;
    wire status_read    = s_axil_arready && s_axil_arvalid && !s_axil_rvalid && (ar_word == W_STATUS);
    wire [31:0] status_word = {26'd0, blit_done, blit_busy, dma_status[0], dma_status[1], frame_done_latched, core_busy};

    integer pi;
    integer oi;
    integer fi;

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
            for (pi = 0; pi < 1024; pi = pi + 1)
                blit_pix_mem[pi] <= 32'd0;
            for (oi = 0; oi < 64; oi = oi + 1)
                blit_obj_mem[oi] <= 32'd0;
            for (fi = 0; fi < 16; fi = fi + 1)
                blit_fifo_mem[fi] <= 32'd0;
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
                flag_smooth        <= 1'b1;
                flag_curvature     <= 1'b1;
                ctrl_shadow[3:2]   <= 2'b00;
                blit_ctrl          <= 32'd0;
                blit_status        <= 32'd0;
                blit_src           <= 32'd0;
                blit_dst           <= 32'd0;
                blit_len           <= 32'd0;
                blit_stride        <= 32'd0;
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
            if (frame_done_pulse)
                frame_done_latched <= 1'b1;
            if (frame_done_pulse)
                int_status[0] <= 1'b1; // frame done
            if (dma_done_pulse)
                int_status[1] <= 1'b1; // dma done
            blit_status[0] <= blit_busy;
            blit_status[1] <= blit_done;
            blit_status[2] <= (blit_fifo_count == 0);
            blit_status[3] <= (blit_fifo_count == 16);

            if (!s_axil_awready)
                s_axil_awready <= s_axil_awvalid;
            if (!s_axil_wready)
                s_axil_wready  <= s_axil_wvalid;

            if (s_axil_awready && s_axil_awvalid &&
                s_axil_wready  && s_axil_wvalid  &&
                !s_axil_bvalid) begin
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
                        if (s_axil_wdata[0] && !dma_busy_in) begin
                            dma_start_pulse <= 1'b1;
                            dma_status[0]   <= 1'b0; // clear done
                        end
                    end
                    W_DMA_STATUS: begin
                        if (s_axil_wdata[0])
                            dma_status[0] <= 1'b0; // w1c done
                    end
                    W_INT_STATUS: int_status <= int_status & ~s_axil_wdata; // w1c
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
                if (blit_ctrl[2] && blit_fifo_count == 0) begin
                    // wait for FIFO data
                end else if (blit_counter != 0) begin
                    // simple copy loop: either from fifo or local pix mem
                    // word addressing; wrap into local mem depth
                    // source word
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
                    blit_idx      <= blit_idx + 1'b1;
                    blit_counter  <= blit_counter - 1'b1;
                end else begin
                    blit_busy      <= 1'b0;
                    blit_status[0] <= 1'b0;
                    blit_done      <= 1'b1;
                    blit_status[1] <= 1'b1;
                    int_status[4]  <= 1'b1;
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
                    W_FLAGS:   s_axil_rdata <= {28'd0, flag_diag_slice, flag_extra_light, flag_curvature, flag_smooth};
                    W_SEL_ACTIVE: s_axil_rdata <= {31'd0, sel_active};
                    W_SEL_X:   s_axil_rdata <= {26'd0, sel_x};
                    W_SEL_Y:   s_axil_rdata <= {26'd0, sel_y};
                    W_SEL_Z:   s_axil_rdata <= {26'd0, sel_z};
                    W_FB_BASE:   s_axil_rdata <= fb_base;
                    W_FB_STRIDE: s_axil_rdata <= fb_stride;
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

endmodule
