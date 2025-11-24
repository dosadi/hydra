// trilinear_interpolator.sv (stub)
`timescale 1ns/1ps

module trilinear_interpolator #(
    parameter GRID_SIZE   = 64,
    parameter COORD_WIDTH = 16,
    parameter FRAC_BITS   = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     enable,
    input  wire signed [COORD_WIDTH-1:0] sample_x,
    input  wire signed [COORD_WIDTH-1:0] sample_y,
    input  wire signed [COORD_WIDTH-1:0] sample_z,

    output reg  [17:0]              voxel_addr,
    input  wire [63:0]              voxel_data,
    output reg                      voxel_read_en,

    output reg [23:0]               interp_color,
    output reg [7:0]                interp_density,
    output reg                      done
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interp_color  <= 24'h000000;
            interp_density<= 8'd0;
            voxel_addr    <= 18'd0;
            voxel_read_en <= 1'b0;
            done          <= 1'b0;
        end else begin
            if (enable) begin
                done <= 1'b1; // no-op
            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule
