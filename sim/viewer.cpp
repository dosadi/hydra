
// viewer.cpp removed: harness is provided by `live_sdl_main.cpp` and
// the thin wrapper `viewer_main.cpp`. This file kept as a placeholder
// to avoid accidental re-addition of the large duplicated source.
//
// If you need an alternate harness, edit `live_sdl_main.cpp` or create
// a new translation unit instead of duplicating code here.


#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"
#include "Vvoxel_framebuffer_top___024root.h"
#include "platform/backend_selector.h"
#include "platform/platform.h"

#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <cmath>
#include <chrono>
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <cctype>
#include <fstream>
#include <filesystem>
#include <strings.h>
#include <unistd.h>

struct ColorRange {
    uint8_t min_r;
    uint8_t min_g;
    uint8_t min_b;
    uint8_t max_r;
    uint8_t max_g;
    uint8_t max_b;
};

static ColorRange color_range_default() {
    return ColorRange{0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00};
}

static void record_color(ColorRange& range, uint32_t argb) {
    uint8_t r = (argb >> 16) & 0xFF;
    uint8_t g = (argb >>  8) & 0xFF;
    uint8_t b = (argb      ) & 0xFF;
    range.min_r = std::min(range.min_r, r);
    range.min_g = std::min(range.min_g, g);
    range.min_b = std::min(range.min_b, b);
    range.max_r = std::max(range.max_r, r);
    range.max_g = std::max(range.max_g, g);
    range.max_b = std::max(range.max_b, b);
}

static const int   SCREEN_WIDTH  = 480;
static const int   SCREEN_HEIGHT = 360;
static const int   HUD_HEIGHT    = 80;
static const float FX            = 256.0f;  // fixed-point scale
static bool        g_vsync       = true;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

enum class PixelViewMode {
    Color = 0,
    Word0,
    Word2,
    SidebandMix,
};

static PixelViewMode g_pixel_view_mode = PixelViewMode::Color;

static const char* pixel_view_mode_name(PixelViewMode m) {
    switch (m) {
        case PixelViewMode::Color:      return "color";
        case PixelViewMode::Word0:      return "word0";
        case PixelViewMode::Word2:      return "word2";
        case PixelViewMode::SidebandMix:return "sideband";
        default:                        return "unknown";
    }
}

static PixelViewMode pixel_view_from_string(const char* s) {
    if (!s) return PixelViewMode::Color;
    if (strcasecmp(s, "color") == 0)    return PixelViewMode::Color;
    if (strcasecmp(s, "word0") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "depth") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "word2") == 0)    return PixelViewMode::Word2;
    if (strcasecmp(s, "reemissure") == 0|| strcasecmp(s, "reem") == 0) return PixelViewMode::Word2;
    if (strcasecmp(s, "sideband") == 0) return PixelViewMode::SidebandMix;
    return PixelViewMode::Color;
}

static uint32_t visualize_word(uint32_t w) {
    uint8_t r = (w >> 24) & 0xFF;
    uint8_t g = (w >> 16) & 0xFF;
    uint8_t b = (w >>  8) & 0xFF;
    // If the upper bytes are zero, fall back to showing the low byte so the view is not blank.
    if (r == 0 && g == 0 && b == 0) {
        uint8_t lsb = w & 0xFF;
        r = g = b = lsb;
    }
    return (0xFFu << 24) |
           (uint32_t(r) << 16) |
           (uint32_t(g) << 8)  |
            uint32_t(b);
}

static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    switch (g_pixel_view_mode) {
        case PixelViewMode::Color: {
            uint8_t r = (w1 >> 24) & 0xFF;
            uint8_t g = (w1 >> 16) & 0xFF;
            uint8_t b = (w1 >>  8) & 0xFF;
            return (0xFFu << 24) |
                   (uint32_t(r) << 16) |
                   (uint32_t(g) << 8)  |
                    uint32_t(b);
        }
        case PixelViewMode::Word0:
            return visualize_word(w0);
        case PixelViewMode::Word2:
            return visualize_word(w2);
        case PixelViewMode::SidebandMix: {
            uint8_t depth_like = (w0 >> 16) & 0xFF;
            uint8_t emissive   = (w2 >> 16) & 0xFF;
            uint8_t diag_bits  = (w0 >> 8)  & 0xFF;
            return (0xFFu << 24) |
                   (uint32_t(emissive)   << 16) |
                   (uint32_t(depth_like) << 8)  |
                    uint32_t(diag_bits);
        }
        default:
            return visualize_word(w1);
    }
}

// Depth-fog configuration and application
static bool g_fog_enabled = false;
static uint32_t g_fog_color = 0xFFE0E0E0; // ARGB
static float g_fog_density = 1.0f; // linear density multiplier

static uint32_t apply_fog(uint32_t src_argb, uint8_t depth_byte) {
    if (!g_fog_enabled) return src_argb;
    float d = static_cast<float>(depth_byte) / 255.0f; // 0..1, 0=near,1=far
    // simple linear/exponential blend control
    float factor = d * g_fog_density;
    if (factor > 1.0f) factor = 1.0f;

    uint8_t sr = (src_argb >> 16) & 0xFF;
    uint8_t sg = (src_argb >> 8)  & 0xFF;
    uint8_t sb =  src_argb        & 0xFF;

    uint8_t fr = (g_fog_color >> 16) & 0xFF;
    uint8_t fg = (g_fog_color >> 8)  & 0xFF;
    uint8_t fb =  g_fog_color        & 0xFF;

    uint8_t rr = static_cast<uint8_t>(sr * (1.0f - factor) + fr * factor);
    uint8_t gg = static_cast<uint8_t>(sg * (1.0f - factor) + fg * factor);
    uint8_t bb = static_cast<uint8_t>(sb * (1.0f - factor) + fb * factor);

    return (0xFFu << 24) | (uint32_t(rr) << 16) | (uint32_t(gg) << 8) | uint32_t(bb);
}

static uint32_t spectrum_pixel(uint32_t addr) {
    uint32_t x = addr % SCREEN_WIDTH;
    uint32_t y = addr / SCREEN_WIDTH;
    uint8_t r = (x * 255) / (SCREEN_WIDTH - 1);
    uint8_t g = (y * 255) / (SCREEN_HEIGHT - 1);
    uint8_t b = ((x + y) * 255) / ((SCREEN_WIDTH + SCREEN_HEIGHT) - 2);
    return (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
}

static inline uint32_t voxel_addr_from_xyz(uint8_t x, uint8_t y, uint8_t z) {
    return (uint32_t(x) << 12) | (uint32_t(y) << 6) | uint32_t(z);
}

static bool env_truthy(const char* key) {
    if (const char* v = std::getenv(key)) {
        return v[0] != '\0' && v[0] != '0' && strcasecmp(v, "false") != 0;
    }
    return false;
}

static void apply_cli_overrides(int argc, char** argv) {
    auto missing_value = [](const char* flag) {
        std::fprintf(stderr, "[hydra] Missing value for %s\n", flag);
    };
    auto set_override = [](const char* key, const char* value, const char* note = nullptr) {
        if (!value) return;
        setenv(key, value, 1);
        if (note) {
            std::fprintf(stderr, "[hydra] CLI override: %s=%s (%s)\n", key, value, note);
        } else {
            std::fprintf(stderr, "[hydra] CLI override: %s=%s\n", key, value);
        }
    };
    auto match_arg = [&](const char* arg, const char* long_flag, int& i) -> const char* {
        size_t len = std::strlen(long_flag);
        if (std::strncmp(arg, long_flag, len) != 0)
            return nullptr;
        if (arg[len] == '=') {
            return arg + len + 1;
        }
        if (i + 1 < argc) {
            return argv[++i];
        }
        missing_value(long_flag);
        return nullptr;
    };

    bool show_caps = false;

    for (int i = 1; i < argc; ++i) {
        const char* arg = argv[i];
        if (!arg) continue;
        if (std::strcmp(arg, "--show-capabilities") == 0 || std::strcmp(arg, "--caps") == 0) {
            show_caps = true;
        } else if (std::strcmp(arg, "--quiet") == 0 || std::strcmp(arg, "-q") == 0) {
            setenv("HYDRA_QUIET", "1", 1);
        } else if (std::strcmp(arg, "--verbose") == 0 || std::strcmp(arg, "-v") == 0) {
            setenv("HYDRA_VERBOSE", "1", 1);
        } else if ((std::strcmp(arg, "--backend") == 0 || std::strcmp(arg, "-b") == 0) && i + 1 < argc) {
            const char* val = argv[++i];
            setenv("HYDRA_BACKEND", val, 1);
            std::fprintf(stderr, "[hydra] CLI override: backend=%s\n", val);
        } else if (const char* val = match_arg(arg, "--backend", i)) {
            set_override("HYDRA_BACKEND", val);
        } else if ((std::strcmp(arg, "--sdl-driver") == 0 || std::strcmp(arg, "--video-driver") == 0) && i + 1 < argc) {
            const char* val = argv[++i];
            setenv("SDL_VIDEODRIVER", val, 1);
            std::fprintf(stderr, "[hydra] CLI override: SDL_VIDEODRIVER=%s\n", val);
        } else if (const char* val = match_arg(arg, "--sdl-driver", i)) {
            set_override("SDL_VIDEODRIVER", val, "SDL video driver");
        } else if (const char* val = match_arg(arg, "--video-driver", i)) {
            set_override("SDL_VIDEODRIVER", val, "SDL video driver");
        } else if (std::strcmp(arg, "--instrument") == 0) {
            setenv("HYDRA_RENDER_INSTRUMENT", "1", 1);
            std::fprintf(stderr, "[hydra] CLI override: render instrumentation enabled\n");
        } else if (const char* val = match_arg(arg, "--cam-pos", i)) {
            set_override("HYDRA_CAM_POS", val, "camera position (x,y,z)");
        } else if (const char* val = match_arg(arg, "--cam-ang", i)) {
            set_override("HYDRA_CAM_ANG", val, "camera yaw,pitch");
        } else if (const char* val = match_arg(arg, "--move-speed", i)) {
            set_override("HYDRA_MOVE_SPEED", val, "move speed");
        } else if (const char* val = match_arg(arg, "--move-speed-fast", i)) {
            set_override("HYDRA_MOVE_SPEED_FAST", val, "fast move speed");
        } else if (const char* val = match_arg(arg, "--turn-speed", i)) {
            set_override("HYDRA_TURN_SPEED_KEYS", val, "key turn speed");
        } else if (const char* val = match_arg(arg, "--mouse-sens", i)) {
            set_override("HYDRA_MOUSE_SENS", val, "mouse sensitivity");
        } else if (const char* val = match_arg(arg, "--fps-target", i)) {
            set_override("HYDRA_FPS_TARGET", val, "frame pacing target");
        } else if (const char* val = match_arg(arg, "--pixel-view", i)) {
            set_override("HYDRA_PIXEL_VIEW", val, "pixel view mode");
        } else if (const char* val = match_arg(arg, "--seed", i)) {
            set_override("HYDRA_WORLD_SEED", val, "world/procedural seed");
        }
    }

    if (show_caps) {
        platform_log_capabilities();
        std::exit(0);
    }
}

static std::string g_backend_info;

static const char* backend_name(PlatformBackend b) {
    switch (b) {
        case PlatformBackend::SDL:    return "SDL";
        case PlatformBackend::GL:     return "GL";
        case PlatformBackend::Vulkan: return "Vulkan";
        case PlatformBackend::Wayland:return "Wayland";
        case PlatformBackend::X11:    return "X11";
        case PlatformBackend::Fbdev:  return "fbdev";
        case PlatformBackend::Win32:  return "Win32";
        case PlatformBackend::MacOS:  return "macOS";
        case PlatformBackend::Headless: return "Headless";
        default: return "Unknown";
    }
}

static void log_backend_caps(PlatformBackend requested, PlatformBackend backend, bool vsync) {
    const char* video_driver = SDL_GetCurrentVideoDriver();
    const char* render_driver = SDL_GetHint(SDL_HINT_RENDER_DRIVER);

    std::fprintf(stderr,
        "[hydra] backend requested=%s actual=%s vsync=%s video_driver=%s render_driver=%s\n",
        backend_name(requested),
        backend_name(backend),
        vsync ? "on" : "off",
        video_driver ? video_driver : "(unknown)",
        render_driver ? render_driver : "(default)");

    std::fprintf(stderr, "[hydra] compiled backends: SDL");
#ifdef HYDRA_ENABLE_GL
    std::fprintf(stderr, " GL");
#endif
#ifdef HYDRA_ENABLE_VULKAN
    std::fprintf(stderr, " Vulkan");
#endif
#ifdef HYDRA_ENABLE_WAYLAND
    std::fprintf(stderr, " Wayland");
#endif
#ifdef HYDRA_ENABLE_X11
    std::fprintf(stderr, " X11");
#endif
    std::fprintf(stderr, " Headless\n");
}

static void log_input_caps() {
    const char* grab_hint = SDL_GetHint(SDL_HINT_GRAB_KEYBOARD);
    const char* mouse_hint = SDL_GetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP);

    int joysticks = SDL_NumJoysticks();
    int controllers = 0;
    for (int i = 0; i < joysticks; ++i) {
        if (SDL_IsGameController(i)) {
            ++controllers;
        }
    }

    int touch_devices = SDL_GetNumTouchDevices();

    std::fprintf(stderr,
        "[hydra] input: keyboard=assumed mouse_capture_hint=%s mouse_relative_hint=%s touch_devices=%d joysticks=%d controllers=%d\n",
        grab_hint ? grab_hint : "(default)",
        mouse_hint ? mouse_hint : "(default)",
        touch_devices,
        joysticks,
        controllers);
}

struct InputState {
    bool forward     = false;
    bool back        = false;
    bool strafe_left = false;
    bool strafe_right = false;
    bool up          = false;
    bool down        = false;
    bool yaw_left    = false;
    bool yaw_right   = false;
    bool pitch_up    = false;
    bool pitch_down  = false;
    bool fast        = false;
};

static inline void update_key_state(InputState& keys, SDL_Scancode sc,
                                    SDL_Keycode keycode, bool pressed) {
    switch (sc) {
        case SDL_SCANCODE_W: keys.forward      = pressed; break;
        case SDL_SCANCODE_S: keys.back         = pressed; break;
        case SDL_SCANCODE_A: keys.strafe_left  = pressed; break;
        case SDL_SCANCODE_D: keys.strafe_right = pressed; break;
        case SDL_SCANCODE_Q: keys.down         = pressed; break;
        case SDL_SCANCODE_E: keys.up           = pressed; break;
        case SDL_SCANCODE_LEFT:  keys.yaw_left  = pressed; break;
        case SDL_SCANCODE_RIGHT: keys.yaw_right = pressed; break;
        case SDL_SCANCODE_UP:    keys.pitch_up  = pressed; break;
        case SDL_SCANCODE_DOWN:  keys.pitch_down= pressed; break;
        case SDL_SCANCODE_LSHIFT:
        case SDL_SCANCODE_RSHIFT: keys.fast     = pressed; break;
        default: break;
    }

    // Fallback to keycodes in case scancodes are missing or unusual.
    SDL_Keycode kc = keycode;
    if (kc >= 'A' && kc <= 'Z')
        kc = kc - 'A' + 'a';

    switch (kc) {
        case SDLK_w: keys.forward      = pressed; break;
        case SDLK_s: keys.back         = pressed; break;
        case SDLK_a: keys.strafe_left  = pressed; break;
        case SDLK_d: keys.strafe_right = pressed; break;
        case SDLK_q: keys.down         = pressed; break;
        case SDLK_e: keys.up           = pressed; break;
        case SDLK_LEFT:  keys.yaw_left  = pressed; break;
        case SDLK_RIGHT: keys.yaw_right = pressed; break;
        case SDLK_UP:    keys.pitch_up  = pressed; break;
        case SDLK_DOWN:  keys.pitch_down= pressed; break;
        case SDLK_LSHIFT:
        case SDLK_RSHIFT: keys.fast     = pressed; break;
        default: break;
    }
}

static void die(const std::string& s) {
    std::fprintf(stderr, "Error: %s\n", s.c_str());
    std::exit(1);
}

