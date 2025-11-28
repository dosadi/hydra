// SPDX-License-Identifier: BSD-3-Clause
// viewer_rendering.cpp - Rendering and framebuffer management implementation
#include "viewer_rendering.h"
#include "viewer_globals.h"
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <chrono>

// FramebufferManager implementation
FramebufferManager::FramebufferManager(int width, int height, uint32_t clear_color)
    : width_(width), height_(height), clear_color_(clear_color),
      framebuffer_(static_cast<size_t>(width) * height, clear_color) {
}

void FramebufferManager::clear(uint32_t color) {
    std::fill(framebuffer_.begin(), framebuffer_.end(), color);
}

uint32_t FramebufferManager::get_pixel(int x, int y) const {
    if (x < 0 || x >= width_ || y < 0 || y >= height_) {
        return 0;
    }
    return framebuffer_[static_cast<size_t>(y) * width_ + x];
}

void FramebufferManager::set_pixel(int x, int y, uint32_t color) {
    if (x < 0 || x >= width_ || y < 0 || y >= height_) {
        return;
    }
    framebuffer_[static_cast<size_t>(y) * width_ + x] = color;
}

// Text rendering utilities
void draw_text_to_fb(std::vector<uint32_t>& fb, int fb_w, int fb_h,
                     TTF_Font* font, const std::string& txt,
                     int x, int y, SDL_Color color) {
    if (!font) return;

    SDL_Surface* surf = TTF_RenderText_Blended(font, txt.c_str(), color);
    if (!surf) return;

    SDL_PixelFormat* fmt = surf->format;
    if (!fmt || fmt->BytesPerPixel != 4) {
        SDL_PixelFormat* target_fmt = SDL_AllocFormat(SDL_PIXELFORMAT_ARGB8888);
        SDL_Surface* conv = SDL_ConvertSurface(surf, target_fmt, 0);
        SDL_FreeFormat(target_fmt);
        SDL_FreeSurface(surf);
        surf = conv;
        if (!surf) return;
        fmt = surf->format;
    }

    uint8_t* src = static_cast<uint8_t*>(surf->pixels);
    int pitch = surf->pitch;
    for (int j = 0; j < surf->h; ++j) {
        int dst_y = y + j;
        if (dst_y < 0 || dst_y >= fb_h) continue;
        uint32_t* row = reinterpret_cast<uint32_t*>(src + j * pitch);
        for (int i = 0; i < surf->w; ++i) {
            int dst_x = x + i;
            if (dst_x < 0 || dst_x >= fb_w) continue;
            uint32_t src_px = row[i];
            uint8_t a = (src_px >> 24) & 0xFF;
            if (a == 0) continue;
            uint8_t sr = (src_px >> 16) & 0xFF;
            uint8_t sg = (src_px >> 8)  & 0xFF;
            uint8_t sb =  src_px        & 0xFF;

            uint32_t& dst_px = fb[static_cast<size_t>(dst_y) * fb_w + dst_x];
            uint8_t dr = (dst_px >> 16) & 0xFF;
            uint8_t dg = (dst_px >> 8)  & 0xFF;
            uint8_t db =  dst_px        & 0xFF;

            uint8_t inv_a = 255 - a;
            uint8_t rr = static_cast<uint8_t>((sr * a + dr * inv_a) / 255);
            uint8_t gg = static_cast<uint8_t>((sg * a + dg * inv_a) / 255);
            uint8_t bb = static_cast<uint8_t>((sb * a + db * inv_a) / 255);

            dst_px = (0xFFu << 24) | (uint32_t(rr) << 16) | (uint32_t(gg) << 8) | uint32_t(bb);
        }
    }

    SDL_FreeSurface(surf);
}

// HUDRenderer implementation
HUDRenderer::HUDRenderer(TTF_Font* font)
    : font_(font), theme_light_(false), enabled_(true) {
}

void HUDRenderer::render_hud(FramebufferManager& fb_mgr, float fps, float fps_target,
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
                           bool selection_active, uint8_t sel_x, uint8_t sel_y, uint8_t sel_z) {
    if (!enabled_ || !font_) return;

    auto& fb = fb_mgr.get_framebuffer();
    int fb_w = fb_mgr.get_width();
    int fb_h = fb_mgr.get_height();

    // Darken HUD band based on theme
    for (int y = fb_h - HUD_HEIGHT; y < fb_h; ++y) {
        if (y < 0) continue;
        for (int x = 0; x < fb_w; ++x) {
            uint32_t& px = fb[static_cast<size_t>(y) * fb_w + x];
            uint8_t r = (px >> 16) & 0xFF;
            uint8_t g = (px >> 8)  & 0xFF;
            uint8_t b =  px        & 0xFF;
            if (theme_light_) {
                r = static_cast<uint8_t>(r + (255 - r) / 4);
                g = static_cast<uint8_t>(g + (255 - g) / 4);
                b = static_cast<uint8_t>(b + (255 - b) / 4);
            } else {
                r = static_cast<uint8_t>((r * 3) / 4);
                g = static_cast<uint8_t>((g * 3) / 4);
                b = static_cast<uint8_t>((b * 3) / 4);
            }
            px = (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
        }
    }

    char buf[256];
    const int hud_y = fb_h - HUD_HEIGHT + 4;
    int yoff = hud_y;
    SDL_Color hud_text_color = theme_light_ ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};

    // FPS and position
    if (fps_target > 0.0f) {
        std::snprintf(buf, sizeof(buf),
            "FPS %.1f / %.0f (target) | Pos %.1f %.1f %.1f",
            fps, fps_target, pos_x, pos_y, pos_z);
    } else {
        std::snprintf(buf, sizeof(buf),
            "FPS %.1f | Pos %.1f %.1f %.1f",
            fps, pos_x, pos_y, pos_z);
    }
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Camera angles
    std::snprintf(buf, sizeof(buf), "Yaw %.2f  Pitch %.2f", yaw, pitch);
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Render flags
    std::snprintf(buf, sizeof(buf),
        "[1] Smooth %s  [2] Curv %s  [3] Extra %s",
        smooth_surfaces ? "ON" : "OFF",
        curvature       ? "ON" : "OFF",
        extra_light     ? "ON" : "OFF");
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // More flags
    std::snprintf(buf, sizeof(buf),
        "[O] Slice %s  [J] Jitter %s  [M] Mouse %s",
        diag_slice     ? "ON" : "OFF",
        ray_jitter     ? "ON" : "OFF",
        mouse_captured ? "ON" : "OFF");
    SDL_Color mouse_line_color = mouse_captured ? hud_text_color : SDL_Color{255, 96, 96, 255};
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, mouse_line_color);
    yoff += 14;

    // Ray tracing stats
    std::snprintf(buf, sizeof(buf),
        "Hits %u | ray avg %.1f max %u miss %u",
        hits, ray_steps_avg, ray_steps_max, ray_miss_count);
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Memory utilization
    std::snprintf(buf, sizeof(buf),
        "Mem: rd %.1f%% wr %.1f%%",
        mem_read_util * 100.0f, mem_write_util * 100.0f);
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Color range stats
    if (color_stats_valid && color_stats) {
        std::snprintf(buf, sizeof(buf),
            "RGB range: R%3u-%3u  G%3u-%3u  B%3u-%3u",
            (unsigned)color_stats->min_r, (unsigned)color_stats->max_r,
            (unsigned)color_stats->min_g, (unsigned)color_stats->max_g,
            (unsigned)color_stats->min_b, (unsigned)color_stats->max_b);
    } else {
        std::snprintf(buf, sizeof(buf), "RGB range: capturing...");
    }
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Pixel view mode
    std::snprintf(buf, sizeof(buf),
        "Pixel view: %s  [V] cycle",
        pixel_view_mode_name(pixel_view_mode));
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Safe defaults
    std::snprintf(buf, sizeof(buf),
        "Safe defaults: %s [F2] (move %.3f/%.3f turn %.3f sens %.4f clamp %s)",
        safe_defaults_mode ? "ON" : "OFF",
        move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
        cam_clamp_enabled ? "ON" : "OFF");
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Safe capture
    std::snprintf(buf, sizeof(buf),
        "Safe capture: %s [F3] (input frozen)",
        safe_capture_mode ? "ON" : "OFF");
    SDL_Color warn_color = safe_capture_mode ? SDL_Color{255, 128, 96, 255} : hud_text_color;
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, warn_color);
    yoff += 14;

    // Backend info
    if (!backend_info.empty()) {
        draw_text_to_fb(fb, fb_w, fb_h, font_, backend_info, 6, yoff, hud_text_color);
        yoff += 14;
    }

    // Cursor info
    if (cursor_hit_valid) {
        std::snprintf(buf, sizeof(buf),
            "Cursor: (%u,%u,%u) mat=0x%02X",
            (unsigned)cursor_x, (unsigned)cursor_y, (unsigned)cursor_z,
            (unsigned)cursor_material_id);
    } else {
        std::snprintf(buf, sizeof(buf), "Cursor: (no hit)");
    }
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
    yoff += 14;

    // Selection info
    if (selection_active) {
        std::snprintf(buf, sizeof(buf),
            "Sel: (%u,%u,%u)  [G] clear  [F] select",
            (unsigned)sel_x, (unsigned)sel_y, (unsigned)sel_z);
    } else {
        std::snprintf(buf, sizeof(buf), "Sel: (none)  (aim + F to select)");
    }
    draw_text_to_fb(fb, fb_w, fb_h, font_, buf, 6, yoff, hud_text_color);
}

void HUDRenderer::render_help_overlay(FramebufferManager& fb_mgr, bool sticky, float timer) {
    if (!font_ || (!sticky && timer <= 0.0f)) return;

    auto& fb = fb_mgr.get_framebuffer();
    int fb_w = fb_mgr.get_width();
    int fb_h = fb_mgr.get_height();

    const char* help_lines[] = {
        "F1: toggle help overlay   /: show briefly",
        "Move: WASD/QE + mouse (M toggles capture)  Shift=fast  F2: safe defaults",
        "Flags: 1 smooth  2 curvature  3 extra  O diag slice  J jitter  T HUD theme",
        "Select: F pick voxel  G clear  Edit: C material, X/Z emissive, B brighten",
        "View: V cycle pixel view (color/word0/word2/sideband)  H HUD on/off",
        "Misc: S screenshot  P print state  R reset  ESC quit"
    };
    int line_count = static_cast<int>(sizeof(help_lines) / sizeof(help_lines[0]));

    int box_x = 6;
    int box_y = 6;
    int box_w = std::min(360, fb_w - 12);
    int box_h = line_count * 14 + 10;

    // Draw background box
    for (int y = box_y; y < box_y + box_h && y < fb_h; ++y) {
        for (int x = box_x; x < box_x + box_w && x < fb_w; ++x) {
            uint32_t& px = fb[static_cast<size_t>(y) * fb_w + x];
            uint8_t r = (px >> 16) & 0xFF;
            uint8_t g = (px >> 8)  & 0xFF;
            uint8_t b =  px        & 0xFF;
            if (theme_light_) {
                r = static_cast<uint8_t>(r + (255 - r) / 2);
                g = static_cast<uint8_t>(g + (255 - g) / 2);
                b = static_cast<uint8_t>(b + (255 - b) / 2);
            } else {
                r = static_cast<uint8_t>((r * 2) / 3);
                g = static_cast<uint8_t>((g * 2) / 3);
                b = static_cast<uint8_t>((b * 2) / 3);
            }
            px = (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
        }
    }

    SDL_Color help_color = theme_light_ ? SDL_Color{0, 0, 0, 255} : SDL_Color{255, 255, 255, 255};
    int help_y = box_y + 4;
    for (int i = 0; i < line_count; ++i) {
        draw_text_to_fb(fb, fb_w, fb_h, font_, help_lines[i], box_x + 4, help_y, help_color);
        help_y += 14;
    }
}

void HUDRenderer::render_mouse_capture_warning(FramebufferManager& fb_mgr, bool mouse_captured) {
    if (mouse_captured || !font_) return;

    auto& fb = fb_mgr.get_framebuffer();
    int fb_w = fb_mgr.get_width();

    SDL_Color warn_color{255, 96, 96, 255};
    int warn_x = fb_w - 210;
    int warn_y = 8;
    draw_text_to_fb(fb, fb_w, fb_mgr.get_height(), font_,
                    "Mouse capture OFF (press M)", warn_x, warn_y, warn_color);
}

// FrameDumper implementation
FrameDumper::FrameDumper()
    : max_dumps_(1), dumps_written_(0), auto_exit_(false) {
}

bool FrameDumper::should_dump_frame(size_t frame_counter) const {
    (void)frame_counter; // Unused for now
    return dumps_written_ < max_dumps_;
}

void FrameDumper::dump_frame(const FramebufferManager& fb_mgr, size_t frame_counter) {
    if (!should_dump_frame(frame_counter)) return;

    std::string pathbuf = dump_path_;
    if (!dump_base_.empty() && max_dumps_ != 1) {
        char buf[512];
        std::snprintf(buf, sizeof(buf), "%s_%zu.ppm", dump_base_.c_str(), frame_counter);
        pathbuf = buf;
    }

    FILE* f = std::fopen(pathbuf.c_str(), "wb");
    if (!f) {
        std::fprintf(stderr, "Failed to open FRAME_DUMP '%s' for write\n", pathbuf.c_str());
        return;
    }

    const auto& fb = fb_mgr.get_framebuffer();
    int width = fb_mgr.get_width();
    int height = fb_mgr.get_height();

    std::fprintf(stderr, "Writing frame dump to %s\n", pathbuf.c_str());
    std::fprintf(f, "P6\n%d %d\n255\n", width, height);

    for (int fy = 0; fy < height; ++fy) {
        for (int fx = 0; fx < width; ++fx) {
            uint32_t argb = fb[static_cast<size_t>(fy) * width + fx];
            uint8_t r = (argb >> 16) & 0xFF;
            uint8_t g = (argb >> 8)  & 0xFF;
            uint8_t b =  argb        & 0xFF;
            uint8_t rgb[3] = {r, g, b};
            std::fwrite(rgb, 1, 3, f);
        }
    }

    std::fclose(f);
    ++dumps_written_;

    if (max_dumps_ > 0 && dumps_written_ >= max_dumps_) {
        std::fprintf(stderr, "Max frame dumps (%d) reached, disabling further FRAME_DUMP writes\n", max_dumps_);
    }
}

void FrameDumper::dump_screenshot(const FramebufferManager& fb_mgr, const std::string& filename) {
    std::string fname = filename;
    if (fname.empty()) {
        auto now = std::chrono::system_clock::now();
        auto secs = std::chrono::duration_cast<std::chrono::seconds>(
            now.time_since_epoch()).count();
        char buf[256];
        std::snprintf(buf, sizeof(buf), "sim/screenshot_%ld.ppm", secs);
        fname = buf;
    }

    FILE* f = std::fopen(fname.c_str(), "wb");
    if (!f) {
        std::fprintf(stderr, "Failed to open %s for screenshot\n", fname.c_str());
        return;
    }

    const auto& fb = fb_mgr.get_framebuffer();
    int width = fb_mgr.get_width();
    int height = fb_mgr.get_height();

    std::fprintf(f, "P6\n%d %d\n255\n", width, height);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            uint32_t argb = fb[static_cast<size_t>(y) * width + x];
            uint8_t rgb[3] = {
                (uint8_t)((argb >> 16) & 0xFF),
                (uint8_t)((argb >> 8) & 0xFF),
                (uint8_t)(argb & 0xFF)
            };
            std::fwrite(rgb, 1, 3, f);
        }
    }
    std::fclose(f);
    std::fprintf(stderr, "Screenshot saved: %s\n", fname.c_str());
}

