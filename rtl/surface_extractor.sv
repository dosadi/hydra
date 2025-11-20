// surface_extractor.sv (stub)
`timescale 1ns/1ps

module surface_extractor #(
    parameter GRID_SIZE   = 64,
    parameter COORD_WIDTH = 16,
    parameter FRAC_BITS   = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   enable,
    input  wire signed [COORD_WIDTH-1:0] hit_x,
    input  wire signed [COORD_WIDTH-1:0] hit_y,
    input  wire signed [COORD_WIDTH-1:0] hit_z,
    input  wire signed [COORD_WIDTH-1:0] ray_dir_x,
    input  wire signed [COORD_WIDTH-1:0] ray_dir_y,
    input  wire signed [COORD_WIDTH-1:0] ray_dir_z,

    output reg  [17:0]            voxel_addr,
    input  wire [63:0]            voxel_data,
    output reg                    voxel_read_en,

    output reg [7:0]              surface_normal_x,
    output reg [7:0]              surface_normal_y,
    output reg [7:0]              surface_normal_z,
    output reg [7:0]              surface_curvature,
    output reg [7:0]              surface_smoothness,
    output reg                    done
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            surface_normal_x  <= 8'd0;
            surface_normal_y  <= 8'd0;
            surface_normal_z  <= 8'd127;
            surface_curvature <= 8'd0;
            surface_smoothness<= 8'd255;
            done              <= 1'b0;
            voxel_read_en     <= 1'b0;
            voxel_addr        <= 18'd0;
        end else begin
            if (enable) begin
                // trivial: instantly "finish"
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule
