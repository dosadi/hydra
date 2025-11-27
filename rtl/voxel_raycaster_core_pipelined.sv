// ============================================================================
// voxel_raycaster_core_pipelined.sv
// - Very simple per-pixel ray marcher through 64^3 voxel volume.
// - Outputs extended 96-bit pixel as 3x32-bit words.
// - Supports:
//   * render_config[0] = "extra light" mode
//   * render_config[1] = diagnostic slice mode (orthographic Y/Z slices)
//   * cursor ray info for center pixel
//   * selection highlight (sel_*)
// ============================================================================

`timescale 1ns/1ps

module voxel_raycaster_core_pipelined #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64,
    parameter integer COORD_WIDTH     = 16,
    parameter integer FRAC_BITS       = 8,
    // Maximal ray steps per pixel in normal mode (sim can override for speed).
    parameter integer MAX_RAY_STEPS = 128,
    // Fixed-point step size along -X (1<<(FRAC_BITS-1) matches original half-voxel).
    parameter integer RAY_STEP_SHIFT = FRAC_BITS-1
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

    // Extended framebuffer: 3 words = 96 bits + 1 reemissure32 sidecar
    output reg [31:0]  pixel_word0,   // reflection/refraction/attenuation/emission
    output reg [31:0]  pixel_word1,   // RGB + material ID
    output reg [31:0]  pixel_word2,   // normal x/y/z + curvature
    output reg [31:0]  pixel_sidecar, // reemissure32: material_props | emissive | light | alpha
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
    output reg [31:0]  dbg_hit_count,
    output reg [31:0]  dbg_ray_steps_total,
    output reg [7:0]   dbg_ray_steps_max,
    output reg [31:0]  dbg_ray_miss_count
);

`ifdef FORMAL
    // Coverage: pixel_addr and ray_steps
    covergroup cg_pixel_addr @(posedge clk);
        pixel_addr_cp: coverpoint pixel_addr {
            bins low[] = {[0:SCREEN_WIDTH*SCREEN_HEIGHT/4-1]};
            bins mid[] = {[SCREEN_WIDTH*SCREEN_HEIGHT/4:3*SCREEN_WIDTH*SCREEN_HEIGHT/4-1]};
            bins high[] = {[3*SCREEN_WIDTH*SCREEN_HEIGHT/4:SCREEN_WIDTH*SCREEN_HEIGHT-1]};
        }
    endgroup
    cg_pixel_addr u_cg_pixel_addr = new();

    covergroup cg_ray_steps @(posedge clk);
        ray_steps_cp: coverpoint ray_steps {
            bins short = {[0:MAX_RAY_STEPS/4-1]};
            bins medium = {[MAX_RAY_STEPS/4:MAX_RAY_STEPS/2-1]};
            bins long = {[MAX_RAY_STEPS/2:MAX_RAY_STEPS-1]};
        }
    endgroup
    cg_ray_steps u_cg_ray_steps = new();

    // SVA: busy only high during active render
    property busy_only_when_active;
        @(posedge clk) disable iff (!rst_n)
        busy |-> (state != S_IDLE);
    endproperty
    busy_only_when_active_sva: assert property (busy_only_when_active);

    // SVA: done only pulses after busy
    property done_after_busy;
        @(posedge clk) disable iff (!rst_n)
        done |-> busy;
    endproperty
    done_after_busy_sva: assert property (done_after_busy);

    // SVA: pixel_addr monotonicity during write
    property pixel_addr_monotonic;
        @(posedge clk) disable iff (!rst_n)
        pixel_write_en |-> pixel_addr >= $past(pixel_addr);
    endproperty
    pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

    // SVA: pixel_write_en only when busy
    property pixel_write_en_when_busy;
        @(posedge clk) disable iff (!rst_n)
        pixel_write_en |-> busy;
    endproperty
    pixel_write_en_when_busy_sva: assert property (pixel_write_en_when_busy);
