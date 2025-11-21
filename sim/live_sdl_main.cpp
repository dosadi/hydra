// ============================================================================
// sim/live_sdl_main.cpp
// Verilator + SDL2 live viewer for voxel_framebuffer_top
// ============================================================================

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"
#include "Vvoxel_framebuffer_top___024root.h"

#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <cmath>
#include <chrono>
#include <cstring>
#include <cstdlib>
#include <cctype>

static const int   SCREEN_WIDTH  = 480;
static const int   SCREEN_HEIGHT = 360;
static const int   HUD_HEIGHT    = 96;
static const float FX            = 256.0f;  // fixed-point scale

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    (void)w0; (void)w2;
    uint8_t r = (w1 >> 24) & 0xFF;
    uint8_t g = (w1 >> 16) & 0xFF;
    uint8_t b = (w1 >>  8) & 0xFF;
    uint8_t a = 0xFF;
    return (uint32_t(a) << 24) |
           (uint32_t(r) << 16) |
           (uint32_t(g) << 8)  |
            uint32_t(b);
}

static inline uint32_t voxel_addr_from_xyz(uint8_t x, uint8_t y, uint8_t z) {
    return (uint32_t(x) << 12) | (uint32_t(y) << 6) | uint32_t(z);
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

static void draw_text(SDL_Renderer* ren, TTF_Font* font,
                      const std::string& txt,
                      int x, int y,
                      SDL_Color color = {255,255,255,255})
{
    SDL_Surface* surf = TTF_RenderText_Blended(font, txt.c_str(), color);
    if (!surf) return;
    SDL_Texture* tex = SDL_CreateTextureFromSurface(ren, surf);
    SDL_FreeSurface(surf);
    if (!tex) return;

    int w, h;
    SDL_QueryTexture(tex, nullptr, nullptr, &w, &h);
    SDL_Rect dst{ x, y, w, h };
    SDL_RenderCopy(ren, tex, nullptr, &dst);
    SDL_DestroyTexture(tex);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vvoxel_framebuffer_top* top = new Vvoxel_framebuffer_top;
    auto* root = top->rootp;  // Access internal regs exposed by Verilator
    top->clk   = 0;
    top->rst_n = 0;

    const bool log_keys = (std::getenv("LOG_KEYS") != nullptr);
    const bool log_frames = (std::getenv("LOG_FRAMES") != nullptr);
    int log_keys_count = 0;
    size_t pixels_this_frame = 0;
    size_t frame_counter = 0;
    int log_pixel_samples = 0;

    // Ensure SDL grabs keyboard focus and uses software paths by default.
    SDL_SetHint(SDL_HINT_GRAB_KEYBOARD, "1");
    SDL_SetHint(SDL_HINT_MOUSE_RELATIVE_MODE_WARP, "1");
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "software");

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
        die(std::string("SDL_Init: ") + SDL_GetError());
    if (TTF_Init() != 0)
        die(std::string("TTF_Init: ") + TTF_GetError());

    SDL_Window* win = SDL_CreateWindow(
        "Voxel Accelerator — Interactive Raycaster",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2,
        SDL_WINDOW_RESIZABLE
    );
    if (!win) die("Cannot create SDL window");
    SDL_RaiseWindow(win);

    SDL_Renderer* ren = SDL_CreateRenderer(
        win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );
    if (!ren) die("Renderer creation failed");

    SDL_RenderSetLogicalSize(ren, SCREEN_WIDTH, SCREEN_HEIGHT);

    SDL_Texture* tex = SDL_CreateTexture(
        ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        SCREEN_WIDTH, SCREEN_HEIGHT
    );
    if (!tex) die("Texture creation failed");

    TTF_Font* font = TTF_OpenFont(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11
    );
    if (!font) {
        std::fprintf(stderr, "Warning: could not open font, HUD text disabled\n");
    }

    const size_t NPIX = size_t(SCREEN_WIDTH) * SCREEN_HEIGHT;
    std::vector<uint32_t> framebuffer(NPIX, 0);

    // Reset sequence
    for (int i = 0; i < 10; ++i) {
        top->clk = 0; top->eval(); main_time++;
        top->clk = 1; top->eval(); main_time++;
    }
    top->rst_n = 1;

    float pos_x = 10.0f;
    float pos_y = 10.0f;
    float pos_z = 10.0f;
    float yaw   = 0.0f;
    float pitch = 0.0f;

    float move_speed      = 0.10f;
    float move_speed_fast = 0.35f;
    float turn_speed_keys = 0.04f;
    float mouse_sens      = 0.0025f;

    bool smooth_surfaces = true;
    bool curvature       = true;
    bool extra_light     = false;
    bool diag_slice      = false;

    bool mouse_captured  = true;

    bool selection_active = false;
    uint8_t selection_x = 0;
    uint8_t selection_y = 0;
    uint8_t selection_z = 0;
    uint64_t selection_word = 0;
    InputState keys;

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
    };

    auto apply_selection_to_dut = [&]() {
        root->voxel_framebuffer_top__DOT__sel_active  = selection_active ? 1 : 0;
        root->voxel_framebuffer_top__DOT__sel_voxel_x = selection_x;
        root->voxel_framebuffer_top__DOT__sel_voxel_y = selection_y;
        root->voxel_framebuffer_top__DOT__sel_voxel_z = selection_z;
    };

    apply_camera_to_dut();
    apply_flags_to_dut();
    apply_selection_to_dut();
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
                            if (log_keys && log_keys_count < 200) {
                                std::fprintf(stderr, "toggle diag_slice -> %d\n", diag_slice ? 1 : 0);
                                ++log_keys_count;
                            }
                            break;
                        case SDLK_m:
                            mouse_captured = !mouse_captured;
                            update_mouse_capture();
                            break;
                        case SDLK_f:
                            if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
                                selection_active = true;
                                selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x);
                                selection_y = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_y);
                                selection_z = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_z);
                                selection_word = static_cast<uint64_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_data);
                                apply_selection_to_dut();
                            }
                            break;
                        case SDLK_g:
                            selection_active = false;
                            selection_word   = 0;
                            apply_selection_to_dut();
                            break;
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
            } else if (ev.type == SDL_MOUSEMOTION && mouse_captured) {
                int dx = ev.motion.xrel;
                int dy = ev.motion.yrel;
                yaw   += dx * mouse_sens;
                pitch -= dy * mouse_sens;
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

        if (pitch >  1.50f) pitch =  1.50f;
        if (pitch < -1.50f) pitch = -1.50f;

        if (cam_changed) {
            apply_camera_to_dut();
            if (log_keys && log_keys_count < 200) {
                std::fprintf(stderr, "cam pos=(%.2f, %.2f, %.2f) yaw=%.2f pitch=%.2f\n",
                             pos_x, pos_y, pos_z, yaw, pitch);
                ++log_keys_count;
            }
        }

        // Simulate HDL
        const int cycles_per_chunk = 2000;
        bool frame_done = false;

        for (int i = 0; i < cycles_per_chunk; ++i) {
            top->clk = 1; top->eval(); main_time++;

            if (top->pixel_write_en) {
                uint32_t addr = top->pixel_addr;
                if (addr < NPIX) {
                    uint32_t w0 = top->pixel_word0;
                    uint32_t w1 = top->pixel_word1;
                    uint32_t w2 = top->pixel_word2;
                    framebuffer[addr] = pixel96_to_argb(w0, w1, w2);

                    if (log_frames && log_pixel_samples < 8) {
                        std::fprintf(stderr, "pix addr=%u w0=%08x w1=%08x w2=%08x argb=%08x\n",
                                     addr, w0, w1, w2,
                                     pixel96_to_argb(w0, w1, w2));
                        ++log_pixel_samples;
                    }
                }
                ++pixels_this_frame;
            }

            if (top->frame_done)
                frame_done = true;

            top->clk = 0; top->eval(); main_time++;
        }

        if (frame_done) {
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
            last_frame_time = now;
            if (dt > 0.0f) fps = 1.0f / dt;

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

            SDL_SetRenderDrawBlendMode(ren, SDL_BLENDMODE_BLEND);
            SDL_SetRenderDrawColor(ren, 0, 0, 0, 120);
            SDL_Rect hud_rect{0, SCREEN_HEIGHT - HUD_HEIGHT, SCREEN_WIDTH, HUD_HEIGHT};
            SDL_RenderFillRect(ren, &hud_rect);

            if (font) {
                char buf[256];
                uint32_t hits = root->voxel_framebuffer_top__DOT__core_dbg_hit_count;
                const int hud_y = SCREEN_HEIGHT - HUD_HEIGHT + 4;
                int yoff = hud_y;

                std::snprintf(buf, sizeof(buf),
                    "FPS %.1f | Pos %.1f %.1f %.1f",
                    fps, pos_x, pos_y, pos_z);
                draw_text(ren, font, buf, 6, yoff);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Yaw %.2f  Pitch %.2f",
                    yaw, pitch);
                draw_text(ren, font, buf, 6, yoff);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "[1] Smooth %s  [2] Curv %s  [3] Extra %s",
                    smooth_surfaces ? "ON" : "OFF",
                    curvature       ? "ON" : "OFF",
                    extra_light     ? "ON" : "OFF");
                draw_text(ren, font, buf, 6, yoff);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "[O] Slice %s  [M] Mouse %s",
                    diag_slice     ? "ON" : "OFF",
                    mouse_captured ? "ON" : "OFF");
                draw_text(ren, font, buf, 6, yoff);
                yoff += 14;

                std::snprintf(buf, sizeof(buf),
                    "Hits this frame: %u", hits);
                draw_text(ren, font, buf, 6, yoff);
                yoff += 14;

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
                draw_text(ren, font, buf, 6, yoff);
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
                draw_text(ren, font, buf, 6, yoff);
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
                    draw_text(ren, font, buf, 6, yoff);
                }
            }

            SDL_RenderPresent(ren);

            pixels_this_frame = 0;
        }

        SDL_Delay(1);
    }

    top->final();
    delete top;

    if (font) TTF_CloseFont(font);
    TTF_Quit();
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
