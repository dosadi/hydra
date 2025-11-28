#include "dut_wrapper.h"
#include "Vvoxel_framebuffer_top___024root.h"

DUTWrapper::DUTWrapper() {
    top_ = new Vvoxel_framebuffer_top;
    root_ = top_->rootp;

    // Initialize all inputs to default values
    top_->clk = 0;
    top_->rst_n = 0;
    top_->cam_load = 0;
    top_->cam_x_in = 0;
    top_->cam_y_in = 0;
    top_->cam_z_in = 0;
    top_->cam_dir_x_in = 0;
    top_->cam_dir_y_in = 0;
    top_->cam_dir_z_in = 0;
    top_->cam_plane_x_in = 0;
    top_->cam_plane_y_in = 0;
    top_->flags_load = 0;
    top_->flag_smooth_in = 0;
    top_->flag_curvature_in = 0;
    top_->flag_extra_light_in = 0;
    top_->flag_diag_slice_in = 0;
    top_->sel_load = 0;
    top_->sel_active_in = 0;
    top_->sel_voxel_x_in = 0;
    top_->sel_voxel_y_in = 0;
    top_->sel_voxel_z_in = 0;
    top_->dbg_ext_write_en = 0;
    top_->dbg_ext_write_addr = 0;
    top_->dbg_ext_write_data = 0;
    top_->start_frame_ext = 0;
    top_->soft_reset_ext = 0;
}

DUTWrapper::~DUTWrapper() {
    if (top_) {
        top_->final();
        delete top_;
        top_ = nullptr;
        root_ = nullptr;
    }
}

void DUTWrapper::set_clock(bool clk) {
    top_->clk = clk ? 1 : 0;
}

void DUTWrapper::set_reset_n(bool rst_n) {
    top_->rst_n = rst_n ? 1 : 0;
}

void DUTWrapper::set_camera_load(bool load) {
    top_->cam_load = load ? 1 : 0;
}

void DUTWrapper::set_camera_position(int16_t x, int16_t y, int16_t z) {
    top_->cam_x_in = x;
    top_->cam_y_in = y;
    top_->cam_z_in = z;
}

void DUTWrapper::set_camera_direction(int16_t dx, int16_t dy, int16_t dz) {
    top_->cam_dir_x_in = dx;
    top_->cam_dir_y_in = dy;
    top_->cam_dir_z_in = dz;
}

void DUTWrapper::set_camera_plane(int16_t px, int16_t py) {
    top_->cam_plane_x_in = px;
    top_->cam_plane_y_in = py;
}

void DUTWrapper::set_flags_load(bool load) {
    top_->flags_load = load ? 1 : 0;
}

void DUTWrapper::set_smooth_surfaces(bool enable) {
    top_->flag_smooth_in = enable ? 1 : 0;
}

void DUTWrapper::set_curvature(bool enable) {
    top_->flag_curvature_in = enable ? 1 : 0;
}

void DUTWrapper::set_extra_light(bool enable) {
    top_->flag_extra_light_in = enable ? 1 : 0;
}

void DUTWrapper::set_diag_slice(bool enable) {
    top_->flag_diag_slice_in = enable ? 1 : 0;
}

void DUTWrapper::set_ray_jitter(bool enable) {
    root_->voxel_framebuffer_top__DOT__cfg_ray_jitter = enable ? 1 : 0;
}

void DUTWrapper::set_selection_load(bool load) {
    top_->sel_load = load ? 1 : 0;
}

void DUTWrapper::set_selection_active(bool active) {
    top_->sel_active_in = active ? 1 : 0;
}

void DUTWrapper::set_selection_voxel(uint8_t x, uint8_t y, uint8_t z) {
    top_->sel_voxel_x_in = x;
    top_->sel_voxel_y_in = y;
    top_->sel_voxel_z_in = z;
}

void DUTWrapper::set_debug_write_enable(bool en) {
    root_->voxel_framebuffer_top__DOT__dbg_write_en = en ? 1 : 0;
}