// Color statistics functions
ColorRange color_range_default() {
    return ColorRange{255, 0, 255, 0, 255, 0};
}

void record_color(ColorRange& stats, uint32_t argb) {
    uint8_t r = (argb >> 16) & 0xFF;
    uint8_t g = (argb >> 8)  & 0xFF;
    uint8_t b =  argb        & 0xFF;

    if (r < stats.min_r) stats.min_r = r;
    if (r > stats.max_r) stats.max_r = r;
    if (g < stats.min_g) stats.min_g = g;
    if (g > stats.max_g) stats.max_g = g;
    if (b < stats.min_b) stats.min_b = b;
    if (b > stats.max_b) stats.max_b = b;
}

// Pixel processing functions
uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    // Extract color components from 96-bit pixel format
    uint8_t r = (w0 >> 16) & 0xFF;
    uint8_t g = (w0 >> 8)  & 0xFF;
    uint8_t b =  w0        & 0xFF;
    uint8_t a = 0xFF; // Fully opaque

    return (uint32_t(a) << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
}

uint32_t apply_fog(uint32_t argb, uint8_t depth_byte) {
    if (!g_fog_enabled) return argb;

    // Simple fog calculation based on depth
    float depth = depth_byte / 255.0f;
    float fog_factor = 1.0f - std::exp(-g_fog_density * depth * depth);

    uint8_t sr = (argb >> 16) & 0xFF;
    uint8_t sg = (argb >> 8)  & 0xFF;
    uint8_t sb =  argb        & 0xFF;
    uint8_t sa = (argb >> 24) & 0xFF;

    uint8_t fr = (g_fog_color >> 16) & 0xFF;
    uint8_t fg = (g_fog_color >> 8)  & 0xFF;
    uint8_t fb =  g_fog_color        & 0xFF;

    uint8_t r = static_cast<uint8_t>(sr * (1.0f - fog_factor) + fr * fog_factor);
    uint8_t g = static_cast<uint8_t>(sg * (1.0f - fog_factor) + fg * fog_factor);
    uint8_t b = static_cast<uint8_t>(sb * (1.0f - fog_factor) + fb * fog_factor);

    return (uint32_t(sa) << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
}

// TextureManager implementation
TextureManager::TextureManager(SDL_Renderer* renderer, int width, int height)
    : renderer_(renderer), texture_(nullptr), width_(width), height_(height) {
    recreate_texture();
}

TextureManager::~TextureManager() {
    if (texture_) {
        SDL_DestroyTexture(texture_);
        texture_ = nullptr;
    }
}

bool TextureManager::recreate_texture() {
    if (texture_) {
        SDL_DestroyTexture(texture_);
        texture_ = nullptr;
    }

    texture_ = SDL_CreateTexture(renderer_, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STREAMING, width_, height_);
    return texture_ != nullptr;
}

bool TextureManager::update_texture(const FramebufferManager& fb_mgr) {
    if (!texture_) return false;

    void* pixels = nullptr;
    int pitch_bytes = 0;
    if (SDL_LockTexture(texture_, nullptr, &pixels, &pitch_bytes) != 0) {
        return false;
    }

    const auto& fb = fb_mgr.get_framebuffer();
    for (int y = 0; y < height_; ++y) {
        uint32_t* row = (uint32_t*)((uint8_t*)pixels + y * pitch_bytes);
        std::memcpy(row, &fb[static_cast<size_t>(y) * width_], width_ * sizeof(uint32_t));
    }

    SDL_UnlockTexture(texture_);
    return true;
}

void TextureManager::render_to_screen() {
    if (!texture_) return;

    SDL_SetRenderDrawColor(renderer_, 0, 0, 0, 255);
    SDL_RenderClear(renderer_);
    SDL_RenderCopy(renderer_, texture_, nullptr, nullptr);
    SDL_RenderPresent(renderer_);
}