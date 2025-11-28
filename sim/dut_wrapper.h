#ifndef DUT_WRAPPER_H
#define DUT_WRAPPER_H

#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"

// Forward declaration of the internal root class
class Vvoxel_framebuffer_top___024root;

/**
 * Device Under Test (DUT) wrapper class for voxel_framebuffer_top.
 *
 * This class provides a simulator-agnostic interface to the Verilator-generated
 * Vvoxel_framebuffer_top module, avoiding direct dependencies on auto-generated
 * class names like Vvoxel_framebuffer_top___024root.
 *
 * This enables the codebase to be portable across different HDL simulators
 * (Verilator, ModelSim, etc.) by abstracting the simulator-specific details.
 */
class DUTWrapper {
public:
    DUTWrapper();
    ~DUTWrapper();

    // Prevent copying
    DUTWrapper(const DUTWrapper&) = delete;
    DUTWrapper& operator=(const DUTWrapper&) = delete;

    // Clock and reset
    void set_clock(bool clk);
    void set_reset_n(bool rst_n);

    // Camera inputs
    void set_camera_load(bool load);
    void set_camera_position(int16_t x, int16_t y, int16_t z);
    void set_camera_direction(int16_t dx, int16_t dy, int16_t dz);
    void set_camera_plane(int16_t px, int16_t py);

    // Flag inputs
    void set_flags_load(bool load);
    void set_smooth_surfaces(bool enable);
    void set_curvature(bool enable);
    void set_extra_light(bool enable);
    void set_diag_slice(bool enable);
    void set_ray_jitter(bool enable);

    // Selection inputs
    void set_selection_load(bool load);
    void set_selection_active(bool active);
    void set_selection_voxel(uint8_t x, uint8_t y, uint8_t z);

    // Debug inputs
    void set_debug_write_enable(bool en);
    void set_debug_write_addr(uint32_t addr);
    void set_debug_write_data(uint64_t data);

    // Control inputs
    void set_start_frame(bool start);
    void set_soft_reset(bool reset);
    void set_world_seed(uint32_t seed);

    // Outputs
    bool get_pixel_write_en() const;
    uint32_t get_pixel_addr() const;
    uint32_t get_pixel_word0() const;
    uint32_t get_pixel_word1() const;
    uint32_t get_pixel_word2() const;
    bool get_frame_done() const;

    // Internal state access (for debugging/HUD)
    uint32_t get_core_dbg_hit_count() const;
    uint32_t get_core_dbg_ray_steps_total() const;
    uint32_t get_core_dbg_ray_steps_max() const;
    uint32_t get_core_dbg_ray_miss_count() const;
    uint64_t get_mem_cycle_count() const;
    uint64_t get_mem_read_cycles() const;
    uint64_t get_mem_write_cycles() const;

    // Cursor/hit detection
    bool get_cursor_hit_valid() const;
    uint8_t get_cursor_voxel_x() const;
    uint8_t get_cursor_voxel_y() const;
    uint8_t get_cursor_voxel_z() const;
    uint8_t get_cursor_material_id() const;
    uint64_t get_cursor_voxel_data() const;

    // Selection state
    bool get_sel_active() const;
    uint8_t get_sel_voxel_x() const;
    uint8_t get_sel_voxel_y() const;
    uint8_t get_sel_voxel_z() const;

    // Evaluation and timing
    void eval();
    void final();

private:
    Vvoxel_framebuffer_top* top_;
    Vvoxel_framebuffer_top___024root* root_;
};

#endif // DUT_WRAPPER_H