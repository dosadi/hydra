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
                // If tuser (SOF) is asserted on this beat, start CRC from this beat's data.
                if (s_axis_tuser) begin
                    frame_crc <= {8'd0, s_axis_tdata};
                    line_count <= 16'd0;
                    pixel_in_line <= 16'd0;
                end else begin
                    // Simple XOR-based CRC surrogate
                    frame_crc <= frame_crc ^ {8'd0, s_axis_tdata};
                end

                // track line/pixel (tlast ends a line/frame)
                if (pixel_in_line == LINE_PIXELS-1 || s_axis_tlast) begin
                    pixel_in_line <= 16'd0;
                    line_count    <= line_count + 1'b1;
                end else begin
                    pixel_in_line <= pixel_in_line + 1'b1;
                end

                if (s_axis_tlast) begin
                    // Capture final CRC for the frame (include this beat)
                    if (s_axis_tuser)
                        last_frame_crc <= {8'd0, s_axis_tdata};
                    else
                        last_frame_crc <= frame_crc ^ {8'd0, s_axis_tdata};

                    frame_count <= frame_count + 1'b1;
                    line_count  <= 16'd0;
                    pixel_in_line <= 16'd0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Note: `tuser` is treated as Start-Of-Frame when seen on a valid beat.
    // `tlast` denotes end-of-line / end-of-frame as implemented above.
    // Further HDMI/TMDS-specific parsing can be added if required by tests.

`ifdef FORMAL
    // SVA: tvalid/tready handshake only when tvalid
    property tready_only_on_tvalid;
        @(posedge clk) disable iff (!rst_n)
        s_axis_tready |-> s_axis_tvalid;
    endproperty
    tready_only_on_tvalid_sva: assert property (tready_only_on_tvalid);

    // SVA: Frame count only increments on tlast
    property frame_count_on_tlast;
        @(posedge clk) disable iff (!rst_n)
        (frame_count != $past(frame_count)) |-> s_axis_tlast;
    endproperty
    frame_count_on_tlast_sva: assert property (frame_count_on_tlast);

    // SVA: CRC update only on tlast
    property last_frame_crc_on_tlast;
        @(posedge clk) disable iff (!rst_n)
        (last_frame_crc != $past(last_frame_crc)) |-> s_axis_tlast;
    endproperty
    last_frame_crc_on_tlast_sva: assert property (last_frame_crc_on_tlast);
`endif

endmodule
