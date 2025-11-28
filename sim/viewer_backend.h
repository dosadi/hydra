// ============================================================================
// viewer_backend.h
// - Backend management module for the voxel viewer
// - Handles platform backend selection, initialization, and presentation
// ============================================================================
#pragma once

#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <string>
#include <vector>
#include "platform/platform.h"

// Forward declarations
struct PlatformContext;
struct PlatformConfig;
enum class PlatformBackend;

// Backend management class
class BackendManager {
public:
    BackendManager();
    ~BackendManager();

    // Backend initialization and setup
    bool initialize_backend(PlatformBackend requested_backend, bool headless_mode);
    void log_backend_capabilities();

    // SDL-specific setup (when using SDL backend)
    bool initialize_sdl_window_and_renderer();
    bool initialize_sdl_texture();
    void recreate_sdl_texture();

    // Presentation
    void present_frame(const std::vector<uint32_t>& framebuffer, bool use_platform_present);

    // Cleanup
    void cleanup();

    // Accessors
    PlatformBackend get_current_backend() const { return backend_; }
    bool is_platform_present_enabled() const { return use_platform_present_; }
    SDL_Window* get_sdl_window() const { return win_; }
    SDL_Renderer* get_sdl_renderer() const { return ren_; }
    SDL_Texture* get_sdl_texture() const { return tex_; }
    const std::string& get_backend_info() const { return g_backend_info_; }
    const char* backend_name(PlatformBackend b) const;

    // Window management
    void handle_window_resize(int new_w, int new_h, std::vector<uint32_t>& framebuffer, uint32_t clear_color);

private:
    // Backend state
    PlatformBackend backend_;
    PlatformContext plat_ctx_;
    bool use_platform_present_;
    bool backend_fallback_;

    // SDL resources (only valid when backend_ == PlatformBackend::SDL)
    SDL_Window* win_;
    SDL_Renderer* ren_;
    SDL_Texture* tex_;

    // Global backend info string
    std::string g_backend_info_;

    // Helper functions
    void log_backend_caps(PlatformBackend requested, PlatformBackend backend, bool vsync);
    void log_input_caps();
};

// Global backend info accessor (for compatibility)
extern std::string g_backend_info;