// ============================================================================
// voxel_axil_csr.sv
// - AXI4-Lite CSR block for voxel core control.
// - Provides registers for camera, flags, selection, and debug BRAM writes.
// - Emits single-cycle load pulses when corresponding registers are written.
// ============================================================================
`timescale 1ns/1ps

module voxel_axil_csr #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32
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

    // Simple DMA stub control
    output reg                      dma_start_pulse,
    output reg                      dma_busy,
    output reg [31:0]               dma_src,
    output reg [31:0]               dma_dst,
    output reg [31:0]               dma_len,
    output reg [31:0]               dma_status // bit0=done sticky, bit1=busy
);

    localparam [1:0] RESP_OKAY = 2'b00;

    // Register file for readback (word addressed)
    reg [31:0] regs [0:27];
    reg [31:0] dma_counter;

    wire [ADDR_WIDTH-1:0] awaddr_aligned = {s_axil_awaddr[ADDR_WIDTH-1:2], 2'b00};
    wire [ADDR_WIDTH-1:0] araddr_aligned = {s_axil_araddr[ADDR_WIDTH-1:2], 2'b00};
    wire [7:0] aw_word = awaddr_aligned[9:2]; // 256B window
    wire [7:0] ar_word = araddr_aligned[9:2];

    integer i;
`ifndef SYNTHESIS
    initial begin
        for (i = 0; i < 28; i = i + 1)
            regs[i] = 32'd0;
        s_axil_awready = 1'b0;
        s_axil_wready  = 1'b0;
        s_axil_bresp   = RESP_OKAY;
        s_axil_bvalid  = 1'b0;
        s_axil_arready = 1'b0;
        s_axil_rdata   = 32'd0;
        s_axil_rresp   = RESP_OKAY;
        s_axil_rvalid  = 1'b0;
        cam_load_pulse   = 1'b0;
        flags_load_pulse = 1'b0;
        sel_load_pulse   = 1'b0;
        dbg_we_pulse     = 1'b0;
        dma_start_pulse  = 1'b0;
        dma_busy         = 1'b0;
        dma_src          = 32'd0;
        dma_dst          = 32'd0;
        dma_len          = 32'd0;
        dma_status       = 32'd0;
        dma_counter      = 32'd0;
    end
