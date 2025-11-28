// viewer_input.h - Input handling and state management
#ifndef VIEWER_INPUT_H
#define VIEWER_INPUT_H

#include <SDL2/SDL.h>
#include <cstdint>
#include <string>

// Forward declarations
class Vvoxel_framebuffer_top___024root;

// Input state structure
struct InputState {
    bool forward = false;
    bool back = false;
    bool strafe_left = false;
    bool strafe_right = false;
    bool up = false;
    bool down = false;
    bool yaw_left = false;
    bool yaw_right = false;
    bool pitch_up = false;
    bool pitch_down = false;
    bool fast = false;
};

// Input handler class
class InputHandler {
public:
    InputHandler();
    ~InputHandler() = default;

    // Main input processing
    void process_events(bool& running, bool headless_backend);

    // State access
    const InputState& get_keys() const { return keys_; }
    bool is_mouse_captured() const { return mouse_captured_; }
    bool is_safe_capture_mode() const { return safe_capture_mode_; }
    bool is_safe_defaults_mode() const { return safe_defaults_mode_; }
    bool is_help_overlay_sticky() const { return help_overlay_sticky_; }
    float get_help_overlay_timer() const { return help_overlay_timer_; }
    float get_sel_miss_timer() const { return sel_miss_timer_; }

    // State modification (for external control)
    void set_mouse_captured(bool captured);
    void set_safe_capture_mode(bool mode);
    void set_safe_defaults_mode(bool mode);
    void set_help_overlay_sticky(bool sticky);
    void update_help_overlay_timer(float dt);
    void update_sel_miss_timer(float dt);
    void reset_key_state();

    // Event handlers with required parameters
    void handle_window_event(const SDL_WindowEvent& ev, bool headless_backend);
    void handle_key_event(const SDL_KeyboardEvent& ev, bool log_keys, int& log_keys_count,
                         Vvoxel_framebuffer_top___024root* root, bool headless_backend);
    void handle_mouse_motion(const SDL_MouseMotionEvent& ev, float& yaw, float& pitch,
                           float mouse_sens, bool invert_y_mouse);

    // Action flags set by input handler for main loop to process
    struct InputActions {
        bool toggle_mouse_capture = false;
        bool update_camera = false;
        bool update_flags = false;
        bool update_selection = false;
        bool reset_camera = false;
        bool take_screenshot = false;
        bool quit = false;
    };

    InputActions get_and_clear_actions() {
        InputActions actions = actions_;
        actions_ = InputActions{};
        return actions;
    }

private:
    InputState keys_;
    bool mouse_captured_;
    bool safe_capture_mode_;
    bool safe_defaults_mode_;
    bool help_overlay_sticky_;
    float help_overlay_timer_;
    float sel_miss_timer_;
    InputActions actions_;

    // Helper functions
    void update_key_state(InputState& keys, SDL_Scancode sc, SDL_Keycode keycode, bool key_down);
    void handle_resize(int width, int height);
    void handle_focus_change(bool gained);
};

#endif // VIEWER_INPUT_H