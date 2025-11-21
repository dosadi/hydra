// ============================================================================
// voxel_axil_shell.sv
// - AXI-Lite + AXI stub shell around voxel_framebuffer_top for simulation/bring-up.
// - Instantiates:
//     * axil_csr_stub  : placeholder BAR0/CSR register file (AXI4-Lite).
//     * axi_sdram_stub : BRAM-backed AXI memory (stand-in for SDRAM/DDR).
//     * axi_stream_sink_stub : captures pixel stream (stand-in for HDMI sink).
// - Connects voxel_framebuffer_top pixel writes into the AXI-Stream sink and
//   exposes a simple AXI-Lite/AXI presence for early fabric testing.
// ============================================================================
`timescale 1ns/1ps

module voxel_axil_shell #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64
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

    // AXI (placeholder SDRAM port)
    input  wire [3:0]  s_axi_awid,
    input  wire [27:0] s_axi_awaddr,
    input  wire [7:0]  s_axi_awlen,
    input  wire [2:0]  s_axi_awsize,
    input  wire [1:0]  s_axi_awburst,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [63:0] s_axi_wdata,
    input  wire [7:0]  s_axi_wstrb,
    input  wire        s_axi_wlast,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [3:0]  s_axi_bid,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [3:0]  s_axi_arid,
    input  wire [27:0] s_axi_araddr,
    input  wire [7:0]  s_axi_arlen,
    input  wire [2:0]  s_axi_arsize,
    input  wire [1:0]  s_axi_arburst,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [3:0]  s_axi_rid,
    output wire [63:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rlast,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // AXI-Stream sink (HDMI placeholder)
    output wire [23:0] s_axis_tdata,
    output wire        s_axis_tvalid,
    output wire        s_axis_tlast,
    output wire        s_axis_tuser,
    input  wire        s_axis_tready,
    output wire [31:0] hdmi_beat_count,
    output wire [31:0] hdmi_frame_count
);

    // --------------------------------------------------------------------
    // CSR stub (AXI-Lite)
    // --------------------------------------------------------------------
    axil_csr_stub #(
        .ADDR_WIDTH(16),
        .DATA_WIDTH(32),
        .NUM_REGS   (16)
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
        .s_axil_rready  (s_axil_rready)
    );

    // --------------------------------------------------------------------
    // SDRAM stub (AXI memory)
    // --------------------------------------------------------------------
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
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata  (s_axi_wdata),
        .s_axi_wstrb  (s_axi_wstrb),
        .s_axi_wlast  (s_axi_wlast),
        .s_axi_wvalid (s_axi_wvalid),
        .s_axi_wready (s_axi_wready),
        .s_axi_bid    (s_axi_bid),
        .s_axi_bresp  (s_axi_bresp),
        .s_axi_bvalid (s_axi_bvalid),
        .s_axi_bready (s_axi_bready),
        .s_axi_arid   (s_axi_arid),
        .s_axi_araddr (s_axi_araddr),
        .s_axi_arlen  (s_axi_arlen),
        .s_axi_arsize (s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rid    (s_axi_rid),
        .s_axi_rdata  (s_axi_rdata),
        .s_axi_rresp  (s_axi_rresp),
        .s_axi_rlast  (s_axi_rlast),
        .s_axi_rvalid (s_axi_rvalid),
        .s_axi_rready (s_axi_rready)
    );

    // --------------------------------------------------------------------
    // Voxel framebuffer + AXI-Stream bridge (HDMI placeholder)
    // --------------------------------------------------------------------
    wire         pixel_write_en;
    wire [31:0]  pixel_addr;
    wire [31:0]  pixel_word0, pixel_word1, pixel_word2;
    wire         frame_done;

    voxel_framebuffer_top #(
        .SCREEN_WIDTH   (SCREEN_WIDTH),
        .SCREEN_HEIGHT  (SCREEN_HEIGHT),
        .VOXEL_GRID_SIZE(VOXEL_GRID_SIZE)
    ) u_voxel (
        .clk            (clk),
        .rst_n          (rst_n),
        .pixel_write_en (pixel_write_en),
        .pixel_addr     (pixel_addr),
        .pixel_word0    (pixel_word0),
        .pixel_word1    (pixel_word1),
        .pixel_word2    (pixel_word2),
        .frame_done     (frame_done)
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
        .frame_count    (hdmi_frame_count)
    );

endmodule