`endif

    // --------------------------------------------------------------------
    // Coverage: pixel_addr and ray_steps
    // --------------------------------------------------------------------
    // covergroup cg_pixel_addr @(posedge clk);
    //     pixel_addr_cp: coverpoint pixel_addr {
    //         bins low[] = {[0:SCREEN_WIDTH*SCREEN_HEIGHT/4-1]};
    //         bins mid[] = {[SCREEN_WIDTH*SCREEN_HEIGHT/4:3*SCREEN_WIDTH*SCREEN_HEIGHT/4-1]};
    //         bins high[] = {[3*SCREEN_WIDTH*SCREEN_HEIGHT/4:SCREEN_WIDTH*SCREEN_HEIGHT-1]};
    //     }
    // endgroup
    // cg_pixel_addr u_cg_pixel_addr = new();

    // covergroup cg_ray_steps @(posedge clk);
    //     ray_steps_cp: coverpoint ray_steps {
    //         bins short = {[0:MAX_RAY_STEPS/4-1]};
    //         bins medium = {[MAX_RAY_STEPS/4:MAX_RAY_STEPS/2-1]};
    //         bins long = {[MAX_RAY_STEPS/2:MAX_RAY_STEPS-1]};
    //     }
    // endgroup
    // cg_ray_steps u_cg_ray_steps = new();
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

    // Simple 2x2 supersampling accumulators (RGB only).
    reg [1:0]  sample_idx;
    reg [15:0] acc_r, acc_g, acc_b;

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
    reg [31:0] pixel_sidecar_word;

    // Ray/sample accumulators
    localparam ACC_WIDTH = 24;
    localparam integer JITTER_SHIFT = (FRAC_BITS > 2) ? FRAC_BITS-3 : 0;
    localparam signed [ACC_WIDTH-1:0] JITTER_STEP = 1 <<< JITTER_SHIFT;
    localparam signed [ACC_WIDTH-1:0] GRID_MAX_SHIFT = (VOXEL_GRID_SIZE-1) <<< FRAC_BITS;
    reg signed [ACC_WIDTH-1:0] ray_pos_x, ray_pos_y, ray_pos_z;
    reg [5:0] sample_voxel_x, sample_voxel_y, sample_voxel_z;
    reg [5:0] map_voxel_y, map_voxel_z;
    localparam integer NUM_SLICES = 7;
    localparam [5:0] SLICE_X_START = 6'd56; // march slices from camera side toward origin
    localparam [5:0] SLICE_STEP    = 6'd8;
    reg [2:0] slice_idx;
    reg       best_hit;
    reg [7:0] best_emissive;
    wire diag_slice_mode = render_config[1];
    wire ray_jitter_mode = render_config[2];
    wire signed [3:0] jitter_sel_y = {1'b0, pixel_y[2:0]} - 4'sd3;
    wire signed [3:0] jitter_sel_z = {1'b0, pixel_x[2:0]} - 4'sd3;
    wire signed [ACC_WIDTH-1:0] jitter_y_delta = ray_jitter_mode ? (jitter_sel_y * JITTER_STEP) : 0;
    wire signed [ACC_WIDTH-1:0] jitter_z_delta = ray_jitter_mode ? (jitter_sel_z * JITTER_STEP) : 0;

    // Simple hard-coded lighting/shadow references for the demo scene.
    localparam [5:0] FLOOR_MIN_Y    = 6'd8;
    localparam [5:0] FLOOR_MAX_Y    = 6'd16;
    localparam [5:0] LIGHT_PLANE_Y  = 6'd52;
    localparam [5:0] SHADOW_CX      = 6'd32;
    localparam [5:0] SHADOW_CZ      = 6'd32;
    localparam [15:0] SHADOW_RADIUS2 = 16'd324; // 18^2 (matches main sphere)

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

    // Soft shadow falloff: extend radius by a fixed band so the floor shadow
    // transitions smoothly instead of a hard on/off circle.
    localparam [15:0] SHADOW_SOFT_WIDTH2 = 16'd256; // extra band beyond SHADOW_RADIUS2
    localparam [15:0] SHADOW_OUTER2      = SHADOW_RADIUS2 + SHADOW_SOFT_WIDTH2;

    // --------------------------------------------------------------------
    // Compute pixel from voxel fields + selection
    // --------------------------------------------------------------------
    task automatic compute_pixel_data;
        reg [8:0] tmp;
        reg [7:0] out_r, out_g, out_b;
        reg [7:0] out_reflection, out_refraction, out_attenuation, out_emission;
        reg [7:0] out_material_id;
        reg [7:0] out_normal_x, out_normal_y, out_normal_z, out_curvature;
        reg [31:0] out_sidecar;
        reg [7:0] grad_coord_r, grad_coord_g, grad_coord_b;
        reg [9:0] mix_r, mix_g, mix_b;
        reg       shadow_hit;
        reg [7:0] shadow_scale;
        reg [15:0] scaled;
        reg signed [7:0] sh_dx, sh_dz;
        reg [15:0] sh_dist2;
        reg [15:0] sh_delta;
        reg [15:0] sh_blend;
        reg [7:0]  sh_t;
        reg [15:0] light_term;
        reg [23:0] mul_tmp;
        reg signed [7:0] n_x, n_y, n_z;
        reg signed [7:0] l_x, l_y, l_z;
        reg signed [17:0] nl_acc;
        reg [7:0]  lambert_scale;
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

        // Emission: brighten proportional to existing color to preserve hue
        if (voxel_emissive != 0) begin
            tmp = out_r + ((voxel_emissive * out_r) >> 8); out_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_g + ((voxel_emissive * out_g) >> 8); out_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_b + ((voxel_emissive * out_b) >> 8); out_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // ------------------------------------------------------------------------
        // Stub: Material ID usage for advanced shading/material effects
        // TODO: Integrate material_id into shading pipeline for future features
        reg [7:0] material_id;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                material_id <= 8'd0;
            end else begin
                // TODO: Use material_id for advanced shading/material effects
                // Currently set to zero for debug compatibility
                material_id <= 8'd0;
            end
        end
        // ------------------------------------------------------------------------

        if (voxel_material_type == 4'd3)       out_reflection = 8'd255;
        else if (voxel_material_type == 4'd5)  out_reflection = 8'd200;
        else                                   out_reflection = voxel_material_props[7:5] << 5;

        if (voxel_material_type == 4'd5)      out_refraction = 8'd128;
        else if (voxel_material_type == 4'd2) out_refraction = 8'd85;
        else                                  out_refraction = 8'd0;

        out_attenuation = ray_steps;
        out_emission    = (voxel_material_type == 4'd1) ? voxel_emissive : 8'd0;

        // NOTE: Normals/curvature are stubbed (up vector) unless smooth surfaces enabled. For full normal computation, extend this logic to use voxel geometry.
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

        // Simple Lambert term using approximate geometry-based normals and a
        // point light near the small emissive sphere.
        // Floor: up-normal; spheres: radial normal from their respective centers.
        if (voxel_material_type == 4'd6) begin
            n_x = 8'sd0;
            n_y = 8'sd127;
            n_z = 8'sd0;
        end else if (voxel_material_type == 4'd5) begin
            n_x = $signed({1'b0,voxel_x}) - $signed({1'b0,6'd32});
            n_y = $signed({1'b0,voxel_y}) - $signed({1'b0,6'd32});
            n_z = $signed({1'b0,voxel_z}) - $signed({1'b0,6'd32});
        end else if (voxel_material_type == 4'd1) begin
            n_x = $signed({1'b0,voxel_x}) - $signed({1'b0,6'd38});
            n_y = $signed({1'b0,voxel_y}) - $signed({1'b0,6'd32});
            n_z = $signed({1'b0,voxel_z}) - $signed({1'b0,6'd28});
        end else begin
            n_x = 8'sd0;
            n_y = 8'sd127;
            n_z = 8'sd0;
        end

        // Light vector from hit voxel toward the small emissive sphere.
        l_x = $signed({1'b0,6'd38}) - $signed({1'b0,voxel_x});
        l_y = $signed({1'b0,6'd32}) - $signed({1'b0,voxel_y});
        l_z = $signed({1'b0,6'd28}) - $signed({1'b0,voxel_z});

        // Dot product N·L, clamp to [0, 255] range for scaling.
        nl_acc = n_x * l_x + n_y * l_y + n_z * l_z;
        if (nl_acc <= 0) begin
            lambert_scale = 8'd0;
        end else begin
            // Take a coarse upper byte as the diffuse factor.
            lambert_scale = (nl_acc[17:10] > 8'hFF) ? 8'hFF : nl_acc[17:10];
        end

        // Apply Lambert to the already light-multiplied color.
        if (lambert_scale != 8'd0) begin
            out_r = (out_r * lambert_scale) >> 8;
            out_g = (out_g * lambert_scale) >> 8;
            out_b = (out_b * lambert_scale) >> 8;
        end

        apply_advanced_lighting(render_config, out_curvature,
                                out_r, out_g, out_b);

        grad_coord_r = {voxel_x, voxel_y[1:0]};
        grad_coord_g = {voxel_y, voxel_z[1:0]};
        grad_coord_b = {voxel_z, voxel_x[1:0]};
        mix_r = (out_r * 3) + grad_coord_r;
        mix_g = (out_g * 3) + grad_coord_g;
        mix_b = (out_b * 3) + grad_coord_b;
        out_r = mix_r[9:2];
        out_g = mix_g[9:2];
        out_b = mix_b[9:2];

        shadow_hit   = 1'b0;
        shadow_scale = 8'd255;
        if (voxel_y >= FLOOR_MIN_Y && voxel_y <= FLOOR_MAX_Y) begin
            sh_dx = $signed({1'b0,voxel_x}) - $signed({1'b0,SHADOW_CX});
            sh_dz = $signed({1'b0,voxel_z}) - $signed({1'b0,SHADOW_CZ});
            sh_dist2 = sh_dx * sh_dx + sh_dz * sh_dz;
            if (sh_dist2 <= SHADOW_OUTER2) begin
                shadow_hit = 1'b1;
                if (sh_dist2 <= SHADOW_RADIUS2) begin
                    shadow_scale = 8'd120;
                end else begin
                    sh_delta = sh_dist2 - SHADOW_RADIUS2;
                    if (sh_delta > SHADOW_SOFT_WIDTH2)
                        sh_delta = SHADOW_SOFT_WIDTH2;
                    sh_blend = (sh_delta * 8'd135) / SHADOW_SOFT_WIDTH2;
                    shadow_scale = 8'd120 + sh_blend;
                    if (shadow_scale > 8'd255)
                        shadow_scale = 8'd255;
                end
            end
        end

        if (shadow_hit) begin
            out_r = (out_r * shadow_scale) >> 8;
            out_g = (out_g * shadow_scale) >> 8;
            out_b = (out_b * shadow_scale) >> 8;
        end

        // Selection highlight
        if (sel_active &&
            voxel_x == sel_voxel_x &&
            voxel_y == sel_voxel_y &&
            voxel_z == sel_voxel_z) begin
            tmp = out_r + 9'd96; out_r = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_g + 9'd16; out_g = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
            tmp = out_b + 9'd96; out_b = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
        end

        // Sidecar packs reflection/refraction/emissive/absorptive for future use
        // [31:24] reflection, [23:16] refraction, [15:8] emissive, [7:0] attenuation/absorptive
        out_sidecar = {out_reflection, out_refraction, voxel_emissive, out_attenuation};

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
        pixel_sidecar_word<= out_sidecar;

        // Pack words:
        // word0: [31:24] reflection, [23:16] refraction, [15:8] attenuation, [7:0] emission
        // word1: [31:24] R, [23:16] G, [15:8] B, [7:0] material ID
        // word2: [31:24] nx, [23:16] ny, [15:8] nz, [7:0] curvature
        // sidecar: [31:24] reflection, [23:16] refraction, [15:8] emissive, [7:0] attenuation/absorptive
        pixel_word0 <= {out_reflection, out_refraction, out_attenuation, out_emission};
        pixel_word1 <= {out_r, out_g, out_b, out_material_id};
        pixel_word2 <= {out_normal_x, out_normal_y, out_normal_z, out_curvature};
        pixel_sidecar <= out_sidecar;
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
            dbg_ray_steps_total <= 32'd0;
            dbg_ray_steps_max   <= 8'd0;
            dbg_ray_miss_count  <= 32'd0;
            slice_idx        <= 2'd0;
            best_hit         <= 1'b0;
            best_emissive    <= 8'd0;
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
                        dbg_ray_steps_total <= 32'd0;
                        dbg_ray_steps_max   <= 8'd0;
                        dbg_ray_miss_count  <= 32'd0;
                        state            <= S_RENDER_PIXEL;
                    end
                end

                // Set up "ray" for this pixel (very simplified)
                S_RENDER_PIXEL: begin
                    ray_steps   <= 8'd0;
                    hit         <= 1'b0;
                    slice_idx   <= 2'd0;
                    best_hit    <= 1'b0;
                    best_emissive <= 8'd0;

                    // Deterministic orthographic scan: map screen to Y/Z, march along -X
                    begin : dir_calc
                        reg [17:0] map_y;
                        reg [17:0] map_z;
                        reg signed [ACC_WIDTH-1:0] y_init;
                        reg signed [ACC_WIDTH-1:0] z_init;
                        map_y = ((SCREEN_HEIGHT-1 - pixel_y) * (VOXEL_GRID_SIZE-1)) / (SCREEN_HEIGHT-1);
                        map_z = (pixel_x * (VOXEL_GRID_SIZE-1)) / (SCREEN_WIDTH-1);

                        y_init = map_y <<< FRAC_BITS;
                        z_init = map_z <<< FRAC_BITS;
                        if (ray_jitter_mode) begin
                            y_init = y_init + jitter_y_delta;
                            z_init = z_init + jitter_z_delta;
                        end
                        if (y_init < 0)
                            y_init = 0;
                        else if (y_init > GRID_MAX_SHIFT)
                            y_init = GRID_MAX_SHIFT;
                        if (z_init < 0)
                            z_init = 0;
                        else if (z_init > GRID_MAX_SHIFT)
                            z_init = GRID_MAX_SHIFT;

                        ray_pos_x <= GRID_MAX_SHIFT;
                        ray_pos_y <= y_init;
                        ray_pos_z <= z_init;
                        map_voxel_y <= map_y[5:0];
                        map_voxel_z <= map_z[5:0];
                    end

                    cursor_sample <= (pixel_x == (SCREEN_WIDTH  >> 1)) &&
                                     (pixel_y == (SCREEN_HEIGHT >> 1));

                    state <= S_STEP;
                end

                // Advance ray along -X
                S_STEP: begin
                    if (diag_slice_mode) begin
                        if (slice_idx >= NUM_SLICES[2:0]) begin
                            if (!best_hit) begin
                                // sky pixel (dark blue) with slight vertical gradient
                                reg [7:0] sky_r, sky_g, sky_b;
                                sky_r = 8'd10 + (pixel_y[7:0] >> 3);
                                sky_g = 8'd40 + (pixel_y[7:0] >> 3);
                                sky_b = 8'd90 + (pixel_y[7:0] >> 2);
                                pixel_word0      <= {8'd0, 8'd0, 8'd255, 8'd0};
                                pixel_word1      <= {sky_r, sky_g, sky_b, 8'hFF};
                                pixel_word2      <= {8'd0, 8'd0, 8'd127, 8'd0};
                                pixel_reflection <= 8'd0;
                                pixel_refraction <= 8'd0;
                                pixel_attenuation<= 8'd255;
                                pixel_emission   <= 8'd0;
                                pixel_r          <= sky_r;
                                pixel_g          <= sky_g;
                                pixel_b          <= sky_b;
                                pixel_material_id<= 8'hFF;
                                pixel_normal_x   <= 8'd0;
                                pixel_normal_y   <= 8'd0;
                                pixel_normal_z   <= 8'd127;
                                pixel_curvature  <= 8'd0;
                                state            <= S_WRITE;
                            end else begin
                                hit <= best_hit;
                                compute_pixel_data();
                                state <= S_WRITE;
                            end
                        end else begin
                            // Single sample on this slice for orthographic view
                            reg [5:0] trunc_y;
                            reg [5:0] trunc_z;
                            reg [5:0] cur_x;
                            cur_x   = SLICE_X_START - (slice_idx * SLICE_STEP);
                            trunc_y = map_voxel_y;
                            trunc_z = map_voxel_z;
                            sample_voxel_x <= cur_x;
                            sample_voxel_y <= trunc_y;
                            sample_voxel_z <= trunc_z;
                            voxel_x        <= cur_x;
                            voxel_y        <= trunc_y;
                            voxel_z        <= trunc_z;
                            voxel_addr     <= {cur_x, trunc_y, trunc_z};
                            voxel_read_en <= 1'b1;
                            state         <= S_FETCH;

                            // Move to next slice (ray_steps mirrors slice count for attenuation)
                            ray_steps <= slice_idx + 1'b1;
                        end
                    end else begin
                        if (ray_steps >= MAX_RAY_STEPS[7:0] || hit) begin
                            if (!hit) begin
                                // sky pixel (dark blue) with slight vertical gradient
                                reg [7:0] sky_r, sky_g, sky_b;
                                sky_r = 8'd10 + (pixel_y[7:0] >> 3);
                                sky_g = 8'd40 + (pixel_y[7:0] >> 3);
                                sky_b = 8'd90 + (pixel_y[7:0] >> 2);
                                pixel_word0      <= {8'd0, 8'd0, 8'd255, 8'd0};
                                pixel_word1      <= {sky_r, sky_g, sky_b, 8'hFF};
                                pixel_word2      <= {8'd0, 8'd0, 8'd127, 8'd0};
                                pixel_reflection <= 8'd0;
                                pixel_refraction <= 8'd0;
                                pixel_attenuation<= 8'd255;
                                pixel_emission   <= 8'd0;
                                pixel_r          <= sky_r;
                                pixel_g          <= sky_g;
                                pixel_b          <= sky_b;
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
                            reg signed [ACC_WIDTH-1:0] wide_x;
                            reg signed [ACC_WIDTH-1:0] wide_y;
                            reg signed [ACC_WIDTH-1:0] wide_z;
                            reg [5:0] trunc_x;
                            reg [5:0] trunc_y;
                            reg [5:0] trunc_z;
                            wide_x  = ray_pos_x >>> FRAC_BITS;
                            wide_y  = ray_pos_y >>> FRAC_BITS;
                            wide_z  = ray_pos_z >>> FRAC_BITS;
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
                            ray_pos_x <= ray_pos_x - (18'sd1 <<< RAY_STEP_SHIFT);
                            ray_steps <= ray_steps + 1'b1;
                        end
                    end
                end

                S_FETCH: begin
                    // Sample, test occupancy
                    if (diag_slice_mode) begin
                        if (voxel_data != 64'd0 && voxel_data[47:40] > 8'd10 && !best_hit) begin
                            best_hit         <= 1'b1;
                            best_emissive    <= voxel_data[55:48];
                            hit              <= 1'b1;
                            dbg_hit_count    <= dbg_hit_count + 1'b1;

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
                        slice_idx <= slice_idx + 1'b1;
                    end else begin
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
                    end

                    state <= S_STEP;
                end

                S_WRITE: begin
                    dbg_ray_steps_total <= dbg_ray_steps_total + ray_steps;
                    if (ray_steps > dbg_ray_steps_max)
                        dbg_ray_steps_max <= ray_steps;
                    if (!hit)
                        dbg_ray_miss_count <= dbg_ray_miss_count + 1'b1;

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
