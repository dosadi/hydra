// ============================================================================
// voxel_memory_64.sv
// Dual-port voxel memory: 64 x 64 x 64 = 262,144 voxels, 64 bits each.
// Address mapping: {x[5:0], y[5:0], z[5:0]} -> [17:12]=x, [11:6]=y, [5:0]=z
// ============================================================================

`timescale 1ns/1ps

module voxel_memory_64 (
    input  wire        clk,

    // Read port
    input  wire [17:0] read_addr,
    input  wire        read_en,
    output reg  [63:0] read_data,

    // Write port
    input  wire [17:0] write_addr,
    input  wire        write_en,
    input  wire [63:0] write_data
);

    reg [63:0] vox [0:262143]; // 64^3

    always @(posedge clk) begin
        if (read_en)
            read_data <= vox[read_addr];

        if (write_en)
            vox[write_addr] <= write_data;
    end

endmodule
