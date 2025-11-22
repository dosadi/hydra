// ============================================================================
// voxel_memory_64.sv
// - Simple 1R1W block-RAM-friendly memory for 64^3 voxels.
// - Address mapping: {x[5:0], y[5:0], z[5:0]} -> [17:12]=x, [11:6]=y, [5:0]=z.
// - Write-first behavior on read-after-write to the same address.
// ============================================================================

`timescale 1ns/1ps

module voxel_memory_64 #(
    parameter integer DATA_WIDTH = 64,
    parameter integer GRID_SIZE  = 64,
    parameter integer ADDR_WIDTH = 18,
    // Simulation-only zero/init helper; synthesis will ignore the for loop.
    parameter integer INIT_ZERO  = 1'b0,
    parameter INIT_FILE          = ""
)(
    input  wire                   clk,

    // Read port
    input  wire [ADDR_WIDTH-1:0]  read_addr,
    input  wire                   read_en,
    output reg  [DATA_WIDTH-1:0]  read_data,

    // Write port
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire                   write_en,
    input  wire [DATA_WIDTH-1:0]  write_data
);

    localparam integer DEPTH = GRID_SIZE * GRID_SIZE * GRID_SIZE; // 262,144

    (* ram_style = "block", ram_decomp = "power" *)
    reg [DATA_WIDTH-1:0] vox [0:DEPTH-1];

`ifndef SYNTHESIS
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, vox);
        end else if (INIT_ZERO) begin
            for (i = 0; i < DEPTH; i = i + 1)
                vox[i] = {DATA_WIDTH{1'b0}};
        end
        read_data = {DATA_WIDTH{1'b0}};
    end
`endif

    always @(posedge clk) begin
        // Write-first behavior if read/write collide
        if (write_en)
            vox[write_addr] <= write_data;

        if (read_en) begin
            if (write_en && (write_addr == read_addr))
                read_data <= write_data;
            else
                read_data <= vox[read_addr];
        end
    end

endmodule
