// ============================================================================
// surface_extractor.sv
// - Surface extraction stub for extracting normals and curvature from voxel data.
// - Part of 3D blitter feature set (see docs/hydra_spec.md BAR0 0x0100+).
// - Currently returns fixed placeholder values; full implementation pending.
// ============================================================================

`timescale 1ns/1ps

module surface_extractor #(
    parameter integer GRID_SIZE   = 64,
    parameter integer COORD_WIDTH = 16,
    parameter integer FRAC_BITS   = 8
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
    // ------------------------------------------------------------------------
    // SVAs and Covergroups for surface extraction protocol and correctness
    // ------------------------------------------------------------------------
    // SVA: Done only pulses when enable is high
    property done_only_on_enable;
        @(posedge clk) disable iff (!rst_n)
        done |-> enable;
    endproperty
    done_only_on_enable_sva: assert property (done_only_on_enable);

    // SVA: Output bounds (normals, curvature, smoothness)
    property output_bounds;
        @(posedge clk) disable iff (!rst_n)
        (surface_normal_x <= 8'd255 && surface_normal_y <= 8'd255 && surface_normal_z <= 8'd255 && surface_curvature <= 8'd255 && surface_smoothness <= 8'd255);
    endproperty
    output_bounds_sva: assert property (output_bounds);
    `ifdef FORMAL
        // SVA: Done only pulses when enable is high
        property done_only_on_enable;
            @(posedge clk) disable iff (!rst_n)
            done |-> enable;
        endproperty
        done_only_on_enable_sva: assert property (done_only_on_enable);

        // SVA: Output bounds (normals, curvature, smoothness)
        property output_bounds;
            @(posedge clk) disable iff (!rst_n)
            (surface_normal_x <= 8'd255 && surface_normal_y <= 8'd255 && surface_normal_z <= 8'd255 && surface_curvature <= 8'd255 && surface_smoothness <= 8'd255);
        endproperty
        output_bounds_sva: assert property (output_bounds);
    `endif

`ifndef VERILATOR
    // Covergroup: Extraction event types
    covergroup cg_extraction_events @(posedge clk);
        done_evt: coverpoint done;
        enable_evt: coverpoint enable;
    endgroup
    cg_extraction_events_inst = new();
`endif // VERILATOR

    // ------------------------------------------------------------------------
    // Stub: Future surface extraction logic
    // TODO: Implement real normal and curvature computation based on voxel_data
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
                // TODO: Add real surface extraction logic here
                // For now, instantly "finish" with placeholder values
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule
