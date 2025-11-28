// SPDX-License-Identifier: BSD-3-Clause
// viewer_rendering.h - Rendering and framebuffer management for Hydra viewer
#pragma once

#include <vector>
#include <cstdint>
#include <string>
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

#include "harness_common.h"

// Forward declarations
struct ColorRange;

// Constants
static const int HUD_HEIGHT = 80;

// Framebuffer management
class FramebufferManager {
public:
    FramebufferManager(int width, int height, uint32_t clear_color = 0);
    ~FramebufferManager() = default;

    // Framebuffer access
    std::vector<uint32_t>& get_framebuffer() { return framebuffer_; }
    const std::vector<uint32_t>& get_framebuffer() const { return framebuffer_; }
    size_t get_pixel_count() const { return framebuffer_.size(); }

    // Framebuffer operations
    void clear(uint32_t color);
    void set_clear_color(uint32_t color) { clear_color_ = color; }
    uint32_t get_clear_color() const { return clear_color_; }

    // Pixel access
    uint32_t get_pixel(int x, int y) const;
    void set_pixel(int x, int y, uint32_t color);

    // Framebuffer info
    int get_width() const { return width_; }
    int get_height() const { return height_; }

private:
    int width_;
    int height_;
    uint32_t clear_color_;
    std::vector<uint32_t> framebuffer_;
};

// Text rendering utilities
void draw_text_to_fb(std::vector<uint32_t>& fb, int fb_w, int fb_h,
                     TTF_Font* font, const std::string& txt,
                     int x, int y, SDL_Color color = {255,255,255,255});

// HUD rendering
class HUDRenderer {
public:
    HUDRenderer(TTF_Font* font = nullptr);
    ~HUDRenderer() = default;

    void set_font(TTF_Font* font) { font_ = font; }
    void set_theme_light(bool light) { theme_light_ = light; }
    void set_enabled(bool enabled) { enabled_ = enabled; }

    // HUD rendering functions
    void render_hud(FramebufferManager& fb, float fps, float fps_target,
                   float pos_x, float pos_y, float pos_z, float yaw, float pitch,
                   bool smooth_surfaces, bool curvature, bool extra_light, bool diag_slice,
                   bool ray_jitter, bool mouse_captured, bool safe_defaults_mode,
                   bool safe_capture_mode, const std::string& backend_info,
                   PixelViewMode pixel_view_mode,
                   float move_speed, float move_speed_fast, float turn_speed_keys, float mouse_sens,
                   bool cam_clamp_enabled,
                   uint32_t hits, float ray_steps_avg, uint32_t ray_steps_max, uint32_t ray_miss_count,
                   float mem_read_util, float mem_write_util,
                   const ColorRange* color_stats, bool color_stats_valid,
                   bool cursor_hit_valid, uint8_t cursor_x, uint8_t cursor_y, uint8_t cursor_z,
                   uint8_t cursor_material_id,
                   bool selection_active, uint8_t sel_x, uint8_t sel_y, uint8_t sel_z);

    void render_help_overlay(FramebufferManager& fb, bool sticky, float timer);
    void render_mouse_capture_warning(FramebufferManager& fb, bool mouse_captured);

private:
    TTF_Font* font_;
    bool theme_light_;
    bool enabled_;
};

// Frame dumping and screenshots
class FrameDumper {
public:
    FrameDumper();
    ~FrameDumper() = default;

    // Configuration
    void set_dump_path(const char* path) { dump_path_ = path ? path : ""; }
    void set_dump_base(const char* base) { dump_base_ = base ? base : ""; }
    void set_max_dumps(int max) { max_dumps_ = max; }
    void set_auto_exit(bool exit) { auto_exit_ = exit; }

    // Frame dumping
    bool should_dump_frame(size_t frame_counter) const;
    void dump_frame(const FramebufferManager& fb, size_t frame_counter);
    void dump_screenshot(const FramebufferManager& fb, const std::string& filename = "");

private:
    std::string dump_path_;
    std::string dump_base_;
    int max_dumps_;
    int dumps_written_;
    bool auto_exit_;
};

// Color statistics tracking
struct ColorRange {
    uint8_t min_r, max_r;
    uint8_t min_g, max_g;
    uint8_t min_b, max_b;
};

ColorRange color_range_default();
void record_color(ColorRange& stats, uint32_t argb);

// Pixel processing
uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2);
uint32_t apply_fog(uint32_t argb, uint8_t depth_byte);

// SDL texture management
class TextureManager {
public:
    TextureManager(SDL_Renderer* renderer, int width, int height);
    ~TextureManager();

    // Texture operations
    bool recreate_texture();
    bool update_texture(const FramebufferManager& fb);
    void render_to_screen();

    // Texture info
    SDL_Texture* get_texture() const { return texture_; }
    bool is_valid() const { return texture_ != nullptr; }

private:
    SDL_Renderer* renderer_;
    SDL_Texture* texture_;
    int width_;
    int height_;
};