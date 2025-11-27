// ============================================================================
// voxel_framebuffer_top.sv
// - Top-level integration for Verilator + SDL demo.
// - Builds world, then runs raycaster frame loop.
// ============================================================================

`timescale 1ns/1ps

module voxel_framebuffer_top #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64,
    parameter integer COORD_WIDTH     = 16,
    parameter integer FRAC_BITS       = 8,
    // Max ray steps and step size for core; default matches original behavior.
    parameter integer MAX_RAY_STEPS   = 128,
    parameter integer RAY_STEP_SHIFT  = FRAC_BITS-1,
    // Test-only: force world_ready to 1 after reset for benches
    parameter integer TEST_FORCE_WORLD_READY = 0,
    // Allow benches to disable auto-run and require host start pulses.
    parameter integer AUTO_START_FRAMES = 1,
    parameter [31:0]  WORLD_SEED_DEFAULT = 32'h0000_0000
)(
    input  wire         clk,
    input  wire         rst_n,

    // Pixel write interface for host framebuffer
    output wire         pixel_write_en,
    output wire [31:0]  pixel_addr,
    output wire [31:0]  pixel_word0,
    output wire [31:0]  pixel_word1,
    output wire [31:0]  pixel_word2,
    output wire [31:0]  pixel_reemissure,

    // Frame done pulse
    output wire         frame_done,
    output wire         core_busy,

    // World ready signal
    output reg         world_ready,

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
    input  wire         flag_ray_jitter_in,

    input  wire         sel_load,
    input  wire         sel_active_in,
    input  wire [5:0]   sel_voxel_x_in,
    input  wire [5:0]   sel_voxel_y_in,
    input  wire [5:0]   sel_voxel_z_in,

    input  wire         dbg_ext_write_en,
    input  wire [17:0]  dbg_ext_write_addr,
    input  wire [63:0]  dbg_ext_write_data,

    input  wire         start_frame_ext,
    input  wire         soft_reset_ext,
    input  wire         benchmark_mode
);

    // ------------------------------------------------------------------------
    // Framebuffer SVAs and Coverage
    // ------------------------------------------------------------------------
    // Track last pixel address for monotonicity check
    reg [31:0] last_pixel_addr;
    reg        pixel_addr_valid;

`ifdef FORMAL
    // SVA: Frame start must eventually result in frame_done
    property frame_start_leads_to_done;
        @(posedge clk) disable iff (!rst_n)
        start_frame_ext |-> ##[1:$] frame_done;
    endproperty
    frame_start_leads_to_done_sva: assert property (frame_start_leads_to_done);

    // SVA: Frame done only when not busy
    property frame_done_when_idle;
        @(posedge clk) disable iff (!rst_n)
        frame_done |-> !core_busy;
    endproperty
    frame_done_when_idle_sva: assert property (frame_done_when_idle);

    // SVA: Pixel address monotonicity
    property pixel_addr_monotonic;
        @(posedge clk) disable iff (!rst_n)
        pixel_write_en |-> pixel_addr >= $past(pixel_addr);
    endproperty
    pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

    // SVA: Pixel write enable only when busy
    property pixel_write_en_when_busy;
        @(posedge clk) disable iff (!rst_n)
        pixel_write_en |-> core_busy;
    endproperty
    pixel_write_en_when_busy_sva: assert property (pixel_write_en_when_busy);

    // Coverage: Pixel address distribution
    covergroup cg_pixel_addr @(posedge clk);
        addr_bins: coverpoint pixel_addr {
            bins low[]    = {[0:1023]};
            bins mid[]    = {[1024:SCREEN_WIDTH*SCREEN_HEIGHT/2]};
            bins high[]   = {[SCREEN_WIDTH*SCREEN_HEIGHT/2+1:SCREEN_WIDTH*SCREEN_HEIGHT-1]};
        }
    endgroup
    cg_pixel_addr_inst = new();

    // Coverage: Write enable pulse coverage
    covergroup cg_pixel_write_en @(posedge clk);
        write_en: coverpoint pixel_write_en;
    endgroup
    cg_pixel_write_en_inst = new();
