// ============================================================================
// hdmi_scanout_stub.sv
// - Simple framebuffer scanout engine for simulation.
// - Reads pixels from a BRAM-backed SDRAM stub debug port and emits AXI-Stream
//   RGB suitable for feeding axi_stream_sink_stub or a TMDS encoder stub.
// - One pixel per 64-bit word; address mapping uses a left shift so the
//   underlying memory index is (FB_BASE_WORD + pixel_index).
// - Not timing-accurate HDMI; intended as a functional model only.
// ============================================================================
`timescale 1ns/1ps

module hdmi_scanout_stub #(
    parameter integer SCREEN_WIDTH  = 480,
    parameter integer SCREEN_HEIGHT = 360,
    // Must match axi_sdram_stub ADDR_WIDTH/MEM_WORDS in the shell
    parameter integer ADDR_WIDTH    = 28,
    parameter integer MEM_WORDS     = 1 << 18,
    // Framebuffer base index in SDRAM words
    parameter integer FB_BASE_WORD  = 0
)(
    input  wire                     clk,
    input  wire                     rst_n,

    localparam integer TOTAL_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;
    localparam integer ADDR_SHIFT   = ADDR_WIDTH - $clog2(MEM_WORDS);

    input  wire                     enable,

    // Debug read port into SDRAM stub
    output reg  [ADDR_WIDTH-1:0]    dbg_addr,
    output reg                      dbg_re,
    input  wire [63:0]              dbg_rdata,

    // AXI-Stream video out (RGB888)
    output reg  [23:0]              s_axis_tdata,
    output reg                      s_axis_tvalid,
    output reg                      s_axis_tlast,
    output reg                      s_axis_tuser,
    input  wire                     s_axis_tready
);

    localparam integer TOTAL_PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;

    // Simple two-stage pipeline: request next pixel from SDRAM while outputting
    // the previously fetched pixel.
    reg [31:0] pix_index;      // 0 .. TOTAL_PIXELS-1
    reg [31:0] next_pix_index;
    reg [15:0] cur_x;
    reg [15:0] cur_y;
    reg [23:0] pixel_latch;
    reg        primed;         // 1 once we have a valid pixel_latch

    wire at_last_pixel = (cur_x == SCREEN_WIDTH-1) && (cur_y == SCREEN_HEIGHT-1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbg_addr      <= {ADDR_WIDTH{1'b0}};
            dbg_re        <= 1'b0;
            s_axis_tdata  <= 24'd0;
            s_axis_tvalid <= 1'b0;
            s_axis_tlast  <= 1'b0;
            s_axis_tuser  <= 1'b0;
            pix_index     <= 32'd0;
            next_pix_index<= 32'd0;
            cur_x         <= 16'd0;
            cur_y         <= 16'd0;
            pixel_latch   <= 24'd0;
            primed        <= 1'b0;
        end else begin
            // Default deassert; re-assert when issuing a read
            dbg_re        <= 1'b0;
            s_axis_tvalid <= 1'b0;
            s_axis_tlast  <= 1'b0;
            s_axis_tuser  <= 1'b0;

            if (!enable) begin
                // Hold in idle when disabled
                pix_index      <= 32'd0;
                next_pix_index <= 32'd0;
                cur_x          <= 16'd0;
                cur_y          <= 16'd0;
                primed         <= 1'b0;
            end else begin
                // Issue a read for the "next" pixel index whenever possible
                if (!primed) begin
                    // Prime pipeline: request first pixel
                    dbg_addr <= ((FB_BASE_WORD + pix_index) << ADDR_SHIFT);
                    dbg_re   <= 1'b1;
                    pixel_latch <= dbg_rdata[23:0];
                    primed   <= 1'b1;
                    // Prepare next index (wrap after last pixel)
                    if (pix_index == TOTAL_PIXELS-1) begin
                        next_pix_index <= 32'd0;
                    end else begin
                        next_pix_index <= pix_index + 1'b1;
                    end
                end else begin
                    // Have a pixel in pixel_latch; stream it out when ready
                    if (s_axis_tready) begin
                        s_axis_tdata  <= pixel_latch;
                        s_axis_tvalid <= 1'b1;
                        s_axis_tuser  <= (cur_x == 16'd0 && cur_y == 16'd0);
                        s_axis_tlast  <= at_last_pixel;

                        // Request the next pixel for the following cycle
                        dbg_addr    <= ((FB_BASE_WORD + next_pix_index) << ADDR_SHIFT);
                        dbg_re      <= 1'b1;
                        pixel_latch <= dbg_rdata[23:0];

                        // Advance x/y and indices
                        if (cur_x == SCREEN_WIDTH-1) begin
                            cur_x <= 16'd0;
                            if (cur_y == SCREEN_HEIGHT-1)
                                cur_y <= 16'd0;
                            else
                                cur_y <= cur_y + 1'b1;
                        end else begin
                            cur_x <= cur_x + 1'b1;
                        end

                        pix_index <= next_pix_index;
                        if (next_pix_index == TOTAL_PIXELS-1)
                            next_pix_index <= 32'd0;
                        else
                            next_pix_index <= next_pix_index + 1'b1;
                    end
                end
            end
        end
    end

endmodule