void DUTWrapper::set_debug_write_addr(uint32_t addr) {
    root_->voxel_framebuffer_top__DOT__dbg_write_addr = addr;
}

void DUTWrapper::set_debug_write_data(uint64_t data) {
    root_->voxel_framebuffer_top__DOT__dbg_write_data = data;
}

void DUTWrapper::set_start_frame(bool start) {
    top_->start_frame_ext = start ? 1 : 0;
}

void DUTWrapper::set_soft_reset(bool reset) {
    top_->soft_reset_ext = reset ? 1 : 0;
}

void DUTWrapper::set_world_seed(uint32_t seed) {
    root_->voxel_framebuffer_top__DOT__world_seed = seed;
}

bool DUTWrapper::get_pixel_write_en() const {
    return top_->pixel_write_en != 0;
}

uint32_t DUTWrapper::get_pixel_addr() const {
    return top_->pixel_addr;
}

uint32_t DUTWrapper::get_pixel_word0() const {
    return top_->pixel_word0;
}

uint32_t DUTWrapper::get_pixel_word1() const {
    return top_->pixel_word1;
}

uint32_t DUTWrapper::get_pixel_word2() const {
    return top_->pixel_word2;
}

bool DUTWrapper::get_frame_done() const {
    return top_->frame_done != 0;
}

uint32_t DUTWrapper::get_core_dbg_hit_count() const {
    return root_->voxel_framebuffer_top__DOT__core_dbg_hit_count;
}

uint32_t DUTWrapper::get_core_dbg_ray_steps_total() const {
    return root_->voxel_framebuffer_top__DOT__core_dbg_ray_steps_total;
}

uint32_t DUTWrapper::get_core_dbg_ray_steps_max() const {
    return root_->voxel_framebuffer_top__DOT__core_dbg_ray_steps_max;
}

uint32_t DUTWrapper::get_core_dbg_ray_miss_count() const {
    return root_->voxel_framebuffer_top__DOT__core_dbg_ray_miss_count;
}

uint64_t DUTWrapper::get_mem_cycle_count() const {
    return root_->voxel_framebuffer_top__DOT__mem_cycle_count;
}

uint64_t DUTWrapper::get_mem_read_cycles() const {
    return root_->voxel_framebuffer_top__DOT__mem_read_cycles;
}

uint64_t DUTWrapper::get_mem_write_cycles() const {
    return root_->voxel_framebuffer_top__DOT__mem_write_cycles;
}

bool DUTWrapper::get_cursor_hit_valid() const {
    return root_->voxel_framebuffer_top__DOT__cursor_hit_valid != 0;
}

uint8_t DUTWrapper::get_cursor_voxel_x() const {
    return root_->voxel_framebuffer_top__DOT__cursor_voxel_x;
}

uint8_t DUTWrapper::get_cursor_voxel_y() const {
    return root_->voxel_framebuffer_top__DOT__cursor_voxel_y;
}

uint8_t DUTWrapper::get_cursor_voxel_z() const {
    return root_->voxel_framebuffer_top__DOT__cursor_voxel_z;
}

uint8_t DUTWrapper::get_cursor_material_id() const {
    return root_->voxel_framebuffer_top__DOT__cursor_material_id;
}

uint64_t DUTWrapper::get_cursor_voxel_data() const {
    return root_->voxel_framebuffer_top__DOT__cursor_voxel_data;
}

bool DUTWrapper::get_sel_active() const {
    return root_->voxel_framebuffer_top__DOT__sel_active != 0;
}

uint8_t DUTWrapper::get_sel_voxel_x() const {
    return root_->voxel_framebuffer_top__DOT__sel_voxel_x;
}

uint8_t DUTWrapper::get_sel_voxel_y() const {
    return root_->voxel_framebuffer_top__DOT__sel_voxel_y;
}

uint8_t DUTWrapper::get_sel_voxel_z() const {
    return root_->voxel_framebuffer_top__DOT__sel_voxel_z;
}

void DUTWrapper::eval() {
    top_->eval();
}

void DUTWrapper::final() {
    if (top_) {
        top_->final();
    }
}