`endif

    // Decode helpers
    localparam integer W_CAM_X      = 8'h00;
    localparam integer W_CAM_Y      = 8'h01;
    localparam integer W_CAM_Z      = 8'h02;
    localparam integer W_CAM_DIR_X  = 8'h03;
    localparam integer W_CAM_DIR_Y  = 8'h04;
    localparam integer W_CAM_DIR_Z  = 8'h05;
    localparam integer W_CAM_PLANE_X= 8'h06;
    localparam integer W_CAM_PLANE_Y= 8'h07;
    localparam integer W_FLAGS      = 8'h08;
    localparam integer W_SEL_X      = 8'h09;
    localparam integer W_SEL_Y      = 8'h0A;
    localparam integer W_SEL_Z      = 8'h0B;
    localparam integer W_SEL_CTRL   = 8'h0C;
    localparam integer W_DBG_ADDR   = 8'h10;
    localparam integer W_DBG_DATA_L = 8'h12;
    localparam integer W_DBG_DATA_H = 8'h13;
    localparam integer W_DBG_CTRL   = 8'h14;

    localparam integer W_DMA_SRC    = 8'h20;
    localparam integer W_DMA_DST    = 8'h21;
    localparam integer W_DMA_LEN    = 8'h22;
    localparam integer W_DMA_CTRL   = 8'h23;
    localparam integer W_DMA_STATUS = 8'h24;

    // Write channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= RESP_OKAY;
            cam_load_pulse   <= 1'b0;
            flags_load_pulse <= 1'b0;
            sel_load_pulse   <= 1'b0;
            dbg_we_pulse     <= 1'b0;
            dma_start_pulse  <= 1'b0;
            dma_busy         <= 1'b0;
            dma_status       <= 32'd0;
            dma_counter      <= 32'd0;
        end else begin
            cam_load_pulse   <= 1'b0;
            flags_load_pulse <= 1'b0;
            sel_load_pulse   <= 1'b0;
            dbg_we_pulse     <= 1'b0;

            if (!s_axil_awready)
                s_axil_awready <= s_axil_awvalid;
            if (!s_axil_wready)
                s_axil_wready  <= s_axil_wvalid;

            if (s_axil_awready && s_axil_awvalid &&
                s_axil_wready  && s_axil_wvalid  &&
                !s_axil_bvalid) begin
                // byte write strobes
                for (i = 0; i < (DATA_WIDTH/8); i = i + 1) begin
                    if (s_axil_wstrb[i])
                        regs[aw_word][8*i +: 8] <= s_axil_wdata[8*i +: 8];
                end

                // Field updates
                case (aw_word)
                    W_CAM_X:       begin cam_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_Y:       begin cam_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_Z:       begin cam_z <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_X:   begin cam_dir_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_Y:   begin cam_dir_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_DIR_Z:   begin cam_dir_z <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_PLANE_X: begin cam_plane_x <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_CAM_PLANE_Y: begin cam_plane_y <= s_axil_wdata[15:0]; cam_load_pulse <= 1'b1; end
                    W_FLAGS: begin
                        flag_smooth     <= s_axil_wdata[0];
                        flag_curvature  <= s_axil_wdata[1];
                        flag_extra_light<= s_axil_wdata[2];
                        flag_diag_slice <= s_axil_wdata[3];
                        flags_load_pulse<= 1'b1;
                    end
                    W_SEL_X:       begin sel_x <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_SEL_Y:       begin sel_y <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_SEL_Z:       begin sel_z <= s_axil_wdata[5:0]; sel_load_pulse <= 1'b1; end
                    W_SEL_CTRL:    begin sel_active <= s_axil_wdata[0]; sel_load_pulse <= 1'b1; end
                    W_DBG_ADDR:    dbg_addr <= s_axil_wdata[17:0];
                    W_DBG_DATA_L:  dbg_wdata[31:0]  <= s_axil_wdata;
                    W_DBG_DATA_H:  dbg_wdata[63:32] <= s_axil_wdata;
                    W_DBG_CTRL:    if (s_axil_wdata[0]) dbg_we_pulse <= 1'b1;
                    W_DMA_SRC:     dma_src <= s_axil_wdata;
                    W_DMA_DST:     dma_dst <= s_axil_wdata;
                    W_DMA_LEN:     dma_len <= s_axil_wdata;
                    W_DMA_CTRL: begin
                        if (s_axil_wdata[0] && !dma_busy) begin
                            dma_start_pulse <= 1'b1;
                            dma_busy        <= 1'b1;
                            dma_status[0]   <= 1'b0; // clear done
                            dma_status[1]   <= 1'b1; // busy
                            dma_counter     <= (dma_len >> 3); // crude cycles ~= bytes/8
                            if (dma_counter == 0)
                                dma_counter <= 32'd16;
                        end
                    end
                    default: ;
                endcase

                s_axil_bresp  <= RESP_OKAY;
                s_axil_bvalid <= 1'b1;
                s_axil_awready<= 1'b0;
                s_axil_wready <= 1'b0;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
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
                    W_DMA_STATUS: s_axil_rdata <= dma_status;
                    default:       s_axil_rdata <= regs[ar_word];
                endcase
                s_axil_rresp   <= RESP_OKAY;
                s_axil_rvalid  <= 1'b1;
                s_axil_arready <= 1'b0;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

    // DMA stub progress: count down cycles, then mark done
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_busy    <= 1'b0;
            dma_status  <= 32'd0;
            dma_counter <= 32'd0;
        end else begin
            if (dma_busy) begin
                if (dma_counter != 0)
                    dma_counter <= dma_counter - 1'b1;
                else begin
                    dma_busy       <= 1'b0;
                    dma_status[1]  <= 1'b0; // busy clear
                    dma_status[0]  <= 1'b1; // done sticky
                end
            end
        end
    end

endmodule
