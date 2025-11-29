// ============================================================================
// cdc_synchronizer.sv
// Basic CDC synchronizer primitives for clock domain crossings
// ============================================================================

module cdc_synchronizer #(
    parameter WIDTH = 1,
    parameter DEPTH = 2  // Sync stages (2-4 recommended)
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] d_in,
    output reg  [WIDTH-1:0] d_out
);

    (* ASYNC_REG = "TRUE" *)
    reg [WIDTH-1:0] sync_reg [0:DEPTH-1];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1)
                sync_reg[i] <= {WIDTH{1'b0}};
            d_out <= {WIDTH{1'b0}};
        end else begin
            sync_reg[0] <= d_in;
            for (i = 1; i < DEPTH; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
            d_out <= sync_reg[DEPTH-1];
        end
    end

endmodule

// Pulse synchronizer (for level to pulse conversion across domains)
module cdc_pulse_sync (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire rst_n,
    input  wire pulse_in,
    output wire pulse_out
);

    // Source domain: pulse to level
    reg pulse_level;
    always @(posedge clk_src or negedge rst_n) begin
        if (!rst_n)
            pulse_level <= 1'b0;
        else if (pulse_in)
            pulse_level <= 1'b1;
        else if (pulse_level && pulse_level_dst_sync)
            pulse_level <= 1'b0;
    end

    // Synchronize level to destination domain
    wire pulse_level_dst_sync;
    cdc_synchronizer #(.WIDTH(1), .DEPTH(2)) level_sync (
        .clk(clk_dst),
        .rst_n(rst_n),
        .d_in(pulse_level),
        .d_out(pulse_level_dst_sync)
    );

    // Destination domain: level to pulse
    reg pulse_level_dst_prev;
    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n)
            pulse_level_dst_prev <= 1'b0;
        else
            pulse_level_dst_prev <= pulse_level_dst_sync;
    end

    assign pulse_out = pulse_level_dst_sync && !pulse_level_dst_prev;

endmodule