static void draw_text_to_fb(std::vector<uint32_t>& fb, int fb_w, int fb_h,
                             TTF_Font* font,
                             const std::string& txt,
                             int x, int y,
                             SDL_Color color = {255,255,255,255})
{
    SDL_Surface* surf = TTF_RenderText_Blended(font, txt.c_str(), color);
    if (!surf) return;

    SDL_PixelFormat* fmt = surf->format;
    if (!fmt || fmt->BytesPerPixel != 4) {
        SDL_Surface* conv = SDL_ConvertSurfaceFormat(surf, SDL_PIXELFORMAT_ARGB8888, 0);
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

struct RenderInstrumentationConfig {
    float cam_pos_x = 0.0f;
    float cam_pos_y = 0.0f;
    float cam_pos_z = 0.0f;
    float yaw = 0.0f;
    float pitch = 0.0f;
    bool smooth_surfaces = false;
    bool curvature = false;
    bool extra_light = false;
    bool diag_slice = false;
    bool ray_jitter = false;
    bool hud_enabled = true;
    float fps_target = 0.0f;
    bool vsync = true;
    std::string backend_name;
    std::string backend_info;
    std::string pixel_view;
};

struct RenderInstrumentation {
    RenderInstrumentation(bool enabled, std::string command_line)
        : enabled_(enabled), command_line_(std::move(command_line)) {
        if (!enabled_)
            return;
        std::filesystem::create_directories("out");
        csv_.open("out/render_pipeline_baseline.csv", std::ios::app);
        if (!csv_)
            die("failed to open out/render_pipeline_baseline.csv for instrumentation logging");
        if (csv_.tellp() == 0)
            csv_ << "frame,timestamp_ms,fps,ray_loop_ms,hud_present_ms,framebuffer_copy_ms,frame_total_ms\n";
    }

    bool active() const { return enabled_; }

    void write_config(const RenderInstrumentationConfig& cfg) {
        if (!enabled_)
            return;
        std::ofstream cfg_out("out/render_pipeline_baseline.cfg");
        if (!cfg_out)
            die("failed to write out/render_pipeline_baseline.cfg");
        cfg_out << "instrument_command=" << command_line_ << "\n";
        cfg_out << "backend=" << cfg.backend_name << "\n";
        cfg_out << "backend_info=" << cfg.backend_info << "\n";
        cfg_out << "pixel_view=" << cfg.pixel_view << "\n";
        cfg_out << "camera_pos=" << cfg.cam_pos_x << "," << cfg.cam_pos_y << "," << cfg.cam_pos_z << "\n";
        cfg_out << "camera_ang=" << cfg.yaw << "," << cfg.pitch << "\n";
        cfg_out << "flags=smooth:" << (cfg.smooth_surfaces ? "1" : "0")
                << ",curvature:" << (cfg.curvature ? "1" : "0")
                << ",extra_light:" << (cfg.extra_light ? "1" : "0")
                << ",diag_slice:" << (cfg.diag_slice ? "1" : "0")
                << ",ray_jitter:" << (cfg.ray_jitter ? "1" : "0") << "\n";
        cfg_out << "hud_enabled=" << (cfg.hud_enabled ? "1" : "0") << "\n";
        cfg_out << "fps_target=" << cfg.fps_target << "\n";
        cfg_out << "vsync=" << (cfg.vsync ? "1" : "0") << "\n";
    }

    void record(uint64_t frame,
                double fps,
                double ray_loop_ms,
                double hud_present_ms,
                double framebuffer_copy_ms,
                double frame_total_ms) {
        if (!enabled_)
            return;
        auto now = std::chrono::system_clock::now();
        auto ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
        csv_ << frame << ',' << ts_ms << ',' << fps << ','
             << ray_loop_ms << ',' << hud_present_ms << ','
             << framebuffer_copy_ms << ',' << frame_total_ms << '\n';
        csv_.flush();
    }

private:
    bool enabled_;
    std::ofstream csv_;
    std::string command_line_;
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    apply_cli_overrides(argc, argv);

    const bool render_instrument_mode = env_truthy("HYDRA_RENDER_INSTRUMENT");
    RenderInstrumentation render_instrument(render_instrument_mode, flatten_cli_args(argc, argv));

    Vvoxel_framebuffer_top* top = new Vvoxel_framebuffer_top;
    auto* root = top->rootp;  // Access internal regs exposed by Verilator
    top->clk   = 0;
    top->rst_n = 0;
    // Default AXI shell inputs (unused in this harness)
    top->cam_load        = 0;
    top->cam_x_in        = 0;
    top->cam_y_in        = 0;
    top->cam_z_in        = 0;
    top->cam_dir_x_in    = 0;
    top->cam_dir_y_in    = 0;
    top->cam_dir_z_in    = 0;
    top->cam_plane_x_in  = 0;
    top->cam_plane_y_in  = 0;
    top->flags_load      = 0;
    top->flag_smooth_in  = 0;
    top->flag_curvature_in = 0;
    top->flag_extra_light_in = 0;
    top->flag_diag_slice_in  = 0;
    top->sel_load        = 0;
    top->sel_active_in   = 0;
    top->sel_voxel_x_in  = 0;
    top->sel_voxel_y_in  = 0;
    top->sel_voxel_z_in  = 0;
    top->dbg_ext_write_en   = 0;
    top->dbg_ext_write_addr = 0;
    top->dbg_ext_write_data = 0;
    top->start_frame_ext   = 0;
    top->soft_reset_ext    = 0;

    const bool log_keys = (std::getenv("LOG_KEYS") != nullptr);
    const bool log_frames = (std::getenv("LOG_FRAMES") != nullptr);
    int log_keys_count = 0;
    size_t pixels_this_frame = 0;
    size_t frame_counter = 0;
    int log_pixel_samples = 0;
    uint64_t prev_mem_cycle = 0;
    uint64_t prev_mem_read  = 0;
    uint64_t prev_mem_write = 0;
    float last_mem_read_util  = 0.0f;
    float last_mem_write_util = 0.0f;
    ColorRange frame_color_stats = color_range_default();
    ColorRange last_frame_color_stats = frame_color_stats;
    bool frame_color_stats_dirty = false;
    bool last_frame_color_stats_valid = false;

    // Configure depth fog from environment
    g_fog_enabled = env_truthy("HYDRA_FOG");
    if (const char* fog_col = std::getenv("HYDRA_FOG_COLOR")) {
        // accept formats like "0xRRGGBB" or "RRGGBB"
        unsigned long v = std::strtoul(fog_col, nullptr, 0);
        g_fog_color = 0xFF000000u | (uint32_t(v) & 0x00FFFFFFu);
    }
    if (const char* fog_den = std::getenv("HYDRA_FOG_DENSITY")) {
        char* endptr = nullptr;
        float d = std::strtof(fog_den, &endptr);
        if (endptr && endptr != fog_den) g_fog_density = d;
    }
    if (g_fog_enabled) {
        std::fprintf(stderr, "[hydra] Depth fog enabled color=%08x density=%.3f\n", g_fog_color, g_fog_density);
    }

    // Ensure SDL grabs keyboard focus; allow renderer selection via SDL hints/env.
    SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1");
    SDL_SetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP, "1");

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
        die(std::string("SDL_Init: ") + SDL_GetError());
    if (TTF_Init() != 0)
        die(std::string("TTF_Init: ") + TTF_GetError());

    // Platform backend selection (HYDRA_BACKEND env respected inside select_default_backend).
    PlatformBackend requested_backend = select_default_backend();
    const bool headless_backend = (requested_backend == PlatformBackend::Headless);
    if (headless_backend) {
        // Force SDL to a dummy driver so no window/display server is required.
        setenv("SDL_VIDEODRIVER", "dummy", 0);
        setenv("SDL_AUDIODRIVER", "dummy", 0);
    }

    log_input_caps();

    if (std::getenv("HYDRA_VSYNC")) {
        g_vsync = env_truthy("HYDRA_VSYNC");
    }
    PlatformBackend backend = PlatformBackend::SDL;
    PlatformContext plat_ctx;
    bool use_platform_present = false;

    // Track if we had to fallback from requested backend
    bool backend_fallback = false;
    PlatformBackend attempted_backend = requested_backend;

    if (requested_backend != PlatformBackend::SDL) {
        if (!platform_backend_supported(requested_backend)) {
            std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' is not supported on this platform\n",
                         backend_name(requested_backend));
            std::fprintf(stderr, "[hydra] REASON: Backend not compiled in or platform incompatible\n");
            std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");
            std::fprintf(stderr, "[hydra] TIP: Run './sim_voxel --caps' to see available backends\n\n");
            backend_fallback = true;
        } else {
            PlatformConfig plat_cfg;
            plat_cfg.width  = SCREEN_WIDTH;
            plat_cfg.height = SCREEN_HEIGHT;
            plat_cfg.vsync  = true;

            std::fprintf(stderr, "[hydra] Initializing %s backend...\n", backend_name(requested_backend));

            if (init_backend(requested_backend, plat_cfg, plat_ctx)) {
                backend = requested_backend;
                use_platform_present = true;
                std::fprintf(stderr, "[hydra] SUCCESS: %s backend initialized\n", backend_name(backend));
            } else {
                std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' initialization failed\n",
                             backend_name(requested_backend));
                std::fprintf(stderr, "[hydra] REASON: Check stderr above for specific error messages\n");
                std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");

                // Provide specific hints based on backend
                if (requested_backend == PlatformBackend::GL) {
                    std::fprintf(stderr, "[hydra] TIP: Install OpenGL drivers or try HYDRA_BACKEND=sdl\n");
                } else if (requested_backend == PlatformBackend::Vulkan) {
                    std::fprintf(stderr, "[hydra] TIP: Install Vulkan drivers or try HYDRA_BACKEND=gl\n");
                } else if (requested_backend == PlatformBackend::Wayland || requested_backend == PlatformBackend::X11) {
                    std::fprintf(stderr, "[hydra] TIP: Check DISPLAY env var or try HYDRA_BACKEND=sdl\n");
                }
                std::fprintf(stderr, "\n");
                backend_fallback = true;
            }
        }
    }

    if (backend == PlatformBackend::SDL) {
        std::fprintf(stderr, "[hydra] Using SDL backend%s\n",
                     backend_fallback ? " (fallback)" : " (default)");
    }

    log_backend_caps(requested_backend, backend, g_vsync);

    SDL_Window* win = SDL_CreateWindow(
        "Voxel Accelerator — Interactive Raycaster",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2,
        SDL_WINDOW_RESIZABLE
    );
    if (!win) die("Cannot create SDL window");
    SDL_RaiseWindow(win);

    uint32_t sdl_renderer_flags = SDL_RENDERER_ACCELERATED;
    if (g_vsync) sdl_renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, sdl_renderer_flags);
    if (!ren) die("Renderer creation failed");

    SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);

    SDL_RendererInfo ren_info;
    if (SDL_GetRendererInfo(ren, &ren_info) == 0) {
        std::fprintf(stderr, "Renderer: %s\n", ren_info.name ? ren_info.name : "(unknown)");
        const char* video_driver = SDL_GetCurrentVideoDriver();
        char buf[160];
        std::snprintf(buf, sizeof(buf), "Backend: %s (vsync %s) renderer=%s video=%s",
                      backend_name(backend),
                      g_vsync ? "on" : "off",
                      ren_info.name ? ren_info.name : "(unknown)",
                      video_driver ? video_driver : "(unknown)");
        g_backend_info = buf;
    }

    SDL_Texture* tex = SDL_CreateTexture(
        ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        SCREEN_WIDTH, SCREEN_HEIGHT
    );
    if (!tex) die("Texture creation failed");

    auto recreate_texture = [&]() {
        if (tex) {
            SDL_DestroyTexture(tex);
            tex = nullptr;
        }
        tex = SDL_CreateTexture(
            ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
            SCREEN_WIDTH, SCREEN_HEIGHT
        );
        if (!tex) die("Texture recreation failed");
    };

    const char* font_env = std::getenv("HYDRA_FONT");
    const char* font_scale_env = std::getenv("HYDRA_FONT_SCALE");
    int font_size = 11;
    if (font_scale_env) {
        float scale = std::atof(font_scale_env);
        if (scale < 0.5f) scale = 0.5f;
        if (scale > 3.0f) scale = 3.0f;
        font_size = std::max(8, static_cast<int>(11 * scale));
    }

    // Fallback font search paths for different platforms
    const char* font_search_paths[] = {
        font_env,  // User override first
        // Debian/Ubuntu
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        // Fedora/RHEL
        "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
        "/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
        // Arch
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
        // FreeBSD
        "/usr/local/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/local/share/fonts/Liberation/LiberationSans-Regular.ttf",
        // macOS
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/SFNSText.ttf",
        // Windows (if running under WSL or similar)
        "/mnt/c/Windows/Fonts/arial.ttf",
        "/mnt/c/Windows/Fonts/Arial.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
        nullptr
    };

    TTF_Font* font = nullptr;
    const char* font_path = nullptr;

    for (int i = 0; font_search_paths[i] != nullptr; ++i) {
        if (font_search_paths[i] == nullptr || font_search_paths[i][0] == '\0')
            continue;

        font = TTF_OpenFont(font_search_paths[i], font_size);
        if (font) {
            font_path = font_search_paths[i];
            break;
        }
    }

    if (!font) {
        std::fprintf(stderr, "Warning: could not find any suitable font, HUD text disabled\n");
        std::fprintf(stderr, "Hint: Set HYDRA_FONT=/path/to/font.ttf to specify a font\n");
    } else if (font_env && font_path != font_env) {
        std::fprintf(stderr, "Warning: HYDRA_FONT='%s' not found, using fallback: %s\n",
                     font_env, font_path);
    }

    const size_t NPIX = size_t(SCREEN_WIDTH) * SCREEN_HEIGHT;

    const char* frame_dump_path = std::getenv("FRAME_DUMP");
    const char* frame_dump_base = std::getenv("HYDRA_FRAME_BASE");
    const char* auto_exit_env   = std::getenv("AUTO_EXIT");
    bool auto_exit              = auto_exit_env && auto_exit_env[0] != '\0';
    const char* max_dump_env    = std::getenv("HYDRA_MAX_FRAME_DUMPS");
    int max_frame_dumps         = max_dump_env ? std::max(0, std::atoi(max_dump_env)) : 1;
    int frame_dumps_written     = 0;
    const char* autosave_cfg    = std::getenv("HYDRA_AUTOSAVE_CFG");
    const bool clear_each_frame = (std::getenv("HYDRA_CLEAR_EACH_FRAME") != nullptr);
    const char* fg_env = std::getenv("HYDRA_CLEAR_COLOR");
    uint32_t clear_color = 0;
    if (fg_env) {
        unsigned int r=0,g=0,b=0;
        if (std::sscanf(fg_env, "%u,%u,%u", &r, &g, &b) == 3) {
            clear_color = (0xFFu << 24) | ((r & 0xFFu) << 16) | ((g & 0xFFu) << 8) | (b & 0xFFu);
        }
    }
    std::vector<uint32_t> framebuffer(NPIX, clear_color);

    auto handle_resize = [&](int new_w, int new_h) {
        (void)new_w; (void)new_h;
        SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);
        recreate_texture();
        std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
        std::fprintf(stderr, "[hydra] window resized, refreshed texture and cleared framebuffer\n");
    };

    // Reset sequence
    for (int i = 0; i < 10; ++i) {
        top->clk = 0; top->eval(); main_time++;
        top->clk = 1; top->eval(); main_time++;
    }
    top->rst_n = 1;

    const char* cam_pos_env = std::getenv("HYDRA_CAM_POS");   // "x,y,z"
    const char* cam_ang_env = std::getenv("HYDRA_CAM_ANG");   // "yaw,pitch"
    auto parse_vec3 = [](const char* s, float def_x, float def_y, float def_z, float& ox, float& oy, float& oz) {
        ox = def_x; oy = def_y; oz = def_z;
        if (!s) return;
        if (std::sscanf(s, "%f,%f,%f", &ox, &oy, &oz) != 3) {
            ox = def_x; oy = def_y; oz = def_z;
        }
    };
    auto parse_vec2 = [](const char* s, float def_a, float def_b, float& oa, float& ob) {
        oa = def_a; ob = def_b;
        if (!s) return;
        if (std::sscanf(s, "%f,%f", &oa, &ob) != 2) {
            oa = def_a; ob = def_b;
        }
    };

    float pos_x = 10.0f;
    float pos_y = 10.0f;
    float pos_z = 10.0f;
    float yaw   = 0.0f;
    float pitch = 0.0f;
    parse_vec3(cam_pos_env, pos_x, pos_y, pos_z, pos_x, pos_y, pos_z);
    parse_vec2(cam_ang_env, yaw, pitch, yaw, pitch);
    const float default_pos_x = pos_x;
    const float default_pos_y = pos_y;
    const float default_pos_z = pos_z;
    const float default_yaw   = yaw;
    const float default_pitch = pitch;

    auto getenv_float = [](const char* name, float def_val) -> float {
        const char* v = std::getenv(name);
        if (!v) return def_val;
        return std::atof(v);
    };

    float move_speed      = getenv_float("HYDRA_MOVE_SPEED", 0.10f);
    float move_speed_fast = getenv_float("HYDRA_MOVE_SPEED_FAST", 0.35f);
    float turn_speed_keys = getenv_float("HYDRA_TURN_SPEED_KEYS", 0.04f);
    float mouse_sens      = getenv_float("HYDRA_MOUSE_SENS", 0.0025f);
    bool invert_y_mouse   = (std::getenv("HYDRA_INVERT_Y") != nullptr);
    const float base_move_speed      = move_speed;
    const float base_move_speed_fast = move_speed_fast;
    const float base_turn_speed_keys = turn_speed_keys;
    const float base_mouse_sens      = mouse_sens;

    bool smooth_surfaces = true;
    bool curvature       = true;
    bool extra_light     = false;
    bool diag_slice      = false;
    bool ray_jitter      = env_truthy("HYDRA_RAY_JITTER");
    bool spectrum_mode   = env_truthy("HYDRA_SPECTRUM_MODE");
    bool hud_enabled     = true;
    bool hud_theme_light = false;
    if (const char* hud_theme_env = std::getenv("HYDRA_HUD_THEME")) {
        if (strcasecmp(hud_theme_env, "light") == 0)
            hud_theme_light = true;
    }
    const char* pixel_view_env = std::getenv("HYDRA_PIXEL_VIEW");
    g_pixel_view_mode = pixel_view_from_string(pixel_view_env);
    bool safe_capture_mode = env_truthy("HYDRA_SAFE_CAPTURE");

    uint32_t world_seed_override = 0;
    const char* world_seed_env = std::getenv("HYDRA_WORLD_SEED");
    if (const char* seed_env = world_seed_env) {
        world_seed_override = static_cast<uint32_t>(std::strtoul(seed_env, nullptr, 0));
    }

    bool mouse_captured  = true;
    const char* mouse_cap_env = std::getenv("HYDRA_MOUSE_CAPTURE");
    if (mouse_cap_env && std::strcmp(mouse_cap_env, "0") == 0)
        mouse_captured = false;

    auto load_autosave_cfg = [&](const char* path) {
        if (!path || path[0] == '\0') return;
        FILE* f = std::fopen(path, "r");
        if (!f) return;
        char line[256];
        while (std::fgets(line, sizeof(line), f)) {
            if (std::strncmp(line, "cam_pos=", 8) == 0) {
                float lx, ly, lz;
                if (std::sscanf(line + 8, "%f,%f,%f", &lx, &ly, &lz) == 3) {
                    pos_x = lx; pos_y = ly; pos_z = lz;
                }
            } else if (std::strncmp(line, "cam_ang=", 8) == 0) {
                float lyaw, lpitch;
                if (std::sscanf(line + 8, "%f,%f", &lyaw, &lpitch) == 2) {
                    yaw = lyaw; pitch = lpitch;
                }
            } else if (std::strncmp(line, "flags=", 6) == 0) {
                int fs, fc, fe, fd;
                if (std::sscanf(line + 6, "%d,%d,%d,%d", &fs, &fc, &fe, &fd) == 4) {
                    smooth_surfaces = (fs != 0);
                    curvature       = (fc != 0);
                    extra_light     = (fe != 0);
                    diag_slice      = (fd != 0);
                }
            } else if (std::strncmp(line, "seed=", 5) == 0) {
                uint32_t s = 0;
                if (std::sscanf(line + 5, "%u", &s) == 1) {
                    world_seed_override = s;
                }
            } else if (std::strncmp(line, "safe_capture=", 13) == 0) {
                int v = 0;
                if (std::sscanf(line + 13, "%d", &v) == 1) {
                    safe_capture_mode = (v != 0);
                }
            }
        }
        std::fclose(f);
    };

    // Camera position clamping (configurable bounds)
    bool cam_clamp_enabled = (std::getenv("HYDRA_CAM_CLAMP") != nullptr);
    float cam_min = -1.0f;
    float cam_max = 65.0f;  // Default to 64x64x64 voxel volume with margin
    const char* cam_bounds_env = std::getenv("HYDRA_CAM_BOUNDS");
    if (cam_bounds_env) {
        float min_val, max_val;
        if (std::sscanf(cam_bounds_env, "%f,%f", &min_val, &max_val) == 2) {
            cam_min = min_val;
            cam_max = max_val;
        }
    }
    const bool base_cam_clamp = cam_clamp_enabled;
    const float base_cam_min = cam_min;
    const float base_cam_max = cam_max;

    // Apply initial clamping if enabled
    if (cam_clamp_enabled) {
        if (pos_x < cam_min) pos_x = cam_min;
        if (pos_x > cam_max) pos_x = cam_max;
        if (pos_y < cam_min) pos_y = cam_min;
        if (pos_y > cam_max) pos_y = cam_max;
        if (pos_z < cam_min) pos_z = cam_min;
        if (pos_z > cam_max) pos_z = cam_max;
    }
    if (autosave_cfg) {
        load_autosave_cfg(autosave_cfg);
    }

    // Frame pacing and timing configuration
    const char* idle_env = std::getenv("HYDRA_SIM_IDLE_MS");
    const int idle_ms = idle_env ? std::max(0, std::atoi(idle_env)) : 0;
    const char* fps_env = std::getenv("HYDRA_FPS_TARGET");
    const float fps_target = fps_env ? std::max(0.0f, static_cast<float>(std::atof(fps_env))) : 0.0f;

    // Print startup summary for reproducibility
    std::fprintf(stderr, "\n[hydra] === Startup Configuration ===\n");
    std::fprintf(stderr, "[hydra] Backend: %s\n", backend_name(backend));

    // Log backend selection details
    if (const char* v = std::getenv("HYDRA_BACKEND")) {
        std::fprintf(stderr, "[hydra] Backend selection: env var HYDRA_BACKEND=%s\n", v);
    } else if (const char* v = std::getenv("HYDRA_BACKEND_PREFS")) {
        std::fprintf(stderr, "[hydra] Backend selection: preference order HYDRA_BACKEND_PREFS=%s\n", v);
    } else {
        std::fprintf(stderr, "[hydra] Backend selection: auto (default preference order)\n");
    }

    // Log SDL info if available
    SDL_version ver;
    SDL_GetVersion(&ver);
    std::fprintf(stderr, "[hydra] SDL version: %d.%d.%d\n", ver.major, ver.minor, ver.patch);
    if (SDL_WasInit(SDL_INIT_VIDEO)) {
        const char* driver = SDL_GetCurrentVideoDriver();
        if (driver) {
            std::fprintf(stderr, "[hydra] SDL video driver: %s\n", driver);
        }
    }

    std::fprintf(stderr, "[hydra] Resolution: %dx%d\n", SCREEN_WIDTH, SCREEN_HEIGHT);
    std::fprintf(stderr, "[hydra] Font: %s (size %d)\n", font_path, font_size);
    if (std::getenv("HYDRA_VSYNC")) std::fprintf(stderr, "[hydra] HYDRA_VSYNC=%s\n", std::getenv("HYDRA_VSYNC"));
    if (frame_dump_path) std::fprintf(stderr, "[hydra] FRAME_DUMP=%s\n", frame_dump_path);
    if (max_dump_env) std::fprintf(stderr, "[hydra] HYDRA_MAX_FRAME_DUMPS=%s\n", max_dump_env);
    if (auto_exit) std::fprintf(stderr, "[hydra] AUTO_EXIT=1\n");
    if (cam_pos_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_POS=%s\n", cam_pos_env);
    if (cam_ang_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_ANG=%s\n", cam_ang_env);
    if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
    if (pixel_view_env) std::fprintf(stderr, "[hydra] HYDRA_PIXEL_VIEW=%s\n", pixel_view_env);
    if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
    if (safe_capture_mode) std::fprintf(stderr, "[hydra] HYDRA_SAFE_CAPTURE=1\n");
    std::fprintf(stderr, "[hydra] Camera: pos=(%.1f,%.1f,%.1f) yaw=%.2f pitch=%.2f\n",
                 pos_x, pos_y, pos_z, yaw, pitch);
    std::fprintf(stderr, "[hydra] Move speed: %.3f (fast: %.3f) Mouse sens: %.4f%s\n",
                 move_speed, move_speed_fast, mouse_sens, invert_y_mouse ? " [Y-inverted]" : "");
    if (cam_clamp_enabled) std::fprintf(stderr, "[hydra] Camera clamping enabled: bounds=[%.1f, %.1f]\n", cam_min, cam_max);
    if (fps_target > 0.0f) std::fprintf(stderr, "[hydra] Frame pacing: target %.1f FPS\n", fps_target);
    if (clear_each_frame) std::fprintf(stderr, "[hydra] HYDRA_CLEAR_EACH_FRAME=1\n");
    if (autosave_cfg) std::fprintf(stderr, "[hydra] HYDRA_AUTOSAVE_CFG=%s\n", autosave_cfg);
    if (ray_jitter) std::fprintf(stderr, "[hydra] HYDRA_RAY_JITTER=1\n");
    std::fprintf(stderr, "[hydra] Pixel view: %s\n", pixel_view_mode_name(g_pixel_view_mode));
    std::fprintf(stderr, "[hydra] ==============================\n\n");

    RenderInstrumentationConfig inst_config;
    inst_config.cam_pos_x = pos_x;
    inst_config.cam_pos_y = pos_y;
    inst_config.cam_pos_z = pos_z;
    inst_config.yaw = yaw;
    inst_config.pitch = pitch;
    inst_config.smooth_surfaces = smooth_surfaces;
    inst_config.curvature = curvature;
    inst_config.extra_light = extra_light;
    inst_config.diag_slice = diag_slice;
    inst_config.ray_jitter = ray_jitter;
    inst_config.hud_enabled = hud_enabled;
    inst_config.fps_target = fps_target;
    inst_config.vsync = g_vsync;
    inst_config.backend_name = backend_name(backend);
    inst_config.backend_info = g_backend_info;
    inst_config.pixel_view = pixel_view_mode_name(g_pixel_view_mode);
    render_instrument.write_config(inst_config);

    bool selection_active = false;
    uint8_t selection_x = 0;
    uint8_t selection_y = 0;
    uint8_t selection_z = 0;
    uint64_t selection_word = 0;
    InputState keys;
    float help_overlay_timer = 3.5f;
    if (std::getenv("HYDRA_HELP_STARTUP")) {
        help_overlay_timer = env_truthy("HYDRA_HELP_STARTUP") ? 3.5f : 0.0f;
    }
    bool help_overlay_sticky = false;
    float sel_miss_timer = 0.0f;

    auto update_mouse_capture = [&]() {
        if (SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE) != 0) {
            std::fprintf(stderr, "Warning: SetRelativeMouseMode failed: %s\n", SDL_GetError());
        }
        SDL_SetWindowGrab(win, mouse_captured ? SDL_TRUE : SDL_FALSE);
        SDL_ShowCursor(mouse_captured ? SDL_FALSE : SDL_TRUE);
    };

    auto apply_camera_to_dut = [&]() {
        float dx = std::cos(yaw) * std::cos(pitch);
        float dy = std::sin(yaw) * std::cos(pitch);
        float dz = std::sin(pitch);

        float px = -dy * 0.66f;
        float py =  dx * 0.66f;

        root->voxel_framebuffer_top__DOT__cam_x       = int16_t(pos_x * FX);
        root->voxel_framebuffer_top__DOT__cam_y       = int16_t(pos_y * FX);
        root->voxel_framebuffer_top__DOT__cam_z       = int16_t(pos_z * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_x   = int16_t(dx * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_y   = int16_t(dy * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_z   = int16_t(dz * FX);
        root->voxel_framebuffer_top__DOT__cam_plane_x = int16_t(px * FX);
        root->voxel_framebuffer_top__DOT__cam_plane_y = int16_t(py * FX);
    };

    auto apply_flags_to_dut = [&]() {
        root->voxel_framebuffer_top__DOT__cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_curvature       = curvature       ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_extra_light     = extra_light     ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_diag_slice      = diag_slice     ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_ray_jitter      = ray_jitter     ? 1 : 0;
    };

    auto apply_selection_to_dut = [&]() {
        root->voxel_framebuffer_top__DOT__sel_active  = selection_active ? 1 : 0;
        root->voxel_framebuffer_top__DOT__sel_voxel_x = selection_x;
        root->voxel_framebuffer_top__DOT__sel_voxel_y = selection_y;
        root->voxel_framebuffer_top__DOT__sel_voxel_z = selection_z;
    };

    bool safe_defaults_mode = env_truthy("HYDRA_SAFE_DEFAULTS");
    auto apply_safe_defaults = [&]() {
        if (safe_defaults_mode) {
            move_speed = 0.06f;
            move_speed_fast = 0.16f;
            turn_speed_keys = 0.03f;
            mouse_sens      = 0.0016f;
            cam_clamp_enabled = true;
        } else {
            move_speed = base_move_speed;
            move_speed_fast = base_move_speed_fast;
            turn_speed_keys = base_turn_speed_keys;
            mouse_sens      = base_mouse_sens;
            cam_clamp_enabled = base_cam_clamp;
            cam_min = base_cam_min;
            cam_max = base_cam_max;
        }
    };

    apply_safe_defaults();
    if (cam_clamp_enabled) {
        if (pos_x < cam_min) pos_x = cam_min;
        if (pos_x > cam_max) pos_x = cam_max;
        if (pos_y < cam_min) pos_y = cam_min;
        if (pos_y > cam_max) pos_y = cam_max;
        if (pos_z < cam_min) pos_z = cam_min;
        if (pos_z > cam_max) pos_z = cam_max;
    }
    apply_camera_to_dut();
    apply_flags_to_dut();
    apply_selection_to_dut();
    root->voxel_framebuffer_top__DOT__world_seed = world_seed_override;
    update_mouse_capture();

    auto reset_key_state = [&]() { keys = InputState{}; };

    bool running = true;
    auto last_frame_time = std::chrono::high_resolution_clock::now();
    float fps = 0.0f;

    while (running && !Verilated::gotFinish()) {
        // Default: no debug write
        root->voxel_framebuffer_top__DOT__dbg_write_en = 0;

        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) {
                running = false;
            } else if (ev.type == SDL_WINDOWEVENT) {
                if (ev.window.event == SDL_WINDOWEVENT_FOCUS_GAINED ||
                    ev.window.event == SDL_WINDOWEVENT_TAKE_FOCUS) {
                    update_mouse_capture();
                } else if (ev.window.event == SDL_WINDOWEVENT_FOCUS_LOST) {
                    reset_key_state();
                } else if (ev.window.event == SDL_WINDOWEVENT_RESIZED ||
                           ev.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
                    handle_resize(ev.window.data1, ev.window.data2);
                }
            } else if (ev.type == SDL_KEYDOWN || ev.type == SDL_KEYUP) {
                bool key_down = (ev.type == SDL_KEYDOWN);
                SDL_Scancode sc = ev.key.keysym.scancode;
                SDL_Keycode keycode = ev.key.keysym.sym;
                update_key_state(keys, sc, keycode, key_down);

                if (log_keys && log_keys_count < 200) {
                    std::fprintf(stderr, "key %s sc=%d kc=%d name=%s mod=0x%x\n",
                                 key_down ? "down" : "up",
                                 (int)sc, (int)keycode,
                                 SDL_GetKeyName(keycode),
                                 ev.key.keysym.mod);
                    ++log_keys_count;
                }

                if (key_down) {
                    switch (keycode) {
                        case SDLK_ESCAPE:
                            running = false;
                            break;
                        case SDLK_1: case SDLK_KP_1:
                            smooth_surfaces = !smooth_surfaces;
                            apply_flags_to_dut();
                            break;
                        case SDLK_2: case SDLK_KP_2:
                            curvature = !curvature;
                            apply_flags_to_dut();
                            break;
                        case SDLK_3: case SDLK_KP_3:
                            extra_light = !extra_light;
                            apply_flags_to_dut();
                            break;
                        case SDLK_o:
                            diag_slice = !diag_slice;
                            apply_flags_to_dut();
                            break;
                        case SDLK_y:
                            spectrum_mode = !spectrum_mode;
                            std::fprintf(stderr, "[hydra] spectrum_mode %s\n", spectrum_mode ? "ON" : "OFF");
                            break;
                        case SDLK_j:
                            ray_jitter = !ray_jitter;
                            apply_flags_to_dut();
                            std::fprintf(stderr, "[hydra] ray jitter %s\n", ray_jitter ? "ON" : "OFF");
                            break;
                        case SDLK_m:
                            mouse_captured = !mouse_captured;
                            update_mouse_capture();
                            break;
                        case SDLK_F3:
                            safe_capture_mode = !safe_capture_mode;
                            std::fprintf(stderr, "[hydra] safe capture %s\n", safe_capture_mode ? "ON" : "OFF");
                            break;
                        case SDLK_F4:
                            g_fog_enabled = !g_fog_enabled;
                            std::fprintf(stderr, "[hydra] depth fog %s\n", g_fog_enabled ? "ON" : "OFF");
                            break;
                        case SDLK_F2:
                            safe_defaults_mode = !safe_defaults_mode;
                            apply_safe_defaults();
                            if (cam_clamp_enabled) {
                                if (pos_x < cam_min) pos_x = cam_min;
                                if (pos_x > cam_max) pos_x = cam_max;
                                if (pos_y < cam_min) pos_y = cam_min;
                                if (pos_y > cam_max) pos_y = cam_max;
                                if (pos_z < cam_min) pos_z = cam_min;
                                if (pos_z > cam_max) pos_z = cam_max;
                            }
                            std::fprintf(stderr, "[hydra] safe defaults %s (move=%.3f/%.3f turn=%.3f mouse=%.4f clamp=%d)\n",
                                         safe_defaults_mode ? "ON" : "OFF",
                                         move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
                                         cam_clamp_enabled ? 1 : 0);
                            break;
                        case SDLK_F1:
                            help_overlay_sticky = !help_overlay_sticky;
                            if (!help_overlay_sticky && help_overlay_timer <= 0.0f) {
                                help_overlay_timer = 3.0f;
                            }
                            break;
                        case SDLK_SLASH:
                            help_overlay_timer = 4.0f;
                            help_overlay_sticky = false;
                            break;
                        case SDLK_f:
                            if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
                                selection_active = true;
                                selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x);
                                selection_y = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_y);
                                selection_z = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_z);
                                selection_word = static_cast<uint64_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_data);
                                apply_selection_to_dut();
                                sel_miss_timer = 0.0f;
                            } else {
                                sel_miss_timer = 1.5f;
                            }
                            break;
                        case SDLK_g:
                            selection_active = false;
                            selection_word   = 0;
                            apply_selection_to_dut();
                            break;
                        case SDLK_h:
                            hud_enabled = !hud_enabled;
                            break;
                        case SDLK_t:
                            hud_theme_light = !hud_theme_light;
                            break;
                        case SDLK_r:
                            // Reset camera and flags to defaults; clear selection.
                            pos_x = default_pos_x;
                            pos_y = default_pos_y;
                            pos_z = default_pos_z;
                            yaw   = default_yaw;
                            pitch = default_pitch;
                            smooth_surfaces = true;
                            curvature       = true;
                            extra_light     = false;
                            diag_slice      = false;
                            selection_active = false;
                            selection_word   = 0;
                            apply_camera_to_dut();
                            apply_flags_to_dut();
                            apply_selection_to_dut();
                            apply_safe_defaults();
                            break;
                        case SDLK_v: {
                            if (g_pixel_view_mode == PixelViewMode::Color) {
                                g_pixel_view_mode = PixelViewMode::Word0;
                            } else if (g_pixel_view_mode == PixelViewMode::Word0) {
                                g_pixel_view_mode = PixelViewMode::Word2;
                            } else if (g_pixel_view_mode == PixelViewMode::Word2) {
                                g_pixel_view_mode = PixelViewMode::SidebandMix;
                            } else {
                                g_pixel_view_mode = PixelViewMode::Color;
                            }
                            std::fprintf(stderr, "[hydra] pixel view -> %s\n",
                                         pixel_view_mode_name(g_pixel_view_mode));
                            break;
                        }
                        case SDLK_p:
                            std::fprintf(stderr,
                                "State: cam=(%.3f,%.3f,%.3f) yaw=%.3f pitch=%.3f flags[smooth=%d curv=%d extra=%d diag=%d] sel=%d (%u,%u,%u)\n",
                                pos_x, pos_y, pos_z, yaw, pitch,
                                smooth_surfaces ? 1 : 0,
                                curvature ? 1 : 0,
                                extra_light ? 1 : 0,
                                diag_slice ? 1 : 0,
                                selection_active ? 1 : 0,
                                (unsigned)selection_x,
                                (unsigned)selection_y,
                                (unsigned)selection_z);
                            break;
                        case SDLK_s: {
                            // Screenshot: save current framebuffer as timestamped PPM
                            auto now = std::chrono::system_clock::now();
                            auto secs = std::chrono::duration_cast<std::chrono::seconds>(
                                now.time_since_epoch()).count();
                            char filename[256];
                            std::snprintf(filename, sizeof(filename), "sim/screenshot_%ld.ppm", secs);
                            FILE* f = std::fopen(filename, "wb");
                            if (!f) {
                                std::fprintf(stderr, "Failed to open %s for screenshot\n", filename);
                            } else {
                                std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
                                for (int y = 0; y < SCREEN_HEIGHT; ++y) {
                                    for (int x = 0; x < SCREEN_WIDTH; ++x) {
                                        uint32_t argb = framebuffer[size_t(y) * SCREEN_WIDTH + x];
                                        uint8_t rgb[3] = {
                                            (uint8_t)((argb >> 16) & 0xFF),
                                            (uint8_t)((argb >> 8) & 0xFF),
                                            (uint8_t)(argb & 0xFF)
                                        };
                                        std::fwrite(rgb, 1, 3, f);
                                    }
                                }
                                std::fclose(f);
                                std::fprintf(stderr, "Screenshot saved: %s\n", filename);
                            }
                            break;
                        }
                        default: break;
                    }

                    // Edit selected voxel
                    if (selection_active) {
                        uint64_t w = selection_word;
                        uint8_t material_props = (w >> 56) & 0xFF;
                        uint8_t emissive       = (w >> 48) & 0xFF;
                        uint8_t alpha          = (w >> 40) & 0xFF;
                        uint8_t light          = (w >> 32) & 0xFF;
                        uint8_t r              = (w >> 24) & 0xFF;
                        uint8_t g              = (w >> 16) & 0xFF;
                        uint8_t b              = (w >>  8) & 0xFF;
                        uint8_t material_type  = (w >>  4) & 0x0F;

                        bool do_write = false;

                        if (keycode == SDLK_c) {
                            material_type = (material_type + 1) & 0x0F;
                            w &= ~((uint64_t)0x0F << 4);
                            w |= (uint64_t(material_type) << 4);
                            do_write = true;
                        } else if (keycode == SDLK_x) {
                            int val = emissive + 16;
                            if (val > 255) val = 255;
                            emissive = (uint8_t)val;
                            w &= ~((uint64_t)0xFF << 48);
                            w |= (uint64_t)emissive << 48;
                            do_write = true;
                        } else if (keycode == SDLK_z) {
                            int val = emissive - 16;
                            if (val < 0) val = 0;
                            emissive = (uint8_t)val;
                            w &= ~((uint64_t)0xFF << 48);
                            w |= (uint64_t)emissive << 48;
                            do_write = true;
                        } else if (keycode == SDLK_b) {
                            auto saturate_add = [](uint8_t c, int delta) -> uint8_t {
                                int v = c + delta;
                                if (v < 0) v = 0;
                                if (v > 255) v = 255;
                                return (uint8_t)v;
                            };
                            r = saturate_add(r, 16);
                            g = saturate_add(g, 16);
                            b = saturate_add(b, 16);
                            w &= ~(((uint64_t)0xFFFFFF) << 8);
                            w |= ((uint64_t)r << 24) |
                                 ((uint64_t)g << 16) |
                                 ((uint64_t)b <<  8);
                            do_write = true;
                        }

                        if (do_write) {
                            selection_word = w;
                            uint32_t addr = voxel_addr_from_xyz(selection_x, selection_y, selection_z);
                            root->voxel_framebuffer_top__DOT__dbg_write_addr = addr;
                            root->voxel_framebuffer_top__DOT__dbg_write_data = w;
                            root->voxel_framebuffer_top__DOT__dbg_write_en   = 1;
                        }
                    }
                }
            } else if (ev.type == SDL_MOUSEMOTION && mouse_captured && !safe_capture_mode) {
                int dx = ev.motion.xrel;
                int dy = ev.motion.yrel;
                yaw   += dx * mouse_sens;
                pitch += (invert_y_mouse ? dy : -dy) * mouse_sens;
    if (pitch >  1.50f) pitch =  1.50f;
    if (pitch < -1.50f) pitch = -1.50f;
                apply_camera_to_dut();
            }
        }

        bool cam_changed = false;

        float fdx = std::cos(yaw);
        float fdy = std::sin(yaw);
        float rdx = -std::sin(yaw);
        float rdy =  std::cos(yaw);

        float cur_speed = keys.fast ? move_speed_fast : move_speed;

        if (!safe_capture_mode) {
            if (keys.forward)      { pos_x += fdx * cur_speed; pos_y += fdy * cur_speed; cam_changed = true; }
            if (keys.back)         { pos_x -= fdx * cur_speed; pos_y -= fdy * cur_speed; cam_changed = true; }
            if (keys.strafe_left)  { pos_x += rdx * cur_speed; pos_y += rdy * cur_speed; cam_changed = true; }
            if (keys.strafe_right) { pos_x -= rdx * cur_speed; pos_y -= rdy * cur_speed; cam_changed = true; }
            if (keys.down)         { pos_z -= cur_speed; cam_changed = true; }
            if (keys.up)           { pos_z += cur_speed; cam_changed = true; }

            if (keys.yaw_left)   { yaw   -= turn_speed_keys; cam_changed = true; }
            if (keys.yaw_right)  { yaw   += turn_speed_keys; cam_changed = true; }
            if (keys.pitch_up)   { pitch += turn_speed_keys; cam_changed = true; }
            if (keys.pitch_down) { pitch -= turn_speed_keys; cam_changed = true; }
        }

        if (pitch >  1.50f) pitch =  1.50f;
        if (pitch < -1.50f) pitch = -1.50f;

        // Apply camera position clamping if enabled
        if (cam_clamp_enabled) {
            if (pos_x < cam_min) pos_x = cam_min;
            if (pos_x > cam_max) pos_x = cam_max;
            if (pos_y < cam_min) pos_y = cam_min;
            if (pos_y > cam_max) pos_y = cam_max;
            if (pos_z < cam_min) pos_z = cam_min;
            if (pos_z > cam_max) pos_z = cam_max;
        }

        if (cam_changed) {
            apply_camera_to_dut();
            if (log_keys && log_keys_count < 200) {
                std::fprintf(stderr, "cam pos=(%.2f, %.2f, %.2f) yaw=%.2f pitch=%.2f\n",
                             pos_x, pos_y, pos_z, yaw, pitch);
                ++log_keys_count;
            }
        }

        // Ensure DUT flags follow local toggles every frame.
        apply_flags_to_dut();

        // Simulate HDL
        const int cycles_per_chunk = 2000;
        bool frame_done = false;
        std::chrono::high_resolution_clock::time_point sim_loop_start;
        if (render_instrument.active())
            sim_loop_start = std::chrono::high_resolution_clock::now();

        for (int i = 0; i < cycles_per_chunk; ++i) {
            top->clk = 1; top->eval(); main_time++;

            if (top->pixel_write_en) {
                uint32_t addr = top->pixel_addr;
                if (addr < NPIX) {
                    uint32_t w0 = top->pixel_word0;
                    uint32_t w1 = top->pixel_word1;
                    uint32_t w2 = top->pixel_word2;
                    uint32_t pixel_value = pixel96_to_argb(w0, w1, w2);
                    uint8_t depth_byte = (w0 >> 16) & 0xFF;
                    if (g_fog_enabled) {
                        pixel_value = apply_fog(pixel_value, depth_byte);
                    }
                    framebuffer[addr] = pixel_value;
                    record_color(frame_color_stats, pixel_value);
                    frame_color_stats_dirty = true;

                    if (log_frames && log_pixel_samples < 512) {
                        uint32_t x = addr % SCREEN_WIDTH;
                        uint32_t y = addr / SCREEN_WIDTH;
                        // Probe a single vertical column through the middle of the screen
                        // to see sky, geometry, and floor along one ray.
                        if (x == SCREEN_WIDTH / 2) {
                            std::fprintf(stderr,
                                "probe x=%u y=%u addr=%u w0=%08x w1=%08x w2=%08x argb=%08x\n",
                                x, y, addr, w0, w1, w2,
                                pixel_value);
                            ++log_pixel_samples;
                        }
                    }
                }
                ++pixels_this_frame;
            }

            if (top->frame_done)
                frame_done = true;

            top->clk = 0; top->eval(); main_time++;
        }

        if (frame_done) {
             std::chrono::high_resolution_clock::time_point sim_loop_end;
             if (render_instrument.active())
                 sim_loop_end = std::chrono::high_resolution_clock::now();
             size_t pixels_written_this_frame = pixels_this_frame;
             last_frame_color_stats = frame_color_stats;
             last_frame_color_stats_valid = frame_color_stats_dirty;
             frame_color_stats = color_range_default();
             frame_color_stats_dirty = false;
             if (auto_exit) {
                 running = false;
             }
            if (frame_dump_path && frame_dump_path[0] != '\0' &&
                (max_frame_dumps == 0 || frame_dumps_written < max_frame_dumps)) {
                char pathbuf[512];
                if (frame_dump_base && max_frame_dumps != 1) {
                    std::snprintf(pathbuf, sizeof(pathbuf), "%s_%d.ppm", frame_dump_base, frame_dumps_written);
                } else {
                    std::snprintf(pathbuf, sizeof(pathbuf), "%s", frame_dump_path);
                }
                FILE* f = std::fopen(pathbuf, "wb");
                if (!f) {
                    std::fprintf(stderr, "Failed to open FRAME_DUMP '%s' for write\n", pathbuf);
                } else {
                    std::fprintf(stderr, "Writing frame dump to %s\n", pathbuf);
                    std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
                    for (int fy = 0; fy < SCREEN_HEIGHT; ++fy) {
                        for (int fx = 0; fx < SCREEN_WIDTH; ++fx) {
                            uint32_t argb = framebuffer[size_t(fy) * SCREEN_WIDTH + fx];
                            uint8_t r = (argb >> 16) & 0xFF;
                            uint8_t g = (argb >> 8)  & 0xFF;
                            uint8_t b =  argb        & 0xFF;
                            uint8_t rgb[3] = {r, g, b};
                            std::fwrite(rgb, 1, 3, f);
                        }
                    }
                    std::fclose(f);
                    ++frame_dumps_written;
                    if (max_frame_dumps > 0 && frame_dumps_written >= max_frame_dumps) {
                        std::fprintf(stderr, "Max frame dumps (%d) reached, disabling further FRAME_DUMP writes\n", max_frame_dumps);
                    }
                }
            }
            if (autosave_cfg && autosave_cfg[0] != '\0') {
                FILE* fcfg = std::fopen(autosave_cfg, "w");
                if (!fcfg) {
                    std::fprintf(stderr, "Failed to write HYDRA_AUTOSAVE_CFG to '%s'\n", autosave_cfg);
                } else {
                    std::fprintf(fcfg, "cam_pos=%.3f,%.3f,%.3f\n", pos_x, pos_y, pos_z);
                    std::fprintf(fcfg, "cam_ang=%.3f,%.3f\n", yaw, pitch);
                    std::fprintf(fcfg, "flags=%d,%d,%d,%d\n",
                                 smooth_surfaces ? 1 : 0,
                                 curvature ? 1 : 0,
                                 extra_light ? 1 : 0,
                                 diag_slice ? 1 : 0);
                    std::fprintf(fcfg, "seed=%u\n", world_seed_override);
                    std::fprintf(fcfg, "safe_capture=%d\n", safe_capture_mode ? 1 : 0);
                    std::fclose(fcfg);
                }
            }

            if (log_frames) {
                size_t nonzero = 0;
                for (uint32_t v : framebuffer) {
                    if (v != 0) ++nonzero;
                }
                uint32_t sample0 = framebuffer.empty() ? 0 : framebuffer[0];
                uint32_t sample_mid = framebuffer.empty() ? 0 : framebuffer[NPIX/2];
                std::fprintf(stderr,
                    "frame %zu done, pixels_written=%zu nonzero=%zu sample0=%08x mid=%08x\n",
                    frame_counter, pixels_this_frame, nonzero, sample0, sample_mid);
            }
            ++frame_counter;

            auto now = std::chrono::high_resolution_clock::now();
            float dt = std::chrono::duration<float>(now - last_frame_time).count();
            if (fps_target > 0.0f) {
                float target_dt = 1.0f / fps_target;
                if (dt < target_dt) {
                    int delay_ms = static_cast<int>((target_dt - dt) * 1000.0f);
                    if (delay_ms > 0) {
                        SDL_Delay(delay_ms);
                        dt += static_cast<float>(delay_ms) / 1000.0f;
                    }
                }
            }
            last_frame_time = now;
            if (dt > 0.0f) fps = 1.0f / dt;

            if (render_instrument.active()) {
                double ray_loop_ms = std::chrono::duration<double, std::milli>(sim_loop_end - sim_loop_start).count();
                double hud_present_ms = std::chrono::duration<double, std::milli>(hud_present_end - hud_present_start).count();
                double framebuffer_copy_ms = std::chrono::duration<double, std::milli>(copy_end - copy_start).count();
                render_instrument.record(frame_counter, fps, ray_loop_ms, hud_present_ms, framebuffer_copy_ms, static_cast<double>(dt * 1000.0));
            }

            if (!help_overlay_sticky && help_overlay_timer > 0.0f && dt > 0.0f) {
                help_overlay_timer = std::max(0.0f, help_overlay_timer - dt);
            }
            if (sel_miss_timer > 0.0f && dt > 0.0f) {
                sel_miss_timer = std::max(0.0f, sel_miss_timer - dt);
            }

            uint64_t mem_cycle = root->voxel_framebuffer_top__DOT__mem_cycle_count;
            uint64_t mem_read  = root->voxel_framebuffer_top__DOT__mem_read_cycles;
            uint64_t mem_write = root->voxel_framebuffer_top__DOT__mem_write_cycles;
            uint64_t dc = mem_cycle - prev_mem_cycle;
            uint64_t dr = mem_read  - prev_mem_read;
            uint64_t dw = mem_write - prev_mem_write;
            prev_mem_cycle = mem_cycle;
            prev_mem_read  = mem_read;
            prev_mem_write = mem_write;
            if (dc > 0) {
                last_mem_read_util  = float(dr) / float(dc);
                last_mem_write_util = float(dw) / float(dc);
            }

            std::chrono::high_resolution_clock::time_point hud_present_start;
            if (render_instrument.active())
                hud_present_start = std::chrono::high_resolution_clock::now();
            if (hud_enabled && font) {
                // Darken or lighten HUD band in the framebuffer based on theme.
                for (int y = SCREEN_HEIGHT - HUD_HEIGHT; y < SCREEN_HEIGHT; ++y) {
                    if (y < 0) continue;
                    for (int x = 0; x < SCREEN_WIDTH; ++x) {
                        uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
                        uint8_t r = (px >> 16) & 0xFF;
                        uint8_t g = (px >> 8)  & 0xFF;
                        uint8_t b =  px        & 0xFF;
                        if (hud_theme_light) {
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
                uint32_t hits = root->voxel_framebuffer_top__DOT__core_dbg_hit_count;
                uint32_t ray_steps_total = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_total;
                uint32_t ray_steps_max   = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_max;
                uint32_t ray_miss_count  = root->voxel_framebuffer_top__DOT__core_dbg_ray_miss_count;
                const float pixel_count = float(SCREEN_WIDTH) * float(SCREEN_HEIGHT);
                const float ray_steps_avg = pixel_count > 0.0f
                    ? float(ray_steps_total) / pixel_count
                    : 0.0f;
                const int hud_y = SCREEN_HEIGHT - HUD_HEIGHT + 4;
                int yoff = hud_y;
                SDL_Color hud_text_color = hud_theme_light ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};

                if (fps_target > 0.0f) {
                    std::snprintf(buf, sizeof(buf),
                        "FPS %.1f / %.0f (target) | Pos %.1f %.1f %.1f",
                        fps, fps_target, pos_x, pos_y, pos_z);
                } else {
                    std::snprintf(buf, sizeof(buf),
                        "FPS %.1f | Pos %.1f %.1f %.1f",
                        fps, pos_x, pos_y, pos_z);
                }
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Yaw %.2f  Pitch %.2f",
                    yaw, pitch);
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "[1] Smooth %s  [2] Curv %s  [3] Extra %s",
                    smooth_surfaces ? "ON" : "OFF",
                    curvature       ? "ON" : "OFF",
                    extra_light     ? "ON" : "OFF");
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "[O] Slice %s  [J] Jitter %s  [M] Mouse %s",
                    diag_slice     ? "ON" : "OFF",
                    ray_jitter     ? "ON" : "OFF",
                    mouse_captured ? "ON" : "OFF");
                SDL_Color mouse_line_color = mouse_captured ? hud_text_color : SDL_Color{255, 96, 96, 255};
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, mouse_line_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Hits %u | ray avg %.1f max %u miss %u",
                    hits, ray_steps_avg, ray_steps_max, ray_miss_count);
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Mem: rd %.1f%% wr %.1f%%",
                    last_mem_read_util * 100.0f,
                    last_mem_write_util * 100.0f);
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                if (last_frame_color_stats_valid) {
                    std::snprintf(buf, sizeof(buf),
                        "RGB range: R%3u-%3u  G%3u-%3u  B%3u-%3u",
                        (unsigned)last_frame_color_stats.min_r,
                        (unsigned)last_frame_color_stats.max_r,
                        (unsigned)last_frame_color_stats.min_g,
                        (unsigned)last_frame_color_stats.max_g,
                        (unsigned)last_frame_color_stats.min_b,
                        (unsigned)last_frame_color_stats.max_b);
                } else {
                    std::snprintf(buf, sizeof(buf), "RGB range: capturing...");
                }
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Pixel view: %s  [V] cycle",
                    pixel_view_mode_name(g_pixel_view_mode));
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Safe defaults: %s [F2] (move %.3f/%.3f turn %.3f sens %.4f clamp %s)",
                    safe_defaults_mode ? "ON" : "OFF",
                    move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
                    cam_clamp_enabled ? "ON" : "OFF");
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                // Fog status (toggle with F4)
                std::snprintf(buf, sizeof(buf), "Fog: %s [F4] color=%06x density=%.2f", g_fog_enabled ? "ON" : "OFF", (g_fog_color & 0x00FFFFFFu), g_fog_density);
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Safe capture: %s [F3] (input frozen)",
                    safe_capture_mode ? "ON" : "OFF");
                SDL_Color warn_color = safe_capture_mode ? SDL_Color{255, 128, 96, 255} : hud_text_color;
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, warn_color);
                yoff += 14;

                if (!g_backend_info.empty()) {
                    draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, g_backend_info, 6, yoff, hud_text_color);
                    yoff += 14;
                }

                if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
                    std::snprintf(buf, sizeof(buf),
                        "Cursor: (%u,%u,%u) mat=0x%02X",
                        (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_x,
                        (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_y,
                        (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_z,
                        (unsigned)(root->voxel_framebuffer_top__DOT__cursor_material_id & 0xFF));
                } else {
                    std::snprintf(buf, sizeof(buf),
                        "Cursor: (no hit)");
                }
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                if (selection_active) {
                    std::snprintf(buf, sizeof(buf),
                        "Sel: (%u,%u,%u)  [G] clear  [F] select",
                        (unsigned)selection_x,
                        (unsigned)selection_y,
                        (unsigned)selection_z);
                } else {
                    std::snprintf(buf, sizeof(buf),
                        "Sel: (none)  (aim + F to select)");
                }
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                yoff += 14;

                if (selection_active) {
                    uint64_t w = selection_word;
                    uint8_t material_props = (w >> 56) & 0xFF;
                    uint8_t emissive       = (w >> 48) & 0xFF;
                    uint8_t alpha          = (w >> 40) & 0xFF;
                    uint8_t light          = (w >> 32) & 0xFF;
                    uint8_t r              = (w >> 24) & 0xFF;
                    uint8_t g              = (w >> 16) & 0xFF;
                    uint8_t b              = (w >>  8) & 0xFF;
                    uint8_t material_type  = (w >>  4) & 0x0F;

                    std::snprintf(buf, sizeof(buf),
                        "Probe RGBA %3u/%3u/%3u/%3u L%3u MT%u MP=%02X E%3u",
                        r, g, b, alpha, light,
                        material_type, material_props, emissive);
                    draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                    yoff += 14;
                    std::snprintf(buf, sizeof(buf),
                        "Edit: [C] material  [X/Z] emissive  [B] brighten");
                    draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                }
                if (sel_miss_timer > 0.0f) {
                    std::snprintf(buf, sizeof(buf),
                        "Selection miss: aim at geometry and press F");
                    SDL_Color warn = {255, 96, 96, 255};
                    draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff + 14, warn);
                }
            }

            if ((help_overlay_sticky || help_overlay_timer > 0.0f) && font) {
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
                int box_w = std::min(360, SCREEN_WIDTH - 12);
                int box_h = line_count * 14 + 10;
                for (int y = box_y; y < box_y + box_h && y < SCREEN_HEIGHT; ++y) {
                    for (int x = box_x; x < box_x + box_w && x < SCREEN_WIDTH; ++x) {
                        uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
                        uint8_t r = (px >> 16) & 0xFF;
                        uint8_t g = (px >> 8)  & 0xFF;
                        uint8_t b =  px        & 0xFF;
                        if (hud_theme_light) {
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

                SDL_Color help_color = hud_theme_light ? SDL_Color{0, 0, 0, 255} : SDL_Color{255, 255, 255, 255};
                int help_y = box_y + 4;
                for (int i = 0; i < line_count; ++i) {
                    draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, help_lines[i],
                                    box_x + 4, help_y, help_color);
                    help_y += 14;
                }
            }

            if (!mouse_captured && font) {
                SDL_Color warn_color{255, 96, 96, 255};
                int warn_x = SCREEN_WIDTH - 210;
                int warn_y = 8;
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font,
                                "Mouse capture OFF (press M)",
                                warn_x, warn_y, warn_color);
            }

            if (use_platform_present) {
                present_backend(backend, plat_ctx, framebuffer.data(),
                                SCREEN_WIDTH, SCREEN_HEIGHT);
            }

            std::chrono::high_resolution_clock::time_point hud_present_end;
            if (render_instrument.active())
                hud_present_end = std::chrono::high_resolution_clock::now();

            std::chrono::high_resolution_clock::time_point copy_start;
            if (render_instrument.active())
                copy_start = std::chrono::high_resolution_clock::now();
            void* pixels = nullptr;
            int pitch_bytes = 0;
            if (SDL_LockTexture(tex, nullptr, &pixels, &pitch_bytes) != 0)
                die("LockTexture failed");

            for (int y = 0; y < SCREEN_HEIGHT; ++y) {
                uint32_t* row = (uint32_t*)((uint8_t*)pixels + y * pitch_bytes);
                std::memcpy(row, &framebuffer[size_t(y)*SCREEN_WIDTH],
                            SCREEN_WIDTH * sizeof(uint32_t));
            }
            SDL_UnlockTexture(tex);

            SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
            SDL_RenderClear(ren);
            SDL_RenderCopy(ren, tex, nullptr, nullptr);
            SDL_RenderPresent(ren);

            std::chrono::high_resolution_clock::time_point copy_end;
            if (render_instrument.active())
                copy_end = std::chrono::high_resolution_clock::now();

            // Clear framebuffer for next frame to avoid stale pixels if the RTL stalls early
            // or when explicit per-frame clearing is requested.
            if (clear_each_frame || pixels_written_this_frame < NPIX) {
                std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
            }

            pixels_this_frame = 0;
        }

        if (idle_ms > 0)
            SDL_Delay(idle_ms);
    }

    top->final();
    delete top;

    if (use_platform_present)
        shutdown_backend(backend, plat_ctx);

    std::fprintf(stderr, "[hydra] exit summary: backend=%s vsync=%s frames_rendered=%zu\n",
                 backend_name(backend),
                 g_vsync ? "on" : "off",
                 frame_counter);

    if (font) TTF_CloseFont(font);
    TTF_Quit();
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
// ============================================================================
// sim/viewer.cpp
// Verilator + SDL2 live viewer for voxel_framebuffer_top
// Cleaned copy with depth-fog and HUD integration.
// ============================================================================

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"
#include "Vvoxel_framebuffer_top___024root.h"
#include "platform/backend_selector.h"
#include "platform/platform.h"

#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <cmath>
#include <chrono>
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <cctype>
#include <fstream>
#include <filesystem>
#include <strings.h>
#include <unistd.h>

struct ColorRange {
    uint8_t min_r;
    uint8_t min_g;
    uint8_t min_b;
    uint8_t max_r;
    uint8_t max_g;
    uint8_t max_b;
};

static ColorRange color_range_default() {
    return ColorRange{0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00};
}

static void record_color(ColorRange& range, uint32_t argb) {
    uint8_t r = (argb >> 16) & 0xFF;
    uint8_t g = (argb >>  8) & 0xFF;
    uint8_t b = (argb      ) & 0xFF;
    range.min_r = std::min(range.min_r, r);
    range.min_g = std::min(range.min_g, g);
    range.min_b = std::min(range.min_b, b);
    range.max_r = std::max(range.max_r, r);
    range.max_g = std::max(range.max_g, g);
    range.max_b = std::max(range.max_b, b);
}

static const int   SCREEN_WIDTH  = 480;
static const int   SCREEN_HEIGHT = 360;
static const int   HUD_HEIGHT    = 80;
static const float FX            = 256.0f;  // fixed-point scale
static bool        g_vsync       = true;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

enum class PixelViewMode {
    Color = 0,
    Word0,
    Word2,
    SidebandMix,
};

static PixelViewMode g_pixel_view_mode = PixelViewMode::Color;

static const char* pixel_view_mode_name(PixelViewMode m) {
    switch (m) {
        case PixelViewMode::Color:      return "color";
        case PixelViewMode::Word0:      return "word0";
        case PixelViewMode::Word2:      return "word2";
        case PixelViewMode::SidebandMix:return "sideband";
        default:                        return "unknown";
    }
}

static PixelViewMode pixel_view_from_string(const char* s) {
    if (!s) return PixelViewMode::Color;
    if (strcasecmp(s, "color") == 0)    return PixelViewMode::Color;
    if (strcasecmp(s, "word0") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "depth") == 0)    return PixelViewMode::Word0;
    if (strcasecmp(s, "word2") == 0)    return PixelViewMode::Word2;
    if (strcasecmp(s, "reemissure") == 0|| strcasecmp(s, "reem") == 0) return PixelViewMode::Word2;
    if (strcasecmp(s, "sideband") == 0) return PixelViewMode::SidebandMix;
    return PixelViewMode::Color;
}

static uint32_t visualize_word(uint32_t w) {
    uint8_t r = (w >> 24) & 0xFF;
    uint8_t g = (w >> 16) & 0xFF;
    uint8_t b = (w >>  8) & 0xFF;
    if (r == 0 && g == 0 && b == 0) {
        uint8_t lsb = w & 0xFF;
        r = g = b = lsb;
    }
    return (0xFFu << 24) |
           (uint32_t(r) << 16) |
           (uint32_t(g) << 8)  |
            uint32_t(b);
}

static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    switch (g_pixel_view_mode) {
        case PixelViewMode::Color: {
            uint8_t r = (w1 >> 24) & 0xFF;
            uint8_t g = (w1 >> 16) & 0xFF;
            uint8_t b = (w1 >>  8) & 0xFF;
            return (0xFFu << 24) |
                   (uint32_t(r) << 16) |
                   (uint32_t(g) << 8)  |
                    uint32_t(b);
        }
        case PixelViewMode::Word0:
            return visualize_word(w0);
        case PixelViewMode::Word2:
            return visualize_word(w2);
        case PixelViewMode::SidebandMix: {
            uint8_t depth_like = (w0 >> 16) & 0xFF;
            uint8_t emissive   = (w2 >> 16) & 0xFF;
            uint8_t diag_bits  = (w0 >> 8)  & 0xFF;
            return (0xFFu << 24) |
                   (uint32_t(emissive)   << 16) |
                   (uint32_t(depth_like) << 8)  |
                    uint32_t(diag_bits);
        }
        default:
            return visualize_word(w1);
    }
}

// Depth-fog configuration and application
static bool g_fog_enabled = false;
static uint32_t g_fog_color = 0xFFE0E0E0; // ARGB
static float g_fog_density = 1.0f; // linear density multiplier

static uint32_t apply_fog(uint32_t src_argb, uint8_t depth_byte) {
    if (!g_fog_enabled) return src_argb;
    float d = static_cast<float>(depth_byte) / 255.0f; // 0..1, 0=near,1=far
    float factor = d * g_fog_density;
    if (factor > 1.0f) factor = 1.0f;

    uint8_t sr = (src_argb >> 16) & 0xFF;
    uint8_t sg = (src_argb >> 8)  & 0xFF;
    uint8_t sb =  src_argb        & 0xFF;

    uint8_t fr = (g_fog_color >> 16) & 0xFF;
    uint8_t fg = (g_fog_color >> 8)  & 0xFF;
    uint8_t fb =  g_fog_color        & 0xFF;

    uint8_t rr = static_cast<uint8_t>(sr * (1.0f - factor) + fr * factor);
    uint8_t gg = static_cast<uint8_t>(sg * (1.0f - factor) + fg * factor);
    uint8_t bb = static_cast<uint8_t>(sb * (1.0f - factor) + fb * factor);

    return (0xFFu << 24) | (uint32_t(rr) << 16) | (uint32_t(gg) << 8) | uint32_t(bb);
}

static uint32_t spectrum_pixel(uint32_t addr) {
    uint32_t x = addr % SCREEN_WIDTH;
    uint32_t y = addr / SCREEN_WIDTH;
    uint8_t r = (x * 255) / (SCREEN_WIDTH - 1);
    uint8_t g = (y * 255) / (SCREEN_HEIGHT - 1);
    uint8_t b = ((x + y) * 255) / ((SCREEN_WIDTH + SCREEN_HEIGHT) - 2);
    return (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
}

static inline uint32_t voxel_addr_from_xyz(uint8_t x, uint8_t y, uint8_t z) {
    return (uint32_t(x) << 12) | (uint32_t(y) << 6) | uint32_t(z);
}

static bool env_truthy(const char* key) {
    if (const char* v = std::getenv(key)) {
        return v[0] != '\0' && v[0] != '0' && strcasecmp(v, "false") != 0;
    }
    return false;
}

static std::string flatten_cli_args(int argc, char** argv) {
    std::string out;
    for (int i = 0; i < argc; ++i) {
        if (i) out += ' ';
        if (argv[i]) out += argv[i];
    }
    return out;
}

static void apply_cli_overrides(int argc, char** argv) {
    auto missing_value = [](const char* flag) {
        std::fprintf(stderr, "[hydra] Missing value for %s\n", flag);
    };
    auto set_override = [](const char* key, const char* value, const char* note = nullptr) {
        if (!value) return;
        setenv(key, value, 1);
        if (note) std::fprintf(stderr, "[hydra] CLI override: %s=%s (%s)\n", key, value, note);
        else      std::fprintf(stderr, "[hydra] CLI override: %s=%s\n", key, value);
    };
    auto match_arg = [&](const char* arg, const char* long_flag, int& i) -> const char* {
        size_t len = std::strlen(long_flag);
        if (std::strncmp(arg, long_flag, len) != 0) return nullptr;
        if (arg[len] == '=') return arg + len + 1;
        if (i + 1 < argc) return argv[++i];
        missing_value(long_flag);
        return nullptr;
    };

    bool show_caps = false;
    for (int i = 1; i < argc; ++i) {
        const char* arg = argv[i];
        if (!arg) continue;
        if (std::strcmp(arg, "--show-capabilities") == 0 || std::strcmp(arg, "--caps") == 0) {
            show_caps = true;
        } else if (std::strcmp(arg, "--quiet") == 0 || std::strcmp(arg, "-q") == 0) {
            setenv("HYDRA_QUIET", "1", 1);
        } else if (std::strcmp(arg, "--verbose") == 0 || std::strcmp(arg, "-v") == 0) {
            setenv("HYDRA_VERBOSE", "1", 1);
        } else if ((std::strcmp(arg, "--backend") == 0 || std::strcmp(arg, "-b") == 0) && i + 1 < argc) {
            const char* val = argv[++i]; setenv("HYDRA_BACKEND", val, 1); std::fprintf(stderr, "[hydra] CLI override: backend=%s\n", val);
        } else if (const char* val = match_arg(arg, "--backend", i)) {
            set_override("HYDRA_BACKEND", val);
        } else if ((std::strcmp(arg, "--sdl-driver") == 0 || std::strcmp(arg, "--video-driver") == 0) && i + 1 < argc) {
            const char* val = argv[++i]; setenv("SDL_VIDEODRIVER", val, 1); std::fprintf(stderr, "[hydra] CLI override: SDL_VIDEODRIVER=%s\n", val);
        } else if (const char* val = match_arg(arg, "--sdl-driver", i)) {
            set_override("SDL_VIDEODRIVER", val, "SDL video driver");
        } else if (const char* val = match_arg(arg, "--video-driver", i)) {
            set_override("SDL_VIDEODRIVER", val, "SDL video driver");
        } else if (std::strcmp(arg, "--instrument") == 0) {
            setenv("HYDRA_RENDER_INSTRUMENT", "1", 1); std::fprintf(stderr, "[hydra] CLI override: render instrumentation enabled\n");
        } else if (const char* val = match_arg(arg, "--cam-pos", i)) {
            set_override("HYDRA_CAM_POS", val, "camera position (x,y,z)");
        } else if (const char* val = match_arg(arg, "--cam-ang", i)) {
            set_override("HYDRA_CAM_ANG", val, "camera yaw,pitch");
        } else if (const char* val = match_arg(arg, "--move-speed", i)) {
            set_override("HYDRA_MOVE_SPEED", val, "move speed");
        } else if (const char* val = match_arg(arg, "--move-speed-fast", i)) {
            set_override("HYDRA_MOVE_SPEED_FAST", val, "fast move speed");
        } else if (const char* val = match_arg(arg, "--turn-speed", i)) {
            set_override("HYDRA_TURN_SPEED_KEYS", val, "key turn speed");
        } else if (const char* val = match_arg(arg, "--mouse-sens", i)) {
            set_override("HYDRA_MOUSE_SENS", val, "mouse sensitivity");
        } else if (const char* val = match_arg(arg, "--fps-target", i)) {
            set_override("HYDRA_FPS_TARGET", val, "frame pacing target");
        } else if (const char* val = match_arg(arg, "--pixel-view", i)) {
            set_override("HYDRA_PIXEL_VIEW", val, "pixel view mode");
        } else if (const char* val = match_arg(arg, "--seed", i)) {
            set_override("HYDRA_WORLD_SEED", val, "world/procedural seed");
        }
    }

    if (show_caps) {
        platform_log_capabilities();
        std::exit(0);
    }
}

static std::string g_backend_info;

static const char* backend_name(PlatformBackend b) {
    switch (b) {
        case PlatformBackend::SDL:    return "SDL";
        case PlatformBackend::GL:     return "GL";
        case PlatformBackend::Vulkan: return "Vulkan";
        case PlatformBackend::Wayland:return "Wayland";
        case PlatformBackend::X11:    return "X11";
        case PlatformBackend::Fbdev:  return "fbdev";
        case PlatformBackend::Win32:  return "Win32";
        case PlatformBackend::MacOS:  return "macOS";
        case PlatformBackend::Headless: return "Headless";
        default: return "Unknown";
    }
}

static void log_backend_caps(PlatformBackend requested, PlatformBackend backend, bool vsync) {
    const char* video_driver = SDL_GetCurrentVideoDriver();
    const char* render_driver = SDL_GetHint(SDL_HINT_RENDER_DRIVER);

    std::fprintf(stderr,
        "[hydra] backend requested=%s actual=%s vsync=%s video_driver=%s render_driver=%s\n",
        backend_name(requested), backend_name(backend), vsync ? "on" : "off",
        video_driver ? video_driver : "(unknown)", render_driver ? render_driver : "(default)");

    std::fprintf(stderr, "[hydra] compiled backends: SDL");
#ifdef HYDRA_ENABLE_GL
    std::fprintf(stderr, " GL");
#endif
#ifdef HYDRA_ENABLE_VULKAN
    std::fprintf(stderr, " Vulkan");
#endif
#ifdef HYDRA_ENABLE_WAYLAND
    std::fprintf(stderr, " Wayland");
#endif
#ifdef HYDRA_ENABLE_X11
    std::fprintf(stderr, " X11");
#endif
    std::fprintf(stderr, " Headless\n");
}

static void log_input_caps() {
    const char* grab_hint = SDL_GetHint(SDL_HINT_GRAB_KEYBOARD);
    const char* mouse_hint = SDL_GetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP);

    int joysticks = SDL_NumJoysticks();
    int controllers = 0;
    for (int i = 0; i < joysticks; ++i) if (SDL_IsGameController(i)) ++controllers;

    int touch_devices = SDL_GetNumTouchDevices();

    std::fprintf(stderr,
        "[hydra] input: keyboard=assumed mouse_capture_hint=%s mouse_relative_hint=%s touch_devices=%d joysticks=%d controllers=%d\n",
        grab_hint ? grab_hint : "(default)", mouse_hint ? mouse_hint : "(default)", touch_devices, joysticks, controllers);
}

struct InputState {
    bool forward     = false;
    bool back        = false;
    bool strafe_left = false;
    bool strafe_right = false;
    bool up          = false;
    bool down        = false;
    bool yaw_left    = false;
    bool yaw_right   = false;
    bool pitch_up    = false;
    bool pitch_down  = false;
    bool fast        = false;
};

static inline void update_key_state(InputState& keys, SDL_Scancode sc, SDL_Keycode keycode, bool pressed) {
    switch (sc) {
        case SDL_SCANCODE_W: keys.forward      = pressed; break;
        case SDL_SCANCODE_S: keys.back         = pressed; break;
        case SDL_SCANCODE_A: keys.strafe_left  = pressed; break;
        case SDL_SCANCODE_D: keys.strafe_right = pressed; break;
        case SDL_SCANCODE_Q: keys.down         = pressed; break;
        case SDL_SCANCODE_E: keys.up           = pressed; break;
        case SDL_SCANCODE_LEFT:  keys.yaw_left  = pressed; break;
        case SDL_SCANCODE_RIGHT: keys.yaw_right = pressed; break;
        case SDL_SCANCODE_UP:    keys.pitch_up  = pressed; break;
        case SDL_SCANCODE_DOWN:  keys.pitch_down= pressed; break;
        case SDL_SCANCODE_LSHIFT:
        case SDL_SCANCODE_RSHIFT: keys.fast     = pressed; break;
        default: break;
    }
    SDL_Keycode kc = keycode;
    if (kc >= 'A' && kc <= 'Z') kc = kc - 'A' + 'a';
    switch (kc) {
        case SDLK_w: keys.forward      = pressed; break;
        case SDLK_s: keys.back         = pressed; break;
        case SDLK_a: keys.strafe_left  = pressed; break;
        case SDLK_d: keys.strafe_right = pressed; break;
        case SDLK_q: keys.down         = pressed; break;
        case SDLK_e: keys.up           = pressed; break;
        case SDLK_LEFT:  keys.yaw_left  = pressed; break;
        case SDLK_RIGHT: keys.yaw_right = pressed; break;
        case SDLK_UP:    keys.pitch_up  = pressed; break;
        case SDLK_DOWN:  keys.pitch_down= pressed; break;
        case SDLK_LSHIFT:
        case SDLK_RSHIFT: keys.fast     = pressed; break;
        default: break;
    }
}

static void die(const std::string& s) { std::fprintf(stderr, "Error: %s\n", s.c_str()); std::exit(1); }

static void draw_text_to_fb(std::vector<uint32_t>& fb, int fb_w, int fb_h, TTF_Font* font, const std::string& txt, int x, int y, SDL_Color color = {255,255,255,255}) {
    SDL_Surface* surf = TTF_RenderText_Blended(font, txt.c_str(), color);
    if (!surf) return;
    SDL_PixelFormat* fmt = surf->format;
    if (!fmt || fmt->BytesPerPixel != 4) {
        SDL_Surface* conv = SDL_ConvertSurfaceFormat(surf, SDL_PIXELFORMAT_ARGB8888, 0);
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

struct RenderInstrumentationConfig {
    float cam_pos_x = 0.0f;
    float cam_pos_y = 0.0f;
    float cam_pos_z = 0.0f;
    float yaw = 0.0f;
    float pitch = 0.0f;
    bool smooth_surfaces = false;
    bool curvature = false;
    bool extra_light = false;
    bool diag_slice = false;
    bool ray_jitter = false;
    bool hud_enabled = true;
    float fps_target = 0.0f;
    bool vsync = true;
    std::string backend_name;
    std::string backend_info;
    std::string pixel_view;
};

struct RenderInstrumentation {
    RenderInstrumentation(bool enabled, std::string command_line)
        : enabled_(enabled), command_line_(std::move(command_line)) {
        if (!enabled_) return;
        std::filesystem::create_directories("out");
        csv_.open("out/render_pipeline_baseline.csv", std::ios::app);
        if (!csv_) die("failed to open out/render_pipeline_baseline.csv for instrumentation logging");
        if (csv_.tellp() == 0)
            csv_ << "frame,timestamp_ms,fps,ray_loop_ms,hud_present_ms,framebuffer_copy_ms,frame_total_ms\n";
    }
    bool active() const { return enabled_; }
    void write_config(const RenderInstrumentationConfig& cfg) {
        if (!enabled_) return;
        std::ofstream cfg_out("out/render_pipeline_baseline.cfg");
        if (!cfg_out) die("failed to write out/render_pipeline_baseline.cfg");
        cfg_out << "instrument_command=" << command_line_ << "\n";
        cfg_out << "backend=" << cfg.backend_name << "\n";
        cfg_out << "backend_info=" << cfg.backend_info << "\n";
        cfg_out << "pixel_view=" << cfg.pixel_view << "\n";
        cfg_out << "camera_pos=" << cfg.cam_pos_x << "," << cfg.cam_pos_y << "," << cfg.cam_pos_z << "\n";
        cfg_out << "camera_ang=" << cfg.yaw << "," << cfg.pitch << "\n";
        cfg_out << "flags=smooth:" << (cfg.smooth_surfaces ? "1" : "0")
                << ",curvature:" << (cfg.curvature ? "1" : "0")
                << ",extra_light:" << (cfg.extra_light ? "1" : "0")
                << ",diag_slice:" << (cfg.diag_slice ? "1" : "0")
                << ",ray_jitter:" << (cfg.ray_jitter ? "1" : "0") << "\n";
        cfg_out << "hud_enabled=" << (cfg.hud_enabled ? "1" : "0") << "\n";
        cfg_out << "fps_target=" << cfg.fps_target << "\n";
        cfg_out << "vsync=" << (cfg.vsync ? "1" : "0") << "\n";
    }
    void record(uint64_t frame, double fps, double ray_loop_ms, double hud_present_ms, double framebuffer_copy_ms, double frame_total_ms) {
        if (!enabled_) return;
        auto now = std::chrono::system_clock::now();
        auto ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
        csv_ << frame << ',' << ts_ms << ',' << fps << ',' << ray_loop_ms << ',' << hud_present_ms << ',' << framebuffer_copy_ms << ',' << frame_total_ms << '\n';
        csv_.flush();
    }
private:
    bool enabled_;
    std::ofstream csv_;
    std::string command_line_;
};

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    apply_cli_overrides(argc, argv);

    const bool render_instrument_mode = env_truthy("HYDRA_RENDER_INSTRUMENT");
    RenderInstrumentation render_instrument(render_instrument_mode, flatten_cli_args(argc, argv));

    Vvoxel_framebuffer_top* top = new Vvoxel_framebuffer_top;
    auto* root = top->rootp;
    top->clk = 0; top->rst_n = 0;
    top->cam_load = 0; top->cam_x_in = 0; top->cam_y_in = 0; top->cam_z_in = 0;
    top->cam_dir_x_in = 0; top->cam_dir_y_in = 0; top->cam_dir_z_in = 0;
    top->cam_plane_x_in = 0; top->cam_plane_y_in = 0;
    top->flags_load = 0; top->flag_smooth_in = 0; top->flag_curvature_in = 0; top->flag_extra_light_in = 0; top->flag_diag_slice_in = 0;
    top->sel_load = 0; top->sel_active_in = 0; top->sel_voxel_x_in = 0; top->sel_voxel_y_in = 0; top->sel_voxel_z_in = 0;
    top->dbg_ext_write_en = 0; top->dbg_ext_write_addr = 0; top->dbg_ext_write_data = 0; top->start_frame_ext = 0; top->soft_reset_ext = 0;

    const bool log_keys = (std::getenv("LOG_KEYS") != nullptr);
    const bool log_frames = (std::getenv("LOG_FRAMES") != nullptr);
    int log_keys_count = 0; size_t pixels_this_frame = 0; size_t frame_counter = 0; int log_pixel_samples = 0;
    uint64_t prev_mem_cycle = 0, prev_mem_read = 0, prev_mem_write = 0;
    float last_mem_read_util = 0.0f, last_mem_write_util = 0.0f;
    ColorRange frame_color_stats = color_range_default();
    ColorRange last_frame_color_stats = frame_color_stats;
    bool frame_color_stats_dirty = false, last_frame_color_stats_valid = false;

    // Configure depth fog from environment
    g_fog_enabled = env_truthy("HYDRA_FOG");
    if (const char* fog_col = std::getenv("HYDRA_FOG_COLOR")) {
        unsigned long v = std::strtoul(fog_col, nullptr, 0);
        g_fog_color = 0xFF000000u | (uint32_t(v) & 0x00FFFFFFu);
    }
    if (const char* fog_den = std::getenv("HYDRA_FOG_DENSITY")) {
        char* endptr = nullptr;
        float d = std::strtof(fog_den, &endptr);
        if (endptr && endptr != fog_den) g_fog_density = d;
    }
    if (g_fog_enabled) std::fprintf(stderr, "[hydra] Depth fog enabled color=%08x density=%.3f\n", g_fog_color, g_fog_density);

    SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1");
    SDL_SetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP, "1");
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0) die(std::string("SDL_Init: ") + SDL_GetError());
    if (TTF_Init() != 0) die(std::string("TTF_Init: ") + TTF_GetError());

    PlatformBackend requested_backend = select_default_backend();
    const bool headless_backend = (requested_backend == PlatformBackend::Headless);
    if (headless_backend) { setenv("SDL_VIDEODRIVER", "dummy", 0); setenv("SDL_AUDIODRIVER", "dummy", 0); }

    log_input_caps();
    if (std::getenv("HYDRA_VSYNC")) g_vsync = env_truthy("HYDRA_VSYNC");

    PlatformBackend backend = PlatformBackend::SDL; PlatformContext plat_ctx; bool use_platform_present = false;
    bool backend_fallback = false;

    if (requested_backend != PlatformBackend::SDL) {
        if (!platform_backend_supported(requested_backend)) {
            std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' is not supported on this platform\n", backend_name(requested_backend));
            backend_fallback = true;
        } else {
            PlatformConfig plat_cfg; plat_cfg.width = SCREEN_WIDTH; plat_cfg.height = SCREEN_HEIGHT; plat_cfg.vsync = true;
            std::fprintf(stderr, "[hydra] Initializing %s backend...\n", backend_name(requested_backend));
            if (init_backend(requested_backend, plat_cfg, plat_ctx)) { backend = requested_backend; use_platform_present = true; std::fprintf(stderr, "[hydra] SUCCESS: %s backend initialized\n", backend_name(backend)); }
            else { std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' initialization failed\n", backend_name(requested_backend)); backend_fallback = true; }
        }
    }

    if (backend == PlatformBackend::SDL) std::fprintf(stderr, "[hydra] Using SDL backend%s\n", backend_fallback ? " (fallback)" : " (default)");
    log_backend_caps(requested_backend, backend, g_vsync);

    SDL_Window* win = SDL_CreateWindow("Voxel Accelerator — Interactive Raycaster", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2, SDL_WINDOW_RESIZABLE);
    if (!win) die("Cannot create SDL window");
    SDL_RaiseWindow(win);
    uint32_t sdl_renderer_flags = SDL_RENDERER_ACCELERATED; if (g_vsync) sdl_renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
    SDL_Renderer* ren = SDL_CreateRenderer(win, -1, sdl_renderer_flags); if (!ren) die("Renderer creation failed");
    SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);

    SDL_RendererInfo ren_info; if (SDL_GetRendererInfo(ren, &ren_info) == 0) {
        std::fprintf(stderr, "Renderer: %s\n", ren_info.name ? ren_info.name : "(unknown)");
        const char* video_driver = SDL_GetCurrentVideoDriver();
        char buf[160]; std::snprintf(buf, sizeof(buf), "Backend: %s (vsync %s) renderer=%s video=%s", backend_name(backend), g_vsync ? "on" : "off", ren_info.name ? ren_info.name : "(unknown)", video_driver ? video_driver : "(unknown)");
        g_backend_info = buf;
    }

    SDL_Texture* tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
    if (!tex) die("Texture creation failed");
    auto recreate_texture = [&]() { if (tex) { SDL_DestroyTexture(tex); tex = nullptr; } tex = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT); if (!tex) die("Texture recreation failed"); };

    const char* font_env = std::getenv("HYDRA_FONT"); const char* font_scale_env = std::getenv("HYDRA_FONT_SCALE"); int font_size = 11;
    if (font_scale_env) { float scale = std::atof(font_scale_env); scale = std::clamp(scale, 0.5f, 3.0f); font_size = std::max(8, static_cast<int>(11 * scale)); }
    const char* font_search_paths[] = { font_env, "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf", "/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf", "/usr/share/fonts/TTF/DejaVuSans.ttf", "/usr/share/fonts/liberation/LiberationSans-Regular.ttf", "/usr/local/share/fonts/dejavu/DejaVuSans.ttf", "/usr/local/share/fonts/Liberation/LiberationSans-Regular.ttf", "/System/Library/Fonts/Helvetica.ttc", "/Library/Fonts/Arial.ttf", "/System/Library/Fonts/SFNSText.ttf", "/mnt/c/Windows/Fonts/arial.ttf", "/mnt/c/Windows/Fonts/Arial.ttf", "C:\\Windows\\Fonts\\arial.ttf", nullptr };
    TTF_Font* font = nullptr; const char* font_path = nullptr;
    for (int i = 0; font_search_paths[i] != nullptr; ++i) {
        if (font_search_paths[i][0] == '\0') continue;
        font = TTF_OpenFont(font_search_paths[i], font_size);
        if (font) { font_path = font_search_paths[i]; break; }
    }
    if (!font) { std::fprintf(stderr, "Warning: could not find any suitable font, HUD text disabled\n"); std::fprintf(stderr, "Hint: Set HYDRA_FONT=/path/to/font.ttf to specify a font\n"); }
    else if (font_env && font_path != font_env) std::fprintf(stderr, "Warning: HYDRA_FONT='%s' not found, using fallback: %s\n", font_env, font_path);

    const size_t NPIX = size_t(SCREEN_WIDTH) * SCREEN_HEIGHT;
    const char* frame_dump_path = std::getenv("FRAME_DUMP"); const char* frame_dump_base = std::getenv("HYDRA_FRAME_BASE"); const char* auto_exit_env = std::getenv("AUTO_EXIT"); bool auto_exit = auto_exit_env && auto_exit_env[0] != '\0';
    const char* max_dump_env = std::getenv("HYDRA_MAX_FRAME_DUMPS"); int max_frame_dumps = max_dump_env ? std::max(0, std::atoi(max_dump_env)) : 1; int frame_dumps_written = 0;
    const char* autosave_cfg = std::getenv("HYDRA_AUTOSAVE_CFG"); const bool clear_each_frame = (std::getenv("HYDRA_CLEAR_EACH_FRAME") != nullptr);
    const char* fg_env = std::getenv("HYDRA_CLEAR_COLOR"); uint32_t clear_color = 0;
    if (fg_env) { unsigned int r=0,g=0,b=0; if (std::sscanf(fg_env, "%u,%u,%u", &r, &g, &b) == 3) clear_color = (0xFFu << 24) | ((r & 0xFFu) << 16) | ((g & 0xFFu) << 8) | (b & 0xFFu); }
    std::vector<uint32_t> framebuffer(NPIX, clear_color);

    auto handle_resize = [&](int new_w, int new_h) { (void)new_w; (void)new_h; SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT); recreate_texture(); std::fill(framebuffer.begin(), framebuffer.end(), clear_color); std::fprintf(stderr, "[hydra] window resized, refreshed texture and cleared framebuffer\n"); };

    // Reset sequence
    for (int i = 0; i < 10; ++i) { top->clk = 0; top->eval(); main_time++; top->clk = 1; top->eval(); main_time++; }
    top->rst_n = 1;

    const char* cam_pos_env = std::getenv("HYDRA_CAM_POS"); const char* cam_ang_env = std::getenv("HYDRA_CAM_ANG");
    auto parse_vec3 = [](const char* s, float def_x, float def_y, float def_z, float& ox, float& oy, float& oz) { ox = def_x; oy = def_y; oz = def_z; if (!s) return; if (std::sscanf(s, "%f,%f,%f", &ox, &oy, &oz) != 3) { ox = def_x; oy = def_y; oz = def_z; } };
    auto parse_vec2 = [](const char* s, float def_a, float def_b, float& oa, float& ob) { oa = def_a; ob = def_b; if (!s) return; if (std::sscanf(s, "%f,%f", &oa, &ob) != 2) { oa = def_a; ob = def_b; } };

    float pos_x = 10.0f, pos_y = 10.0f, pos_z = 10.0f, yaw = 0.0f, pitch = 0.0f;
    parse_vec3(cam_pos_env, pos_x, pos_y, pos_z, pos_x, pos_y, pos_z);
    parse_vec2(cam_ang_env, yaw, pitch, yaw, pitch);
    const float default_pos_x = pos_x, default_pos_y = pos_y, default_pos_z = pos_z, default_yaw = yaw, default_pitch = pitch;

    auto getenv_float = [](const char* name, float def_val) -> float { const char* v = std::getenv(name); if (!v) return def_val; return std::atof(v); };
    float move_speed = getenv_float("HYDRA_MOVE_SPEED", 0.10f);
    float move_speed_fast = getenv_float("HYDRA_MOVE_SPEED_FAST", 0.35f);
    float turn_speed_keys = getenv_float("HYDRA_TURN_SPEED_KEYS", 0.04f);
    float mouse_sens = getenv_float("HYDRA_MOUSE_SENS", 0.0025f);
    bool invert_y_mouse = (std::getenv("HYDRA_INVERT_Y") != nullptr);
    const float base_move_speed = move_speed, base_move_speed_fast = move_speed_fast, base_turn_speed_keys = turn_speed_keys, base_mouse_sens = mouse_sens;

    bool smooth_surfaces = true, curvature = true, extra_light = false, diag_slice = false;
    bool ray_jitter = env_truthy("HYDRA_RAY_JITTER"); bool spectrum_mode = env_truthy("HYDRA_SPECTRUM_MODE");
    bool hud_enabled = true; bool hud_theme_light = false; if (const char* hud_theme_env = std::getenv("HYDRA_HUD_THEME")) if (strcasecmp(hud_theme_env, "light") == 0) hud_theme_light = true;
    const char* pixel_view_env = std::getenv("HYDRA_PIXEL_VIEW"); g_pixel_view_mode = pixel_view_from_string(pixel_view_env);
    bool safe_capture_mode = env_truthy("HYDRA_SAFE_CAPTURE");

    uint32_t world_seed_override = 0; const char* world_seed_env = std::getenv("HYDRA_WORLD_SEED"); if (const char* seed_env = world_seed_env) world_seed_override = static_cast<uint32_t>(std::strtoul(seed_env, nullptr, 0));

    bool mouse_captured = true; const char* mouse_cap_env = std::getenv("HYDRA_MOUSE_CAPTURE"); if (mouse_cap_env && std::strcmp(mouse_cap_env, "0") == 0) mouse_captured = false;

    auto load_autosave_cfg = [&](const char* path) {
        if (!path || path[0] == '\0') return; FILE* f = std::fopen(path, "r"); if (!f) return; char line[256];
        while (std::fgets(line, sizeof(line), f)) {
            if (std::strncmp(line, "cam_pos=", 8) == 0) { float lx,ly,lz; if (std::sscanf(line+8, "%f,%f,%f", &lx,&ly,&lz) == 3) { pos_x = lx; pos_y = ly; pos_z = lz; } }
            else if (std::strncmp(line, "cam_ang=", 8) == 0) { float lyaw, lpitch; if (std::sscanf(line+8, "%f,%f", &lyaw, &lpitch) == 2) { yaw = lyaw; pitch = lpitch; } }
            else if (std::strncmp(line, "flags=", 6) == 0) { int fs,fc,fe,fd; if (std::sscanf(line+6, "%d,%d,%d,%d", &fs,&fc,&fe,&fd) == 4) { smooth_surfaces = (fs!=0); curvature = (fc!=0); extra_light = (fe!=0); diag_slice = (fd!=0); } }
            else if (std::strncmp(line, "seed=", 5) == 0) { uint32_t s=0; if (std::sscanf(line+5, "%u", &s) == 1) world_seed_override = s; }
            else if (std::strncmp(line, "safe_capture=", 13) == 0) { int v=0; if (std::sscanf(line+13, "%d", &v) == 1) safe_capture_mode = (v!=0); }
        }
        std::fclose(f);
    };

    bool cam_clamp_enabled = (std::getenv("HYDRA_CAM_CLAMP") != nullptr);
    float cam_min = -1.0f, cam_max = 65.0f; const char* cam_bounds_env = std::getenv("HYDRA_CAM_BOUNDS"); if (cam_bounds_env) { float min_val,max_val; if (std::sscanf(cam_bounds_env, "%f,%f", &min_val, &max_val) == 2) { cam_min = min_val; cam_max = max_val; } }
    const bool base_cam_clamp = cam_clamp_enabled; const float base_cam_min = cam_min, base_cam_max = cam_max;

    if (cam_clamp_enabled) { if (pos_x < cam_min) pos_x = cam_min; if (pos_x > cam_max) pos_x = cam_max; if (pos_y < cam_min) pos_y = cam_min; if (pos_y > cam_max) pos_y = cam_max; if (pos_z < cam_min) pos_z = cam_min; if (pos_z > cam_max) pos_z = cam_max; }
    if (autosave_cfg) load_autosave_cfg(autosave_cfg);

    const char* idle_env = std::getenv("HYDRA_SIM_IDLE_MS"); const int idle_ms = idle_env ? std::max(0, std::atoi(idle_env)) : 0;
    const char* fps_env = std::getenv("HYDRA_FPS_TARGET"); const float fps_target = fps_env ? std::max(0.0f, static_cast<float>(std::atof(fps_env))) : 0.0f;

    std::fprintf(stderr, "\n[hydra] === Startup Configuration ===\n");
    std::fprintf(stderr, "[hydra] Backend: %s\n", backend_name(backend));
    SDL_version ver; SDL_GetVersion(&ver); std::fprintf(stderr, "[hydra] SDL version: %d.%d.%d\n", ver.major, ver.minor, ver.patch);
    std::fprintf(stderr, "[hydra] Resolution: %dx%d\n", SCREEN_WIDTH, SCREEN_HEIGHT);
    std::fprintf(stderr, "[hydra] Font: %s (size %d)\n", font_path, font_size);
    std::fprintf(stderr, "[hydra] Pixel view: %s\n", pixel_view_mode_name(g_pixel_view_mode));
    std::fprintf(stderr, "[hydra] ==============================\n\n");

    RenderInstrumentationConfig inst_config; inst_config.cam_pos_x = pos_x; inst_config.cam_pos_y = pos_y; inst_config.cam_pos_z = pos_z; inst_config.yaw = yaw; inst_config.pitch = pitch; inst_config.smooth_surfaces = smooth_surfaces; inst_config.curvature = curvature; inst_config.extra_light = extra_light; inst_config.diag_slice = diag_slice; inst_config.ray_jitter = ray_jitter; inst_config.hud_enabled = hud_enabled; inst_config.fps_target = fps_target; inst_config.vsync = g_vsync; inst_config.backend_name = backend_name(backend); inst_config.backend_info = g_backend_info; inst_config.pixel_view = pixel_view_mode_name(g_pixel_view_mode);
    render_instrument.write_config(inst_config);

    bool selection_active = false; uint8_t selection_x = 0, selection_y = 0, selection_z = 0; uint64_t selection_word = 0;
    InputState keys; float help_overlay_timer = 3.5f; if (std::getenv("HYDRA_HELP_STARTUP")) help_overlay_timer = env_truthy("HYDRA_HELP_STARTUP") ? 3.5f : 0.0f;
    bool help_overlay_sticky = false; float sel_miss_timer = 0.0f;

    auto update_mouse_capture = [&]() { if (SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE) != 0) std::fprintf(stderr, "Warning: SetRelativeMouseMode failed: %s\n", SDL_GetError()); SDL_SetWindowGrab(win, mouse_captured ? SDL_TRUE : SDL_FALSE); SDL_ShowCursor(mouse_captured ? SDL_FALSE : SDL_TRUE); };

    auto apply_camera_to_dut = [&]() {
        float dx = std::cos(yaw) * std::cos(pitch);
        float dy = std::sin(yaw) * std::cos(pitch);
        float dz = std::sin(pitch);
        float px = -dy * 0.66f; float py = dx * 0.66f;
        root->voxel_framebuffer_top__DOT__cam_x = int16_t(pos_x * FX);
        root->voxel_framebuffer_top__DOT__cam_y = int16_t(pos_y * FX);
        root->voxel_framebuffer_top__DOT__cam_z = int16_t(pos_z * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_x = int16_t(dx * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_y = int16_t(dy * FX);
        root->voxel_framebuffer_top__DOT__cam_dir_z = int16_t(dz * FX);
        root->voxel_framebuffer_top__DOT__cam_plane_x = int16_t(px * FX);
        root->voxel_framebuffer_top__DOT__cam_plane_y = int16_t(py * FX);
    };

    auto apply_flags_to_dut = [&]() {
        root->voxel_framebuffer_top__DOT__cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_curvature = curvature ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_extra_light = extra_light ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_diag_slice = diag_slice ? 1 : 0;
        root->voxel_framebuffer_top__DOT__cfg_ray_jitter = ray_jitter ? 1 : 0;
    };

    auto apply_selection_to_dut = [&]() { root->voxel_framebuffer_top__DOT__sel_active = selection_active ? 1 : 0; root->voxel_framebuffer_top__DOT__sel_voxel_x = selection_x; root->voxel_framebuffer_top__DOT__sel_voxel_y = selection_y; root->voxel_framebuffer_top__DOT__sel_voxel_z = selection_z; };

    bool safe_defaults_mode = env_truthy("HYDRA_SAFE_DEFAULTS");
    auto apply_safe_defaults = [&]() {
        if (safe_defaults_mode) { move_speed = 0.06f; move_speed_fast = 0.16f; turn_speed_keys = 0.03f; mouse_sens = 0.0016f; cam_clamp_enabled = true; }
        else { move_speed = base_move_speed; move_speed_fast = base_move_speed_fast; turn_speed_keys = base_turn_speed_keys; mouse_sens = base_mouse_sens; cam_clamp_enabled = base_cam_clamp; cam_min = base_cam_min; cam_max = base_cam_max; }
    };

    apply_safe_defaults(); if (cam_clamp_enabled) { if (pos_x < cam_min) pos_x = cam_min; if (pos_x > cam_max) pos_x = cam_max; if (pos_y < cam_min) pos_y = cam_min; if (pos_y > cam_max) pos_y = cam_max; if (pos_z < cam_min) pos_z = cam_min; if (pos_z > cam_max) pos_z = cam_max; }
    apply_camera_to_dut(); apply_flags_to_dut(); apply_selection_to_dut(); root->voxel_framebuffer_top__DOT__world_seed = world_seed_override; update_mouse_capture();

    auto reset_key_state = [&]() { keys = InputState{}; };
    bool running = true; auto last_frame_time = std::chrono::high_resolution_clock::now(); float fps = 0.0f;

    while (running && !Verilated::gotFinish()) {
        root->voxel_framebuffer_top__DOT__dbg_write_en = 0;
        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) running = false;
            else if (ev.type == SDL_WINDOWEVENT) {
                if (ev.window.event == SDL_WINDOWEVENT_FOCUS_GAINED || ev.window.event == SDL_WINDOWEVENT_TAKE_FOCUS) update_mouse_capture();
                else if (ev.window.event == SDL_WINDOWEVENT_FOCUS_LOST) reset_key_state();
                else if (ev.window.event == SDL_WINDOWEVENT_RESIZED || ev.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) handle_resize(ev.window.data1, ev.window.data2);
            } else if (ev.type == SDL_KEYDOWN || ev.type == SDL_KEYUP) {
                bool key_down = (ev.type == SDL_KEYDOWN);
                SDL_Scancode sc = ev.key.keysym.scancode; SDL_Keycode keycode = ev.key.keysym.sym;
                update_key_state(keys, sc, keycode, key_down);
                if (log_keys && log_keys_count < 200) { std::fprintf(stderr, "key %s sc=%d kc=%d name=%s mod=0x%x\n", key_down ? "down" : "up", (int)sc, (int)keycode, SDL_GetKeyName(keycode), ev.key.keysym.mod); ++log_keys_count; }
                if (key_down) {
                    switch (keycode) {
                        case SDLK_ESCAPE: running = false; break;
                        case SDLK_1: case SDLK_KP_1: smooth_surfaces = !smooth_surfaces; apply_flags_to_dut(); break;
                        case SDLK_2: case SDLK_KP_2: curvature = !curvature; apply_flags_to_dut(); break;
                        case SDLK_3: case SDLK_KP_3: extra_light = !extra_light; apply_flags_to_dut(); break;
                        case SDLK_o: diag_slice = !diag_slice; apply_flags_to_dut(); break;
                        case SDLK_y: spectrum_mode = !spectrum_mode; std::fprintf(stderr, "[hydra] spectrum_mode %s\n", spectrum_mode ? "ON" : "OFF"); break;
                        case SDLK_j: ray_jitter = !ray_jitter; apply_flags_to_dut(); break;
                        case SDLK_m: mouse_captured = !mouse_captured; update_mouse_capture(); break;
                        case SDLK_F3: safe_capture_mode = !safe_capture_mode; break;
                        case SDLK_F4: g_fog_enabled = !g_fog_enabled; std::fprintf(stderr, "[hydra] depth fog %s\n", g_fog_enabled ? "ON" : "OFF"); break;
                        case SDLK_F2: safe_defaults_mode = !safe_defaults_mode; apply_safe_defaults(); break;
                        case SDLK_F1: help_overlay_sticky = !help_overlay_sticky; if (!help_overlay_sticky && help_overlay_timer <= 0.0f) help_overlay_timer = 3.0f; break;
                        case SDLK_SLASH: help_overlay_timer = 4.0f; help_overlay_sticky = false; break;
                        case SDLK_f: if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) { selection_active = true; selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x); selection_y = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_y); selection_z = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_z); selection_word = static_cast<uint64_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_data); apply_selection_to_dut(); sel_miss_timer = 0.0f; } else { sel_miss_timer = 1.5f; } break;
                        case SDLK_g: selection_active = false; selection_word = 0; apply_selection_to_dut(); break;
                        case SDLK_h: hud_enabled = !hud_enabled; break;
                        case SDLK_t: hud_theme_light = !hud_theme_light; break;
                        case SDLK_r: pos_x = default_pos_x; pos_y = default_pos_y; pos_z = default_pos_z; yaw = default_yaw; pitch = default_pitch; smooth_surfaces = true; curvature = true; extra_light = false; diag_slice = false; selection_active = false; selection_word = 0; apply_camera_to_dut(); apply_flags_to_dut(); apply_selection_to_dut(); apply_safe_defaults(); break;
                        case SDLK_v: if (g_pixel_view_mode == PixelViewMode::Color) g_pixel_view_mode = PixelViewMode::Word0; else if (g_pixel_view_mode == PixelViewMode::Word0) g_pixel_view_mode = PixelViewMode::Word2; else if (g_pixel_view_mode == PixelViewMode::Word2) g_pixel_view_mode = PixelViewMode::SidebandMix; else g_pixel_view_mode = PixelViewMode::Color; break;
                        case SDLK_p: std::fprintf(stderr, "State: cam=(%.3f,%.3f,%.3f) yaw=%.3f pitch=%.3f flags[smooth=%d curv=%d extra=%d diag=%d] sel=%d (%u,%u,%u)\n", pos_x, pos_y, pos_z, yaw, pitch, smooth_surfaces ? 1 : 0, curvature ? 1 : 0, extra_light ? 1 : 0, diag_slice ? 1 : 0, selection_active ? 1 : 0, (unsigned)selection_x, (unsigned)selection_y, (unsigned)selection_z); break;
                        case SDLK_s: { auto now = std::chrono::system_clock::now(); auto secs = std::chrono::duration_cast<std::chrono::seconds>(now.time_since_epoch()).count(); char filename[256]; std::snprintf(filename, sizeof(filename), "sim/screenshot_%ld.ppm", secs); FILE* f = std::fopen(filename, "wb"); if (!f) std::fprintf(stderr, "Failed to open %s for screenshot\n", filename); else { std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT); for (int y = 0; y < SCREEN_HEIGHT; ++y) for (int x = 0; x < SCREEN_WIDTH; ++x) { uint32_t argb = framebuffer[size_t(y) * SCREEN_WIDTH + x]; uint8_t rgb[3] = { (uint8_t)((argb >> 16) & 0xFF), (uint8_t)((argb >> 8) & 0xFF), (uint8_t)(argb & 0xFF) }; std::fwrite(rgb, 1, 3, f); } std::fclose(f); std::fprintf(stderr, "Screenshot saved: %s\n", filename); } break; }

                    // Edit selected voxel
                    if (selection_active) {
                        uint64_t w = selection_word;
                        uint8_t material_props = (w >> 56) & 0xFF;
                        uint8_t emissive       = (w >> 48) & 0xFF;
                        uint8_t alpha          = (w >> 40) & 0xFF;
                        uint8_t light          = (w >> 32) & 0xFF;
                        uint8_t r              = (w >> 24) & 0xFF;
                        uint8_t g              = (w >> 16) & 0xFF;
                        uint8_t b              = (w >>  8) & 0xFF;
                        uint8_t material_type  = (w >>  4) & 0x0F;
                        bool do_write = false;
                        if (keycode == SDLK_c) { material_type = (material_type + 1) & 0x0F; w &= ~((uint64_t)0x0F << 4); w |= (uint64_t(material_type) << 4); do_write = true; }
                        else if (keycode == SDLK_x) { int val = emissive + 16; if (val > 255) val = 255; emissive = (uint8_t)val; w &= ~((uint64_t)0xFF << 48); w |= (uint64_t)emissive << 48; do_write = true; }
                        else if (keycode == SDLK_z) { int val = emissive - 16; if (val < 0) val = 0; emissive = (uint8_t)val; w &= ~((uint64_t)0xFF << 48); w |= (uint64_t)emissive << 48; do_write = true; }
                        else if (keycode == SDLK_b) { auto saturate_add = [](uint8_t c, int delta) -> uint8_t { int v = c + delta; if (v < 0) v = 0; if (v > 255) v = 255; return (uint8_t)v; }; r = saturate_add(r, 16); g = saturate_add(g, 16); b = saturate_add(b, 16); w &= ~(((uint64_t)0xFFFFFF) << 8); w |= ((uint64_t)r << 24) | ((uint64_t)g << 16) | ((uint64_t)b <<  8); do_write = true; }
                        if (do_write) { selection_word = w; uint32_t addr = voxel_addr_from_xyz(selection_x, selection_y, selection_z); root->voxel_framebuffer_top__DOT__dbg_write_addr = addr; root->voxel_framebuffer_top__DOT__dbg_write_data = w; root->voxel_framebuffer_top__DOT__dbg_write_en   = 1; }
                    }
                }
            } else if (ev.type == SDL_MOUSEMOTION && mouse_captured && !safe_capture_mode) {
                int dx = ev.motion.xrel; int dy = ev.motion.yrel; yaw += dx * mouse_sens; pitch += (invert_y_mouse ? dy : -dy) * mouse_sens; if (pitch >  1.50f) pitch =  1.50f; if (pitch < -1.50f) pitch = -1.50f; apply_camera_to_dut();
            }
        }

        bool cam_changed = false;
        float fdx = std::cos(yaw); float fdy = std::sin(yaw); float rdx = -std::sin(yaw); float rdy = std::cos(yaw);
        float cur_speed = keys.fast ? move_speed_fast : move_speed;
        if (!safe_capture_mode) {
            if (keys.forward)      { pos_x += fdx * cur_speed; pos_y += fdy * cur_speed; cam_changed = true; }
            if (keys.back)         { pos_x -= fdx * cur_speed; pos_y -= fdy * cur_speed; cam_changed = true; }
            if (keys.strafe_left)  { pos_x += rdx * cur_speed; pos_y += rdy * cur_speed; cam_changed = true; }
            if (keys.strafe_right) { pos_x -= rdx * cur_speed; pos_y -= rdy * cur_speed; cam_changed = true; }
            if (keys.down)         { pos_z -= cur_speed; cam_changed = true; }
            if (keys.up)           { pos_z += cur_speed; cam_changed = true; }
            if (keys.yaw_left)   { yaw   -= turn_speed_keys; cam_changed = true; }
            if (keys.yaw_right)  { yaw   += turn_speed_keys; cam_changed = true; }
            if (keys.pitch_up)   { pitch += turn_speed_keys; cam_changed = true; }
            if (keys.pitch_down) { pitch -= turn_speed_keys; cam_changed = true; }
        }
        if (pitch >  1.50f) pitch =  1.50f; if (pitch < -1.50f) pitch = -1.50f;
        if (cam_clamp_enabled) { if (pos_x < cam_min) pos_x = cam_min; if (pos_x > cam_max) pos_x = cam_max; if (pos_y < cam_min) pos_y = cam_min; if (pos_y > cam_max) pos_y = cam_max; if (pos_z < cam_min) pos_z = cam_min; if (pos_z > cam_max) pos_z = cam_max; }
        if (cam_changed) { apply_camera_to_dut(); if (log_keys && log_keys_count < 200) { std::fprintf(stderr, "cam pos=(%.2f, %.2f, %.2f) yaw=%.2f pitch=%.2f\n", pos_x, pos_y, pos_z, yaw, pitch); ++log_keys_count; } }
        apply_flags_to_dut();

        // Simulate HDL
        const int cycles_per_chunk = 2000; bool frame_done = false; std::chrono::high_resolution_clock::time_point sim_loop_start;
        if (render_instrument.active()) sim_loop_start = std::chrono::high_resolution_clock::now();

        for (int i = 0; i < cycles_per_chunk; ++i) {
            top->clk = 1; top->eval(); main_time++;
            if (top->pixel_write_en) {
                uint32_t addr = top->pixel_addr;
                if (addr < NPIX) {
                    uint32_t w0 = top->pixel_word0; uint32_t w1 = top->pixel_word1; uint32_t w2 = top->pixel_word2;
                    uint32_t pixel_value = pixel96_to_argb(w0, w1, w2);
                    uint8_t depth_byte = (w0 >> 16) & 0xFF;
                    if (g_fog_enabled) pixel_value = apply_fog(pixel_value, depth_byte);
                    framebuffer[addr] = pixel_value; record_color(frame_color_stats, pixel_value); frame_color_stats_dirty = true;
                    if (log_frames && log_pixel_samples < 512) {
                        uint32_t x = addr % SCREEN_WIDTH; uint32_t y = addr / SCREEN_WIDTH;
                        if (x == SCREEN_WIDTH / 2) { std::fprintf(stderr, "probe x=%u y=%u addr=%u w0=%08x w1=%08x w2=%08x argb=%08x\n", x, y, addr, w0, w1, w2, pixel_value); ++log_pixel_samples; }
                    }
                }
                ++pixels_this_frame;
            }
            if (top->frame_done) frame_done = true;
            top->clk = 0; top->eval(); main_time++;
        }

        if (frame_done) {
            std::chrono::high_resolution_clock::time_point sim_loop_end;
            if (render_instrument.active()) sim_loop_end = std::chrono::high_resolution_clock::now();
            size_t pixels_written_this_frame = pixels_this_frame;
            last_frame_color_stats = frame_color_stats; last_frame_color_stats_valid = frame_color_stats_dirty; frame_color_stats = color_range_default(); frame_color_stats_dirty = false;
            if (auto_exit) running = false;
            if (frame_dump_path && frame_dump_path[0] != '\0' && (max_frame_dumps == 0 || frame_dumps_written < max_frame_dumps)) {
                char pathbuf[512]; if (frame_dump_base && max_frame_dumps != 1) std::snprintf(pathbuf, sizeof(pathbuf), "%s_%d.ppm", frame_dump_base, frame_dumps_written); else std::snprintf(pathbuf, sizeof(pathbuf), "%s", frame_dump_path);
                FILE* f = std::fopen(pathbuf, "wb"); if (!f) std::fprintf(stderr, "Failed to open FRAME_DUMP '%s' for write\n", pathbuf); else { std::fprintf(stderr, "Writing frame dump to %s\n", pathbuf); std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT); for (int fy = 0; fy < SCREEN_HEIGHT; ++fy) for (int fx = 0; fx < SCREEN_WIDTH; ++fx) { uint32_t argb = framebuffer[size_t(fy) * SCREEN_WIDTH + fx]; uint8_t r = (argb >> 16) & 0xFF; uint8_t g = (argb >> 8)  & 0xFF; uint8_t b =  argb        & 0xFF; uint8_t rgb[3] = {r,g,b}; std::fwrite(rgb, 1, 3, f); } std::fclose(f); ++frame_dumps_written; if (max_frame_dumps > 0 && frame_dumps_written >= max_frame_dumps) std::fprintf(stderr, "Max frame dumps (%d) reached, disabling further FRAME_DUMP writes\n", max_frame_dumps); }
            }
            if (autosave_cfg && autosave_cfg[0] != '\0') { FILE* fcfg = std::fopen(autosave_cfg, "w"); if (!fcfg) std::fprintf(stderr, "Failed to write HYDRA_AUTOSAVE_CFG to '%s'\n", autosave_cfg); else { std::fprintf(fcfg, "cam_pos=%.3f,%.3f,%.3f\n", pos_x, pos_y, pos_z); std::fprintf(fcfg, "cam_ang=%.3f,%.3f\n", yaw, pitch); std::fprintf(fcfg, "flags=%d,%d,%d,%d\n", smooth_surfaces ? 1 : 0, curvature ? 1 : 0, extra_light ? 1 : 0, diag_slice ? 1 : 0); std::fprintf(fcfg, "seed=%u\n", world_seed_override); std::fprintf(fcfg, "safe_capture=%d\n", safe_capture_mode ? 1 : 0); std::fclose(fcfg); } }

            if (log_frames) { size_t nonzero = 0; for (uint32_t v : framebuffer) if (v != 0) ++nonzero; uint32_t sample0 = framebuffer.empty() ? 0 : framebuffer[0]; uint32_t sample_mid = framebuffer.empty() ? 0 : framebuffer[NPIX/2]; std::fprintf(stderr, "frame %zu done, pixels_written=%zu nonzero=%zu sample0=%08x mid=%08x\n", frame_counter, pixels_this_frame, nonzero, sample0, sample_mid); }
            ++frame_counter;

            auto now = std::chrono::high_resolution_clock::now(); float dt = std::chrono::duration<float>(now - last_frame_time).count();
            if (fps_target > 0.0f) { float target_dt = 1.0f / fps_target; if (dt < target_dt) { int delay_ms = static_cast<int>((target_dt - dt) * 1000.0f); if (delay_ms > 0) { SDL_Delay(delay_ms); dt += static_cast<float>(delay_ms) / 1000.0f; } } }
            last_frame_time = now; if (dt > 0.0f) fps = 1.0f / dt;

            if (render_instrument.active()) {
                // hud_present_end and copy timings are captured below around HUD draw / texture copy
            }

            if (!help_overlay_sticky && help_overlay_timer > 0.0f && dt > 0.0f) help_overlay_timer = std::max(0.0f, help_overlay_timer - dt);
            if (sel_miss_timer > 0.0f && dt > 0.0f) sel_miss_timer = std::max(0.0f, sel_miss_timer - dt);

            uint64_t mem_cycle = root->voxel_framebuffer_top__DOT__mem_cycle_count;
            uint64_t mem_read  = root->voxel_framebuffer_top__DOT__mem_read_cycles;
            uint64_t mem_write = root->voxel_framebuffer_top__DOT__mem_write_cycles;
            uint64_t dc = mem_cycle - prev_mem_cycle; uint64_t dr = mem_read - prev_mem_read; uint64_t dw = mem_write - prev_mem_write;
            prev_mem_cycle = mem_cycle; prev_mem_read = mem_read; prev_mem_write = mem_write;
            if (dc > 0) { last_mem_read_util = float(dr) / float(dc); last_mem_write_util = float(dw) / float(dc); }

            std::chrono::high_resolution_clock::time_point hud_present_start;
            if (render_instrument.active()) hud_present_start = std::chrono::high_resolution_clock::now();

            if (hud_enabled && font) {
                for (int y = SCREEN_HEIGHT - HUD_HEIGHT; y < SCREEN_HEIGHT; ++y) {
                    if (y < 0) continue;
                    for (int x = 0; x < SCREEN_WIDTH; ++x) {
                        uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
                        uint8_t r = (px >> 16) & 0xFF; uint8_t g = (px >> 8) & 0xFF; uint8_t b = px & 0xFF;
                        if (hud_theme_light) { r = static_cast<uint8_t>(r + (255 - r) / 4); g = static_cast<uint8_t>(g + (255 - g) / 4); b = static_cast<uint8_t>(b + (255 - b) / 4); }
                        else { r = static_cast<uint8_t>((r * 3) / 4); g = static_cast<uint8_t>((g * 3) / 4); b = static_cast<uint8_t>((b * 3) / 4); }
                        px = (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
                    }
                }

                char buf[256]; uint32_t hits = root->voxel_framebuffer_top__DOT__core_dbg_hit_count; uint32_t ray_steps_total = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_total; uint32_t ray_steps_max = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_max; uint32_t ray_miss_count = root->voxel_framebuffer_top__DOT__core_dbg_ray_miss_count;
                const float pixel_count = float(SCREEN_WIDTH) * float(SCREEN_HEIGHT);
                const float ray_steps_avg = pixel_count > 0.0f ? float(ray_steps_total) / pixel_count : 0.0f;
                const int hud_y = SCREEN_HEIGHT - HUD_HEIGHT + 4; int yoff = hud_y;
                SDL_Color hud_text_color = hud_theme_light ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};

                if (fps_target > 0.0f) std::snprintf(buf, sizeof(buf), "FPS %.1f / %.0f (target) | Pos %.1f %.1f %.1f", fps, fps_target, pos_x, pos_y, pos_z);
                else std::snprintf(buf, sizeof(buf), "FPS %.1f | Pos %.1f %.1f %.1f", fps, pos_x, pos_y, pos_z);
                draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Yaw %.2f  Pitch %.2f", yaw, pitch); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "[1] Smooth %s  [2] Curv %s  [3] Extra %s", smooth_surfaces ? "ON" : "OFF", curvature ? "ON" : "OFF", extra_light ? "ON" : "OFF"); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "[O] Slice %s  [J] Jitter %s  [M] Mouse %s", diag_slice ? "ON" : "OFF", ray_jitter ? "ON" : "OFF", mouse_captured ? "ON" : "OFF"); SDL_Color mouse_line_color = mouse_captured ? hud_text_color : SDL_Color{255, 96, 96, 255}; draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, mouse_line_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Hits %u | ray avg %.1f max %u miss %u", hits, ray_steps_avg, ray_steps_max, ray_miss_count); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Mem: rd %.1f%% wr %.1f%%", last_mem_read_util * 100.0f, last_mem_write_util * 100.0f); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                if (last_frame_color_stats_valid) std::snprintf(buf, sizeof(buf), "RGB range: R%3u-%3u  G%3u-%3u  B%3u-%3u", (unsigned)last_frame_color_stats.min_r, (unsigned)last_frame_color_stats.max_r, (unsigned)last_frame_color_stats.min_g, (unsigned)last_frame_color_stats.max_g, (unsigned)last_frame_color_stats.min_b, (unsigned)last_frame_color_stats.max_b);
                else std::snprintf(buf, sizeof(buf), "RGB range: capturing..."); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Pixel view: %s  [V] cycle", pixel_view_mode_name(g_pixel_view_mode)); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Safe defaults: %s [F2] (move %.3f/%.3f turn %.3f sens %.4f clamp %s)", safe_defaults_mode ? "ON" : "OFF", move_speed, move_speed_fast, turn_speed_keys, mouse_sens, cam_clamp_enabled ? "ON" : "OFF"); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                // Fog status (toggle with F4)
                std::snprintf(buf, sizeof(buf), "Fog: %s [F4] color=%06x density=%.2f", g_fog_enabled ? "ON" : "OFF", (g_fog_color & 0x00FFFFFFu), g_fog_density); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                std::snprintf(buf, sizeof(buf), "Safe capture: %s [F3] (input frozen)", safe_capture_mode ? "ON" : "OFF"); SDL_Color warn_color = safe_capture_mode ? SDL_Color{255, 128, 96, 255} : hud_text_color; draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, warn_color); yoff += 14;

                if (!g_backend_info.empty()) { draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, g_backend_info, 6, yoff, hud_text_color); yoff += 14; }

                if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) std::snprintf(buf, sizeof(buf), "Cursor: (%u,%u,%u) mat=0x%02X", (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_x, (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_y, (unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_z, (unsigned)(root->voxel_framebuffer_top__DOT__cursor_material_id & 0xFF));
                else std::snprintf(buf, sizeof(buf), "Cursor: (no hit)"); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                if (selection_active) std::snprintf(buf, sizeof(buf), "Sel: (%u,%u,%u)  [G] clear  [F] select", (unsigned)selection_x, (unsigned)selection_y, (unsigned)selection_z);
                else std::snprintf(buf, sizeof(buf), "Sel: (none)  (aim + F to select)"); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;

                if (selection_active) {
                    uint64_t w = selection_word; uint8_t material_props = (w >> 56) & 0xFF; uint8_t emissive = (w >> 48) & 0xFF; uint8_t alpha = (w >> 40) & 0xFF; uint8_t light = (w >> 32) & 0xFF; uint8_t r = (w >> 24) & 0xFF; uint8_t g = (w >> 16) & 0xFF; uint8_t b = (w >> 8) & 0xFF; uint8_t material_type = (w >> 4) & 0x0F;
                    std::snprintf(buf, sizeof(buf), "Probe RGBA %3u/%3u/%3u/%3u L%3u MT%u MP=%02X E%3u", r, g, b, alpha, light, material_type, material_props, emissive); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color); yoff += 14;
                    std::snprintf(buf, sizeof(buf), "Edit: [C] material  [X/Z] emissive  [B] brighten"); draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
                }
                if (sel_miss_timer > 0.0f) { std::snprintf(buf, sizeof(buf), "Selection miss: aim at geometry and press F"); SDL_Color warn = {255, 96, 96, 255}; draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff + 14, warn); }
            }

            if ((help_overlay_sticky || help_overlay_timer > 0.0f) && font) {
                const char* help_lines[] = {
                    "F1: toggle help overlay   /: show briefly",
                    "Move: WASD/QE + mouse (M toggles capture)  Shift=fast  F2: safe defaults",
                    "Flags: 1 smooth  2 curvature  3 extra  O diag slice  J jitter  T HUD theme",
                    "Select: F pick voxel  G clear  Edit: C material, X/Z emissive, B brighten",
                    "View: V cycle pixel view (color/word0/word2/sideband)  H HUD on/off",
                    "Misc: S screenshot  P print state  R reset  ESC quit"
                };
                int line_count = static_cast<int>(sizeof(help_lines) / sizeof(help_lines[0]));
                int box_x = 6, box_y = 6, box_w = std::min(360, SCREEN_WIDTH - 12), box_h = line_count * 14 + 10;
                for (int y = box_y; y < box_y + box_h && y < SCREEN_HEIGHT; ++y) for (int x = box_x; x < box_x + box_w && x < SCREEN_WIDTH; ++x) { uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x]; uint8_t r = (px >> 16) & 0xFF; uint8_t g = (px >> 8) & 0xFF; uint8_t b = px & 0xFF; if (hud_theme_light) { r = static_cast<uint8_t>(r + (255 - r) / 2); g = static_cast<uint8_t>(g + (255 - g) / 2); b = static_cast<uint8_t>(b + (255 - b) / 2); } else { r = static_cast<uint8_t>((r * 2) / 3); g = static_cast<uint8_t>((g * 2) / 3); b = static_cast<uint8_t>((b * 2) / 3); } px = (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b); }
                SDL_Color help_color = hud_theme_light ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};
                int help_y = box_y + 4; for (int i = 0; i < line_count; ++i) { draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, help_lines[i], box_x + 4, help_y, help_color); help_y += 14; }
            }

            if (!mouse_captured && font) { SDL_Color warn_color{255, 96, 96, 255}; int warn_x = SCREEN_WIDTH - 210; int warn_y = 8; draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, "Mouse capture OFF (press M)", warn_x, warn_y, warn_color); }

            if (use_platform_present) present_backend(backend, plat_ctx, framebuffer.data(), SCREEN_WIDTH, SCREEN_HEIGHT);

            std::chrono::high_resolution_clock::time_point hud_present_end;
            if (render_instrument.active()) hud_present_end = std::chrono::high_resolution_clock::now();

            std::chrono::high_resolution_clock::time_point copy_start;
            if (render_instrument.active()) copy_start = std::chrono::high_resolution_clock::now();
            void* pixels = nullptr; int pitch_bytes = 0; if (SDL_LockTexture(tex, nullptr, &pixels, &pitch_bytes) != 0) die("LockTexture failed");
            for (int y = 0; y < SCREEN_HEIGHT; ++y) { uint32_t* row = (uint32_t*)((uint8_t*)pixels + y * pitch_bytes); std::memcpy(row, &framebuffer[size_t(y)*SCREEN_WIDTH], SCREEN_WIDTH * sizeof(uint32_t)); }
            SDL_UnlockTexture(tex);

            SDL_SetRenderDrawColor(ren, 0, 0, 0, 255); SDL_RenderClear(ren); SDL_RenderCopy(ren, tex, nullptr, nullptr); SDL_RenderPresent(ren);

            std::chrono::high_resolution_clock::time_point copy_end;
            if (render_instrument.active()) copy_end = std::chrono::high_resolution_clock::now();

            if (clear_each_frame || pixels_written_this_frame < NPIX) std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
            pixels_this_frame = 0;

            if (render_instrument.active()) render_instrument.record(frame_counter, fps, std::chrono::duration<double, std::milli>(sim_loop_end - sim_loop_start).count(), std::chrono::duration<double, std::milli>(hud_present_end - hud_present_start).count(), std::chrono::duration<double, std::milli>(copy_end - copy_start).count(), static_cast<double>(dt * 1000.0));
        }

        if (idle_ms > 0) SDL_Delay(idle_ms);
    }

    top->final(); delete top;
    if (use_platform_present) shutdown_backend(backend, plat_ctx);
    std::fprintf(stderr, "[hydra] exit summary: backend=%s vsync=%s frames_rendered=%zu\n", backend_name(backend), g_vsync ? "on" : "off", frame_counter);
    if (font) TTF_CloseFont(font); TTF_Quit(); SDL_DestroyTexture(tex); SDL_DestroyRenderer(ren); SDL_DestroyWindow(win); SDL_Quit();
    return 0;
}
// ============================================================================
// sim/viewer.cpp
// Verilator + SDL2 live viewer for voxel_framebuffer_top
// ============================================================================

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"
#include "Vvoxel_framebuffer_top___024root.h"
#include "platform/backend_selector.h"
#include "platform/platform.h"