`endif

    // SVA: Frame done pulse only when not busy (all pixels written)
    property frame_done_when_idle;
        @(posedge clk) disable iff (!rst_n)
        frame_done |-> !core_busy;
    endproperty
    frame_done_when_idle_sva: assert property (frame_done_when_idle);

    // SVA: Every frame start pulse must eventually result in a frame_done pulse
    // NOTE: Verilator does not support SVA sequence delays (##[n:m]).
    // Full liveness check (frame start always leads to frame_done) requires a formal tool or custom testbench monitor.

    // Covergroup: Pixel address distribution
    // covergroup cg_pixel_addr @(posedge clk);
    //     addr_bins: coverpoint pixel_addr {
    //         bins low[]    = {[0:1023]};
    //         bins mid[]    = {[1024:SCREEN_WIDTH*SCREEN_HEIGHT/2]};
    //         bins high[]   = {[SCREEN_WIDTH*SCREEN_HEIGHT/2+1:SCREEN_WIDTH*SCREEN_HEIGHT-1]};
    //     }
    // endgroup
    // cg_pixel_addr_inst = new();

    // Covergroup: Write enable pulse coverage
    // covergroup cg_pixel_write_en @(posedge clk);
    //     write_en: coverpoint pixel_write_en;
    // endgroup
    // cg_pixel_write_en_inst = new();

    // Track last pixel address for SVAs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_pixel_addr   <= 32'd0;
            pixel_addr_valid  <= 1'b0;
        end else begin
            if (pixel_write_en) begin
                last_pixel_addr  <= pixel_addr;
                pixel_addr_valid <= 1'b1;
            end
        end
    end

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
    reg cfg_ray_jitter;

    // Selection controls
    reg       sel_active;
    reg [5:0] sel_voxel_x;
    reg [5:0] sel_voxel_y;
    reg [5:0] sel_voxel_z;

    // Debug write interface (host-driven)
    reg [17:0] dbg_write_addr;
    reg        dbg_write_en;
    reg [63:0] dbg_write_data;
    reg [31:0] world_seed;

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
    wire [31:0] core_dbg_ray_steps_total;
    wire [7:0]  core_dbg_ray_steps_max;
    wire [31:0] core_dbg_ray_miss_count;

    // Expose cursor/regs to Verilator (they are regs/wires in this scope)
    // (No extra ports needed; Verilator can access internal regs/wires.)

    // Memory utilization counters (visible to Verilator)
    reg [63:0] mem_cycle_count;
    reg [63:0] mem_read_cycles;
    reg [63:0] mem_write_cycles;
    reg [63:0] mem_readwrite_cycles;

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
        cfg_ray_jitter      <= 1'b0;

        sel_active   <= 1'b0;
        sel_voxel_x  <= 6'd0;
        sel_voxel_y  <= 6'd0;
        sel_voxel_z  <= 6'd0;

        dbg_write_addr <= 18'd0;
        dbg_write_en   <= 1'b0;
        dbg_write_data <= 64'd0;
        world_seed     <= WORLD_SEED_DEFAULT;

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
        .seed       (world_seed),
        .write_addr (world_waddr),
        .write_en   (world_wen),
        .write_data (world_wdata)
    );

    // Memory write arbitration: priority arbiter between debug writes and world_gen
    wire        dbg_write_en_mux   = dbg_write_en | dbg_ext_write_en;
    wire [17:0] dbg_write_addr_mux = dbg_ext_write_en ? dbg_ext_write_addr : dbg_write_addr;
    wire [63:0] dbg_write_data_mux = dbg_ext_write_en ? dbg_ext_write_data : dbg_write_data;

    // Arbiter select: 1 => debug, 0 => world
    reg mem_write_arb;

    wire [17:0] mem_write_addr = mem_write_arb ? dbg_write_addr_mux : world_waddr;
    wire        mem_write_en   = mem_write_arb ? dbg_write_en_mux     : world_wen;
    wire [63:0] mem_write_data = mem_write_arb ? dbg_write_data_mux   : world_wdata;

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
    wire [31:0] render_config = {29'd0, cfg_ray_jitter, cfg_diag_slice, cfg_extra_light};

    voxel_raycaster_core_pipelined #(
        .SCREEN_WIDTH    (SCREEN_WIDTH),
        .SCREEN_HEIGHT   (SCREEN_HEIGHT),
        .VOXEL_GRID_SIZE (VOXEL_GRID_SIZE),
        .COORD_WIDTH     (COORD_WIDTH),
        .FRAC_BITS       (FRAC_BITS),
        .MAX_RAY_STEPS   (MAX_RAY_STEPS),
        .RAY_STEP_SHIFT  (RAY_STEP_SHIFT)
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
        .pixel_sidecar      (pixel_reemissure),
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
        .dbg_hit_count      (core_dbg_hit_count),
        .dbg_ray_steps_total(core_dbg_ray_steps_total),
        .dbg_ray_steps_max  (core_dbg_ray_steps_max),
        .dbg_ray_miss_count (core_dbg_ray_miss_count)
    );

    assign frame_done = done;
    assign core_busy  = busy;

    // Simple control: run world_gen once, then repeatedly start frames
    reg world_started;
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
                if (world_ready && !busy && start_frame_ext) begin
                    start <= 1'b1;
                end else if (world_ready && AUTO_START_FRAMES && busy_d && !busy && !benchmark_mode) begin
                    start <= 1'b1;
                end

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
                cfg_ray_jitter      <= flag_ray_jitter_in;
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

    // Memory utilization tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || soft_reset_ext) begin
            mem_cycle_count      <= 64'd0;
            mem_read_cycles      <= 64'd0;
            mem_write_cycles     <= 64'd0;
            mem_readwrite_cycles <= 64'd0;
        end else begin
            mem_cycle_count <= mem_cycle_count + 64'd1;
            if (geom_rd_en)
                mem_read_cycles <= mem_read_cycles + 64'd1;
            if (mem_write_en)
                mem_write_cycles <= mem_write_cycles + 64'd1;
            if (geom_rd_en && mem_write_en)
                mem_readwrite_cycles <= mem_readwrite_cycles + 64'd1;
        end
    end

    // ------------------------------------------------------------------------
    // Robust memory write arbitration between debug writes and world_gen
    // Priority: debug writes (host or external) win when both request the same
    // cycle. Arbiter favors debug and otherwise allows the world generator.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_write_arb <= 1'b0;
        end else begin
            // If debug requests a write this cycle, prefer it.
            // Otherwise, if world requests, allow world.
            if (dbg_write_en_mux && !world_wen)
                mem_write_arb <= 1'b1;
            else if (!dbg_write_en_mux && world_wen)
                mem_write_arb <= 1'b0;
            else if (dbg_write_en_mux && world_wen)
                mem_write_arb <= 1'b1; // tie: prefer debug
            else
                mem_write_arb <= 1'b0;
        end
    end

`ifdef FORMAL
    // SVA: when both sources request a write, arbiter must prefer debug
    property arb_prefers_debug;
        @(posedge clk) disable iff (!rst_n)
        (dbg_write_en_mux && world_wen) |-> (mem_write_arb == 1'b1);
    endproperty
    arb_prefers_debug_sva: assert property (arb_prefers_debug);

    // SVA: final mem write signals must reflect the selected source
    property mem_write_reflects_source;
        @(posedge clk) disable iff (!rst_n)
        mem_write_en |-> ((mem_write_arb && dbg_write_en_mux) || (!mem_write_arb && world_wen));
    endproperty
    mem_write_reflects_source_sva: assert property (mem_write_reflects_source);
`endif

endmodule
