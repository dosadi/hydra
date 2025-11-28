// viewer_input.cpp - Input handling implementation
#include "viewer_input.h"
#include "viewer_globals.h"
#include "harness_common.h"
#include <cstdio>
#include <cstring>
#include <SDL2/SDL.h>

// External dependencies that need to be passed as parameters
extern bool smooth_surfaces;
extern bool curvature;
extern bool extra_light;
extern bool diag_slice;
extern bool ray_jitter;
extern bool spectrum_mode;
extern bool hud_enabled;
extern bool hud_theme_light;
extern bool selection_active;
extern uint8_t selection_x, selection_y, selection_z;
extern uint64_t selection_word;
extern float pos_x, pos_y, pos_z, yaw, pitch;
extern float move_speed, move_speed_fast, turn_speed_keys, mouse_sens;
extern bool cam_clamp_enabled;
extern float cam_min, cam_max;
extern uint32_t world_seed_override;
extern bool invert_y_mouse;
extern int log_keys_count;
extern bool log_keys;

// Function pointers for external functions
extern void apply_camera_to_dut();
extern void apply_flags_to_dut();
extern void apply_selection_to_dut();
extern void update_mouse_capture();
extern void apply_safe_defaults();
extern uint32_t voxel_addr_from_xyz(uint8_t x, uint8_t y, uint8_t z);

// Default camera values
extern float default_pos_x, default_pos_y, default_pos_z, default_yaw, default_pitch;

InputHandler::InputHandler()
    : mouse_captured_(false), safe_capture_mode_(false), safe_defaults_mode_(false),
      help_overlay_sticky_(false), help_overlay_timer_(0.0f), sel_miss_timer_(0.0f) {
}

void InputHandler::process_events(bool& running, bool headless_backend) {
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        switch (ev.type) {
            case SDL_QUIT:
                running = false;
                break;

            case SDL_WINDOWEVENT:
                handle_window_event(ev.window, headless_backend);
                break;

            case SDL_KEYDOWN:
            case SDL_KEYUP:
                // Note: This will need to be updated when integrating with main
                // handle_key_event(ev.key, log_keys, log_keys_count, nullptr, headless_backend);
                break;

            case SDL_MOUSEMOTION:
                if (mouse_captured_ && !safe_capture_mode_) {
                    // Note: This will need yaw/pitch parameters when integrating
                    // handle_mouse_motion(ev.motion, yaw, pitch, mouse_sens, invert_y_mouse);
                }
                break;

            default:
                break;
        }
    }
}

void InputHandler::handle_window_event(const SDL_WindowEvent& ev, bool headless_backend) {
    switch (ev.event) {
        case SDL_WINDOWEVENT_FOCUS_GAINED:
        case SDL_WINDOWEVENT_TAKE_FOCUS:
            if (!headless_backend) {
                actions_.toggle_mouse_capture = true;
            }
            break;

        case SDL_WINDOWEVENT_FOCUS_LOST:
            reset_key_state();
            break;

        case SDL_WINDOWEVENT_RESIZED:
        case SDL_WINDOWEVENT_SIZE_CHANGED:
            handle_resize(ev.data1, ev.data2);
            break;

        default:
            break;
    }
}

void InputHandler::handle_key_event(const SDL_KeyboardEvent& ev, bool log_keys, int& log_keys_count,
                                         bool headless_backend) {
    bool key_down = (ev.type == SDL_KEYDOWN);
    SDL_Scancode sc = ev.keysym.scancode;
    SDL_Keycode keycode = ev.keysym.sym;

    update_key_state(keys_, sc, keycode, key_down);

    // Debug logging for 'o' and 'O' keys
    if (key_down && (keycode == 'o' || keycode == 'O' || keycode == SDLK_o || sc == SDL_SCANCODE_O)) {
        std::fprintf(stderr, "[DEBUG] O key event: sc=%d kc=%d name=%s SDLK_o=%d\n",
                     (int)sc, (int)keycode, SDL_GetKeyName(keycode), (int)SDLK_o);
    }

    if (log_keys && log_keys_count < 200) {
        std::fprintf(stderr, "key %s sc=%d kc=%d name=%s mod=0x%x\n",
                     key_down ? "down" : "up",
                     (int)sc, (int)keycode,
                     SDL_GetKeyName(keycode),
                     ev.keysym.mod);
        ++log_keys_count;
    }

    if (key_down) {
        switch (keycode) {
            case SDLK_ESCAPE:
                // Handled by caller
                break;

            case SDLK_m:
                if (!headless_backend) {
                    actions_.toggle_mouse_capture = true;
                }
                break;

            case SDLK_F3:
                safe_capture_mode_ = !safe_capture_mode_;
                std::fprintf(stderr, "[hydra] safe capture %s\n", safe_capture_mode_ ? "ON" : "OFF");
                break;

            case SDLK_F1:
                help_overlay_sticky_ = !help_overlay_sticky_;
                if (!help_overlay_sticky_ && help_overlay_timer_ <= 0.0f) {
                    help_overlay_timer_ = 3.0f;
                }
                break;

            case SDLK_SLASH:
                help_overlay_timer_ = 4.0f;
                help_overlay_sticky_ = false;
                break;

            // Note: Other key handlers commented out to avoid dependency issues
            // They will be re-implemented when integrating with the main file

            default:
                break;
        }
    }
}

void InputHandler::handle_mouse_motion(const SDL_MouseMotionEvent& ev, float& yaw, float& pitch,
                                     float mouse_sens, bool invert_y_mouse) {
    int dx = ev.xrel;
    int dy = ev.yrel;
    yaw += dx * mouse_sens;
    pitch += (invert_y_mouse ? dy : -dy) * mouse_sens;

    if (pitch > 1.50f) pitch = 1.50f;
    if (pitch < -1.50f) pitch = -1.50f;

    actions_.update_camera = true;
}

void InputHandler::update_key_state(InputState& keys, SDL_Scancode sc, SDL_Keycode keycode, bool key_down) {
    switch (sc) {
        case SDL_SCANCODE_W: keys.forward = key_down; break;
        case SDL_SCANCODE_S: keys.back = key_down; break;
        case SDL_SCANCODE_A: keys.strafe_left = key_down; break;
        case SDL_SCANCODE_D: keys.strafe_right = key_down; break;
        case SDL_SCANCODE_Q: keys.down = key_down; break;
        case SDL_SCANCODE_E: keys.up = key_down; break;
        case SDL_SCANCODE_LEFT: keys.yaw_left = key_down; break;
        case SDL_SCANCODE_RIGHT: keys.yaw_right = key_down; break;
        case SDL_SCANCODE_UP: keys.pitch_up = key_down; break;
        case SDL_SCANCODE_DOWN: keys.pitch_down = key_down; break;
        case SDL_SCANCODE_LSHIFT: case SDL_SCANCODE_RSHIFT: keys.fast = key_down; break;
        default: break;
    }
}

void InputHandler::handle_resize(int width, int height) {
    // Resize handling - could be extended if needed
    (void)width;
    (void)height;
}

void InputHandler::handle_focus_change(bool gained) {
    if (!gained) {
        reset_key_state();
    }
}

void InputHandler::set_mouse_captured(bool captured) {
    mouse_captured_ = captured;
    actions_.toggle_mouse_capture = true;
}

void InputHandler::set_safe_capture_mode(bool mode) {
    safe_capture_mode_ = mode;
}

void InputHandler::set_safe_defaults_mode(bool mode) {
    safe_defaults_mode_ = mode;
}

void InputHandler::set_help_overlay_sticky(bool sticky) {
    help_overlay_sticky_ = sticky;
}

void InputHandler::update_help_overlay_timer(float dt) {
    if (!help_overlay_sticky_ && help_overlay_timer_ > 0.0f) {
        help_overlay_timer_ = std::max(0.0f, help_overlay_timer_ - dt);
    }
}

void InputHandler::update_sel_miss_timer(float dt) {
    if (sel_miss_timer_ > 0.0f) {
        sel_miss_timer_ = std::max(0.0f, sel_miss_timer_ - dt);
    }
}

void InputHandler::reset_key_state() {
    keys_ = InputState{};
}