#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <cmath>
#include <chrono>
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <cctype>
#include <fstream>
#include <filesystem>
#include <strings.h>
#include <unistd.h>

struct ColorRange {
	uint8_t min_r;
	uint8_t min_g;
	uint8_t min_b;
	uint8_t max_r;
	uint8_t max_g;
	uint8_t max_b;
};

static ColorRange color_range_default() {
	return ColorRange{0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00};
}

static void record_color(ColorRange& range, uint32_t argb) {
	uint8_t r = (argb >> 16) & 0xFF;
	uint8_t g = (argb >>  8) & 0xFF;
	uint8_t b = (argb      ) & 0xFF;
	// ============================================================================
	// sim/viewer.cpp
	// Verilator + SDL2 live viewer for voxel_framebuffer_top
	// ============================================================================

	#include <SDL2/SDL.h>
	#include <SDL2/SDL_ttf.h>
	#include <verilated.h>
	#include "Vvoxel_framebuffer_top.h"
	#include "Vvoxel_framebuffer_top___024root.h"
	#include "platform/backend_selector.h"
	#include "platform/platform.h"

	#include <cstdint>
	#include <cstdio>
	#include <vector>
	#include <string>
	#include <cmath>
	#include <chrono>
	#include <algorithm>
	#include <cstring>
	#include <cstdlib>
	#include <cctype>
	#include <fstream>
	#include <filesystem>
	#include <strings.h>
	#include <unistd.h>

	struct ColorRange {
		uint8_t min_r;
		uint8_t min_g;
		uint8_t min_b;
		uint8_t max_r;
		uint8_t max_g;
		uint8_t max_b;
	};

	static ColorRange color_range_default() {
		return ColorRange{0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00};
	}

	static void record_color(ColorRange& range, uint32_t argb) {
		uint8_t r = (argb >> 16) & 0xFF;
		uint8_t g = (argb >>  8) & 0xFF;
		uint8_t b = (argb      ) & 0xFF;
		range.min_r = std::min(range.min_r, r);
		range.min_g = std::min(range.min_g, g);
		range.min_b = std::min(range.min_b, b);
		range.max_r = std::max(range.max_r, r);
		range.max_g = std::max(range.max_g, g);
		range.max_b = std::max(range.max_b, b);
	}

	static const int   SCREEN_WIDTH  = 480;
	static const int   SCREEN_HEIGHT = 360;
	static const int   HUD_HEIGHT    = 80;
	static const float FX            = 256.0f;  // fixed-point scale
	static bool        g_vsync       = true;

	vluint64_t main_time = 0;
	double sc_time_stamp() { return main_time; }

	enum class PixelViewMode {
		Color = 0,
		Word0,
		Word2,
		SidebandMix,
	};

	static PixelViewMode g_pixel_view_mode = PixelViewMode::Color;

	static const char* pixel_view_mode_name(PixelViewMode m) {
		switch (m) {
			case PixelViewMode::Color:      return "color";
			case PixelViewMode::Word0:      return "word0";
			case PixelViewMode::Word2:      return "word2";
			case PixelViewMode::SidebandMix:return "sideband";
			default:                        return "unknown";
		}
	}

	static PixelViewMode pixel_view_from_string(const char* s) {
		if (!s) return PixelViewMode::Color;
		if (strcasecmp(s, "color") == 0)    return PixelViewMode::Color;
		if (strcasecmp(s, "word0") == 0)    return PixelViewMode::Word0;
		if (strcasecmp(s, "depth") == 0)    return PixelViewMode::Word0;
		if (strcasecmp(s, "word2") == 0)    return PixelViewMode::Word2;
		if (strcasecmp(s, "reemissure") == 0|| strcasecmp(s, "reem") == 0) return PixelViewMode::Word2;
		if (strcasecmp(s, "sideband") == 0) return PixelViewMode::SidebandMix;
		return PixelViewMode::Color;
	}

	static uint32_t visualize_word(uint32_t w) {
		uint8_t r = (w >> 24) & 0xFF;
		uint8_t g = (w >> 16) & 0xFF;
		uint8_t b = (w >>  8) & 0xFF;
		// If the upper bytes are zero, fall back to showing the low byte so the view is not blank.
		if (r == 0 && g == 0 && b == 0) {
			uint8_t lsb = w & 0xFF;
			r = g = b = lsb;
		}
		return (0xFFu << 24) |
			   (uint32_t(r) << 16) |
			   (uint32_t(g) << 8)  |
				uint32_t(b);
	}

	static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
		switch (g_pixel_view_mode) {
			case PixelViewMode::Color: {
				uint8_t r = (w1 >> 24) & 0xFF;
				uint8_t g = (w1 >> 16) & 0xFF;
				uint8_t b = (w1 >>  8) & 0xFF;
				return (0xFFu << 24) |
					   (uint32_t(r) << 16) |
					   (uint32_t(g) << 8)  |
						uint32_t(b);
			}
			case PixelViewMode::Word0:
				return visualize_word(w0);
			case PixelViewMode::Word2:
				return visualize_word(w2);
			case PixelViewMode::SidebandMix: {
				uint8_t depth_like = (w0 >> 16) & 0xFF;
				uint8_t emissive   = (w2 >> 16) & 0xFF;
				uint8_t diag_bits  = (w0 >> 8)  & 0xFF;
				return (0xFFu << 24) |
					   (uint32_t(emissive)   << 16) |
					   (uint32_t(depth_like) << 8)  |
						uint32_t(diag_bits);
			}
			default:
				return visualize_word(w1);
		}
	}

	// Depth-fog configuration and application
	static bool g_fog_enabled = false;
	static uint32_t g_fog_color = 0xFFE0E0E0; // ARGB
	static float g_fog_density = 1.0f; // linear density multiplier

	static uint32_t apply_fog(uint32_t src_argb, uint8_t depth_byte) {
		if (!g_fog_enabled) return src_argb;
		float d = static_cast<float>(depth_byte) / 255.0f; // 0..1, 0=near,1=far
		// simple linear/exponential blend control
		float factor = d * g_fog_density;
		if (factor > 1.0f) factor = 1.0f;

		uint8_t sr = (src_argb >> 16) & 0xFF;
		uint8_t sg = (src_argb >> 8)  & 0xFF;
		uint8_t sb =  src_argb        & 0xFF;

		uint8_t fr = (g_fog_color >> 16) & 0xFF;
		uint8_t fg = (g_fog_color >> 8)  & 0xFF;
		uint8_t fb =  g_fog_color        & 0xFF;

		uint8_t rr = static_cast<uint8_t>(sr * (1.0f - factor) + fr * factor);
		uint8_t gg = static_cast<uint8_t>(sg * (1.0f - factor) + fg * factor);
		uint8_t bb = static_cast<uint8_t>(sb * (1.0f - factor) + fb * factor);

		return (0xFFu << 24) | (uint32_t(rr) << 16) | (uint32_t(gg) << 8) | uint32_t(bb);
	}

	static uint32_t spectrum_pixel(uint32_t addr) {
		uint32_t x = addr % SCREEN_WIDTH;
		uint32_t y = addr / SCREEN_WIDTH;
		uint8_t r = (x * 255) / (SCREEN_WIDTH - 1);
		uint8_t g = (y * 255) / (SCREEN_HEIGHT - 1);
		uint8_t b = ((x + y) * 255) / ((SCREEN_WIDTH + SCREEN_HEIGHT) - 2);
		return (0xFFu << 24) | (uint32_t(r) << 16) | (uint32_t(g) << 8) | uint32_t(b);
	}

	static inline uint32_t voxel_addr_from_xyz(uint8_t x, uint8_t y, uint8_t z) {
		return (uint32_t(x) << 12) | (uint32_t(y) << 6) | uint32_t(z);
	}

	static bool env_truthy(const char* key) {
		if (const char* v = std::getenv(key)) {
			return v[0] != '\0' && v[0] != '0' && strcasecmp(v, "false") != 0;
		}
		return false;
	}

	static void apply_cli_overrides(int argc, char** argv) {
		auto missing_value = [](const char* flag) {
			std::fprintf(stderr, "[hydra] Missing value for %s\n", flag);
		};
		auto set_override = [](const char* key, const char* value, const char* note = nullptr) {
			if (!value) return;
			setenv(key, value, 1);
			if (note) {
				std::fprintf(stderr, "[hydra] CLI override: %s=%s (%s)\n", key, value, note);
			} else {
				std::fprintf(stderr, "[hydra] CLI override: %s=%s\n", key, value);
			}
		};
		auto match_arg = [&](const char* arg, const char* long_flag, int& i) -> const char* {
			size_t len = std::strlen(long_flag);
			if (std::strncmp(arg, long_flag, len) != 0)
				return nullptr;
			if (arg[len] == '=') {
				return arg + len + 1;
			}
			if (i + 1 < argc) {
				return argv[++i];
			}
			missing_value(long_flag);
			return nullptr;
		};

		bool show_caps = false;

		for (int i = 1; i < argc; ++i) {
			const char* arg = argv[i];
			if (!arg) continue;
			if (std::strcmp(arg, "--show-capabilities") == 0 || std::strcmp(arg, "--caps") == 0) {
				show_caps = true;
			} else if (std::strcmp(arg, "--quiet") == 0 || std::strcmp(arg, "-q") == 0) {
				setenv("HYDRA_QUIET", "1", 1);
			} else if (std::strcmp(arg, "--verbose") == 0 || std::strcmp(arg, "-v") == 0) {
				setenv("HYDRA_VERBOSE", "1", 1);
			} else if ((std::strcmp(arg, "--backend") == 0 || std::strcmp(arg, "-b") == 0) && i + 1 < argc) {
				const char* val = argv[++i];
				setenv("HYDRA_BACKEND", val, 1);
				std::fprintf(stderr, "[hydra] CLI override: backend=%s\n", val);
			} else if (const char* val = match_arg(arg, "--backend", i)) {
				set_override("HYDRA_BACKEND", val);
			} else if ((std::strcmp(arg, "--sdl-driver") == 0 || std::strcmp(arg, "--video-driver") == 0) && i + 1 < argc) {
				const char* val = argv[++i];
				setenv("SDL_VIDEODRIVER", val, 1);
				std::fprintf(stderr, "[hydra] CLI override: SDL_VIDEODRIVER=%s\n", val);
			} else if (const char* val = match_arg(arg, "--sdl-driver", i)) {
				set_override("SDL_VIDEODRIVER", val, "SDL video driver");
			} else if (const char* val = match_arg(arg, "--video-driver", i)) {
				set_override("SDL_VIDEODRIVER", val, "SDL video driver");
			} else if (std::strcmp(arg, "--instrument") == 0) {
				setenv("HYDRA_RENDER_INSTRUMENT", "1", 1);
				std::fprintf(stderr, "[hydra] CLI override: render instrumentation enabled\n");
			} else if (const char* val = match_arg(arg, "--cam-pos", i)) {
				set_override("HYDRA_CAM_POS", val, "camera position (x,y,z)");
			} else if (const char* val = match_arg(arg, "--cam-ang", i)) {
				set_override("HYDRA_CAM_ANG", val, "camera yaw,pitch");
			} else if (const char* val = match_arg(arg, "--move-speed", i)) {
				set_override("HYDRA_MOVE_SPEED", val, "move speed");
			} else if (const char* val = match_arg(arg, "--move-speed-fast", i)) {
				set_override("HYDRA_MOVE_SPEED_FAST", val, "fast move speed");
			} else if (const char* val = match_arg(arg, "--turn-speed", i)) {
				set_override("HYDRA_TURN_SPEED_KEYS", val, "key turn speed");
			} else if (const char* val = match_arg(arg, "--mouse-sens", i)) {
				set_override("HYDRA_MOUSE_SENS", val, "mouse sensitivity");
			} else if (const char* val = match_arg(arg, "--fps-target", i)) {
				set_override("HYDRA_FPS_TARGET", val, "frame pacing target");
			} else if (const char* val = match_arg(arg, "--pixel-view", i)) {
				set_override("HYDRA_PIXEL_VIEW", val, "pixel view mode");
			} else if (const char* val = match_arg(arg, "--seed", i)) {
				set_override("HYDRA_WORLD_SEED", val, "world/procedural seed");
			}
		}

		if (show_caps) {
			platform_log_capabilities();
			std::exit(0);
		}
	}

	static std::string g_backend_info;

	static const char* backend_name(PlatformBackend b) {
		switch (b) {
			case PlatformBackend::SDL:    return "SDL";
			case PlatformBackend::GL:     return "GL";
			case PlatformBackend::Vulkan: return "Vulkan";
			case PlatformBackend::Wayland:return "Wayland";
			case PlatformBackend::X11:    return "X11";
			case PlatformBackend::Fbdev:  return "fbdev";
			case PlatformBackend::Win32:  return "Win32";
			case PlatformBackend::MacOS:  return "macOS";
			case PlatformBackend::Headless: return "Headless";
			default: return "Unknown";
		}
	}

	static void log_backend_caps(PlatformBackend requested, PlatformBackend backend, bool vsync) {
		const char* video_driver = SDL_GetCurrentVideoDriver();
		const char* render_driver = SDL_GetHint(SDL_HINT_RENDER_DRIVER);

		std::fprintf(stderr,
			"[hydra] backend requested=%s actual=%s vsync=%s video_driver=%s render_driver=%s\n",
			backend_name(requested),
			backend_name(backend),
			vsync ? "on" : "off",
			video_driver ? video_driver : "(unknown)",
			render_driver ? render_driver : "(default)");

		std::fprintf(stderr, "[hydra] compiled backends: SDL");
	#ifdef HYDRA_ENABLE_GL
		std::fprintf(stderr, " GL");
	#endif
	#ifdef HYDRA_ENABLE_VULKAN
		std::fprintf(stderr, " Vulkan");
	#endif
	#ifdef HYDRA_ENABLE_WAYLAND
		std::fprintf(stderr, " Wayland");
	#endif
	#ifdef HYDRA_ENABLE_X11
		std::fprintf(stderr, " X11");
	#endif
		std::fprintf(stderr, " Headless\n");
	}

	static void log_input_caps() {
		const char* grab_hint = SDL_GetHint(SDL_HINT_GRAB_KEYBOARD);
		const char* mouse_hint = SDL_GetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP);

		int joysticks = SDL_NumJoysticks();
		int controllers = 0;
		for (int i = 0; i < joysticks; ++i) {
			if (SDL_IsGameController(i)) {
				++controllers;
			}
		}

		int touch_devices = SDL_GetNumTouchDevices();

		std::fprintf(stderr,
			"[hydra] input: keyboard=assumed mouse_capture_hint=%s mouse_relative_hint=%s touch_devices=%d joysticks=%d controllers=%d\n",
			grab_hint ? grab_hint : "(default)",
			mouse_hint ? mouse_hint : "(default)",
			touch_devices,
			joysticks,
			controllers);
	}

	struct InputState {
		bool forward     = false;
		bool back        = false;
		bool strafe_left = false;
		bool strafe_right = false;
		bool up          = false;
		bool down        = false;
		bool yaw_left    = false;
		bool yaw_right   = false;
		bool pitch_up    = false;
		bool pitch_down  = false;
		bool fast        = false;
	};

	static inline void update_key_state(InputState& keys, SDL_Scancode sc,
										SDL_Keycode keycode, bool pressed) {
		switch (sc) {
			case SDL_SCANCODE_W: keys.forward      = pressed; break;
			case SDL_SCANCODE_S: keys.back         = pressed; break;
			case SDL_SCANCODE_A: keys.strafe_left  = pressed; break;
			case SDL_SCANCODE_D: keys.strafe_right = pressed; break;
			case SDL_SCANCODE_Q: keys.down         = pressed; break;
			case SDL_SCANCODE_E: keys.up           = pressed; break;
			case SDL_SCANCODE_LEFT:  keys.yaw_left  = pressed; break;
			case SDL_SCANCODE_RIGHT: keys.yaw_right = pressed; break;
			case SDL_SCANCODE_UP:    keys.pitch_up  = pressed; break;
			case SDL_SCANCODE_DOWN:  keys.pitch_down= pressed; break;
			case SDL_SCANCODE_LSHIFT:
			case SDL_SCANCODE_RSHIFT: keys.fast     = pressed; break;
			default: break;
		}

		// Fallback to keycodes in case scancodes are missing or unusual.
		SDL_Keycode kc = keycode;
		if (kc >= 'A' && kc <= 'Z')
			kc = kc - 'A' + 'a';

		switch (kc) {
			case SDLK_w: keys.forward      = pressed; break;
			case SDLK_s: keys.back         = pressed; break;
			case SDLK_a: keys.strafe_left  = pressed; break;
			case SDLK_d: keys.strafe_right = pressed; break;
			case SDLK_q: keys.down         = pressed; break;
			case SDLK_e: keys.up           = pressed; break;
			case SDLK_LEFT:  keys.yaw_left  = pressed; break;
			case SDLK_RIGHT: keys.yaw_right = pressed; break;
			case SDLK_UP:    keys.pitch_up  = pressed; break;
			case SDLK_DOWN:  keys.pitch_down= pressed; break;
			case SDLK_LSHIFT:
			case SDLK_RSHIFT: keys.fast     = pressed; break;
			default: break;
		}
	}

	static void die(const std::string& s) {
		std::fprintf(stderr, "Error: %s\n", s.c_str());
		std::exit(1);
	}

	static void draw_text_to_fb(std::vector<uint32_t>& fb, int fb_w, int fb_h,
								 TTF_Font* font,
								 const std::string& txt,
								 int x, int y,
								 SDL_Color color = {255,255,255,255})
	{
		SDL_Surface* surf = TTF_RenderText_Blended(font, txt.c_str(), color);
		if (!surf) return;

		SDL_PixelFormat* fmt = surf->format;
		if (!fmt || fmt->BytesPerPixel != 4) {
			SDL_Surface* conv = SDL_ConvertSurfaceFormat(surf, SDL_PIXELFORMAT_ARGB8888, 0);
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

	static std::string flatten_cli_args(int argc, char** argv) {
		std::string out;
		for (int i = 0; i < argc; ++i) {
			if (i) out += ' ';
			if (argv[i]) {
				out += argv[i];
			}
		}
		return out;
	}

	struct RenderInstrumentationConfig {
		float cam_pos_x = 0.0f;
		float cam_pos_y = 0.0f;
		float cam_pos_z = 0.0f;
		float yaw = 0.0f;
		float pitch = 0.0f;
		bool smooth_surfaces = false;
		bool curvature = false;
		bool extra_light = false;
		bool diag_slice = false;
		bool ray_jitter = false;
		bool hud_enabled = true;
		float fps_target = 0.0f;
		bool vsync = true;
		std::string backend_name;
		std::string backend_info;
		std::string pixel_view;
	};

	struct RenderInstrumentation {
		RenderInstrumentation(bool enabled, std::string command_line)
			: enabled_(enabled), command_line_(std::move(command_line)) {
			if (!enabled_)
				return;
			std::filesystem::create_directories("out");
			csv_.open("out/render_pipeline_baseline.csv", std::ios::app);
			if (!csv_)
				die("failed to open out/render_pipeline_baseline.csv for instrumentation logging");
			if (csv_.tellp() == 0)
				csv_ << "frame,timestamp_ms,fps,ray_loop_ms,hud_present_ms,framebuffer_copy_ms,frame_total_ms\n";
		}

		bool active() const { return enabled_; }

		void write_config(const RenderInstrumentationConfig& cfg) {
			if (!enabled_)
				return;
			std::ofstream cfg_out("out/render_pipeline_baseline.cfg");
			if (!cfg_out)
				die("failed to write out/render_pipeline_baseline.cfg");
			cfg_out << "instrument_command=" << command_line_ << "\n";
			cfg_out << "backend=" << cfg.backend_name << "\n";
			cfg_out << "backend_info=" << cfg.backend_info << "\n";
			cfg_out << "pixel_view=" << cfg.pixel_view << "\n";
			cfg_out << "camera_pos=" << cfg.cam_pos_x << "," << cfg.cam_pos_y << "," << cfg.cam_pos_z << "\n";
			cfg_out << "camera_ang=" << cfg.yaw << "," << cfg.pitch << "\n";
			cfg_out << "flags=smooth:" << (cfg.smooth_surfaces ? "1" : "0")
					<< ",curvature:" << (cfg.curvature ? "1" : "0")
					<< ",extra_light:" << (cfg.extra_light ? "1" : "0")
					<< ",diag_slice:" << (cfg.diag_slice ? "1" : "0")
					<< ",ray_jitter:" << (cfg.ray_jitter ? "1" : "0") << "\n";
			cfg_out << "hud_enabled=" << (cfg.hud_enabled ? "1" : "0") << "\n";
			cfg_out << "fps_target=" << cfg.fps_target << "\n";
			cfg_out << "vsync=" << (cfg.vsync ? "1" : "0") << "\n";
		}

		void record(uint64_t frame,
					double fps,
					double ray_loop_ms,
					double hud_present_ms,
					double framebuffer_copy_ms,
					double frame_total_ms) {
			if (!enabled_)
				return;
			auto now = std::chrono::system_clock::now();
			auto ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
			csv_ << frame << ',' << ts_ms << ',' << fps << ','
				 << ray_loop_ms << ',' << hud_present_ms << ','
				 << framebuffer_copy_ms << ',' << frame_total_ms << '\n';
			csv_.flush();
		}

	private:
		bool enabled_;
		std::ofstream csv_;
		std::string command_line_;
	};

	int main(int argc, char** argv) {
		Verilated::commandArgs(argc, argv);
		apply_cli_overrides(argc, argv);

		const bool render_instrument_mode = env_truthy("HYDRA_RENDER_INSTRUMENT");
		RenderInstrumentation render_instrument(render_instrument_mode, flatten_cli_args(argc, argv));

		Vvoxel_framebuffer_top* top = new Vvoxel_framebuffer_top;
		auto* root = top->rootp;  // Access internal regs exposed by Verilator
		top->clk   = 0;
		top->rst_n = 0;
		// Default AXI shell inputs (unused in this harness)
		top->cam_load        = 0;
		top->cam_x_in        = 0;
		top->cam_y_in        = 0;
		top->cam_z_in        = 0;
		top->cam_dir_x_in    = 0;
		top->cam_dir_y_in    = 0;
		top->cam_dir_z_in    = 0;
		top->cam_plane_x_in  = 0;
		top->cam_plane_y_in  = 0;
		top->flags_load      = 0;
		top->flag_smooth_in  = 0;
		top->flag_curvature_in = 0;
		top->flag_extra_light_in = 0;
		top->flag_diag_slice_in  = 0;
		top->sel_load        = 0;
		top->sel_active_in   = 0;
		top->sel_voxel_x_in  = 0;
		top->sel_voxel_y_in  = 0;
		top->sel_voxel_z_in  = 0;
		top->dbg_ext_write_en   = 0;
		top->dbg_ext_write_addr = 0;
		top->dbg_ext_write_data = 0;
		top->start_frame_ext   = 0;
		top->soft_reset_ext    = 0;

		const bool log_keys = (std::getenv("LOG_KEYS") != nullptr);
		const bool log_frames = (std::getenv("LOG_FRAMES") != nullptr);
		int log_keys_count = 0;
		size_t pixels_this_frame = 0;
		size_t frame_counter = 0;
		int log_pixel_samples = 0;
		uint64_t prev_mem_cycle = 0;
		uint64_t prev_mem_read  = 0;
		uint64_t prev_mem_write = 0;
		float last_mem_read_util  = 0.0f;
		float last_mem_write_util = 0.0f;
		ColorRange frame_color_stats = color_range_default();
		ColorRange last_frame_color_stats = frame_color_stats;
		bool frame_color_stats_dirty = false;
		bool last_frame_color_stats_valid = false;

		// Configure depth fog from environment
		g_fog_enabled = env_truthy("HYDRA_FOG");
		if (const char* fog_col = std::getenv("HYDRA_FOG_COLOR")) {
			// accept formats like "0xRRGGBB" or "RRGGBB"
			unsigned long v = std::strtoul(fog_col, nullptr, 0);
			g_fog_color = 0xFF000000u | (uint32_t(v) & 0x00FFFFFFu);
		}
		if (const char* fog_den = std::getenv("HYDRA_FOG_DENSITY")) {
			char* endptr = nullptr;
			float d = std::strtof(fog_den, &endptr);
			if (endptr && endptr != fog_den) g_fog_density = d;
		}
		if (g_fog_enabled) {
			std::fprintf(stderr, "[hydra] Depth fog enabled color=%08x density=%.3f\n", g_fog_color, g_fog_density);
		}

		// Ensure SDL grabs keyboard focus; allow renderer selection via SDL hints/env.
		SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1");
		SDL_SetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP, "1");

		if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
			die(std::string("SDL_Init: ") + SDL_GetError());
		if (TTF_Init() != 0)
			die(std::string("TTF_Init: ") + TTF_GetError());

		// Platform backend selection (HYDRA_BACKEND env respected inside select_default_backend).
		PlatformBackend requested_backend = select_default_backend();
		const bool headless_backend = (requested_backend == PlatformBackend::Headless);
		if (headless_backend) {
			// Force SDL to a dummy driver so no window/display server is required.
			setenv("SDL_VIDEODRIVER", "dummy", 0);
			setenv("SDL_AUDIODRIVER", "dummy", 0);
		}

		log_input_caps();

		if (std::getenv("HYDRA_VSYNC")) {
			g_vsync = env_truthy("HYDRA_VSYNC");
		}
		PlatformBackend backend = PlatformBackend::SDL;
		PlatformContext plat_ctx;
		bool use_platform_present = false;

		// Track if we had to fallback from requested backend
		bool backend_fallback = false;
		PlatformBackend attempted_backend = requested_backend;

		if (requested_backend != PlatformBackend::SDL) {
			if (!platform_backend_supported(requested_backend)) {
				std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' is not supported on this platform\n",
							 backend_name(requested_backend));
				std::fprintf(stderr, "[hydra] REASON: Backend not compiled in or platform incompatible\n");
				std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");
				std::fprintf(stderr, "[hydra] TIP: Run './sim_voxel --caps' to see available backends\n\n");
				backend_fallback = true;
			} else {
				PlatformConfig plat_cfg;
				plat_cfg.width  = SCREEN_WIDTH;
				plat_cfg.height = SCREEN_HEIGHT;
				plat_cfg.vsync  = true;

				std::fprintf(stderr, "[hydra] Initializing %s backend...\n", backend_name(requested_backend));

				if (init_backend(requested_backend, plat_cfg, plat_ctx)) {
					backend = requested_backend;
					use_platform_present = true;
					std::fprintf(stderr, "[hydra] SUCCESS: %s backend initialized\n", backend_name(backend));
				} else {
					std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' initialization failed\n",
								 backend_name(requested_backend));
					std::fprintf(stderr, "[hydra] REASON: Check stderr above for specific error messages\n");
					std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");

					// Provide specific hints based on backend
					if (requested_backend == PlatformBackend::GL) {
						std::fprintf(stderr, "[hydra] TIP: Install OpenGL drivers or try HYDRA_BACKEND=sdl\n");
					} else if (requested_backend == PlatformBackend::Vulkan) {
						std::fprintf(stderr, "[hydra] TIP: Install Vulkan drivers or try HYDRA_BACKEND=gl\n");
					} else if (requested_backend == PlatformBackend::Wayland || requested_backend == PlatformBackend::X11) {
						std::fprintf(stderr, "[hydra] TIP: Check DISPLAY env var or try HYDRA_BACKEND=sdl\n");
					}
					std::fprintf(stderr, "\n");
					backend_fallback = true;
				}
			}
		}

		if (backend == PlatformBackend::SDL) {
			std::fprintf(stderr, "[hydra] Using SDL backend%s\n",
						 backend_fallback ? " (fallback)" : " (default)");
		}

		log_backend_caps(requested_backend, backend, g_vsync);

		SDL_Window* win = SDL_CreateWindow(
			"Voxel Accelerator — Interactive Raycaster",
			SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
			SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2,
			SDL_WINDOW_RESIZABLE
		);
		if (!win) die("Cannot create SDL window");
		SDL_RaiseWindow(win);

		uint32_t sdl_renderer_flags = SDL_RENDERER_ACCELERATED;
		if (g_vsync) sdl_renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
		SDL_Renderer* ren = SDL_CreateRenderer(win, -1, sdl_renderer_flags);
		if (!ren) die("Renderer creation failed");

		SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);

		SDL_RendererInfo ren_info;
		if (SDL_GetRendererInfo(ren, &ren_info) == 0) {
			std::fprintf(stderr, "Renderer: %s\n", ren_info.name ? ren_info.name : "(unknown)");
			const char* video_driver = SDL_GetCurrentVideoDriver();
			char buf[160];
			std::snprintf(buf, sizeof(buf), "Backend: %s (vsync %s) renderer=%s video=%s",
						  backend_name(backend),
						  g_vsync ? "on" : "off",
						  ren_info.name ? ren_info.name : "(unknown)",
						  video_driver ? video_driver : "(unknown)");
			g_backend_info = buf;
		}

		SDL_Texture* tex = SDL_CreateTexture(
			ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
			SCREEN_WIDTH, SCREEN_HEIGHT
		);
		if (!tex) die("Texture creation failed");

		auto recreate_texture = [&]() {
			if (tex) {
				SDL_DestroyTexture(tex);
				tex = nullptr;
			}
			tex = SDL_CreateTexture(
				ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
				SCREEN_WIDTH, SCREEN_HEIGHT
			);
			if (!tex) die("Texture recreation failed");
		};

		const char* font_env = std::getenv("HYDRA_FONT");
		const char* font_scale_env = std::getenv("HYDRA_FONT_SCALE");
		int font_size = 11;
		if (font_scale_env) {
			float scale = std::atof(font_scale_env);
			if (scale < 0.5f) scale = 0.5f;
			if (scale > 3.0f) scale = 3.0f;
			font_size = std::max(8, static_cast<int>(11 * scale));
		}

		// Fallback font search paths for different platforms
		const char* font_search_paths[] = {
			font_env,  // User override first
			// Debian/Ubuntu
			"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
			"/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
			// Fedora/RHEL
			"/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
			"/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
			// Arch
			"/usr/share/fonts/TTF/DejaVuSans.ttf",
			"/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
			// FreeBSD
			"/usr/local/share/fonts/dejavu/DejaVuSans.ttf",
			"/usr/local/share/fonts/Liberation/LiberationSans-Regular.ttf",
			// macOS
			"/System/Library/Fonts/Helvetica.ttc",
			"/Library/Fonts/Arial.ttf",
			"/System/Library/Fonts/SFNSText.ttf",
			// Windows (if running under WSL or similar)
			"/mnt/c/Windows/Fonts/arial.ttf",
			"/mnt/c/Windows/Fonts/Arial.ttf",
			"C:\\Windows\\Fonts\\arial.ttf",
			nullptr
		};

		TTF_Font* font = nullptr;
		const char* font_path = nullptr;

		for (int i = 0; font_search_paths[i] != nullptr; ++i) {
			if (font_search_paths[i] == nullptr || font_search_paths[i][0] == '\0')
				continue;

			font = TTF_OpenFont(font_search_paths[i], font_size);
			if (font) {
				font_path = font_search_paths[i];
				break;
			}
		}

		if (!font) {
			std::fprintf(stderr, "Warning: could not find any suitable font, HUD text disabled\n");
			std::fprintf(stderr, "Hint: Set HYDRA_FONT=/path/to/font.ttf to specify a font\n");
		} else if (font_env && font_path != font_env) {
			std::fprintf(stderr, "Warning: HYDRA_FONT='%s' not found, using fallback: %s\n",
						 font_env, font_path);
		}

		const size_t NPIX = size_t(SCREEN_WIDTH) * SCREEN_HEIGHT;

		const char* frame_dump_path = std::getenv("FRAME_DUMP");
		const char* frame_dump_base = std::getenv("HYDRA_FRAME_BASE");
		const char* auto_exit_env   = std::getenv("AUTO_EXIT");
		bool auto_exit              = auto_exit_env && auto_exit_env[0] != '\0';
		const char* max_dump_env    = std::getenv("HYDRA_MAX_FRAME_DUMPS");
		int max_frame_dumps         = max_dump_env ? std::max(0, std::atoi(max_dump_env)) : 1;
		int frame_dumps_written     = 0;
		const char* autosave_cfg    = std::getenv("HYDRA_AUTOSAVE_CFG");
		const bool clear_each_frame = (std::getenv("HYDRA_CLEAR_EACH_FRAME") != nullptr);
		const char* fg_env = std::getenv("HYDRA_CLEAR_COLOR");
		uint32_t clear_color = 0;
		if (fg_env) {
			unsigned int r=0,g=0,b=0;
			if (std::sscanf(fg_env, "%u,%u,%u", &r, &g, &b) == 3) {
				clear_color = (0xFFu << 24) | ((r & 0xFFu) << 16) | ((g & 0xFFu) << 8) | (b & 0xFFu);
			}
		}
		std::vector<uint32_t> framebuffer(NPIX, clear_color);

		auto handle_resize = [&](int new_w, int new_h) {
			(void)new_w; (void)new_h;
			SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);
			recreate_texture();
			std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
			std::fprintf(stderr, "[hydra] window resized, refreshed texture and cleared framebuffer\n");
		};

		// Reset sequence
		for (int i = 0; i < 10; ++i) {
			top->clk = 0; top->eval(); main_time++;
			top->clk = 1; top->eval(); main_time++;
		}
		top->rst_n = 1;

		const char* cam_pos_env = std::getenv("HYDRA_CAM_POS");   // "x,y,z"
		const char* cam_ang_env = std::getenv("HYDRA_CAM_ANG");   // "yaw,pitch"
		auto parse_vec3 = [](const char* s, float def_x, float def_y, float def_z, float& ox, float& oy, float& oz) {
			ox = def_x; oy = def_y; oz = def_z;
			if (!s) return;
			if (std::sscanf(s, "%f,%f,%f", &ox, &oy, &oz) != 3) {
				ox = def_x; oy = def_y; oz = def_z;
			}
		};
		auto parse_vec2 = [](const char* s, float def_a, float def_b, float& oa, float& ob) {
			oa = def_a; ob = def_b;
			if (!s) return;
			if (std::sscanf(s, "%f,%f", &oa, &ob) != 2) {
				oa = def_a; ob = def_b;
			}
		};

		float pos_x = 10.0f;
		float pos_y = 10.0f;
		float pos_z = 10.0f;
		float yaw   = 0.0f;
		float pitch = 0.0f;
		parse_vec3(cam_pos_env, pos_x, pos_y, pos_z, pos_x, pos_y, pos_z);
		parse_vec2(cam_ang_env, yaw, pitch, yaw, pitch);
		const float default_pos_x = pos_x;
		const float default_pos_y = pos_y;
		const float default_pos_z = pos_z;
		const float default_yaw   = yaw;
		const float default_pitch = pitch;

		auto getenv_float = [](const char* name, float def_val) -> float {
			const char* v = std::getenv(name);
			if (!v) return def_val;
			return std::atof(v);
		};

		float move_speed      = getenv_float("HYDRA_MOVE_SPEED", 0.10f);
		float move_speed_fast = getenv_float("HYDRA_MOVE_SPEED_FAST", 0.35f);
		float turn_speed_keys = getenv_float("HYDRA_TURN_SPEED_KEYS", 0.04f);
		float mouse_sens      = getenv_float("HYDRA_MOUSE_SENS", 0.0025f);
		bool invert_y_mouse   = (std::getenv("HYDRA_INVERT_Y") != nullptr);
		const float base_move_speed      = move_speed;
		const float base_move_speed_fast = move_speed_fast;
		const float base_turn_speed_keys = turn_speed_keys;
		const float base_mouse_sens      = mouse_sens;

		bool smooth_surfaces = true;
		bool curvature       = true;
		bool extra_light     = false;
		bool diag_slice      = false;
		bool ray_jitter      = env_truthy("HYDRA_RAY_JITTER");
		bool spectrum_mode   = env_truthy("HYDRA_SPECTRUM_MODE");
		bool hud_enabled     = true;
		bool hud_theme_light = false;
		if (const char* hud_theme_env = std::getenv("HYDRA_HUD_THEME")) {
			if (strcasecmp(hud_theme_env, "light") == 0)
				hud_theme_light = true;
		}
		const char* pixel_view_env = std::getenv("HYDRA_PIXEL_VIEW");
		g_pixel_view_mode = pixel_view_from_string(pixel_view_env);
		bool safe_capture_mode = env_truthy("HYDRA_SAFE_CAPTURE");

		uint32_t world_seed_override = 0;
		const char* world_seed_env = std::getenv("HYDRA_WORLD_SEED");
		if (const char* seed_env = world_seed_env) {
			world_seed_override = static_cast<uint32_t>(std::strtoul(seed_env, nullptr, 0));
		}

		bool mouse_captured  = true;
		const char* mouse_cap_env = std::getenv("HYDRA_MOUSE_CAPTURE");
		if (mouse_cap_env && std::strcmp(mouse_cap_env, "0") == 0)
			mouse_captured = false;

		auto load_autosave_cfg = [&](const char* path) {
			if (!path || path[0] == '\0') return;
			FILE* f = std::fopen(path, "r");
			if (!f) return;
			char line[256];
			while (std::fgets(line, sizeof(line), f)) {
				if (std::strncmp(line, "cam_pos=", 8) == 0) {
					float lx, ly, lz;
					if (std::sscanf(line + 8, "%f,%f,%f", &lx, &ly, &lz) == 3) {
						pos_x = lx; pos_y = ly; pos_z = lz;
					}
				} else if (std::strncmp(line, "cam_ang=", 8) == 0) {
					float lyaw, lpitch;
					if (std::sscanf(line + 8, "%f,%f", &lyaw, &lpitch) == 2) {
						yaw = lyaw; pitch = lpitch;
					}
				} else if (std::strncmp(line, "flags=", 6) == 0) {
					int fs, fc, fe, fd;
					if (std::sscanf(line + 6, "%d,%d,%d,%d", &fs, &fc, &fe, &fd) == 4) {
						smooth_surfaces = (fs != 0);
						curvature       = (fc != 0);
						extra_light     = (fe != 0);
						diag_slice      = (fd != 0);
					}
				} else if (std::strncmp(line, "seed=", 5) == 0) {
					uint32_t s = 0;
					if (std::sscanf(line + 5, "%u", &s) == 1) {
						world_seed_override = s;
					}
				} else if (std::strncmp(line, "safe_capture=", 13) == 0) {
					int v = 0;
					if (std::sscanf(line + 13, "%d", &v) == 1) {
						safe_capture_mode = (v != 0);
					}
				}
			}
			std::fclose(f);
		};

		// Camera position clamping (configurable bounds)
		bool cam_clamp_enabled = (std::getenv("HYDRA_CAM_CLAMP") != nullptr);
		float cam_min = -1.0f;
		float cam_max = 65.0f;  // Default to 64x64x64 voxel volume with margin
		const char* cam_bounds_env = std::getenv("HYDRA_CAM_BOUNDS");
		if (cam_bounds_env) {
			float min_val, max_val;
			if (std::sscanf(cam_bounds_env, "%f,%f", &min_val, &max_val) == 2) {
				cam_min = min_val;
				cam_max = max_val;
			}
		}
		const bool base_cam_clamp = cam_clamp_enabled;
		const float base_cam_min = cam_min;
		const float base_cam_max = cam_max;

		// Apply initial clamping if enabled
		if (cam_clamp_enabled) {
			if (pos_x < cam_min) pos_x = cam_min;
			if (pos_x > cam_max) pos_x = cam_max;
			if (pos_y < cam_min) pos_y = cam_min;
			if (pos_y > cam_max) pos_y = cam_max;
			if (pos_z < cam_min) pos_z = cam_min;
			if (pos_z > cam_max) pos_z = cam_max;
		}
		if (autosave_cfg) {
			load_autosave_cfg(autosave_cfg);
		}

		// Frame pacing and timing configuration
		const char* idle_env = std::getenv("HYDRA_SIM_IDLE_MS");
		const int idle_ms = idle_env ? std::max(0, std::atoi(idle_env)) : 0;
		const char* fps_env = std::getenv("HYDRA_FPS_TARGET");
		const float fps_target = fps_env ? std::max(0.0f, static_cast<float>(std::atof(fps_env))) : 0.0f;

		// Print startup summary for reproducibility
		std::fprintf(stderr, "\n[hydra] === Startup Configuration ===\n");
		std::fprintf(stderr, "[hydra] Backend: %s\n", backend_name(backend));

		// Log backend selection details
		if (const char* v = std::getenv("HYDRA_BACKEND")) {
			std::fprintf(stderr, "[hydra] Backend selection: env var HYDRA_BACKEND=%s\n", v);
		} else if (const char* v = std::getenv("HYDRA_BACKEND_PREFS")) {
			std::fprintf(stderr, "[hydra] Backend selection: preference order HYDRA_BACKEND_PREFS=%s\n", v);
		} else {
			std::fprintf(stderr, "[hydra] Backend selection: auto (default preference order)\n");
		}

		// Log SDL info if available
		SDL_version ver;
		SDL_GetVersion(&ver);
		std::fprintf(stderr, "[hydra] SDL version: %d.%d.%d\n", ver.major, ver.minor, ver.patch);
		if (SDL_WasInit(SDL_INIT_VIDEO)) {
			const char* driver = SDL_GetCurrentVideoDriver();
			if (driver) {
				std::fprintf(stderr, "[hydra] SDL video driver: %s\n", driver);
			}
		}

		std::fprintf(stderr, "[hydra] Resolution: %dx%d\n", SCREEN_WIDTH, SCREEN_HEIGHT);
		std::fprintf(stderr, "[hydra] Font: %s (size %d)\n", font_path, font_size);
		if (std::getenv("HYDRA_VSYNC")) std::fprintf(stderr, "[hydra] HYDRA_VSYNC=%s\n", std::getenv("HYDRA_VSYNC"));
		if (frame_dump_path) std::fprintf(stderr, "[hydra] FRAME_DUMP=%s\n", frame_dump_path);
		if (max_dump_env) std::fprintf(stderr, "[hydra] HYDRA_MAX_FRAME_DUMPS=%s\n", max_dump_env);
		if (auto_exit) std::fprintf(stderr, "[hydra] AUTO_EXIT=1\n");
		if (cam_pos_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_POS=%s\n", cam_pos_env);
		if (cam_ang_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_ANG=%s\n", cam_ang_env);
		if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
		if (pixel_view_env) std::fprintf(stderr, "[hydra] HYDRA_PIXEL_VIEW=%s\n", pixel_view_env);
		if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
		if (safe_capture_mode) std::fprintf(stderr, "[hydra] HYDRA_SAFE_CAPTURE=1\n");
		std::fprintf(stderr, "[hydra] Camera: pos=(%.1f,%.1f,%.1f) yaw=%.2f pitch=%.2f\n",
					 pos_x, pos_y, pos_z, yaw, pitch);
		std::fprintf(stderr, "[hydra] Move speed: %.3f (fast: %.3f) Mouse sens: %.4f%s\n",
					 move_speed, move_speed_fast, mouse_sens, invert_y_mouse ? " [Y-inverted]" : "");
		if (cam_clamp_enabled) std::fprintf(stderr, "[hydra] Camera clamping enabled: bounds=[%.1f, %.1f]\n", cam_min, cam_max);
		if (fps_target > 0.0f) std::fprintf(stderr, "[hydra] Frame pacing: target %.1f FPS\n", fps_target);
		if (clear_each_frame) std::fprintf(stderr, "[hydra] HYDRA_CLEAR_EACH_FRAME=1\n");
		if (autosave_cfg) std::fprintf(stderr, "[hydra] HYDRA_AUTOSAVE_CFG=%s\n", autosave_cfg);
		if (ray_jitter) std::fprintf(stderr, "[hydra] HYDRA_RAY_JITTER=1\n");
		std::fprintf(stderr, "[hydra] Pixel view: %s\n", pixel_view_mode_name(g_pixel_view_mode));
		std::fprintf(stderr, "[hydra] ==============================\n\n");

		RenderInstrumentationConfig inst_config;
		inst_config.cam_pos_x = pos_x;
		inst_config.cam_pos_y = pos_y;
		inst_config.cam_pos_z = pos_z;
		inst_config.yaw = yaw;
		inst_config.pitch = pitch;
		inst_config.smooth_surfaces = smooth_surfaces;
		inst_config.curvature = curvature;
		inst_config.extra_light = extra_light;
		inst_config.diag_slice = diag_slice;
		inst_config.ray_jitter = ray_jitter;
		inst_config.hud_enabled = hud_enabled;
		inst_config.fps_target = fps_target;
		inst_config.vsync = g_vsync;
		inst_config.backend_name = backend_name(backend);
		inst_config.backend_info = g_backend_info;
		inst_config.pixel_view = pixel_view_mode_name(g_pixel_view_mode);
		render_instrument.write_config(inst_config);

		bool selection_active = false;
		uint8_t selection_x = 0;
		uint8_t selection_y = 0;
		uint8_t selection_z = 0;
		uint64_t selection_word = 0;
		InputState keys;
		float help_overlay_timer = 3.5f;
		if (std::getenv("HYDRA_HELP_STARTUP")) {
			help_overlay_timer = env_truthy("HYDRA_HELP_STARTUP") ? 3.5f : 0.0f;
		}
		bool help_overlay_sticky = false;
		float sel_miss_timer = 0.0f;

		auto update_mouse_capture = [&]() {
			if (SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE) != 0) {
				std::fprintf(stderr, "Warning: SetRelativeMouseMode failed: %s\n", SDL_GetError());
			}
			SDL_SetWindowGrab(win, mouse_captured ? SDL_TRUE : SDL_FALSE);
			SDL_ShowCursor(mouse_captured ? SDL_FALSE : SDL_TRUE);
		};

		auto apply_camera_to_dut = [&]() {
			float dx = std::cos(yaw) * std::cos(pitch);
			float dy = std::sin(yaw) * std::cos(pitch);
			float dz = std::sin(pitch);

			float px = -dy * 0.66f;
			float py =  dx * 0.66f;

			root->voxel_framebuffer_top__DOT__cam_x       = int16_t(pos_x * FX);
			root->voxel_framebuffer_top__DOT__cam_y       = int16_t(pos_y * FX);
			root->voxel_framebuffer_top__DOT__cam_z       = int16_t(pos_z * FX);
			root->voxel_framebuffer_top__DOT__cam_dir_x   = int16_t(dx * FX);
			root->voxel_framebuffer_top__DOT__cam_dir_y   = int16_t(dy * FX);
			root->voxel_framebuffer_top__DOT__cam_dir_z   = int16_t(dz * FX);
			root->voxel_framebuffer_top__DOT__cam_plane_x = int16_t(px * FX);
			root->voxel_framebuffer_top__DOT__cam_plane_y = int16_t(py * FX);
		};

		auto apply_flags_to_dut = [&]() {
			root->voxel_framebuffer_top__DOT__cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
			root->voxel_framebuffer_top__DOT__cfg_curvature       = curvature       ? 1 : 0;
			root->voxel_framebuffer_top__DOT__cfg_extra_light     = extra_light     ? 1 : 0;
			root->voxel_framebuffer_top__DOT__cfg_diag_slice      = diag_slice     ? 1 : 0;
			root->voxel_framebuffer_top__DOT__cfg_ray_jitter      = ray_jitter     ? 1 : 0;
		};

		auto apply_selection_to_dut = [&]() {
			root->voxel_framebuffer_top__DOT__sel_active  = selection_active ? 1 : 0;
			root->voxel_framebuffer_top__DOT__sel_voxel_x = selection_x;
			root->voxel_framebuffer_top__DOT__sel_voxel_y = selection_y;
			root->voxel_framebuffer_top__DOT__sel_voxel_z = selection_z;
		};

		bool safe_defaults_mode = env_truthy("HYDRA_SAFE_DEFAULTS");
		auto apply_safe_defaults = [&]() {
			if (safe_defaults_mode) {
				move_speed      = 0.06f;
				move_speed_fast = 0.16f;
				turn_speed_keys = 0.03f;
				mouse_sens      = 0.0016f;
				cam_clamp_enabled = true;
			} else {
				move_speed      = base_move_speed;
				move_speed_fast = base_move_speed_fast;
				turn_speed_keys = base_turn_speed_keys;
				mouse_sens      = base_mouse_sens;
				cam_clamp_enabled = base_cam_clamp;
				cam_min = base_cam_min;
				cam_max = base_cam_max;
			}
		};

		apply_safe_defaults();
		if (cam_clamp_enabled) {
			if (pos_x < cam_min) pos_x = cam_min;
			if (pos_x > cam_max) pos_x = cam_max;
			if (pos_y < cam_min) pos_y = cam_min;
			if (pos_y > cam_max) pos_y = cam_max;
			if (pos_z < cam_min) pos_z = cam_min;
			if (pos_z > cam_max) pos_z = cam_max;
		}
		apply_camera_to_dut();
		apply_flags_to_dut();
		apply_selection_to_dut();
		root->voxel_framebuffer_top__DOT__world_seed = world_seed_override;
		update_mouse_capture();

		auto reset_key_state = [&]() { keys = InputState{}; };

		bool running = true;
		auto last_frame_time = std::chrono::high_resolution_clock::now();
		float fps = 0.0f;

		while (running && !Verilated::gotFinish()) {
			// Default: no debug write
			root->voxel_framebuffer_top__DOT__dbg_write_en = 0;

			SDL_Event ev;
			while (SDL_PollEvent(&ev)) {
				if (ev.type == SDL_QUIT) {
					running = false;
				} else if (ev.type == SDL_WINDOWEVENT) {
					if (ev.window.event == SDL_WINDOWEVENT_FOCUS_GAINED ||
						ev.window.event == SDL_WINDOWEVENT_TAKE_FOCUS) {
						update_mouse_capture();
					} else if (ev.window.event == SDL_WINDOWEVENT_FOCUS_LOST) {
						reset_key_state();
					} else if (ev.window.event == SDL_WINDOWEVENT_RESIZED ||
							   ev.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
						handle_resize(ev.window.data1, ev.window.data2);
					}
				} else if (ev.type == SDL_KEYDOWN || ev.type == SDL_KEYUP) {
					bool key_down = (ev.type == SDL_KEYDOWN);
					SDL_Scancode sc = ev.key.keysym.scancode;
					SDL_Keycode keycode = ev.key.keysym.sym;
					update_key_state(keys, sc, keycode, key_down);

					// Debug: Log 'o' and 'O' keys specifically
					if (key_down && (keycode == 'o' || keycode == 'O' || keycode == SDLK_o || sc == SDL_SCANCODE_O)) {
						std::fprintf(stderr, "[DEBUG] O key event: sc=%d kc=%d name=%s SDLK_o=%d\n",
									 (int)sc, (int)keycode, SDL_GetKeyName(keycode), (int)SDLK_o);
					}

					if (log_keys && log_keys_count < 200) {
						std::fprintf(stderr, "key %s sc=%d kc=%d name=%s mod=0x%x\n",
									 key_down ? "down" : "up",
									 (int)sc, (int)keycode,
									 SDL_GetKeyName(keycode),
									 ev.key.keysym.mod);
						++log_keys_count;
					}

					if (key_down) {
						switch (keycode) {
							case SDLK_ESCAPE:
								running = false;
								break;
							case SDLK_1: case SDLK_KP_1:
								smooth_surfaces = !smooth_surfaces;
								apply_flags_to_dut();
								if (log_keys && log_keys_count < 200) {
									std::fprintf(stderr, "toggle smooth -> %d\n", smooth_surfaces ? 1 : 0);
									++log_keys_count;
								}
								break;
							case SDLK_2: case SDLK_KP_2:
								curvature = !curvature;
								apply_flags_to_dut();
								if (log_keys && log_keys_count < 200) {
									std::fprintf(stderr, "toggle curvature -> %d\n", curvature ? 1 : 0);
									++log_keys_count;
								}
								break;
							case SDLK_3: case SDLK_KP_3:
								extra_light = !extra_light;
								apply_flags_to_dut();
								if (log_keys && log_keys_count < 200) {
									std::fprintf(stderr, "toggle extra_light -> %d\n", extra_light ? 1 : 0);
									++log_keys_count;
								}
								break;
							case SDLK_o:
								diag_slice = !diag_slice;
								apply_flags_to_dut();
								std::fprintf(stderr, "[DEBUG] 'o' key pressed: diag_slice now = %d\n", diag_slice ? 1 : 0);
								if (log_keys && log_keys_count < 200) {
									std::fprintf(stderr, "toggle diag_slice -> %d\n", diag_slice ? 1 : 0);
									++log_keys_count;
								}
								break;
							case SDLK_y:
								spectrum_mode = !spectrum_mode;
								std::fprintf(stderr, "[hydra] spectrum_mode %s\n", spectrum_mode ? "ON" : "OFF");
								break;
							case SDLK_j:
								ray_jitter = !ray_jitter;
								apply_flags_to_dut();
								std::fprintf(stderr, "[hydra] ray jitter %s\n", ray_jitter ? "ON" : "OFF");
								if (log_keys && log_keys_count < 200) {
									std::fprintf(stderr, "toggle ray_jitter -> %d\n", ray_jitter ? 1 : 0);
									++log_keys_count;
								}
								break;
							case SDLK_m:
								mouse_captured = !mouse_captured;
								update_mouse_capture();
								break;
							case SDLK_F3:
								safe_capture_mode = !safe_capture_mode;
								std::fprintf(stderr, "[hydra] safe capture %s\n", safe_capture_mode ? "ON" : "OFF");
								break;
							case SDLK_F4:
								g_fog_enabled = !g_fog_enabled;
								std::fprintf(stderr, "[hydra] depth fog %s\n", g_fog_enabled ? "ON" : "OFF");
								break;
							case SDLK_F2:
								safe_defaults_mode = !safe_defaults_mode;
								apply_safe_defaults();
								if (cam_clamp_enabled) {
									if (pos_x < cam_min) pos_x = cam_min;
									if (pos_x > cam_max) pos_x = cam_max;
									if (pos_y < cam_min) pos_y = cam_min;
									if (pos_y > cam_max) pos_y = cam_max;
									if (pos_z < cam_min) pos_z = cam_min;
									if (pos_z > cam_max) pos_z = cam_max;
								}
								std::fprintf(stderr, "[hydra] safe defaults %s (move=%.3f/%.3f turn=%.3f mouse=%.4f clamp=%d)\n",
											 safe_defaults_mode ? "ON" : "OFF",
											 move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
											 cam_clamp_enabled ? 1 : 0);
								break;
							case SDLK_F1:
								help_overlay_sticky = !help_overlay_sticky;
								if (!help_overlay_sticky && help_overlay_timer <= 0.0f) {
									help_overlay_timer = 3.0f;
								}
								break;
							case SDLK_SLASH:
								help_overlay_timer = 4.0f;
								help_overlay_sticky = false;
								break;
							case SDLK_f:
								if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
									selection_active = true;
									selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x);
									selection_y = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_y);
									selection_z = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_z);
									selection_word = static_cast<uint64_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_data);
									apply_selection_to_dut();
									sel_miss_timer = 0.0f;
								} else {
									sel_miss_timer = 1.5f;
								}
								break;
							case SDLK_g:
								selection_active = false;
								selection_word   = 0;
								apply_selection_to_dut();
								break;
							case SDLK_h:
								hud_enabled = !hud_enabled;
								break;
							case SDLK_t:
								hud_theme_light = !hud_theme_light;
								break;
							case SDLK_r:
								// Reset camera and flags to defaults; clear selection.
								pos_x = default_pos_x;
								pos_y = default_pos_y;
								pos_z = default_pos_z;
								yaw   = default_yaw;
								pitch = default_pitch;
								smooth_surfaces = true;
								curvature       = true;
								extra_light     = false;
								diag_slice      = false;
								selection_active = false;
								selection_word   = 0;
								apply_camera_to_dut();
								apply_flags_to_dut();
								apply_selection_to_dut();
								apply_safe_defaults();
								break;
							case SDLK_v: {
								if (g_pixel_view_mode == PixelViewMode::Color) {
									g_pixel_view_mode = PixelViewMode::Word0;
								} else if (g_pixel_view_mode == PixelViewMode::Word0) {
									g_pixel_view_mode = PixelViewMode::Word2;
								} else if (g_pixel_view_mode == PixelViewMode::Word2) {
									g_pixel_view_mode = PixelViewMode::SidebandMix;
								} else {
									g_pixel_view_mode = PixelViewMode::Color;
								}
								std::fprintf(stderr, "[hydra] pixel view -> %s\n",
											 pixel_view_mode_name(g_pixel_view_mode));
								break;
							}
							case SDLK_p:
								std::fprintf(stderr,
									"State: cam=(%.3f,%.3f,%.3f) yaw=%.3f pitch=%.3f flags[smooth=%d curv=%d extra=%d diag=%d] sel=%d (%u,%u,%u)\n",
									pos_x, pos_y, pos_z, yaw, pitch,
									smooth_surfaces ? 1 : 0,
									curvature ? 1 : 0,
									extra_light ? 1 : 0,
									diag_slice ? 1 : 0,
									selection_active ? 1 : 0,
									(unsigned)selection_x,
									(unsigned)selection_y,
									(unsigned)selection_z);
								break;
							case SDLK_s: {
								// Screenshot: save current framebuffer as timestamped PPM
								auto now = std::chrono::system_clock::now();
								auto secs = std::chrono::duration_cast<std::chrono::seconds>(
									now.time_since_epoch()).count();
								char filename[256];
								std::snprintf(filename, sizeof(filename), "sim/screenshot_%ld.ppm", secs);
								FILE* f = std::fopen(filename, "wb");
								if (!f) {
									std::fprintf(stderr, "Failed to open %s for screenshot\n", filename);
								} else {
									std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
									for (int y = 0; y < SCREEN_HEIGHT; ++y) {
										for (int x = 0; x < SCREEN_WIDTH; ++x) {
											uint32_t argb = framebuffer[size_t(y) * SCREEN_WIDTH + x];
											uint8_t rgb[3] = {
												(uint8_t)((argb >> 16) & 0xFF),
												(uint8_t)((argb >> 8) & 0xFF),
												(uint8_t)(argb & 0xFF)
											};
											std::fwrite(rgb, 1, 3, f);
										}
									}
									std::fclose(f);
									std::fprintf(stderr, "Screenshot saved: %s\n", filename);
								}
								break;
							}
							default: break;
						}

						// Edit selected voxel
						if (selection_active) {
							uint64_t w = selection_word;
							uint8_t material_props = (w >> 56) & 0xFF;
							uint8_t emissive       = (w >> 48) & 0xFF;
							uint8_t alpha          = (w >> 40) & 0xFF;
							uint8_t light          = (w >> 32) & 0xFF;
							uint8_t r              = (w >> 24) & 0xFF;
							uint8_t g              = (w >> 16) & 0xFF;
							uint8_t b              = (w >>  8) & 0xFF;
							uint8_t material_type  = (w >>  4) & 0x0F;

							bool do_write = false;

							if (keycode == SDLK_c) {
								material_type = (material_type + 1) & 0x0F;
								w &= ~((uint64_t)0x0F << 4);
								w |= (uint64_t(material_type) << 4);
								do_write = true;
							} else if (keycode == SDLK_x) {
								int val = emissive + 16;
								if (val > 255) val = 255;
								emissive = (uint8_t)val;
								w &= ~((uint64_t)0xFF << 48);
								w |= (uint64_t)emissive << 48;
								do_write = true;
							} else if (keycode == SDLK_z) {
								int val = emissive - 16;
								if (val < 0) val = 0;
								emissive = (uint8_t)val;
								w &= ~((uint64_t)0xFF << 48);
								w |= (uint64_t)emissive << 48;
								do_write = true;
							} else if (keycode == SDLK_b) {
								auto saturate_add = [](uint8_t c, int delta) -> uint8_t {
									int v = c + delta;
									if (v < 0) v = 0;
									if (v > 255) v = 255;
									return (uint8_t)v;
								};
								r = saturate_add(r, 16);
								g = saturate_add(g, 16);
								b = saturate_add(b, 16);
								w &= ~(((uint64_t)0xFFFFFF) << 8);
								w |= ((uint64_t)r << 24) |
									 ((uint64_t)g << 16) |
									 ((uint64_t)b <<  8);
								do_write = true;
							}

							if (do_write) {
								selection_word = w;
								uint32_t addr = voxel_addr_from_xyz(selection_x, selection_y, selection_z);
								root->voxel_framebuffer_top__DOT__dbg_write_addr = addr;
								root->voxel_framebuffer_top__DOT__dbg_write_data = w;
								root->voxel_framebuffer_top__DOT__dbg_write_en   = 1;
							}
						}
					}
				} else if (ev.type == SDL_MOUSEMOTION && mouse_captured && !safe_capture_mode) {
					int dx = ev.motion.xrel;
					int dy = ev.motion.yrel;
					yaw   += dx * mouse_sens;
					pitch += (invert_y_mouse ? dy : -dy) * mouse_sens;
		if (pitch >  1.50f) pitch =  1.50f;
		if (pitch < -1.50f) pitch = -1.50f;
					apply_camera_to_dut();
				}
			}

			bool cam_changed = false;

			float fdx = std::cos(yaw);
			float fdy = std::sin(yaw);
			float rdx = -std::sin(yaw);
			float rdy =  std::cos(yaw);

			float cur_speed = keys.fast ? move_speed_fast : move_speed;

			if (!safe_capture_mode) {
				if (keys.forward)      { pos_x += fdx * cur_speed; pos_y += fdy * cur_speed; cam_changed = true; }
				if (keys.back)         { pos_x -= fdx * cur_speed; pos_y -= fdy * cur_speed; cam_changed = true; }
				if (keys.strafe_left)  { pos_x += rdx * cur_speed; pos_y += rdy * cur_speed; cam_changed = true; }
				if (keys.strafe_right) { pos_x -= rdx * cur_speed; pos_y -= rdy * cur_speed; cam_changed = true; }
				if (keys.down)         { pos_z -= cur_speed; cam_changed = true; }
				if (keys.up)           { pos_z += cur_speed; cam_changed = true; }

				if (keys.yaw_left)   { yaw   -= turn_speed_keys; cam_changed = true; }
				if (keys.yaw_right)  { yaw   += turn_speed_keys; cam_changed = true; }
				if (keys.pitch_up)   { pitch += turn_speed_keys; cam_changed = true; }
				if (keys.pitch_down) { pitch -= turn_speed_keys; cam_changed = true; }
			}

			if (pitch >  1.50f) pitch =  1.50f;
			if (pitch < -1.50f) pitch = -1.50f;

			// Apply camera position clamping if enabled
			if (cam_clamp_enabled) {
				if (pos_x < cam_min) pos_x = cam_min;
				if (pos_x > cam_max) pos_x = cam_max;
				if (pos_y < cam_min) pos_y = cam_min;
				if (pos_y > cam_max) pos_y = cam_max;
				if (pos_z < cam_min) pos_z = cam_min;
				if (pos_z > cam_max) pos_z = cam_max;
			}

			if (cam_changed) {
				apply_camera_to_dut();
				if (log_keys && log_keys_count < 200) {
					std::fprintf(stderr, "cam pos=(%.2f, %.2f, %.2f) yaw=%.2f pitch=%.2f\n",
								 pos_x, pos_y, pos_z, yaw, pitch);
					++log_keys_count;
				}
			}

			// Ensure DUT flags follow local toggles every frame.
			apply_flags_to_dut();

			// Simulate HDL
			const int cycles_per_chunk = 2000;
			bool frame_done = false;
			std::chrono::high_resolution_clock::time_point sim_loop_start;
			if (render_instrument.active())
				sim_loop_start = std::chrono::high_resolution_clock::now();

			for (int i = 0; i < cycles_per_chunk; ++i) {
				top->clk = 1; top->eval(); main_time++;

				if (top->pixel_write_en) {
					uint32_t addr = top->pixel_addr;
					if (addr < NPIX) {
						uint32_t w0 = top->pixel_word0;
						uint32_t w1 = top->pixel_word1;
						uint32_t w2 = top->pixel_word2;
						uint32_t pixel_value = pixel96_to_argb(w0, w1, w2);
						uint8_t depth_byte = (w0 >> 16) & 0xFF;
						if (g_fog_enabled) {
							pixel_value = apply_fog(pixel_value, depth_byte);
						}
						framebuffer[addr] = pixel_value;
						record_color(frame_color_stats, pixel_value);
						frame_color_stats_dirty = true;

						if (log_frames && log_pixel_samples < 512) {
							uint32_t x = addr % SCREEN_WIDTH;
							uint32_t y = addr / SCREEN_WIDTH;
							// Probe a single vertical column through the middle of the screen
							// to see sky, geometry, and floor along one ray.
							if (x == SCREEN_WIDTH / 2) {
								std::fprintf(stderr,
									"probe x=%u y=%u addr=%u w0=%08x w1=%08x w2=%08x argb=%08x\n",
									x, y, addr, w0, w1, w2,
									pixel_value);
								++log_pixel_samples;
							}
						}
					}
					++pixels_this_frame;
				}

				if (top->frame_done)
					frame_done = true;

				top->clk = 0; top->eval(); main_time++;
			}

			if (frame_done) {
				 std::chrono::high_resolution_clock::time_point sim_loop_end;
				 if (render_instrument.active())
					 sim_loop_end = std::chrono::high_resolution_clock::now();
				 size_t pixels_written_this_frame = pixels_this_frame;
				 last_frame_color_stats = frame_color_stats;
				 last_frame_color_stats_valid = frame_color_stats_dirty;
				 frame_color_stats = color_range_default();
				 frame_color_stats_dirty = false;
				 if (auto_exit) {
					 running = false;
				 }
				if (frame_dump_path && frame_dump_path[0] != '\0' &&
					(max_frame_dumps == 0 || frame_dumps_written < max_frame_dumps)) {
					char pathbuf[512];
					if (frame_dump_base && max_frame_dumps != 1) {
						std::snprintf(pathbuf, sizeof(pathbuf), "%s_%d.ppm", frame_dump_base, frame_dumps_written);
					} else {
						std::snprintf(pathbuf, sizeof(pathbuf), "%s", frame_dump_path);
					}
					FILE* f = std::fopen(pathbuf, "wb");
					if (!f) {
						std::fprintf(stderr, "Failed to open FRAME_DUMP '%s' for write\n", pathbuf);
					} else {
						std::fprintf(stderr, "Writing frame dump to %s\n", pathbuf);
						std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
						for (int fy = 0; fy < SCREEN_HEIGHT; ++fy) {
							for (int fx = 0; fx < SCREEN_WIDTH; ++fx) {
								uint32_t argb = framebuffer[size_t(fy) * SCREEN_WIDTH + fx];
								uint8_t r = (argb >> 16) & 0xFF;
								uint8_t g = (argb >> 8)  & 0xFF;
								uint8_t b =  argb        & 0xFF;
								uint8_t rgb[3] = {r, g, b};
								std::fwrite(rgb, 1, 3, f);
							}
						}
						std::fclose(f);
						++frame_dumps_written;
						if (max_frame_dumps > 0 && frame_dumps_written >= max_frame_dumps) {
							std::fprintf(stderr, "Max frame dumps (%d) reached, disabling further FRAME_DUMP writes\n", max_frame_dumps);
						}
					}
				}
				if (autosave_cfg && autosave_cfg[0] != '\0') {
					FILE* fcfg = std::fopen(autosave_cfg, "w");
					if (!fcfg) {
						std::fprintf(stderr, "Failed to write HYDRA_AUTOSAVE_CFG to '%s'\n", autosave_cfg);
					} else {
						std::fprintf(fcfg, "cam_pos=%.3f,%.3f,%.3f\n", pos_x, pos_y, pos_z);
						std::fprintf(fcfg, "cam_ang=%.3f,%.3f\n", yaw, pitch);
						std::fprintf(fcfg, "flags=%d,%d,%d,%d\n",
									 smooth_surfaces ? 1 : 0,
									 curvature ? 1 : 0,
									 extra_light ? 1 : 0,
									 diag_slice ? 1 : 0);
						std::fprintf(fcfg, "seed=%u\n", world_seed_override);
						std::fprintf(fcfg, "safe_capture=%d\n", safe_capture_mode ? 1 : 0);
						std::fclose(fcfg);
					}
				}

				if (log_frames) {
					size_t nonzero = 0;
					for (uint32_t v : framebuffer) {
						if (v != 0) ++nonzero;
					}
					uint32_t sample0 = framebuffer.empty() ? 0 : framebuffer[0];
					uint32_t sample_mid = framebuffer.empty() ? 0 : framebuffer[NPIX/2];
					std::fprintf(stderr,
						"frame %zu done, pixels_written=%zu nonzero=%zu sample0=%08x mid=%08x\n",
						frame_counter, pixels_this_frame, nonzero, sample0, sample_mid);
				}
				++frame_counter;

				auto now = std::chrono::high_resolution_clock::now();
				float dt = std::chrono::duration<float>(now - last_frame_time).count();
				if (fps_target > 0.0f) {
					float target_dt = 1.0f / fps_target;
					if (dt < target_dt) {
						int delay_ms = static_cast<int>((target_dt - dt) * 1000.0f);
						if (delay_ms > 0) {
							SDL_Delay(delay_ms);
							dt += static_cast<float>(delay_ms) / 1000.0f;
						}
					}
				}
				last_frame_time = now;
				if (dt > 0.0f) fps = 1.0f / dt;

				if (render_instrument.active()) {
					double ray_loop_ms = std::chrono::duration<double, std::milli>(sim_loop_end - sim_loop_start).count();
					double hud_present_ms = std::chrono::duration<double, std::milli>(hud_present_end - hud_present_start).count();
					double framebuffer_copy_ms = std::chrono::duration<double, std::milli>(copy_end - copy_start).count();
					render_instrument.record(frame_counter, fps, ray_loop_ms, hud_present_ms, framebuffer_copy_ms, static_cast<double>(dt * 1000.0f));
				}

				if (!help_overlay_sticky && help_overlay_timer > 0.0f && dt > 0.0f) {
					help_overlay_timer = std::max(0.0f, help_overlay_timer - dt);
				}
				if (sel_miss_timer > 0.0f && dt > 0.0f) {
					sel_miss_timer = std::max(0.0f, sel_miss_timer - dt);
				}

				uint64_t mem_cycle = root->voxel_framebuffer_top__DOT__mem_cycle_count;
				uint64_t mem_read  = root->voxel_framebuffer_top__DOT__mem_read_cycles;
				uint64_t mem_write = root->voxel_framebuffer_top__DOT__mem_write_cycles;
				uint64_t dc = mem_cycle - prev_mem_cycle;
				uint64_t dr = mem_read  - prev_mem_read;
				uint64_t dw = mem_write - prev_mem_write;
				prev_mem_cycle = mem_cycle;
				prev_mem_read  = mem_read;
				prev_mem_write = mem_write;
				if (dc > 0) {
					last_mem_read_util  = float(dr) / float(dc);
					last_mem_write_util = float(dw) / float(dc);
				}

				std::chrono::high_resolution_clock::time_point hud_present_start;
				if (render_instrument.active())
					hud_present_start = std::chrono::high_resolution_clock::now();
				if (hud_enabled && font) {
					// Darken or lighten HUD band in the framebuffer based on theme.
					for (int y = SCREEN_HEIGHT - HUD_HEIGHT; y < SCREEN_HEIGHT; ++y) {
						if (y < 0) continue;
						for (int x = 0; x < SCREEN_WIDTH; ++x) {
							uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
							uint8_t r = (px >> 16) & 0xFF;
							uint8_t g = (px >> 8)  & 0xFF;
							uint8_t b =  px        & 0xFF;
							if (hud_theme_light) {
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
					uint32_t hits = root->voxel_framebuffer_top__DOT__core_dbg_hit_count;
					uint32_t ray_steps_total = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_total;
					uint32_t ray_steps_max   = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_max;
					uint32_t ray_miss_count  = root->voxel_framebuffer_top__DOT__core_dbg_ray_miss_count;
					const float pixel_count = float(SCREEN_WIDTH) * float(SCREEN_HEIGHT);
					const float ray_steps_avg = pixel_count > 0.0f
						? float(ray_steps_total) / pixel_count
						: 0.0f;
					const int hud_y = SCREEN_HEIGHT - HUD_HEIGHT + 4;
					int yoff = hud_y;
					SDL_Color hud_text_color = hud_theme_light ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};

					if (fps_target > 0.0f) {
						std::snprintf(buf, sizeof(buf),
							"FPS %.1f / %.0f (target) | Pos %.1f %.1f %.1f",
							fps, fps_target, pos_x, pos_y, pos_z);
					} else {
						std::snprintf(buf, sizeof(buf),
							"FPS %.1f | Pos %.1f %.1f %.1f",
							fps, pos_x, pos_y, pos_z);
					}
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Yaw %.2f  Pitch %.2f",
						yaw, pitch);
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"[1] Smooth %s  [2] Curv %s  [3] Extra %s",
						smooth_surfaces ? "ON" : "OFF",
						curvature       ? "ON" : "OFF",
						extra_light     ? "ON" : "OFF");
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"[O] Slice %s  [J] Jitter %s  [M] Mouse %s",
						diag_slice     ? "ON" : "OFF",
						ray_jitter     ? "ON" : "OFF",
						mouse_captured ? "ON" : "OFF");
					SDL_Color mouse_line_color = mouse_captured ? hud_text_color : SDL_Color{255, 96, 96, 255};
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, mouse_line_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Hits %u | ray avg %.1f max %u miss %u",
						hits, ray_steps_avg, ray_steps_max, ray_miss_count);
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Mem: rd %.1f%% wr %.1f%%",
						last_mem_read_util * 100.0f,
						last_mem_write_util * 100.0f);
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					if (last_frame_color_stats_valid) {
						std::snprintf(buf, sizeof(buf),
							"RGB range: R%3u-%3u  G%3u-%3u  B%3u-%3u",
							(unsigned)last_frame_color_stats.min_r,
							(unsigned)last_frame_color_stats.max_r,
							(unsigned)last_frame_color_stats.min_g,
							(unsigned)last_frame_color_stats.max_g,
							(unsigned)last_frame_color_stats.min_b,
							(unsigned)last_frame_color_stats.max_b);
					} else {
						std::snprintf(buf, sizeof(buf), "RGB range: capturing...");
					}
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Pixel view: %s  [V] cycle",
						pixel_view_mode_name(g_pixel_view_mode));
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Safe defaults: %s [F2] (move %.3f/%.3f turn %.3f sens %.4f clamp %s)",
						safe_defaults_mode ? "ON" : "OFF",
						move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
						cam_clamp_enabled ? "ON" : "OFF");
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					// Fog status (toggle with F4)
					std::snprintf(buf, sizeof(buf),
						"Fog: %s [F4] color=%06x density=%.2f",
						g_fog_enabled ? "ON" : "OFF",
						(g_fog_color & 0x00FFFFFFu),
						g_fog_density);
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					std::snprintf(buf, sizeof(buf),
						"Safe capture: %s [F3] (input frozen)",
						safe_capture_mode ? "ON" : "OFF");
					SDL_Color warn_color = safe_capture_mode ? SDL_Color{255, 128, 96, 255} : hud_text_color;
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, warn_color);
					yoff += 14;

					if (!g_backend_info.empty()) {
						draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, g_backend_info, 6, yoff, hud_text_color);
						yoff += 14;
					}

					if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
						std::snprintf(buf, sizeof(buf),
							"Cursor: (%u,%u,%u) mat=0x%02X",
							(unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_x,
							(unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_y,
							(unsigned)root->voxel_framebuffer_top__DOT__cursor_voxel_z,
							(unsigned)(root->voxel_framebuffer_top__DOT__cursor_material_id & 0xFF));
					} else {
						std::snprintf(buf, sizeof(buf),
							"Cursor: (no hit)");
					}
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					if (selection_active) {
						std::snprintf(buf, sizeof(buf),
							"Sel: (%u,%u,%u)  [G] clear  [F] select",
							(unsigned)selection_x,
							(unsigned)selection_y,
							(unsigned)selection_z);
					} else {
						std::snprintf(buf, sizeof(buf),
							"Sel: (none)  (aim + F to select)");
					}
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					yoff += 14;

					if (selection_active) {
						uint64_t w = selection_word;
						uint8_t material_props = (w >> 56) & 0xFF;
						uint8_t emissive       = (w >> 48) & 0xFF;
						uint8_t alpha          = (w >> 40) & 0xFF;
						uint8_t light          = (w >> 32) & 0xFF;
						uint8_t r              = (w >> 24) & 0xFF;
						uint8_t g              = (w >> 16) & 0xFF;
						uint8_t b              = (w >>  8) & 0xFF;
						uint8_t material_type  = (w >>  4) & 0x0F;

						std::snprintf(buf, sizeof(buf),
							"Probe RGBA %3u/%3u/%3u/%3u L%3u MT%u MP=%02X E%3u",
							r, g, b, alpha, light,
							material_type, material_props, emissive);
						draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
						yoff += 14;
						std::snprintf(buf, sizeof(buf),
							"Edit: [C] material  [X/Z] emissive  [B] brighten");
						draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
					}
					if (sel_miss_timer > 0.0f) {
						std::snprintf(buf, sizeof(buf),
							"Selection miss: aim at geometry and press F");
						SDL_Color warn = {255, 96, 96, 255};
						draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff + 14, warn);
					}
				}

				if ((help_overlay_sticky || help_overlay_timer > 0.0f) && font) {
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
					int box_w = std::min(360, SCREEN_WIDTH - 12);
					int box_h = line_count * 14 + 10;
					for (int y = box_y; y < box_y + box_h && y < SCREEN_HEIGHT; ++y) {
						for (int x = box_x; x < box_x + box_w && x < SCREEN_WIDTH; ++x) {
							uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
							uint8_t r = (px >> 16) & 0xFF;
							uint8_t g = (px >> 8)  & 0xFF;
							uint8_t b =  px        & 0xFF;
							if (hud_theme_light) {
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

					SDL_Color help_color = hud_theme_light ? SDL_Color{0, 0, 0, 255} : SDL_Color{255, 255, 255, 255};
					int help_y = box_y + 4;
					for (int i = 0; i < line_count; ++i) {
						draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, help_lines[i],
										box_x + 4, help_y, help_color);
						help_y += 14;
					}
				}

				if (!mouse_captured && font) {
					SDL_Color warn_color{255, 96, 96, 255};
					int warn_x = SCREEN_WIDTH - 210;
					int warn_y = 8;
					draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font,
									"Mouse capture OFF (press M)",
									warn_x, warn_y, warn_color);
				}

				if (use_platform_present) {
					present_backend(backend, plat_ctx, framebuffer.data(),
									SCREEN_WIDTH, SCREEN_HEIGHT);
				}

				std::chrono::high_resolution_clock::time_point hud_present_end;
				if (render_instrument.active())
					hud_present_end = std::chrono::high_resolution_clock::now();

				std::chrono::high_resolution_clock::time_point copy_start;
				if (render_instrument.active())
					copy_start = std::chrono::high_resolution_clock::now();
				void* pixels = nullptr;
				int pitch_bytes = 0;
				if (SDL_LockTexture(tex, nullptr, &pixels, &pitch_bytes) != 0)
					die("LockTexture failed");

				for (int y = 0; y < SCREEN_HEIGHT; ++y) {
					uint32_t* row = (uint32_t*)((uint8_t*)pixels + y * pitch_bytes);
					std::memcpy(row, &framebuffer[size_t(y)*SCREEN_WIDTH],
								SCREEN_WIDTH * sizeof(uint32_t));
				}
				SDL_UnlockTexture(tex);

				SDL_SetRenderDrawColor(ren, 0, 0, 0, 255);
				SDL_RenderClear(ren);
				SDL_RenderCopy(ren, tex, nullptr, nullptr);
				SDL_RenderPresent(ren);

				std::chrono::high_resolution_clock::time_point copy_end;
				if (render_instrument.active())
					copy_end = std::chrono::high_resolution_clock::now();

				// Clear framebuffer for next frame to avoid stale pixels if the RTL stalls early
				// or when explicit per-frame clearing is requested.
				if (clear_each_frame || pixels_written_this_frame < NPIX) {
					std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
				}

				pixels_this_frame = 0;
			}

			if (idle_ms > 0)
				SDL_Delay(idle_ms);
		}

		top->final();
		delete top;

		if (use_platform_present)
			shutdown_backend(backend, plat_ctx);

		std::fprintf(stderr, "[hydra] exit summary: backend=%s vsync=%s frames_rendered=%zu\n",
					 backend_name(backend),
					 g_vsync ? "on" : "off",
					 frame_counter);

		if (font) TTF_CloseFont(font);
		TTF_Quit();
		SDL_DestroyTexture(tex);
		SDL_DestroyRenderer(ren);
		SDL_DestroyWindow(win);
		SDL_Quit();
		return 0;
	}
			uint8_t bb = static_cast<uint8_t>((sb * a + db * inv_a) / 255);

			dst_px = (0xFFu << 24) | (uint32_t(rr) << 16) | (uint32_t(gg) << 8) | uint32_t(bb);
		}
	}

	SDL_FreeSurface(surf);
}

