// ============================================================================
// voxel_world_gen.sv
// - Procedural scene generator for 64^3 volume.
// - Clears memory, writes a lit floor, an emissive ceiling, and two spheres.
// - Drives a write port into voxel_memory_64.
// ============================================================================

`timescale 1ns/1ps

module voxel_world_gen #(
    parameter GRID_SIZE = 64
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         busy,
    output reg         done,

    output reg [17:0]  write_addr,
    output reg         write_en,
    output reg [63:0]  write_data
);

    localparam S_IDLE     = 3'd0;
    localparam S_CLEAR    = 3'd1;
    localparam S_PLANES   = 3'd2;
    localparam S_SPHERE0  = 3'd3;
    localparam S_SPHERE1  = 3'd4;
    localparam S_FINISH   = 3'd5;

    reg [2:0] state;

    reg [5:0] x, y, z;

    reg  signed [7:0] dx, dy, dz;
    reg  [15:0] dist2;
    reg  [15:0] radius2_0;
    reg  [15:0] radius2_1;

    localparam [5:0] SPH0_CX = 6'd32;
    localparam [5:0] SPH0_CY = 6'd32;
    localparam [5:0] SPH0_CZ = 6'd32;

    localparam [5:0] SPH1_CX = 6'd38;
    localparam [5:0] SPH1_CY = 6'd32;
    localparam [5:0] SPH1_CZ = 6'd28;

    localparam [5:0] FLOOR_Y = 6'd12;
    localparam [5:0] LIGHT_Y = 6'd52;

    initial begin
        radius2_0 = 16'd18 * 16'd18;
        radius2_1 = 16'd7  * 16'd7;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            busy       <= 1'b0;
            done       <= 1'b0;
            write_en   <= 1'b0;
            write_addr <= 18'd0;
            write_data <= 64'd0;
            x          <= 6'd0;
            y          <= 6'd0;
            z          <= 6'd0;
        end else begin
            write_en <= 1'b0;
            done     <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        x    <= 6'd0;
                        y    <= 6'd0;
                        z    <= 6'd0;
                        state <= S_CLEAR;
                    end
                end

                // Clear volume
                S_CLEAR: begin
                    write_addr <= {x, y, z};
                    write_data <= 64'd0;
                    write_en   <= 1'b1;

                    if (z == GRID_SIZE-1) begin
                        z <= 0;
                        if (y == GRID_SIZE-1) begin
                            y <= 0;
                            if (x == GRID_SIZE-1) begin
                                x <= 0;
                                state <= S_PLANES;
                            end else x <= x + 1'b1;
                        end else y <= y + 1'b1;
                    end else z <= z + 1'b1;
                end

                // Floor (at y=FLOOR_Y) and ceiling light plane (at y=LIGHT_Y)
                S_PLANES: begin
                    if (y == FLOOR_Y) begin
                        write_addr <= {x, y, z};
                        write_data <= {
                            8'd196,    // material_props
                            8'd0,      // emissive
                            8'd255,    // alpha
                            8'd150,    // light (base, boosted by shader)
                            8'h40, 8'h50, 8'h60, // RGB (cool floor)
                            4'd6, 4'd0           // material_type, reserved
                        };
                        write_en <= 1'b1;
                    end else if (y == LIGHT_Y) begin
                        write_addr <= {x, y, z};
                        write_data <= {
                            8'd255,    // material_props
                            8'd255,    // emissive (acts as light source)
                            8'd255,    // alpha
                            8'd255,    // light
                            8'hFF, 8'hD0, 8'hA0, // RGB (warm ceiling light)
                            4'd1, 4'd0           // material_type, reserved
                        };
                        write_en <= 1'b1;
                    end

                    if (z == GRID_SIZE-1) begin
                        z <= 0;
                        if (y == GRID_SIZE-1) begin
                            y <= 0;
                            if (x == GRID_SIZE-1) begin
                                x <= 0;
                                state <= S_SPHERE0;
                            end else x <= x + 1'b1;
                        end else y <= y + 1'b1;
                    end else z <= z + 1'b1;
                end

                // Large diffuse sphere
                S_SPHERE0: begin
                    dx = $signed({1'b0,x}) - $signed({1'b0,SPH0_CX});
                    dy = $signed({1'b0,y}) - $signed({1'b0,SPH0_CY});
                    dz = $signed({1'b0,z}) - $signed({1'b0,SPH0_CZ});
                    dist2 = dx*dx + dy*dy + dz*dz;

                    if (dist2 <= radius2_0) begin
                        write_addr <= {x, y, z};
                        write_data <= {
                            8'd180,      // material_props
                            8'd0,        // emissive
                            8'd255,      // alpha
                            8'd220,      // light
                            8'h40, 8'hC0, 8'hFF, // RGB (bright cyan)
                            4'd5, 4'd0           // material_type, reserved
                        };
                        write_en <= 1'b1;
                    end

                    if (z == GRID_SIZE-1) begin
                        z <= 0;
                        if (y == GRID_SIZE-1) begin
                            y <= 0;
                            if (x == GRID_SIZE-1) begin
                                x <= 0;
                                state <= S_SPHERE1;
                            end else x <= x + 1'b1;
                        end else y <= y + 1'b1;
                    end else z <= z + 1'b1;
                end

                // Smaller emissive sphere
                S_SPHERE1: begin
                    dx = $signed({1'b0,x}) - $signed({1'b0,SPH1_CX});
                    dy = $signed({1'b0,y}) - $signed({1'b0,SPH1_CY});
                    dz = $signed({1'b0,z}) - $signed({1'b0,SPH1_CZ});
                    dist2 = dx*dx + dy*dy + dz*dz;

                    if (dist2 <= radius2_1) begin
                        write_addr <= {x, y, z};
                        write_data <= {
                            8'd64,       // material_props
                            8'd200,      // emissive
                            8'd255,      // alpha
                            8'd220,      // light
                            8'hFF, 8'h40, 8'hFF, // RGB (magenta-ish)
                            4'd1, 4'd0           // material_type, reserved
                        };
                        write_en <= 1'b1;
                    end

                    if (z == GRID_SIZE-1) begin
                        z <= 0;
                        if (y == GRID_SIZE-1) begin
                            y <= 0;
                            if (x == GRID_SIZE-1) begin
                                x <= 0;
                                state <= S_FINISH;
                            end else x <= x + 1'b1;
                        end else y <= y + 1'b1;
                    end else z <= z + 1'b1;
                end

                S_FINISH: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
