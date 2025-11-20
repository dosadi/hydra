// ============================================================================
// voxel_raycaster_core_pipelined.sv
// - Very simple per-pixel ray marcher through 64^3 voxel volume.
// - Outputs extended 96-bit pixel as 3x32-bit words.
// - Supports:
//   * render_config[0] = "extra light" mode
//   * cursor ray info for center pixel
//   * selection highlight (sel_*)
// ============================================================================

`timescale 1ns/1ps

module voxel_raycaster_core_pipelined #(
    parameter SCREEN_WIDTH    = 320,
    parameter SCREEN_HEIGHT   = 240,
    parameter VOXEL_GRID_SIZE = 64,
    parameter COORD_WIDTH     = 16,
    parameter FRAC_BITS       = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    // Camera parameters (fixed-point)
    input  wire signed [15:0] cam_x,
    input  wire signed [15:0] cam_y,
    input  wire signed [15:0] cam_z,
    input  wire signed [15:0] cam_dir_x,
    input  wire signed [15:0] cam_dir_y,
    input  wire signed [15:0] cam_dir_z,
    input  wire signed [15:0] cam_plane_x,
    input  wire signed [15:0] cam_plane_y,

    // Render configuration
    input  wire [31:0] render_config,
    input  wire        enable_smooth_surfaces,
    input  wire        enable_curvature,

    // Selection controls
    input  wire        sel_active,
    input  wire [5:0]  sel_voxel_x,
    input  wire [5:0]  sel_voxel_y,
    input  wire [5:0]  sel_voxel_z,

    // Voxel memory
    output reg  [17:0] voxel_addr,
    input  wire [63:0] voxel_data,
    output reg         voxel_read_en,

    // Extended framebuffer: 3 words = 96 bits
    output reg [31:0]  pixel_word0, // reflection/refraction/attenuation/emission
    output reg [31:0]  pixel_word1, // RGB + material ID
    output reg [31:0]  pixel_word2, // normal x/y/z + curvature
    output reg [31:0]  pixel_addr,
    output reg         pixel_write_en,

    output reg         busy,
    output reg         done,

    // Cursor-ray info
    output reg         cursor_hit_valid,
    output reg [5:0]   cursor_voxel_x,
    output reg [5:0]   cursor_voxel_y,
    output reg [5:0]   cursor_voxel_z,
    output reg [7:0]   cursor_material_id,
    output reg [63:0]  cursor_voxel_data
);

    // State machine
    localparam S_IDLE        = 4'd0;
    localparam S_RENDER_PIXEL= 4'd1;
    localparam S_STEP        = 4'd2;
    localparam S_FETCH       = 4'd3;
    localparam S_SHADE       = 4'd4;
    localparam S_WRITE       = 4'd5;
    localparam S_NEXT_PIXEL  = 4'd6;

    reg [3:0]  state;

    reg [10:0] pixel_x, pixel_y;
    reg        cursor_sample;

    // Current ray voxel position
    reg [5:0]  voxel_x, voxel_y, voxel_z;
    reg [7:0]  ray_steps;
    reg        hit;

    // Latched voxel fields
    reg [7:0]  voxel_material_props;
    reg [7:0]  voxel_emissive;
    reg [7:0]  voxel_alpha;
    reg [7:0]  voxel_light;
    reg [23:0] voxel_color;
    reg [3:0]  voxel_material_type;

    // Pixel components
    reg [7:0]  pixel_reflection;
    reg [7:0]  pixel_refraction;
    reg [7:0]  pixel_attenuation;
    reg [7:0]  pixel_emission;
    reg [7:0]  pixel_r, pixel_g, pixel_b;
    reg [7:0]  pixel_material_id;
    reg [7:0]  pixel_normal_x, pixel_normal_y, pixel_normal_z;
    reg [7:0]  pixel_curvature;

    // --------------------------------------------------------------------
    // Advanced lighting helper (simplified).
    // --------------------------------------------------------------------
    task automatic apply_advanced_lighting;
        input  [31:0] cfg;
        input  [7:0]  curvature;
        inout  [7:0]  r;
        inout  [7:0]  g;
        inout  [7:0]  b;
        reg    [8:0]  tmp;
    begin
        // Simple ambient + light-term (voxel_light already applied).
        // Just add slight curvature-based boost when extra-light enabled.
        if (cfg[0]) begin
            if (curvature > 8'd32) begin
                tmp = r + (curvature >> 4); r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
                tmp = b + (curvature >> 4); b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            end
        end
    end
    endtask

    // --------------------------------------------------------------------
    // Compute pixel from voxel fields + selection
    // --------------------------------------------------------------------
    task automatic compute_pixel_data;
        reg [8:0] tmp;
    begin
        // Base lighting
        pixel_r = (voxel_color[23:16] * voxel_light) >> 8;
        pixel_g = (voxel_color[15:8]  * voxel_light) >> 8;
        pixel_b = (voxel_color[7:0]   * voxel_light) >> 8;

        // Emission
        if (voxel_emissive != 0) begin
            tmp = pixel_r + voxel_emissive; pixel_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = pixel_g + voxel_emissive; pixel_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = pixel_b + voxel_emissive; pixel_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // Material fields
        pixel_material_id = {voxel_material_type, 4'h0};

        if (voxel_material_type == 4'd3)       pixel_reflection = 8'd255;
        else if (voxel_material_type == 4'd5)  pixel_reflection = 8'd200;
        else                                   pixel_reflection = voxel_material_props[7:5] << 5;

        if (voxel_material_type == 4'd5)      pixel_refraction = 8'd128;
        else if (voxel_material_type == 4'd2) pixel_refraction = 8'd85;
        else                                  pixel_refraction = 8'd0;

        pixel_attenuation = ray_steps;
        pixel_emission    = (voxel_material_type == 4'd1) ? voxel_emissive : 8'd0;

        // Normals/curvature are stubbed: up vector
        if (!enable_smooth_surfaces) begin
            pixel_normal_x  = 8'd0;
            pixel_normal_y  = 8'd0;
            pixel_normal_z  = 8'd127;
            pixel_curvature = 8'd0;
        end

        apply_advanced_lighting(render_config, pixel_curvature,
                                pixel_r, pixel_g, pixel_b);

        // Selection highlight
        if (sel_active &&
            voxel_x == sel_voxel_x &&
            voxel_y == sel_voxel_y &&
            voxel_z == sel_voxel_z) begin
            tmp = pixel_r + 9'd96; pixel_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = pixel_g + 9'd16; pixel_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = pixel_b + 9'd96; pixel_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // Pack words:
        // word0: [31:24] reflection, [23:16] refraction, [15:8] attenuation, [7:0] emission
        // word1: [31:24] R, [23:16] G, [15:8] B, [7:0] material ID
        // word2: [31:24] nx, [23:16] ny, [15:8] nz, [7:0] curvature
        pixel_word0 <= {pixel_reflection, pixel_refraction, pixel_attenuation, pixel_emission};
        pixel_word1 <= {pixel_r, pixel_g, pixel_b, pixel_material_id};
        pixel_word2 <= {pixel_normal_x, pixel_normal_y, pixel_normal_z, pixel_curvature};
    end
    endtask

    // --------------------------------------------------------------------
    // Main FSM
    // --------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            busy             <= 1'b0;
            done             <= 1'b0;
            pixel_x          <= 11'd0;
            pixel_y          <= 11'd0;
            pixel_addr       <= 32'd0;
            pixel_write_en   <= 1'b0;
            voxel_addr       <= 18'd0;
            voxel_read_en    <= 1'b0;
            cursor_hit_valid <= 1'b0;
            cursor_voxel_x   <= 6'd0;
            cursor_voxel_y   <= 6'd0;
            cursor_voxel_z   <= 6'd0;
            cursor_material_id <= 8'd0;
            cursor_voxel_data  <= 64'd0;
        end else begin
            pixel_write_en <= 1'b0;
            voxel_read_en  <= 1'b0;
            done           <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        busy             <= 1'b1;
                        pixel_x          <= 11'd0;
                        pixel_y          <= 11'd0;
                        cursor_hit_valid <= 1'b0;
                        cursor_voxel_data<= 64'd0;
                        state            <= S_RENDER_PIXEL;
                    end
                end

                // Set up "ray" for this pixel (very simplified)
                S_RENDER_PIXEL: begin
                    ray_steps   <= 8'd0;
                    hit         <= 1'b0;

                    // For now, derive a simple voxel coord from camera + pixel Y:
                    voxel_x <= cam_x[FRAC_BITS+5:FRAC_BITS];
                    voxel_y <= pixel_y[5:0];
                    voxel_z <= pixel_x[5:0];

                    cursor_sample <= (pixel_x == (SCREEN_WIDTH  >> 1)) &&
                                     (pixel_y == (SCREEN_HEIGHT >> 1));

                    state <= S_STEP;
                end

                // Advance ray a few steps in x-direction
                S_STEP: begin
                    if (ray_steps >= 8'd40 || hit) begin
                        if (!hit) begin
                            // sky pixel (dark blue)
                            pixel_r <= 8'd30;
                            pixel_g <= 8'd30;
                            pixel_b <= 8'd60;
                            pixel_reflection  <= 8'd0;
                            pixel_refraction  <= 8'd0;
                            pixel_attenuation <= 8'd255;
                            pixel_emission    <= 8'd0;
                            pixel_material_id <= 8'hFF;
                            pixel_normal_x    <= 8'd0;
                            pixel_normal_y    <= 8'd0;
                            pixel_normal_z    <= 8'd127;
                            pixel_curvature   <= 8'd0;
                            compute_pixel_data();
                            state <= S_WRITE;
                        end else begin
                            compute_pixel_data();
                            state <= S_WRITE;
                        end
                    end else begin
                        voxel_addr    <= {voxel_x, voxel_y, voxel_z};
                        voxel_read_en <= 1'b1;
                        state         <= S_FETCH;
                    end
                end

                S_FETCH: begin
                    // Sample, test occupancy
                    if (!hit && voxel_data != 64'd0 && voxel_data[47:40] > 8'd10) begin
                        hit <= 1'b1;

                        voxel_material_props <= voxel_data[63:56];
                        voxel_emissive       <= voxel_data[55:48];
                        voxel_alpha          <= voxel_data[47:40];
                        voxel_light          <= voxel_data[39:32];
                        voxel_color          <= voxel_data[31:8];
                        voxel_material_type  <= voxel_data[7:4];

                        if (cursor_sample && !cursor_hit_valid) begin
                            cursor_hit_valid    <= 1'b1;
                            cursor_voxel_x      <= voxel_x;
                            cursor_voxel_y      <= voxel_y;
                            cursor_voxel_z      <= voxel_z;
                            cursor_material_id  <= {voxel_material_type, 4'h0};
                            cursor_voxel_data   <= voxel_data;
                        end
                    end

                    // advance along z as a fake "ray"
                    ray_steps <= ray_steps + 1'b1;
                    if (voxel_z < VOXEL_GRID_SIZE-1)
                        voxel_z <= voxel_z + 1'b1;
                    else
                        voxel_z <= 6'd0;

                    state <= S_STEP;
                end

                S_WRITE: begin
                    pixel_addr     <= pixel_y * SCREEN_WIDTH + pixel_x;
                    pixel_write_en <= 1'b1;
                    state          <= S_NEXT_PIXEL;
                end

                S_NEXT_PIXEL: begin
                    if (pixel_x == SCREEN_WIDTH-1) begin
                        pixel_x <= 11'd0;
                        if (pixel_y == SCREEN_HEIGHT-1) begin
                            pixel_y <= 11'd0;
                            busy    <= 1'b0;
                            done    <= 1'b1;
                            state   <= S_IDLE;
                        end else begin
                            pixel_y <= pixel_y + 1'b1;
                            state   <= S_RENDER_PIXEL;
                        end
                    end else begin
                        pixel_x <= pixel_x + 1'b1;
                        state   <= S_RENDER_PIXEL;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