int main(int argc, char** argv) {
	Verilated::commandArgs(argc, argv);
	apply_cli_overrides(argc, argv);

	const bool render_instrument_mode = env_truthy("HYDRA_RENDER_INSTRUMENT");
	RenderInstrumentation render_instrument(render_instrument_mode, flatten_cli_args(argc, argv));

	Vvoxel_framebuffer_top* top = new Vvoxel_framebuffer_top;
	auto* root = top->rootp;  // Access internal regs exposed by Verilator
	top->clk   = 0;
	top->rst_n = 0;
	// Default AXI shell inputs (unused in this harness)
	top->cam_load        = 0;
	top->cam_x_in        = 0;
	top->cam_y_in        = 0;
	top->cam_z_in        = 0;
	top->cam_dir_x_in    = 0;
	top->cam_dir_y_in    = 0;
	top->cam_dir_z_in    = 0;
	top->cam_plane_x_in  = 0;
	top->cam_plane_y_in  = 0;
	top->flags_load      = 0;
	top->flag_smooth_in  = 0;
	top->flag_curvature_in = 0;
	top->flag_extra_light_in = 0;
	top->flag_diag_slice_in  = 0;
	top->sel_load        = 0;
	top->sel_active_in   = 0;
	top->sel_voxel_x_in  = 0;
	top->sel_voxel_y_in  = 0;
	top->sel_voxel_z_in  = 0;
	top->dbg_ext_write_en   = 0;
	top->dbg_ext_write_addr = 0;
	top->dbg_ext_write_data = 0;
	top->start_frame_ext   = 0;
	top->soft_reset_ext    = 0;

	const bool log_keys = (std::getenv("LOG_KEYS") != nullptr);
	const bool log_frames = (std::getenv("LOG_FRAMES") != nullptr);
	int log_keys_count = 0;
	size_t pixels_this_frame = 0;
	size_t frame_counter = 0;
	int log_pixel_samples = 0;
	uint64_t prev_mem_cycle = 0;
	uint64_t prev_mem_read  = 0;
	uint64_t prev_mem_write = 0;
	float last_mem_read_util  = 0.0f;
	float last_mem_write_util = 0.0f;
	ColorRange frame_color_stats = color_range_default();
	ColorRange last_frame_color_stats = frame_color_stats;
	bool frame_color_stats_dirty = false;
	bool last_frame_color_stats_valid = false;

	// Configure depth fog from environment
	g_fog_enabled = env_truthy("HYDRA_FOG");
	if (const char* fog_col = std::getenv("HYDRA_FOG_COLOR")) {
		// accept formats like "0xRRGGBB" or "RRGGBB"
		unsigned long v = std::strtoul(fog_col, nullptr, 0);
		g_fog_color = 0xFF000000u | (uint32_t(v) & 0x00FFFFFFu);
	}
	if (const char* fog_den = std::getenv("HYDRA_FOG_DENSITY")) {
		char* endptr = nullptr;
		float d = std::strtof(fog_den, &endptr);
		if (endptr && endptr != fog_den) g_fog_density = d;
	}
	if (g_fog_enabled) {
		std::fprintf(stderr, "[hydra] Depth fog enabled color=%08x density=%.3f\n", g_fog_color, g_fog_density);
	}

	// Ensure SDL grabs keyboard focus; allow renderer selection via SDL hints/env.
	SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1");
	SDL_SetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP, "1");

	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
		die(std::string("SDL_Init: ") + SDL_GetError());
	if (TTF_Init() != 0)
		die(std::string("TTF_Init: ") + TTF_GetError());

	// Platform backend selection (HYDRA_BACKEND env respected inside select_default_backend).
	PlatformBackend requested_backend = select_default_backend();
	const bool headless_backend = (requested_backend == PlatformBackend::Headless);
	if (headless_backend) {
		// Force SDL to a dummy driver so no window/display server is required.
		setenv("SDL_VIDEODRIVER", "dummy", 0);
		setenv("SDL_AUDIODRIVER", "dummy", 0);
}

