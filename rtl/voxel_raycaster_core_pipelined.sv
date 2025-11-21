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
    output reg [63:0]  cursor_voxel_data,
    output reg [31:0]  dbg_hit_count
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

    // Ray/sample accumulators
    localparam ACC_WIDTH = 24;
    reg signed [ACC_WIDTH-1:0] ray_pos_x, ray_pos_y, ray_pos_z;
    reg [5:0] sample_voxel_x, sample_voxel_y, sample_voxel_z;

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
        reg [7:0] out_r, out_g, out_b;
        reg [7:0] out_reflection, out_refraction, out_attenuation, out_emission;
        reg [7:0] out_material_id;
        reg [7:0] out_normal_x, out_normal_y, out_normal_z, out_curvature;
    begin
        // Base lighting
        out_r = (voxel_color[23:16] * voxel_light) >> 8;
        out_g = (voxel_color[15:8]  * voxel_light) >> 8;
        out_b = (voxel_color[7:0]   * voxel_light) >> 8;
        if (out_r == 0 && out_g == 0 && out_b == 0) begin
            // Fallback in case light or color was zeroed; keep something visible.
            out_r = voxel_color[23:16];
            out_g = voxel_color[15:8];
            out_b = voxel_color[7:0];
        end

        // Emission
        if (voxel_emissive != 0) begin
            tmp = out_r + voxel_emissive; out_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_g + voxel_emissive; out_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_b + voxel_emissive; out_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // Material fields
        out_material_id = {voxel_material_type, 4'h0};

        if (voxel_material_type == 4'd3)       out_reflection = 8'd255;
        else if (voxel_material_type == 4'd5)  out_reflection = 8'd200;
        else                                   out_reflection = voxel_material_props[7:5] << 5;

        if (voxel_material_type == 4'd5)      out_refraction = 8'd128;
        else if (voxel_material_type == 4'd2) out_refraction = 8'd85;
        else                                  out_refraction = 8'd0;

        out_attenuation = ray_steps;
        out_emission    = (voxel_material_type == 4'd1) ? voxel_emissive : 8'd0;

        // Normals/curvature are stubbed: up vector unless smooth surfaces enabled
        out_normal_x  = pixel_normal_x;
        out_normal_y  = pixel_normal_y;
        out_normal_z  = pixel_normal_z;
        out_curvature = pixel_curvature;
        if (!enable_smooth_surfaces) begin
            out_normal_x  = 8'd0;
            out_normal_y  = 8'd0;
            out_normal_z  = 8'd127;
            out_curvature = 8'd0;
        end

        apply_advanced_lighting(render_config, out_curvature,
                                out_r, out_g, out_b);

        // Selection highlight
        if (sel_active &&
            voxel_x == sel_voxel_x &&
            voxel_y == sel_voxel_y &&
            voxel_z == sel_voxel_z) begin
            tmp = out_r + 9'd96; out_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_g + 9'd16; out_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_b + 9'd96; out_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // Commit results with non-blocking assignments to keep sequential logic consistent
        pixel_reflection  <= out_reflection;
        pixel_refraction  <= out_refraction;
        pixel_attenuation <= out_attenuation;
        pixel_emission    <= out_emission;
        pixel_r           <= out_r;
        pixel_g           <= out_g;
        pixel_b           <= out_b;
        pixel_material_id <= out_material_id;
        pixel_normal_x    <= out_normal_x;
        pixel_normal_y    <= out_normal_y;
        pixel_normal_z    <= out_normal_z;
        pixel_curvature   <= out_curvature;

        // Pack words:
        // word0: [31:24] reflection, [23:16] refraction, [15:8] attenuation, [7:0] emission
        // word1: [31:24] R, [23:16] G, [15:8] B, [7:0] material ID
        // word2: [31:24] nx, [23:16] ny, [15:8] nz, [7:0] curvature
        pixel_word0 <= {out_reflection, out_refraction, out_attenuation, out_emission};
        pixel_word1 <= {out_r, out_g, out_b, out_material_id};
        pixel_word2 <= {out_normal_x, out_normal_y, out_normal_z, out_curvature};
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
            dbg_hit_count    <= 32'd0;
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
                        dbg_hit_count    <= 32'd0;
                        state            <= S_RENDER_PIXEL;
                    end
                end

                // Set up "ray" for this pixel (very simplified)
                S_RENDER_PIXEL: begin
                    ray_steps   <= 8'd0;
                    hit         <= 1'b0;

                    // Deterministic orthographic scan: map screen to Y/Z, march along -X
                    begin : dir_calc
                        reg [17:0] map_y;
                        reg [17:0] map_z;
                        map_y = (pixel_y * (VOXEL_GRID_SIZE-1)) / (SCREEN_HEIGHT-1);
                        map_z = (pixel_x * (VOXEL_GRID_SIZE-1)) / (SCREEN_WIDTH-1);

                        ray_pos_x <= (VOXEL_GRID_SIZE-1) <<< FRAC_BITS;
                        ray_pos_y <= map_y <<< FRAC_BITS;
                        ray_pos_z <= map_z <<< FRAC_BITS;
                    end

                    cursor_sample <= (pixel_x == (SCREEN_WIDTH  >> 1)) &&
                                     (pixel_y == (SCREEN_HEIGHT >> 1));

                    state <= S_STEP;
                end

                // Advance ray along -X
                S_STEP: begin
                    if (ray_steps >= 8'd128 || hit) begin
                        if (!hit) begin
                            // sky pixel (dark blue), bypass voxel-based shader
                            pixel_word0      <= {8'd0, 8'd0, 8'd255, 8'd0};
                            pixel_word1      <= {8'd30, 8'd30, 8'd60, 8'hFF};
                            pixel_word2      <= {8'd0, 8'd0, 8'd127, 8'd0};
                            pixel_reflection <= 8'd0;
                            pixel_refraction <= 8'd0;
                            pixel_attenuation<= 8'd255;
                            pixel_emission   <= 8'd0;
                            pixel_r          <= 8'd30;
                            pixel_g          <= 8'd30;
                            pixel_b          <= 8'd60;
                            pixel_material_id<= 8'hFF;
                            pixel_normal_x   <= 8'd0;
                            pixel_normal_y   <= 8'd0;
                            pixel_normal_z   <= 8'd127;
                            pixel_curvature  <= 8'd0;
                            state            <= S_WRITE;
                        end else begin
                            compute_pixel_data();
                            state <= S_WRITE;
                        end
                    end else begin
                        // Sample current ray position -> voxel coords (wrap into 0..63)
                        reg [ACC_WIDTH-1:0] wide_x;
                        reg [ACC_WIDTH-1:0] wide_y;
                        reg [ACC_WIDTH-1:0] wide_z;
                        reg [5:0] trunc_x;
                        reg [5:0] trunc_y;
                        reg [5:0] trunc_z;
                        wide_x  = ray_pos_x >>> FRAC_BITS;
                        wide_y  = (ray_pos_y + {{(ACC_WIDTH-8){1'b0}}, ray_steps}) >>> FRAC_BITS;
                        wide_z  = (ray_pos_z + {{(ACC_WIDTH-8){1'b0}}, ray_steps}) >>> FRAC_BITS;
                        trunc_x = wide_x[5:0];
                        trunc_y = wide_y[5:0];
                        trunc_z = wide_z[5:0];
                        sample_voxel_x <= trunc_x;
                        sample_voxel_y <= trunc_y;
                        sample_voxel_z <= trunc_z;
                        voxel_x        <= trunc_x;
                        voxel_y        <= trunc_y;
                        voxel_z        <= trunc_z;
                        voxel_addr     <= {trunc_x, trunc_y, trunc_z};
                        voxel_read_en <= 1'b1;
                        state         <= S_FETCH;

                        // Step along -X by half a voxel to increase sampling density
                        ray_pos_x <= ray_pos_x - (18'sd1 <<< (FRAC_BITS-1));
                        ray_steps <= ray_steps + 1'b1;
                    end
                end

                S_FETCH: begin
                    // Sample, test occupancy
                    if (!hit && voxel_data != 64'd0 && voxel_data[47:40] > 8'd10) begin
                        hit <= 1'b1;
                        dbg_hit_count <= dbg_hit_count + 1'b1;

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
