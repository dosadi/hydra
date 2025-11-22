// ============================================================================
// voxel_framebuffer_top.sv
// - Top-level integration for Verilator + SDL demo.
// - Builds world, then runs raycaster frame loop.
// ============================================================================

`timescale 1ns/1ps

module voxel_framebuffer_top #(
    parameter SCREEN_WIDTH    = 480,
    parameter SCREEN_HEIGHT   = 360,
    parameter VOXEL_GRID_SIZE = 64,
    parameter COORD_WIDTH     = 16,
    parameter FRAC_BITS       = 8,
    // Test-only: force world_ready to 1 after reset for benches
    parameter TEST_FORCE_WORLD_READY = 0,
    // Allow benches to disable auto-run and require host start pulses.
    parameter AUTO_START_FRAMES = 1
)(
    input  wire         clk,
    input  wire         rst_n,

    // Pixel write interface for host framebuffer
    output wire         pixel_write_en,
    output wire [31:0]  pixel_addr,
    output wire [31:0]  pixel_word0,
    output wire [31:0]  pixel_word1,
    output wire [31:0]  pixel_word2,

    // Frame done pulse
    output wire         frame_done,
    output wire         core_busy,

    // Optional external control (AXI-Lite shell / host)
    input  wire         cam_load,
    input  wire signed [15:0] cam_x_in,
    input  wire signed [15:0] cam_y_in,
    input  wire signed [15:0] cam_z_in,
    input  wire signed [15:0] cam_dir_x_in,
    input  wire signed [15:0] cam_dir_y_in,
    input  wire signed [15:0] cam_dir_z_in,
    input  wire signed [15:0] cam_plane_x_in,
    input  wire signed [15:0] cam_plane_y_in,

    input  wire         flags_load,
    input  wire         flag_smooth_in,
    input  wire         flag_curvature_in,
    input  wire         flag_extra_light_in,
    input  wire         flag_diag_slice_in,

    input  wire         sel_load,
    input  wire         sel_active_in,
    input  wire [5:0]   sel_voxel_x_in,
    input  wire [5:0]   sel_voxel_y_in,
    input  wire [5:0]   sel_voxel_z_in,

    input  wire         dbg_ext_write_en,
    input  wire [17:0]  dbg_ext_write_addr,
    input  wire [63:0]  dbg_ext_write_data,

    input  wire         start_frame_ext,
    input  wire         soft_reset_ext
);

    // Camera registers (host-writeable)
    reg signed [15:0] cam_x;
    reg signed [15:0] cam_y;
    reg signed [15:0] cam_z;
    reg signed [15:0] cam_dir_x;
    reg signed [15:0] cam_dir_y;
    reg signed [15:0] cam_dir_z;
    reg signed [15:0] cam_plane_x;
    reg signed [15:0] cam_plane_y;

    // Render config bits
    reg cfg_smooth_surfaces;
    reg cfg_curvature;
    reg cfg_extra_light;
    reg cfg_diag_slice;

    // Selection controls
    reg       sel_active;
    reg [5:0] sel_voxel_x;
    reg [5:0] sel_voxel_y;
    reg [5:0] sel_voxel_z;

    // Debug write interface (host-driven)
    reg [17:0] dbg_write_addr;
    reg        dbg_write_en;
    reg [63:0] dbg_write_data;

    // World generator
    reg  world_start;
    wire world_busy, world_done;
    wire [17:0] world_waddr;
    wire        world_wen;
    wire [63:0] world_wdata;

    // Memory <-> core
    wire [17:0] geom_addr;
    wire        geom_rd_en;
    wire [63:0] geom_data;

    // Core control
    reg         start;
    wire        busy;
    wire        done;

    // Cursor signals from core
    wire        cursor_hit_valid;
    wire [5:0]  cursor_voxel_x;
    wire [5:0]  cursor_voxel_y;
    wire [5:0]  cursor_voxel_z;
    wire [7:0]  cursor_material_id;
    wire [63:0] cursor_voxel_data;
    wire [31:0] core_dbg_hit_count;

    // Expose cursor/regs to Verilator (they are regs/wires in this scope)
    // (No extra ports needed; Verilator can access internal regs/wires.)

    // Simple init
    initial begin
        cam_x  <= 16'sd10 <<< FRAC_BITS;
        cam_y  <= 16'sd10 <<< FRAC_BITS;
        cam_z  <= 16'sd10 <<< FRAC_BITS;
        cam_dir_x   <= 16'sd256; // ~1.0 in fixed
        cam_dir_y   <= 16'sd0;
        cam_dir_z   <= 16'sd0;
        cam_plane_x <= 16'sd0;
        cam_plane_y <= 16'sd170;

        cfg_smooth_surfaces <= 1'b1;
        cfg_curvature       <= 1'b1;
        cfg_extra_light     <= 1'b0;
        cfg_diag_slice      <= 1'b0;

        sel_active   <= 1'b0;
        sel_voxel_x  <= 6'd0;
        sel_voxel_y  <= 6'd0;
        sel_voxel_z  <= 6'd0;

        dbg_write_addr <= 18'd0;
        dbg_write_en   <= 1'b0;
        dbg_write_data <= 64'd0;

        world_start <= 1'b0;
        start       <= 1'b0;
    end

    // World generator instance
    voxel_world_gen #(
        .GRID_SIZE(VOXEL_GRID_SIZE)
    ) world_gen (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (world_start),
        .busy       (world_busy),
        .done       (world_done),
        .write_addr (world_waddr),
        .write_en   (world_wen),
        .write_data (world_wdata)
    );

    // Memory write arbitration: debug writes override world_gen
    wire        dbg_write_en_mux   = dbg_write_en | dbg_ext_write_en;
    wire [17:0] dbg_write_addr_mux = dbg_ext_write_en ? dbg_ext_write_addr : dbg_write_addr;
    wire [63:0] dbg_write_data_mux = dbg_ext_write_en ? dbg_ext_write_data : dbg_write_data;

    wire [17:0] mem_write_addr = dbg_write_en_mux ? dbg_write_addr_mux : world_waddr;
    wire        mem_write_en   = dbg_write_en_mux | world_wen;
    wire [63:0] mem_write_data = dbg_write_en_mux ? dbg_write_data_mux : world_wdata;

    voxel_memory_64 geom_mem (
        .clk        (clk),
        .read_addr  (geom_addr),
        .read_en    (geom_rd_en),
        .read_data  (geom_data),
        .write_addr (mem_write_addr),
        .write_en   (mem_write_en),
        .write_data (mem_write_data)
    );

    // Core config word
    wire [31:0] render_config = {30'd0, cfg_diag_slice, cfg_extra_light};

    voxel_raycaster_core_pipelined #(
        .SCREEN_WIDTH    (SCREEN_WIDTH),
        .SCREEN_HEIGHT   (SCREEN_HEIGHT),
        .VOXEL_GRID_SIZE (VOXEL_GRID_SIZE),
        .COORD_WIDTH     (COORD_WIDTH),
        .FRAC_BITS       (FRAC_BITS)
    ) core (
        .clk                (clk),
        .rst_n              (rst_n),
        .start              (start),

        .cam_x              (cam_x),
        .cam_y              (cam_y),
        .cam_z              (cam_z),
        .cam_dir_x          (cam_dir_x),
        .cam_dir_y          (cam_dir_y),
        .cam_dir_z          (cam_dir_z),
        .cam_plane_x        (cam_plane_x),
        .cam_plane_y        (cam_plane_y),

        .render_config      (render_config),
        .enable_smooth_surfaces(cfg_smooth_surfaces),
        .enable_curvature   (cfg_curvature),

        .sel_active         (sel_active),
        .sel_voxel_x        (sel_voxel_x),
        .sel_voxel_y        (sel_voxel_y),
        .sel_voxel_z        (sel_voxel_z),

        .voxel_addr         (geom_addr),
        .voxel_data         (geom_data),
        .voxel_read_en      (geom_rd_en),

        .pixel_word0        (pixel_word0),
        .pixel_word1        (pixel_word1),
        .pixel_word2        (pixel_word2),
        .pixel_addr         (pixel_addr),
        .pixel_write_en     (pixel_write_en),

        .busy               (busy),
        .done               (done),

        .cursor_hit_valid   (cursor_hit_valid),
        .cursor_voxel_x     (cursor_voxel_x),
        .cursor_voxel_y     (cursor_voxel_y),
        .cursor_voxel_z     (cursor_voxel_z),
        .cursor_material_id (cursor_material_id),
        .cursor_voxel_data  (cursor_voxel_data),
        .dbg_hit_count      (core_dbg_hit_count)
    );

    assign frame_done = done;
    assign core_busy  = busy;

    // Simple control: run world_gen once, then repeatedly start frames
    reg world_started;
    reg world_ready;
    reg busy_d;
    reg pending_start;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            world_started <= 1'b0;
            world_ready   <= TEST_FORCE_WORLD_READY ? 1'b1 : 1'b0;
            world_start   <= 1'b0;
            start         <= 1'b0;
            busy_d        <= 1'b0;
            pending_start <= 1'b0;
        end else begin
            busy_d      <= busy;
            world_start <= 1'b0;
            start       <= 1'b0;

            if (soft_reset_ext) begin
                world_started <= 1'b0;
                world_ready   <= TEST_FORCE_WORLD_READY ? 1'b1 : 1'b0;
                pending_start <= 1'b0;
            end else begin
                if (!world_started) begin
                    world_start   <= 1'b1;
                    world_started <= 1'b1;
                end

                if (world_done)
                    world_ready <= 1'b1;

                if (start_frame_ext)
                    pending_start <= 1'b1;

                // Kick frames when idle:
                // - If AUTO_START_FRAMES, free-run once world is ready.
                // - Otherwise require a pending_start from host.
                if (world_ready && AUTO_START_FRAMES && !busy)
                    start <= 1'b1;
                else if (world_ready && AUTO_START_FRAMES && busy_d && !busy)
                    start <= 1'b1;

                if (world_ready && pending_start) begin
                    start         <= 1'b1;
                    pending_start <= 1'b0;
                end
            end
        end
    end

    // External control updates (camera/flags/selection/debug write)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || soft_reset_ext) begin
            cam_x  <= 16'sd10 <<< FRAC_BITS;
            cam_y  <= 16'sd10 <<< FRAC_BITS;
            cam_z  <= 16'sd10 <<< FRAC_BITS;
            cam_dir_x   <= 16'sd256;
            cam_dir_y   <= 16'sd0;
            cam_dir_z   <= 16'sd0;
            cam_plane_x <= 16'sd0;
            cam_plane_y <= 16'sd170;

            cfg_smooth_surfaces <= 1'b1;
            cfg_curvature       <= 1'b1;
            cfg_extra_light     <= 1'b0;
            cfg_diag_slice      <= 1'b0;

            sel_active   <= 1'b0;
            sel_voxel_x  <= 6'd0;
            sel_voxel_y  <= 6'd0;
            sel_voxel_z  <= 6'd0;

            dbg_write_addr <= 18'd0;
            dbg_write_en   <= 1'b0;
            dbg_write_data <= 64'd0;
        end else begin
            dbg_write_en <= 1'b0;

            if (cam_load) begin
                cam_x       <= cam_x_in;
                cam_y       <= cam_y_in;
                cam_z       <= cam_z_in;
                cam_dir_x   <= cam_dir_x_in;
                cam_dir_y   <= cam_dir_y_in;
                cam_dir_z   <= cam_dir_z_in;
                cam_plane_x <= cam_plane_x_in;
                cam_plane_y <= cam_plane_y_in;
            end

            if (flags_load) begin
                cfg_smooth_surfaces <= flag_smooth_in;
                cfg_curvature       <= flag_curvature_in;
                cfg_extra_light     <= flag_extra_light_in;
                cfg_diag_slice      <= flag_diag_slice_in;
            end

            if (sel_load) begin
                sel_active  <= sel_active_in;
                sel_voxel_x <= sel_voxel_x_in;
                sel_voxel_y <= sel_voxel_y_in;
                sel_voxel_z <= sel_voxel_z_in;
            end

            if (dbg_ext_write_en) begin
                dbg_write_en   <= 1'b1;
                dbg_write_addr <= dbg_ext_write_addr;
                dbg_write_data <= dbg_ext_write_data;
            end
        end
    end

endmodule