static std::string flatten_cli_args(int argc, char** argv) {
	std::string out;
	for (int i = 0; i < argc; ++i) {
		if (i) out += ' ';
		if (argv[i]) {
			out += argv[i];
		}
	}
	return out;
}

struct RenderInstrumentationConfig {
	float cam_pos_x = 0.0f;
	float cam_pos_y = 0.0f;
	float cam_pos_z = 0.0f;
	float yaw = 0.0f;
	float pitch = 0.0f;
	bool smooth_surfaces = false;
	bool curvature = false;
	bool extra_light = false;
	bool diag_slice = false;
	bool ray_jitter = false;
	bool hud_enabled = true;
	float fps_target = 0.0f;
	bool vsync = true;
	std::string backend_name;
	std::string backend_info;
	std::string pixel_view;
};

struct RenderInstrumentation {
	RenderInstrumentation(bool enabled, std::string command_line)
		: enabled_(enabled), command_line_(std::move(command_line)) {
		if (!enabled_)
			return;
		std::filesystem::create_directories("out");
		csv_.open("out/render_pipeline_baseline.csv", std::ios::app);
		if (!csv_)
			die("failed to open out/render_pipeline_baseline.csv for instrumentation logging");
		if (csv_.tellp() == 0)
			csv_ << "frame,timestamp_ms,fps,ray_loop_ms,hud_present_ms,framebuffer_copy_ms,frame_total_ms\n";
	}

	bool active() const { return enabled_; }

	void write_config(const RenderInstrumentationConfig& cfg) {
		if (!enabled_)
			return;
		std::ofstream cfg_out("out/render_pipeline_baseline.cfg");
		if (!cfg_out)
			die("failed to write out/render_pipeline_baseline.cfg");
		cfg_out << "instrument_command=" << command_line_ << "\n";
		cfg_out << "backend=" << cfg.backend_name << "\n";
		cfg_out << "backend_info=" << cfg.backend_info << "\n";
		cfg_out << "pixel_view=" << cfg.pixel_view << "\n";
		cfg_out << "camera_pos=" << cfg.cam_pos_x << "," << cfg.cam_pos_y << "," << cfg.cam_pos_z << "\n";
		cfg_out << "camera_ang=" << cfg.yaw << "," << cfg.pitch << "\n";
		cfg_out << "flags=smooth:" << (cfg.smooth_surfaces ? "1" : "0")
				<< ",curvature:" << (cfg.curvature ? "1" : "0")
				<< ",extra_light:" << (cfg.extra_light ? "1" : "0")
				<< ",diag_slice:" << (cfg.diag_slice ? "1" : "0")
				<< ",ray_jitter:" << (cfg.ray_jitter ? "1" : "0") << "\n";
		cfg_out << "hud_enabled=" << (cfg.hud_enabled ? "1" : "0") << "\n";
		cfg_out << "fps_target=" << cfg.fps_target << "\n";
		cfg_out << "vsync=" << (cfg.vsync ? "1" : "0") << "\n";
	}

