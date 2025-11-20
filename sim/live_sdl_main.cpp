// ============================================================================
// sim/live_sdl_main.cpp
// Verilator + SDL2 live viewer for voxel_framebuffer_top
// ============================================================================

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <verilated.h>
#include "Vvoxel_framebuffer_top.h"

#include <cstdint>
#include <cstdio>
#include <vector>
#include <string>
#include <cmath>
#include <chrono>
#include <cstring>

static const int   SCREEN_WIDTH  = 320;
static const int   SCREEN_HEIGHT = 240;
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
    top->clk   = 0;
    top->rst_n = 0;

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
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12
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

    bool mouse_captured  = true;

    bool selection_active = false;
    uint8_t selection_x = 0;
    uint8_t selection_y = 0;
    uint8_t selection_z = 0;
    uint64_t selection_word = 0;

    auto update_mouse_capture = [&]() {
        SDL_SetRelativeMouseMode(mouse_captured ? SDL_TRUE : SDL_FALSE);
        SDL_ShowCursor(mouse_captured ? SDL_FALSE : SDL_TRUE);
    };

    auto apply_camera_to_dut = [&]() {
        float dx = std::cos(yaw) * std::cos(pitch);
        float dy = std::sin(yaw) * std::cos(pitch);
        float dz = std::sin(pitch);

        float px = -dy * 0.66f;
        float py =  dx * 0.66f;

        top->cam_x       = int16_t(pos_x * FX);
        top->cam_y       = int16_t(pos_y * FX);
        top->cam_z       = int16_t(pos_z * FX);
        top->cam_dir_x   = int16_t(dx * FX);
        top->cam_dir_y   = int16_t(dy * FX);
        top->cam_dir_z   = int16_t(dz * FX);
        top->cam_plane_x = int16_t(px * FX);
        top->cam_plane_y = int16_t(py * FX);
    };

    auto apply_flags_to_dut = [&]() {
        top->cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
        top->cfg_curvature       = curvature       ? 1 : 0;
        top->cfg_extra_light     = extra_light     ? 1 : 0;
    };

    auto apply_selection_to_dut = [&]() {
        top->sel_active   = selection_active ? 1 : 0;
        top->sel_voxel_x  = selection_x;
        top->sel_voxel_y  = selection_y;
        top->sel_voxel_z  = selection_z;
    };

    apply_camera_to_dut();
    apply_flags_to_dut();
    apply_selection_to_dut();
    update_mouse_capture();

    bool running = true;
    auto last_frame_time = std::chrono::high_resolution_clock::now();
    float fps = 0.0f;

    while (running && !Verilated::gotFinish()) {
        // Default: no debug write
        top->dbg_write_en = 0;

        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) {
                running = false;
            } else if (ev.type == SDL_KEYDOWN) {
                SDL_Keycode key = ev.key.keysym.sym;

                if (key == SDLK_ESCAPE) {
                    running = false;
                } else if (key == SDLK_1) {
                    smooth_surfaces = !smooth_surfaces;
                    apply_flags_to_dut();
                } else if (key == SDLK_2) {
                    curvature = !curvature;
                    apply_flags_to_dut();
                } else if (key == SDLK_3) {
                    extra_light = !extra_light;
                    apply_flags_to_dut();
                } else if (key == SDLK_m || key == SDLK_M) {
                    mouse_captured = !mouse_captured;
                    update_mouse_capture();
                }

                // Selection
                else if (key == SDLK_f || key == SDLK_F) {
                    if (top->cursor_hit_valid) {
                        selection_active = true;
                        selection_x = static_cast<uint8_t>(top->cursor_voxel_x);
                        selection_y = static_cast<uint8_t>(top->cursor_voxel_y);
                        selection_z = static_cast<uint8_t>(top->cursor_voxel_z);
                        selection_word = static_cast<uint64_t>(top->cursor_voxel_data);
                        apply_selection_to_dut();
                    }
                } else if (key == SDLK_g || key == SDLK_G) {
                    selection_active = false;
                    selection_word   = 0;
                    apply_selection_to_dut();
                }

                // Edit selected voxel
                else if (selection_active) {
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

                    if (key == SDLK_c || key == SDLK_C) {
                        material_type = (material_type + 1) & 0x0F;
                        w &= ~((uint64_t)0x0F << 4);
                        w |= (uint64_t(material_type) << 4);
                        do_write = true;
                    } else if (key == SDLK_x || key == SDLK_X) {
                        int val = emissive + 16;
                        if (val > 255) val = 255;
                        emissive = (uint8_t)val;
                        w &= ~((uint64_t)0xFF << 48);
                        w |= (uint64_t)emissive << 48;
                        do_write = true;
                    } else if (key == SDLK_z || key == SDLK_Z) {
                        int val = emissive - 16;
                        if (val < 0) val = 0;
                        emissive = (uint8_t)val;
                        w &= ~((uint64_t)0xFF << 48);
                        w |= (uint64_t)emissive << 48;
                        do_write = true;
                    } else if (key == SDLK_b || key == SDLK_B) {
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
                        top->dbg_write_addr = addr;
                        top->dbg_write_data = w;
                        top->dbg_write_en   = 1;
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

        const Uint8* keys = SDL_GetKeyboardState(nullptr);
        bool cam_changed = false;

        float fdx = std::cos(yaw);
        float fdy = std::sin(yaw);
        float rdx = -std::sin(yaw);
        float rdy =  std::cos(yaw);

        float cur_speed = (keys[SDL_SCANCODE_LSHIFT] ||
                           keys[SDL_SCANCODE_RSHIFT]) ?
                           move_speed_fast : move_speed;

        if (keys[SDL_SCANCODE_W]) { pos_x += fdx * cur_speed; pos_y += fdy * cur_speed; cam_changed = true; }
        if (keys[SDL_SCANCODE_S]) { pos_x -= fdx * cur_speed; pos_y -= fdy * cur_speed; cam_changed = true; }
        if (keys[SDL_SCANCODE_A]) { pos_x += rdx * cur_speed; pos_y += rdy * cur_speed; cam_changed = true; }
        if (keys[SDL_SCANCODE_D]) { pos_x -= rdx * cur_speed; pos_y -= rdy * cur_speed; cam_changed = true; }
        if (keys[SDL_SCANCODE_Q]) { pos_z -= cur_speed; cam_changed = true; }
        if (keys[SDL_SCANCODE_E]) { pos_z += cur_speed; cam_changed = true; }

        if (keys[SDL_SCANCODE_LEFT])  { yaw   -= turn_speed_keys; cam_changed = true; }
        if (keys[SDL_SCANCODE_RIGHT]) { yaw   += turn_speed_keys; cam_changed = true; }
        if (keys[SDL_SCANCODE_UP])    { pitch += turn_speed_keys; cam_changed = true; }
        if (keys[SDL_SCANCODE_DOWN])  { pitch -= turn_speed_keys; cam_changed = true; }

        if (pitch >  1.50f) pitch =  1.50f;
        if (pitch < -1.50f) pitch = -1.50f;

        if (cam_changed)
            apply_camera_to_dut();

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
                }
            }

            if (top->frame_done)
                frame_done = true;

            top->clk = 0; top->eval(); main_time++;
        }

        if (frame_done) {
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
            SDL_SetRenderDrawColor(ren, 0, 0, 0, 160);
            SDL_Rect hud_rect{0, 0, SCREEN_WIDTH, 84};
            SDL_RenderFillRect(ren, &hud_rect);

            if (font) {
                char buf[256];

                std::snprintf(buf, sizeof(buf),
                    "FPS: %.1f  Pos:(%.1f, %.1f, %.1f)  Yaw:%.2f  Pitch:%.2f",
                    fps, pos_x, pos_y, pos_z, yaw, pitch);
                draw_text(ren, font, buf, 4, 4);

                std::snprintf(buf, sizeof(buf),
                    "[1] Smooth:%s  [2] Curv:%s  [3] ExtraLight:%s  [M] Mouse:%s",
                    smooth_surfaces ? "ON" : "OFF",
                    curvature       ? "ON" : "OFF",
                    extra_light     ? "ON" : "OFF",
                    mouse_captured  ? "ON" : "OFF");
                draw_text(ren, font, buf, 4, 20);

                if (top->cursor_hit_valid) {
                    std::snprintf(buf, sizeof(buf),
                        "Cursor: voxel=(%u,%u,%u) mat=0x%02X",
                        (unsigned)top->cursor_voxel_x,
                        (unsigned)top->cursor_voxel_y,
                        (unsigned)top->cursor_voxel_z,
                        (unsigned)(top->cursor_material_id & 0xFF));
                } else {
                    std::snprintf(buf, sizeof(buf),
                        "Cursor: (no hit)");
                }
                draw_text(ren, font, buf, 4, 36);

                if (selection_active) {
                    std::snprintf(buf, sizeof(buf),
                        "Sel: voxel=(%u,%u,%u)  (G=clear, F=select)",
                        (unsigned)selection_x,
                        (unsigned)selection_y,
                        (unsigned)selection_z);
                } else {
                    std::snprintf(buf, sizeof(buf),
                        "Sel: (none)  (aim + F to select)");
                }
                draw_text(ren, font, buf, 4, 52);

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
                        "Probe: RGBA=(%3u,%3u,%3u,%3u) L=%3u MType=%u MProps=0x%02X Emis=%3u",
                        r, g, b, alpha, light,
                        material_type, material_props, emissive);
                    draw_text(ren, font, buf, 4, 68);
                }
            }

            SDL_RenderPresent(ren);
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
