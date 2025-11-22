// ============================================================================
// axi_stream_sink_stub.sv
// - Minimal AXI-Stream sink that counts beats/frames.
// - For HDMI/TMDS stub usage: drive tuser as SOF and tlast as end-of-line/frame
//   as appropriate for your testbench.
// ============================================================================
`timescale 1ns/1ps

module axi_stream_sink_stub #(
    parameter integer DATA_WIDTH = 24,
    parameter integer LINE_PIXELS = 480
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire                     s_axis_tvalid,
    input  wire                     s_axis_tlast,
    input  wire                     s_axis_tuser,
    output wire                     s_axis_tready,

    output reg  [31:0]              beat_count,
    output reg  [31:0]              frame_count,
    output reg  [31:0]              frame_crc,
    output reg  [31:0]              last_frame_crc,
    output reg  [15:0]              line_count,
    output reg  [15:0]              pixel_in_line
);

    assign s_axis_tready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_count      <= 32'd0;
            frame_count     <= 32'd0;
            frame_crc       <= 32'd0;
            last_frame_crc  <= 32'd0;
            line_count      <= 16'd0;
            pixel_in_line   <= 16'd0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                beat_count <= beat_count + 1'b1;
                // Simple XOR-based CRC surrogate
                frame_crc <= frame_crc ^ {8'd0, s_axis_tdata};
                // track line/pixel
                if (pixel_in_line == LINE_PIXELS-1 || s_axis_tlast) begin
                    pixel_in_line <= 16'd0;
                    line_count    <= line_count + 1'b1;
                end else begin
                    pixel_in_line <= pixel_in_line + 1'b1;
                end
                if (s_axis_tlast) begin
                    frame_count <= frame_count + 1'b1;
                    line_count  <= 16'd0;
                    pixel_in_line <= 16'd0;
                end
            end
            if (s_axis_tuser) begin
                // start of frame: reset running CRC
                frame_crc <= 32'd0;
                line_count <= 16'd0;
                pixel_in_line <= 16'd0;
            end
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast) begin
                last_frame_crc <= frame_crc;
            end
        end
    end

endmodule