	void record(uint64_t frame,
				double fps,
				double ray_loop_ms,
				double hud_present_ms,
				double framebuffer_copy_ms,
				double frame_total_ms) {
		if (!enabled_)
			return;
		auto now = std::chrono::system_clock::now();
		auto ts_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
		csv_ << frame << ',' << ts_ms << ',' << fps << ','
			 << ray_loop_ms << ',' << hud_present_ms << ','
			 << framebuffer_copy_ms << ',' << frame_total_ms << '\n';
		csv_.flush();
	}

private:
	bool enabled_;
	std::ofstream csv_;
	std::string command_line_;
};

	log_input_caps();

	if (std::getenv("HYDRA_VSYNC")) {
		g_vsync = env_truthy("HYDRA_VSYNC");
	}
	PlatformBackend backend = PlatformBackend::SDL;
	PlatformContext plat_ctx;
	bool use_platform_present = false;

	// Track if we had to fallback from requested backend
	bool backend_fallback = false;
	PlatformBackend attempted_backend = requested_backend;

	if (requested_backend != PlatformBackend::SDL) {
		if (!platform_backend_supported(requested_backend)) {
			std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' is not supported on this platform\n",
						 backend_name(requested_backend));
			std::fprintf(stderr, "[hydra] REASON: Backend not compiled in or platform incompatible\n");
			std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");
			std::fprintf(stderr, "[hydra] TIP: Run './sim_voxel --caps' to see available backends\n\n");
			backend_fallback = true;
		} else {
			PlatformConfig plat_cfg;
			plat_cfg.width  = SCREEN_WIDTH;
			plat_cfg.height = SCREEN_HEIGHT;
			plat_cfg.vsync  = true;

			std::fprintf(stderr, "[hydra] Initializing %s backend...\n", backend_name(requested_backend));

			if (init_backend(requested_backend, plat_cfg, plat_ctx)) {
				backend = requested_backend;
				use_platform_present = true;
				std::fprintf(stderr, "[hydra] SUCCESS: %s backend initialized\n", backend_name(backend));
			} else {
				std::fprintf(stderr, "\n[hydra] WARNING: Backend '%s' initialization failed\n",
							 backend_name(requested_backend));
				std::fprintf(stderr, "[hydra] REASON: Check stderr above for specific error messages\n");
				std::fprintf(stderr, "[hydra] ACTION: Falling back to SDL backend\n");

				// Provide specific hints based on backend
				if (requested_backend == PlatformBackend::GL) {
					std::fprintf(stderr, "[hydra] TIP: Install OpenGL drivers or try HYDRA_BACKEND=sdl\n");
				} else if (requested_backend == PlatformBackend::Vulkan) {
					std::fprintf(stderr, "[hydra] TIP: Install Vulkan drivers or try HYDRA_BACKEND=gl\n");
				} else if (requested_backend == PlatformBackend::Wayland || requested_backend == PlatformBackend::X11) {
					std::fprintf(stderr, "[hydra] TIP: Check DISPLAY env var or try HYDRA_BACKEND=sdl\n");
				}
				std::fprintf(stderr, "\n");
				backend_fallback = true;
			}
		}
	}

	if (backend == PlatformBackend::SDL) {
		std::fprintf(stderr, "[hydra] Using SDL backend%s\n",
					 backend_fallback ? " (fallback)" : " (default)");
	}

	log_backend_caps(requested_backend, backend, g_vsync);

	SDL_Window* win = SDL_CreateWindow(
		"Voxel Accelerator — Interactive Raycaster",
		SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
		SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2,
		SDL_WINDOW_RESIZABLE
	);
	if (!win) die("Cannot create SDL window");
	SDL_RaiseWindow(win);

	uint32_t sdl_renderer_flags = SDL_RENDERER_ACCELERATED;
	if (g_vsync) sdl_renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
	SDL_Renderer* ren = SDL_CreateRenderer(win, -1, sdl_renderer_flags);
	if (!ren) die("Renderer creation failed");

	SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);

	SDL_RendererInfo ren_info;
	if (SDL_GetRendererInfo(ren, &ren_info) == 0) {
		std::fprintf(stderr, "Renderer: %s\n", ren_info.name ? ren_info.name : "(unknown)");
		const char* video_driver = SDL_GetCurrentVideoDriver();
		char buf[160];
		std::snprintf(buf, sizeof(buf), "Backend: %s (vsync %s) renderer=%s video=%s",
					  backend_name(backend),
					  g_vsync ? "on" : "off",
					  ren_info.name ? ren_info.name : "(unknown)",
					  video_driver ? video_driver : "(unknown)");
		g_backend_info = buf;
	}

	SDL_Texture* tex = SDL_CreateTexture(
		ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
		SCREEN_WIDTH, SCREEN_HEIGHT
	);
	if (!tex) die("Texture creation failed");

	auto recreate_texture = [&]() {
		if (tex) {
			SDL_DestroyTexture(tex);
			tex = nullptr;
		}
		tex = SDL_CreateTexture(
			ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
			SCREEN_WIDTH, SCREEN_HEIGHT
		);
		if (!tex) die("Texture recreation failed");
	};

	const char* font_env = std::getenv("HYDRA_FONT");
	const char* font_scale_env = std::getenv("HYDRA_FONT_SCALE");
	int font_size = 11;
	if (font_scale_env) {
		float scale = std::atof(font_scale_env);
		if (scale < 0.5f) scale = 0.5f;
		if (scale > 3.0f) scale = 3.0f;
		font_size = std::max(8, static_cast<int>(11 * scale));
	}

	// Fallback font search paths for different platforms
	const char* font_search_paths[] = {
		font_env,  // User override first
		// Debian/Ubuntu
		"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
		"/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
		// Fedora/RHEL
		"/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf",
		"/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
		// Arch
		"/usr/share/fonts/TTF/DejaVuSans.ttf",
		"/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
		// FreeBSD
		"/usr/local/share/fonts/dejavu/DejaVuSans.ttf",
		"/usr/local/share/fonts/Liberation/LiberationSans-Regular.ttf",
		// macOS
		"/System/Library/Fonts/Helvetica.ttc",
		"/Library/Fonts/Arial.ttf",
		"/System/Library/Fonts/SFNSText.ttf",
		// Windows (if running under WSL or similar)
		"/mnt/c/Windows/Fonts/arial.ttf",
		"/mnt/c/Windows/Fonts/Arial.ttf",
		"C:\\Windows\\Fonts\\arial.ttf",
		nullptr
	};

	TTF_Font* font = nullptr;
	const char* font_path = nullptr;

	for (int i = 0; font_search_paths[i] != nullptr; ++i) {
		if (font_search_paths[i] == nullptr || font_search_paths[i][0] == '\0')
			continue;

		font = TTF_OpenFont(font_search_paths[i], font_size);
		if (font) {
			font_path = font_search_paths[i];
			break;
		}
	}

	if (!font) {
		std::fprintf(stderr, "Warning: could not find any suitable font, HUD text disabled\n");
		std::fprintf(stderr, "Hint: Set HYDRA_FONT=/path/to/font.ttf to specify a font\n");
	} else if (font_env && font_path != font_env) {
		std::fprintf(stderr, "Warning: HYDRA_FONT='%s' not found, using fallback: %s\n",
					 font_env, font_path);
	}

	const size_t NPIX = size_t(SCREEN_WIDTH) * SCREEN_HEIGHT;

	const char* frame_dump_path = std::getenv("FRAME_DUMP");
	const char* frame_dump_base = std::getenv("HYDRA_FRAME_BASE");
	const char* auto_exit_env   = std::getenv("AUTO_EXIT");
	bool auto_exit              = auto_exit_env && auto_exit_env[0] != '\0';
	const char* max_dump_env    = std::getenv("HYDRA_MAX_FRAME_DUMPS");
	int max_frame_dumps         = max_dump_env ? std::max(0, std::atoi(max_dump_env)) : 1;
	int frame_dumps_written     = 0;
	const char* autosave_cfg    = std::getenv("HYDRA_AUTOSAVE_CFG");
	const bool clear_each_frame = (std::getenv("HYDRA_CLEAR_EACH_FRAME") != nullptr);
	const char* fg_env = std::getenv("HYDRA_CLEAR_COLOR");
	uint32_t clear_color = 0;
	if (fg_env) {
		unsigned int r=0,g=0,b=0;
		if (std::sscanf(fg_env, "%u,%u,%u", &r, &g, &b) == 3) {
			clear_color = (0xFFu << 24) | ((r & 0xFFu) << 16) | ((g & 0xFFu) << 8) | (b & 0xFFu);
		}
	}
	std::vector<uint32_t> framebuffer(NPIX, clear_color);

	auto handle_resize = [&](int new_w, int new_h) {
		(void)new_w; (void)new_h;
		SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);
		recreate_texture();
		std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
		std::fprintf(stderr, "[hydra] window resized, refreshed texture and cleared framebuffer\n");
	};

	// Reset sequence
	for (int i = 0; i < 10; ++i) {
		top->clk = 0; top->eval(); main_time++;
		top->clk = 1; top->eval(); main_time++;
	}
	top->rst_n = 1;

	const char* cam_pos_env = std::getenv("HYDRA_CAM_POS");   // "x,y,z"
	const char* cam_ang_env = std::getenv("HYDRA_CAM_ANG");   // "yaw,pitch"
	auto parse_vec3 = [](const char* s, float def_x, float def_y, float def_z, float& ox, float& oy, float& oz) {
		ox = def_x; oy = def_y; oz = def_z;
		if (!s) return;
		if (std::sscanf(s, "%f,%f,%f", &ox, &oy, &oz) != 3) {
			ox = def_x; oy = def_y; oz = def_z;
		}
	};
	auto parse_vec2 = [](const char* s, float def_a, float def_b, float& oa, float& ob) {
		oa = def_a; ob = def_b;
		if (!s) return;
		if (std::sscanf(s, "%f,%f", &oa, &ob) != 2) {
			oa = def_a; ob = def_b;
		}
	};

	float pos_x = 10.0f;
	float pos_y = 10.0f;
	float pos_z = 10.0f;
	float yaw   = 0.0f;
	float pitch = 0.0f;
	parse_vec3(cam_pos_env, pos_x, pos_y, pos_z, pos_x, pos_y, pos_z);
	parse_vec2(cam_ang_env, yaw, pitch, yaw, pitch);
	const float default_pos_x = pos_x;
	const float default_pos_y = pos_y;
	const float default_pos_z = pos_z;
	const float default_yaw   = yaw;
	const float default_pitch = pitch;

	auto getenv_float = [](const char* name, float def_val) -> float {
		const char* v = std::getenv(name);
		if (!v) return def_val;
		return std::atof(v);
	};

	float move_speed      = getenv_float("HYDRA_MOVE_SPEED", 0.10f);
	float move_speed_fast = getenv_float("HYDRA_MOVE_SPEED_FAST", 0.35f);
	float turn_speed_keys = getenv_float("HYDRA_TURN_SPEED_KEYS", 0.04f);
	float mouse_sens      = getenv_float("HYDRA_MOUSE_SENS", 0.0025f);
	bool invert_y_mouse   = (std::getenv("HYDRA_INVERT_Y") != nullptr);
	const float base_move_speed      = move_speed;
	const float base_move_speed_fast = move_speed_fast;
	const float base_turn_speed_keys = turn_speed_keys;
	const float base_mouse_sens      = mouse_sens;

	bool smooth_surfaces = true;
	bool curvature       = true;
	bool extra_light     = false;
	bool diag_slice      = false;
	bool ray_jitter      = env_truthy("HYDRA_RAY_JITTER");
	bool spectrum_mode   = env_truthy("HYDRA_SPECTRUM_MODE");
	bool hud_enabled     = true;
	bool hud_theme_light = false;
	if (const char* hud_theme_env = std::getenv("HYDRA_HUD_THEME")) {
		if (strcasecmp(hud_theme_env, "light") == 0)
			hud_theme_light = true;
	}
	const char* pixel_view_env = std::getenv("HYDRA_PIXEL_VIEW");
	g_pixel_view_mode = pixel_view_from_string(pixel_view_env);
	bool safe_capture_mode = env_truthy("HYDRA_SAFE_CAPTURE");

	uint32_t world_seed_override = 0;
	const char* world_seed_env = std::getenv("HYDRA_WORLD_SEED");
	if (const char* seed_env = world_seed_env) {
		world_seed_override = static_cast<uint32_t>(std::strtoul(seed_env, nullptr, 0));
	}

	bool mouse_captured  = true;
	const char* mouse_cap_env = std::getenv("HYDRA_MOUSE_CAPTURE");
	if (mouse_cap_env && std::strcmp(mouse_cap_env, "0") == 0)
		mouse_captured = false;

	auto load_autosave_cfg = [&](const char* path) {
		if (!path || path[0] == '\0') return;
		FILE* f = std::fopen(path, "r");
		if (!f) return;
		char line[256];
		while (std::fgets(line, sizeof(line), f)) {
			if (std::strncmp(line, "cam_pos=", 8) == 0) {
				float lx, ly, lz;
				if (std::sscanf(line + 8, "%f,%f,%f", &lx, &ly, &lz) == 3) {
					pos_x = lx; pos_y = ly; pos_z = lz;
				}
			} else if (std::strncmp(line, "cam_ang=", 8) == 0) {
				float lyaw, lpitch;
				if (std::sscanf(line + 8, "%f,%f", &lyaw, &lpitch) == 2) {
					yaw = lyaw; pitch = lpitch;
				}
			} else if (std::strncmp(line, "flags=", 6) == 0) {
				int fs, fc, fe, fd;
				if (std::sscanf(line + 6, "%d,%d,%d,%d", &fs, &fc, &fe, &fd) == 4) {
					smooth_surfaces = (fs != 0);
					curvature       = (fc != 0);
					extra_light     = (fe != 0);
					diag_slice      = (fd != 0);
				}
			} else if (std::strncmp(line, "seed=", 5) == 0) {
				uint32_t s = 0;
				if (std::sscanf(line + 5, "%u", &s) == 1) {
					world_seed_override = s;
				}
			} else if (std::strncmp(line, "safe_capture=", 13) == 0) {
				int v = 0;
				if (std::sscanf(line + 13, "%d", &v) == 1) {
					safe_capture_mode = (v != 0);
				}
			}
		}
		std::fclose(f);
	};

	// Camera position clamping (configurable bounds)
	bool cam_clamp_enabled = (std::getenv("HYDRA_CAM_CLAMP") != nullptr);
	float cam_min = -1.0f;
	float cam_max = 65.0f;  // Default to 64x64x64 voxel volume with margin
	const char* cam_bounds_env = std::getenv("HYDRA_CAM_BOUNDS");
	if (cam_bounds_env) {
		float min_val, max_val;
		if (std::sscanf(cam_bounds_env, "%f,%f", &min_val, &max_val) == 2) {
			cam_min = min_val;
			cam_max = max_val;
		}
	}
	const bool base_cam_clamp = cam_clamp_enabled;
	const float base_cam_min = cam_min;
	const float base_cam_max = cam_max;

	// Apply initial clamping if enabled
	if (cam_clamp_enabled) {
		if (pos_x < cam_min) pos_x = cam_min;
		if (pos_x > cam_max) pos_x = cam_max;
		if (pos_y < cam_min) pos_y = cam_min;
		if (pos_y > cam_max) pos_y = cam_max;
		if (pos_z < cam_min) pos_z = cam_min;
		if (pos_z > cam_max) pos_z = cam_max;
	}
	if (autosave_cfg) {
		load_autosave_cfg(autosave_cfg);
	}

	// Frame pacing and timing configuration
	const char* idle_env = std::getenv("HYDRA_SIM_IDLE_MS");
	const int idle_ms = idle_env ? std::max(0, std::atoi(idle_env)) : 0;
	const char* fps_env = std::getenv("HYDRA_FPS_TARGET");
	const float fps_target = fps_env ? std::max(0.0f, static_cast<float>(std::atof(fps_env))) : 0.0f;

	// Print startup summary for reproducibility
	std::fprintf(stderr, "\n[hydra] === Startup Configuration ===\n");
	std::fprintf(stderr, "[hydra] Backend: %s\n", backend_name(backend));

	// Log backend selection details
	if (const char* v = std::getenv("HYDRA_BACKEND")) {
		std::fprintf(stderr, "[hydra] Backend selection: env var HYDRA_BACKEND=%s\n", v);
	} else if (const char* v = std::getenv("HYDRA_BACKEND_PREFS")) {
		std::fprintf(stderr, "[hydra] Backend selection: preference order HYDRA_BACKEND_PREFS=%s\n", v);
	} else {
		std::fprintf(stderr, "[hydra] Backend selection: auto (default preference order)\n");
	}

	// Log SDL info if available
	SDL_version ver;
	SDL_GetVersion(&ver);
	std::fprintf(stderr, "[hydra] SDL version: %d.%d.%d\n", ver.major, ver.minor, ver.patch);
	if (SDL_WasInit(SDL_INIT_VIDEO)) {
		const char* driver = SDL_GetCurrentVideoDriver();
		if (driver) {
			std::fprintf(stderr, "[hydra] SDL video driver: %s\n", driver);
		}
	}

	std::fprintf(stderr, "[hydra] Resolution: %dx%d\n", SCREEN_WIDTH, SCREEN_HEIGHT);
	std::fprintf(stderr, "[hydra] Font: %s (size %d)\n", font_path, font_size);
	if (std::getenv("HYDRA_VSYNC")) std::fprintf(stderr, "[hydra] HYDRA_VSYNC=%s\n", std::getenv("HYDRA_VSYNC"));
	if (frame_dump_path) std::fprintf(stderr, "[hydra] FRAME_DUMP=%s\n", frame_dump_path);
	if (max_dump_env) std::fprintf(stderr, "[hydra] HYDRA_MAX_FRAME_DUMPS=%s\n", max_dump_env);
	if (auto_exit) std::fprintf(stderr, "[hydra] AUTO_EXIT=1\n");
	if (cam_pos_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_POS=%s\n", cam_pos_env);
	if (cam_ang_env) std::fprintf(stderr, "[hydra] HYDRA_CAM_ANG=%s\n", cam_ang_env);
	if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
	if (pixel_view_env) std::fprintf(stderr, "[hydra] HYDRA_PIXEL_VIEW=%s\n", pixel_view_env);
	if (const char* v = std::getenv("HYDRA_WORLD_SEED")) std::fprintf(stderr, "[hydra] HYDRA_WORLD_SEED=%s\n", v);
	if (safe_capture_mode) std::fprintf(stderr, "[hydra] HYDRA_SAFE_CAPTURE=1\n");
	std::fprintf(stderr, "[hydra] Camera: pos=(%.1f,%.1f,%.1f) yaw=%.2f pitch=%.2f\n",
				 pos_x, pos_y, pos_z, yaw, pitch);
	std::fprintf(stderr, "[hydra] Move speed: %.3f (fast: %.3f) Mouse sens: %.4f%s\n",
				 move_speed, move_speed_fast, mouse_sens, invert_y_mouse ? " [Y-inverted]" : "");
	if (cam_clamp_enabled) std::fprintf(stderr, "[hydra] Camera clamping enabled: bounds=[%.1f, %.1f]\n", cam_min, cam_max);
	if (fps_target > 0.0f) std::fprintf(stderr, "[hydra] Frame pacing: target %.1f FPS\n", fps_target);
	if (clear_each_frame) std::fprintf(stderr, "[hydra] HYDRA_CLEAR_EACH_FRAME=1\n");
	if (autosave_cfg) std::fprintf(stderr, "[hydra] HYDRA_AUTOSAVE_CFG=%s\n", autosave_cfg);
	if (ray_jitter) std::fprintf(stderr, "[hydra] HYDRA_RAY_JITTER=1\n");
	std::fprintf(stderr, "[hydra] Pixel view: %s\n", pixel_view_mode_name(g_pixel_view_mode));
	std::fprintf(stderr, "[hydra] ==============================\n\n");

	RenderInstrumentationConfig inst_config;
	inst_config.cam_pos_x = pos_x;
	inst_config.cam_pos_y = pos_y;
	inst_config.cam_pos_z = pos_z;
	inst_config.yaw = yaw;
	inst_config.pitch = pitch;
	inst_config.smooth_surfaces = smooth_surfaces;
	inst_config.curvature = curvature;
	inst_config.extra_light = extra_light;
	inst_config.diag_slice = diag_slice;
	inst_config.ray_jitter = ray_jitter;
	inst_config.hud_enabled = hud_enabled;
	inst_config.fps_target = fps_target;
	inst_config.vsync = g_vsync;
	inst_config.backend_name = backend_name(backend);
	inst_config.backend_info = g_backend_info;
	inst_config.pixel_view = pixel_view_mode_name(g_pixel_view_mode);
	render_instrument.write_config(inst_config);

	bool selection_active = false;
	uint8_t selection_x = 0;
	uint8_t selection_y = 0;
	uint8_t selection_z = 0;
	uint64_t selection_word = 0;
	InputState keys;
	float help_overlay_timer = 3.5f;
	if (std::getenv("HYDRA_HELP_STARTUP")) {
		help_overlay_timer = env_truthy("HYDRA_HELP_STARTUP") ? 3.5f : 0.0f;
	}
	bool help_overlay_sticky = false;
	float sel_miss_timer = 0.0f;

	auto update_mouse_capture = [&]() {
		if (SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE) != 0) {
			std::fprintf(stderr, "Warning: SetRelativeMouseMode failed: %s\n", SDL_GetError());
		}
		SDL_SetWindowGrab(win, mouse_captured ? SDL_TRUE : SDL_FALSE);
		SDL_ShowCursor(mouse_captured ? SDL_FALSE : SDL_TRUE);
	};

	auto apply_camera_to_dut = [&]() {
		float dx = std::cos(yaw) * std::cos(pitch);
		float dy = std::sin(yaw) * std::cos(pitch);
		float dz = std::sin(pitch);

		float px = -dy * 0.66f;
		float py =  dx * 0.66f;

		root->voxel_framebuffer_top__DOT__cam_x       = int16_t(pos_x * FX);
		root->voxel_framebuffer_top__DOT__cam_y       = int16_t(pos_y * FX);
		root->voxel_framebuffer_top__DOT__cam_z       = int16_t(pos_z * FX);
		root->voxel_framebuffer_top__DOT__cam_dir_x   = int16_t(dx * FX);
		root->voxel_framebuffer_top__DOT__cam_dir_y   = int16_t(dy * FX);
		root->voxel_framebuffer_top__DOT__cam_dir_z   = int16_t(dz * FX);
		root->voxel_framebuffer_top__DOT__cam_plane_x = int16_t(px * FX);
		root->voxel_framebuffer_top__DOT__cam_plane_y = int16_t(py * FX);
	};

	auto apply_flags_to_dut = [&]() {
		root->voxel_framebuffer_top__DOT__cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
		root->voxel_framebuffer_top__DOT__cfg_curvature       = curvature       ? 1 : 0;
		root->voxel_framebuffer_top__DOT__cfg_extra_light     = extra_light     ? 1 : 0;
		root->voxel_framebuffer_top__DOT__cfg_diag_slice      = diag_slice     ? 1 : 0;
		root->voxel_framebuffer_top__DOT__cfg_ray_jitter      = ray_jitter     ? 1 : 0;
	};

	auto apply_selection_to_dut = [&]() {
		root->voxel_framebuffer_top__DOT__sel_active  = selection_active ? 1 : 0;
		root->voxel_framebuffer_top__DOT__sel_voxel_x = selection_x;
		root->voxel_framebuffer_top__DOT__sel_voxel_y = selection_y;
		root->voxel_framebuffer_top__DOT__sel_voxel_z = selection_z;
	};

	bool safe_defaults_mode = env_truthy("HYDRA_SAFE_DEFAULTS");
	auto apply_safe_defaults = [&]() {
		if (safe_defaults_mode) {
			move_speed      = 0.06f;
			move_speed_fast = 0.16f;
			turn_speed_keys = 0.03f;
			mouse_sens      = 0.0016f;
			cam_clamp_enabled = true;
		} else {
			move_speed      = base_move_speed;
			move_speed_fast = base_move_speed_fast;
			turn_speed_keys = base_turn_speed_keys;
			mouse_sens      = base_mouse_sens;
			cam_clamp_enabled = base_cam_clamp;
			cam_min = base_cam_min;
			cam_max = base_cam_max;
		}
	};

	apply_safe_defaults();
	if (cam_clamp_enabled) {
		if (pos_x < cam_min) pos_x = cam_min;
		if (pos_x > cam_max) pos_x = cam_max;
		if (pos_y < cam_min) pos_y = cam_min;
		if (pos_y > cam_max) pos_y = cam_max;
		if (pos_z < cam_min) pos_z = cam_min;
		if (pos_z > cam_max) pos_z = cam_max;
	}
	apply_camera_to_dut();
	apply_flags_to_dut();
	apply_selection_to_dut();
	root->voxel_framebuffer_top__DOT__world_seed = world_seed_override;
	update_mouse_capture();

	auto reset_key_state = [&]() { keys = InputState{}; };

	bool running = true;
	auto last_frame_time = std::chrono::high_resolution_clock::now();
	float fps = 0.0f;

	while (running && !Verilated::gotFinish()) {
		// Default: no debug write
		root->voxel_framebuffer_top__DOT__dbg_write_en = 0;

		SDL_Event ev;
		while (SDL_PollEvent(&ev)) {
			if (ev.type == SDL_QUIT) {
				running = false;
			} else if (ev.type == SDL_WINDOWEVENT) {
				if (ev.window.event == SDL_WINDOWEVENT_FOCUS_GAINED ||
					ev.window.event == SDL_WINDOWEVENT_TAKE_FOCUS) {
					update_mouse_capture();
				} else if (ev.window.event == SDL_WINDOWEVENT_FOCUS_LOST) {
					reset_key_state();
				} else if (ev.window.event == SDL_WINDOWEVENT_RESIZED ||
						   ev.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
					handle_resize(ev.window.data1, ev.window.data2);
				}
			} else if (ev.type == SDL_KEYDOWN || ev.type == SDL_KEYUP) {
				bool key_down = (ev.type == SDL_KEYDOWN);
				SDL_Scancode sc = ev.key.keysym.scancode;
				SDL_Keycode keycode = ev.key.keysym.sym;
				update_key_state(keys, sc, keycode, key_down);

				// Debug: Log 'o' and 'O' keys specifically
				if (key_down && (keycode == 'o' || keycode == 'O' || keycode == SDLK_o || sc == SDL_SCANCODE_O)) {
					std::fprintf(stderr, "[DEBUG] O key event: sc=%d kc=%d name=%s SDLK_o=%d\n",
								 (int)sc, (int)keycode, SDL_GetKeyName(keycode), (int)SDLK_o);
				}

				if (log_keys && log_keys_count < 200) {
					std::fprintf(stderr, "key %s sc=%d kc=%d name=%s mod=0x%x\n",
								 key_down ? "down" : "up",
								 (int)sc, (int)keycode,
								 SDL_GetKeyName(keycode),
								 ev.key.keysym.mod);
					++log_keys_count;
				}

				if (key_down) {
					switch (keycode) {
						case SDLK_ESCAPE:
							running = false;
							break;
						case SDLK_1: case SDLK_KP_1:
							smooth_surfaces = !smooth_surfaces;
							apply_flags_to_dut();
							if (log_keys && log_keys_count < 200) {
								std::fprintf(stderr, "toggle smooth -> %d\n", smooth_surfaces ? 1 : 0);
								++log_keys_count;
							}
							break;
						case SDLK_2: case SDLK_KP_2:
							curvature = !curvature;
							apply_flags_to_dut();
							if (log_keys && log_keys_count < 200) {
								std::fprintf(stderr, "toggle curvature -> %d\n", curvature ? 1 : 0);
								++log_keys_count;
							}
							break;
						case SDLK_3: case SDLK_KP_3:
							extra_light = !extra_light;
							apply_flags_to_dut();
							if (log_keys && log_keys_count < 200) {
								std::fprintf(stderr, "toggle extra_light -> %d\n", extra_light ? 1 : 0);
								++log_keys_count;
							}
							break;
						case SDLK_o:
							diag_slice = !diag_slice;
							apply_flags_to_dut();
							std::fprintf(stderr, "[DEBUG] 'o' key pressed: diag_slice now = %d\n", diag_slice ? 1 : 0);
							if (log_keys && log_keys_count < 200) {
								std::fprintf(stderr, "toggle diag_slice -> %d\n", diag_slice ? 1 : 0);
								++log_keys_count;
							}
							break;
						case SDLK_y:
							spectrum_mode = !spectrum_mode;
							std::fprintf(stderr, "[hydra] spectrum_mode %s\n", spectrum_mode ? "ON" : "OFF");
							break;
						case SDLK_j:
							ray_jitter = !ray_jitter;
							apply_flags_to_dut();
							std::fprintf(stderr, "[hydra] ray jitter %s\n", ray_jitter ? "ON" : "OFF");
							if (log_keys && log_keys_count < 200) {
								std::fprintf(stderr, "toggle ray_jitter -> %d\n", ray_jitter ? 1 : 0);
								++log_keys_count;
							}
							break;
						case SDLK_m:
							mouse_captured = !mouse_captured;
							update_mouse_capture();
							break;
						case SDLK_F3:
							safe_capture_mode = !safe_capture_mode;
							std::fprintf(stderr, "[hydra] safe capture %s\n", safe_capture_mode ? "ON" : "OFF");
							break;
						case SDLK_F4:
							g_fog_enabled = !g_fog_enabled;
							std::fprintf(stderr, "[hydra] depth fog %s\n", g_fog_enabled ? "ON" : "OFF");
							break;
						case SDLK_F2:
							safe_defaults_mode = !safe_defaults_mode;
							apply_safe_defaults();
							if (cam_clamp_enabled) {
								if (pos_x < cam_min) pos_x = cam_min;
								if (pos_x > cam_max) pos_x = cam_max;
								if (pos_y < cam_min) pos_y = cam_min;
								if (pos_y > cam_max) pos_y = cam_max;
								if (pos_z < cam_min) pos_z = cam_min;
								if (pos_z > cam_max) pos_z = cam_max;
							}
							std::fprintf(stderr, "[hydra] safe defaults %s (move=%.3f/%.3f turn=%.3f mouse=%.4f clamp=%d)\n",
										 safe_defaults_mode ? "ON" : "OFF",
										 move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
										 cam_clamp_enabled ? 1 : 0);
							break;
						case SDLK_F1:
							help_overlay_sticky = !help_overlay_sticky;
							if (!help_overlay_sticky && help_overlay_timer <= 0.0f) {
								help_overlay_timer = 3.0f;
							}
							break;
						case SDLK_SLASH:
							help_overlay_timer = 4.0f;
							help_overlay_sticky = false;
							break;
						case SDLK_f:
							if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
								selection_active = true;
								selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x);
								selection_y = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_y);
								selection_z = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_z);
								selection_word = static_cast<uint64_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_data);
								apply_selection_to_dut();
								sel_miss_timer = 0.0f;
							} else {
								sel_miss_timer = 1.5f;
							}
							break;
						case SDLK_g:
							selection_active = false;
							selection_word   = 0;
							apply_selection_to_dut();
							break;
						case SDLK_h:
							hud_enabled = !hud_enabled;
							break;
						case SDLK_t:
							hud_theme_light = !hud_theme_light;
							break;
						case SDLK_r:
							// Reset camera and flags to defaults; clear selection.
							pos_x = default_pos_x;
							pos_y = default_pos_y;
							pos_z = default_pos_z;
							yaw   = default_yaw;
							pitch = default_pitch;
							smooth_surfaces = true;
							curvature       = true;
							extra_light     = false;
							diag_slice      = false;
							selection_active = false;
							selection_word   = 0;
							apply_camera_to_dut();
							apply_flags_to_dut();
							apply_selection_to_dut();
							apply_safe_defaults();
							break;
						case SDLK_v: {
							if (g_pixel_view_mode == PixelViewMode::Color) {
								g_pixel_view_mode = PixelViewMode::Word0;
							} else if (g_pixel_view_mode == PixelViewMode::Word0) {
								g_pixel_view_mode = PixelViewMode::Word2;
							} else if (g_pixel_view_mode == PixelViewMode::Word2) {
								g_pixel_view_mode = PixelViewMode::SidebandMix;
							} else {
								g_pixel_view_mode = PixelViewMode::Color;
							}
							std::fprintf(stderr, "[hydra] pixel view -> %s\n",
										 pixel_view_mode_name(g_pixel_view_mode));
							break;
						}
						case SDLK_p:
							std::fprintf(stderr,
								"State: cam=(%.3f,%.3f,%.3f) yaw=%.3f pitch=%.3f flags[smooth=%d curv=%d extra=%d diag=%d] sel=%d (%u,%u,%u)\n",
								pos_x, pos_y, pos_z, yaw, pitch,
								smooth_surfaces ? 1 : 0,
								curvature ? 1 : 0,
								extra_light ? 1 : 0,
								diag_slice ? 1 : 0,
								selection_active ? 1 : 0,
								(unsigned)selection_x,
								(unsigned)selection_y,
								(unsigned)selection_z);
							break;
						case SDLK_s: {
							// Screenshot: save current framebuffer as timestamped PPM
							auto now = std::chrono::system_clock::now();
							auto secs = std::chrono::duration_cast<std::chrono::seconds>(
								now.time_since_epoch()).count();
							char filename[256];
							std::snprintf(filename, sizeof(filename), "sim/screenshot_%ld.ppm", secs);
							FILE* f = std::fopen(filename, "wb");
							if (!f) {
								std::fprintf(stderr, "Failed to open %s for screenshot\n", filename);
							} else {
								std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
								for (int y = 0; y < SCREEN_HEIGHT; ++y) {
									for (int x = 0; x < SCREEN_WIDTH; ++x) {
										uint32_t argb = framebuffer[size_t(y) * SCREEN_WIDTH + x];
										uint8_t rgb[3] = {
											(uint8_t)((argb >> 16) & 0xFF),
											(uint8_t)((argb >> 8) & 0xFF),
											(uint8_t)(argb & 0xFF)
										};
										std::fwrite(rgb, 1, 3, f);
									}
								}
								std::fclose(f);
								std::fprintf(stderr, "Screenshot saved: %s\n", filename);
							}
							break;
						}
						default: break;
					}

					// Edit selected voxel
					if (selection_active) {
						uint64_t w = selection_word;
						uint8_t material_props = (w >> 56) & 0xFF;
						uint8_t emissive       = (w >> 48) & 0xFF;
						uint8_t alpha          = (w >> 40) & 0xFF;
						uint8_t light          = (w >> 32) & 0xFF;
						uint8_t r              = (w >> 24) & 0xFF;
						uint8_t g              = (w >> 16) & 0xFF;
						uint8_t b              = (w >>  8) & 0xFF;
						uint8_t material_type  = (w >>  4) & 0x0F;

						bool do_write = false;

						if (keycode == SDLK_c) {
							material_type = (material_type + 1) & 0x0F;
							w &= ~((uint64_t)0x0F << 4);
							w |= (uint64_t(material_type) << 4);
							do_write = true;
						} else if (keycode == SDLK_x) {
							int val = emissive + 16;
							if (val > 255) val = 255;
							emissive = (uint8_t)val;
							w &= ~((uint64_t)0xFF << 48);
							w |= (uint64_t)emissive << 48;
							do_write = true;
						} else if (keycode == SDLK_z) {
							int val = emissive - 16;
							if (val < 0) val = 0;
							emissive = (uint8_t)val;
							w &= ~((uint64_t)0xFF << 48);
							w |= (uint64_t)emissive << 48;
							do_write = true;
						} else if (keycode == SDLK_b) {
							auto saturate_add = [](uint8_t c, int delta) -> uint8_t {
								int v = c + delta;
								if (v < 0) v = 0;
								if (v > 255) v = 255;
								return (uint8_t)v;
							};
							r = saturate_add(r, 16);
							g = saturate_add(g, 16);
							b = saturate_add(b, 16);
							w &= ~(((uint64_t)0xFFFFFF) << 8);
							w |= ((uint64_t)r << 24) |
								 ((uint64_t)g << 16) |
								 ((uint64_t)b <<  8);
							do_write = true;
						}

						if (do_write) {
							selection_word = w;
							uint32_t addr = voxel_addr_from_xyz(selection_x, selection_y, selection_z);
							root->voxel_framebuffer_top__DOT__dbg_write_addr = addr;
							root->voxel_framebuffer_top__DOT__dbg_write_data = w;
							root->voxel_framebuffer_top__DOT__dbg_write_en   = 1;
						}
					}
				}
			} else if (ev.type == SDL_MOUSEMOTION && mouse_captured && !safe_capture_mode) {
				int dx = ev.motion.xrel;
				int dy = ev.motion.yrel;
				yaw   += dx * mouse_sens;
				pitch += (invert_y_mouse ? dy : -dy) * mouse_sens;
	if (pitch >  1.50f) pitch =  1.50f;
	if (pitch < -1.50f) pitch = -1.50f;
				apply_camera_to_dut();
			}
		}

		bool cam_changed = false;

		float fdx = std::cos(yaw);
		float fdy = std::sin(yaw);
		float rdx = -std::sin(yaw);
		float rdy =  std::cos(yaw);

		float cur_speed = keys.fast ? move_speed_fast : move_speed;

		if (!safe_capture_mode) {
			if (keys.forward)      { pos_x += fdx * cur_speed; pos_y += fdy * cur_speed; cam_changed = true; }
			if (keys.back)         { pos_x -= fdx * cur_speed; pos_y -= fdy * cur_speed; cam_changed = true; }
			if (keys.strafe_left)  { pos_x += rdx * cur_speed; pos_y += rdy * cur_speed; cam_changed = true; }
			if (keys.strafe_right) { pos_x -= rdx * cur_speed; pos_y -= rdy * cur_speed; cam_changed = true; }
			if (keys.down)         { pos_z -= cur_speed; cam_changed = true; }
			if (keys.up)           { pos_z += cur_speed; cam_changed = true; }

			if (keys.yaw_left)   { yaw   -= turn_speed_keys; cam_changed = true; }
			if (keys.yaw_right)  { yaw   += turn_speed_keys; cam_changed = true; }
			if (keys.pitch_up)   { pitch += turn_speed_keys; cam_changed = true; }
			if (keys.pitch_down) { pitch -= turn_speed_keys; cam_changed = true; }
		}

		if (pitch >  1.50f) pitch =  1.50f;
		if (pitch < -1.50f) pitch = -1.50f;

		// Apply camera position clamping if enabled
		if (cam_clamp_enabled) {
			if (pos_x < cam_min) pos_x = cam_min;
			if (pos_x > cam_max) pos_x = cam_max;
			if (pos_y < cam_min) pos_y = cam_min;
			if (pos_y > cam_max) pos_y = cam_max;
			if (pos_z < cam_min) pos_z = cam_min;
			if (pos_z > cam_max) pos_z = cam_max;
		}

		if (cam_changed) {
			apply_camera_to_dut();
			if (log_keys && log_keys_count < 200) {
				std::fprintf(stderr, "cam pos=(%.2f, %.2f, %.2f) yaw=%.2f pitch=%.2f\n",
							 pos_x, pos_y, pos_z, yaw, pitch);
				++log_keys_count;
			}
		}

		// Ensure DUT flags follow local toggles every frame.
		apply_flags_to_dut();

		// Simulate HDL
		const int cycles_per_chunk = 2000;
		bool frame_done = false;
		std::chrono::high_resolution_clock::time_point sim_loop_start;
		if (render_instrument.active())
			sim_loop_start = std::chrono::high_resolution_clock::now();

		for (int i = 0; i < cycles_per_chunk; ++i) {
			top->clk = 1; top->eval(); main_time++;

			if (top->pixel_write_en) {
				uint32_t addr = top->pixel_addr;
				if (addr < NPIX) {
					uint32_t w0 = top->pixel_word0;
					uint32_t w1 = top->pixel_word1;
					uint32_t w2 = top->pixel_word2;
					uint32_t pixel_value = pixel96_to_argb(w0, w1, w2);
					uint8_t depth_byte = (w0 >> 16) & 0xFF;
					if (g_fog_enabled) {
						pixel_value = apply_fog(pixel_value, depth_byte);
					}
					framebuffer[addr] = pixel_value;
					record_color(frame_color_stats, pixel_value);
					frame_color_stats_dirty = true;

					if (log_frames && log_pixel_samples < 512) {
						uint32_t x = addr % SCREEN_WIDTH;
						uint32_t y = addr / SCREEN_WIDTH;
						// Probe a single vertical column through the middle of the screen
						// to see sky, geometry, and floor along one ray.
						if (x == SCREEN_WIDTH / 2) {
							std::fprintf(stderr,
								"probe x=%u y=%u addr=%u w0=%08x w1=%08x w2=%08x argb=%08x\n",
								x, y, addr, w0, w1, w2,
								pixel_value);
							++log_pixel_samples;
						}
					}
				}
				++pixels_this_frame;
			}

			if (top->frame_done)
				frame_done = true;

			top->clk = 0; top->eval(); main_time++;
		}

		if (frame_done) {
			 std::chrono::high_resolution_clock::time_point sim_loop_end;
			 if (render_instrument.active())
				 sim_loop_end = std::chrono::high_resolution_clock::now();
			 size_t pixels_written_this_frame = pixels_this_frame;
			 last_frame_color_stats = frame_color_stats;
			 last_frame_color_stats_valid = frame_color_stats_dirty;
			 frame_color_stats = color_range_default();
			 frame_color_stats_dirty = false;
			 if (auto_exit) {
				 running = false;
			 }
			if (frame_dump_path && frame_dump_path[0] != '\0' &&
				(max_frame_dumps == 0 || frame_dumps_written < max_frame_dumps)) {
				char pathbuf[512];
				if (frame_dump_base && max_frame_dumps != 1) {
					std::snprintf(pathbuf, sizeof(pathbuf), "%s_%d.ppm", frame_dump_base, frame_dumps_written);
				} else {
					std::snprintf(pathbuf, sizeof(pathbuf), "%s", frame_dump_path);
				}
				FILE* f = std::fopen(pathbuf, "wb");
				if (!f) {
					std::fprintf(stderr, "Failed to open FRAME_DUMP '%s' for write\n", pathbuf);
				} else {
					std::fprintf(stderr, "Writing frame dump to %s\n", pathbuf);
					std::fprintf(f, "P6\n%d %d\n255\n", SCREEN_WIDTH, SCREEN_HEIGHT);
					for (int fy = 0; fy < SCREEN_HEIGHT; ++fy) {
						for (int fx = 0; fx < SCREEN_WIDTH; ++fx) {
							uint32_t argb = framebuffer[size_t(fy) * SCREEN_WIDTH + fx];
							uint8_t r = (argb >> 16) & 0xFF;
							uint8_t g = (argb >> 8)  & 0xFF;
							uint8_t b =  argb        & 0xFF;
							uint8_t rgb[3] = {r, g, b};
							std::fwrite(rgb, 1, 3, f);
						}
					}
					std::fclose(f);
					++frame_dumps_written;
					if (max_frame_dumps > 0 && frame_dumps_written >= max_frame_dumps) {
						std::fprintf(stderr, "Max frame dumps (%d) reached, disabling further FRAME_DUMP writes\n", max_frame_dumps);
					}
				}
			}
			if (autosave_cfg && autosave_cfg[0] != '\0') {
				FILE* fcfg = std::fopen(autosave_cfg, "w");
				if (!fcfg) {
					std::fprintf(stderr, "Failed to write HYDRA_AUTOSAVE_CFG to '%s'\n", autosave_cfg);
				} else {
					std::fprintf(fcfg, "cam_pos=%.3f,%.3f,%.3f\n", pos_x, pos_y, pos_z);
					std::fprintf(fcfg, "cam_ang=%.3f,%.3f\n", yaw, pitch);
					std::fprintf(fcfg, "flags=%d,%d,%d,%d\n",
								 smooth_surfaces ? 1 : 0,
								 curvature ? 1 : 0,
								 extra_light ? 1 : 0,
								 diag_slice ? 1 : 0);
					std::fprintf(fcfg, "seed=%u\n", world_seed_override);
					std::fprintf(fcfg, "safe_capture=%d\n", safe_capture_mode ? 1 : 0);
					std::fclose(fcfg);
				}
			}

			if (log_frames) {
				size_t nonzero = 0;
				for (uint32_t v : framebuffer) {
					if (v != 0) ++nonzero;
				}
				uint32_t sample0 = framebuffer.empty() ? 0 : framebuffer[0];
				uint32_t sample_mid = framebuffer.empty() ? 0 : framebuffer[NPIX/2];
				std::fprintf(stderr,
					"frame %zu done, pixels_written=%zu nonzero=%zu sample0=%08x mid=%08x\n",
					frame_counter, pixels_this_frame, nonzero, sample0, sample_mid);
			}
			++frame_counter;

			auto now = std::chrono::high_resolution_clock::now();
			float dt = std::chrono::duration<float>(now - last_frame_time).count();
			if (fps_target > 0.0f) {
				float target_dt = 1.0f / fps_target;
				if (dt < target_dt) {
					int delay_ms = static_cast<int>((target_dt - dt) * 1000.0f);
					if (delay_ms > 0) {
						SDL_Delay(delay_ms);
						dt += static_cast<float>(delay_ms) / 1000.0f;
					}
				}
			}
			last_frame_time = now;
			if (dt > 0.0f) fps = 1.0f / dt;

			if (render_instrument.active()) {
				double ray_loop_ms = std::chrono::duration<double, std::milli>(sim_loop_end - sim_loop_start).count();
				double hud_present_ms = std::chrono::duration<double, std::milli>(hud_present_end - hud_present_start).count();
				double framebuffer_copy_ms = std::chrono::duration<double, std::milli>(copy_end - copy_start).count();
				render_instrument.record(frame_counter, fps, ray_loop_ms, hud_present_ms, framebuffer_copy_ms, static_cast<double>(dt * 1000.0f));
			}

			if (!help_overlay_sticky && help_overlay_timer > 0.0f && dt > 0.0f) {
				help_overlay_timer = std::max(0.0f, help_overlay_timer - dt);
			}
			if (sel_miss_timer > 0.0f && dt > 0.0f) {
				sel_miss_timer = std::max(0.0f, sel_miss_timer - dt);
			}

			uint64_t mem_cycle = root->voxel_framebuffer_top__DOT__mem_cycle_count;
			uint64_t mem_read  = root->voxel_framebuffer_top__DOT__mem_read_cycles;
			uint64_t mem_write = root->voxel_framebuffer_top__DOT__mem_write_cycles;
			uint64_t dc = mem_cycle - prev_mem_cycle;
			uint64_t dr = mem_read  - prev_mem_read;
			uint64_t dw = mem_write - prev_mem_write;
			prev_mem_cycle = mem_cycle;
			prev_mem_read  = mem_read;
			prev_mem_write = mem_write;
			if (dc > 0) {
				last_mem_read_util  = float(dr) / float(dc);
				last_mem_write_util = float(dw) / float(dc);
			}

			std::chrono::high_resolution_clock::time_point hud_present_start;
			if (render_instrument.active())
				hud_present_start = std::chrono::high_resolution_clock::now();
			if (hud_enabled && font) {
				// Darken or lighten HUD band in the framebuffer based on theme.
				for (int y = SCREEN_HEIGHT - HUD_HEIGHT; y < SCREEN_HEIGHT; ++y) {
					if (y < 0) continue;
					for (int x = 0; x < SCREEN_WIDTH; ++x) {
						uint32_t& px = framebuffer[static_cast<size_t>(y) * SCREEN_WIDTH + x];
						uint8_t r = (px >> 16) & 0xFF;
						uint8_t g = (px >> 8)  & 0xFF;
						uint8_t b =  px        & 0xFF;
						if (hud_theme_light) {
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
				uint32_t hits = root->voxel_framebuffer_top__DOT__core_dbg_hit_count;
				uint32_t ray_steps_total = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_total;
				uint32_t ray_steps_max   = root->voxel_framebuffer_top__DOT__core_dbg_ray_steps_max;
				uint32_t ray_miss_count  = root->voxel_framebuffer_top__DOT__core_dbg_ray_miss_count;
				const float pixel_count = float(SCREEN_WIDTH) * float(SCREEN_HEIGHT);
				const float ray_steps_avg = pixel_count > 0.0f
					? float(ray_steps_total) / pixel_count
					: 0.0f;
				const int hud_y = SCREEN_HEIGHT - HUD_HEIGHT + 4;
				int yoff = hud_y;
				SDL_Color hud_text_color = hud_theme_light ? SDL_Color{0,0,0,255} : SDL_Color{255,255,255,255};

				if (fps_target > 0.0f) {
					std::snprintf(buf, sizeof(buf),
						"FPS %.1f / %.0f (target) | Pos %.1f %.1f %.1f",
						fps, fps_target, pos_x, pos_y, pos_z);
				} else {
					std::snprintf(buf, sizeof(buf),
						"FPS %.1f | Pos %.1f %.1f %.1f",
						fps, pos_x, pos_y, pos_z);
				}
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"Yaw %.2f  Pitch %.2f",
					yaw, pitch);
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"[1] Smooth %s  [2] Curv %s  [3] Extra %s",
					smooth_surfaces ? "ON" : "OFF",
					curvature       ? "ON" : "OFF",
					extra_light     ? "ON" : "OFF");
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"[O] Slice %s  [J] Jitter %s  [M] Mouse %s",
					diag_slice     ? "ON" : "OFF",
					ray_jitter     ? "ON" : "OFF",
					mouse_captured ? "ON" : "OFF");
				SDL_Color mouse_line_color = mouse_captured ? hud_text_color : SDL_Color{255, 96, 96, 255};
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, mouse_line_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"Hits %u | ray avg %.1f max %u miss %u",
					hits, ray_steps_avg, ray_steps_max, ray_miss_count);
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"Mem: rd %.1f%% wr %.1f%%",
					last_mem_read_util * 100.0f,
					last_mem_write_util * 100.0f);
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				if (last_frame_color_stats_valid) {
					std::snprintf(buf, sizeof(buf),
						"RGB range: R%3u-%3u  G%3u-%3u  B%3u-%3u",
						(unsigned)last_frame_color_stats.min_r,
						(unsigned)last_frame_color_stats.max_r,
						(unsigned)last_frame_color_stats.min_g,
						(unsigned)last_frame_color_stats.max_g,
						(unsigned)last_frame_color_stats.min_b,
						(unsigned)last_frame_color_stats.max_b);
				} else {
					std::snprintf(buf, sizeof(buf), "RGB range: capturing...");
				}
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"Pixel view: %s  [V] cycle",
					pixel_view_mode_name(g_pixel_view_mode));
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),
					"Safe defaults: %s [F2] (move %.3f/%.3f turn %.3f sens %.4f clamp %s)",
					safe_defaults_mode ? "ON" : "OFF",
					move_speed, move_speed_fast, turn_speed_keys, mouse_sens,
					cam_clamp_enabled ? "ON" : "OFF");
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				// Fog status (toggle with F4)
				std::snprintf(buf, sizeof(buf),
					"Fog: %s [F4] color=%06x density=%.2f",
					g_fog_enabled ? "ON" : "OFF",
					(g_fog_color & 0x00FFFFFFu),
					g_fog_density);
				draw_text_to_fb(framebuffer, SCREEN_WIDTH, SCREEN_HEIGHT, font, buf, 6, yoff, hud_text_color);
				yoff += 14;

				std::snprintf(buf, sizeof(buf),

