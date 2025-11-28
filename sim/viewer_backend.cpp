// ============================================================================
// viewer_backend.cpp
// - Backend management implementation for the voxel viewer
// ============================================================================
#include "viewer_backend.h"
#include "platform/backend_selector.h"
#include "platform/platform.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <cstdio>
#include <algorithm>
#include <cstring>

// Global backend info (for compatibility with existing code)
std::string g_backend_info;

BackendManager::BackendManager()
    : backend_(PlatformBackend::SDL)
    , use_platform_present_(false)
    , backend_fallback_(false)
    , win_(nullptr)
    , ren_(nullptr)
    , tex_(nullptr)
{
}

BackendManager::~BackendManager() {
    cleanup();
}

bool BackendManager::initialize_backend(PlatformBackend requested_backend, bool headless_mode) {
    // Platform backend selection (HYDRA_BACKEND env respected inside select_default_backend).
    const bool headless_backend = (requested_backend == PlatformBackend::Headless);
    if (headless_backend) {
        // Force SDL to a dummy driver so no window/display server is required.
        setenv("SDL_VIDEODRIVER", "dummy", 0);
        setenv("SDL_AUDIODRIVER", "dummy", 0);
    }

    log_input_caps();

    // Check VSYNC setting
    bool g_vsync = true;
    if (std::getenv("HYDRA_VSYNC")) {
        g_vsync = (std::getenv("HYDRA_VSYNC")[0] != '0');
    }

    PlatformBackend backend = PlatformBackend::SDL;
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
            plat_cfg.width  = 480;  // SCREEN_WIDTH
            plat_cfg.height = 360;  // SCREEN_HEIGHT
            plat_cfg.vsync  = true;

            std::fprintf(stderr, "[hydra] Initializing %s backend...\n", backend_name(requested_backend));

            if (init_backend(requested_backend, plat_cfg, plat_ctx_)) {
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

    // Store state
    backend_ = backend;
    use_platform_present_ = use_platform_present;
    backend_fallback_ = backend_fallback;

    return true;
}

void BackendManager::log_backend_capabilities() {
    platform_log_capabilities();
}

bool BackendManager::initialize_sdl_window_and_renderer() {
    if (backend_ != PlatformBackend::SDL) {
        return true; // Non-SDL backends don't need SDL window/renderer
    }

    // Check VSYNC setting
    bool g_vsync = true;
    if (std::getenv("HYDRA_VSYNC")) {
        g_vsync = (std::getenv("HYDRA_VSYNC")[0] != '0');
    }

    win_ = SDL_CreateWindow(
        "Voxel Accelerator — Interactive Raycaster",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        480 * 2, 360 * 2,  // SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2
        SDL_WINDOW_RESIZABLE
    );
    if (!win_) {
        std::fprintf(stderr, "Cannot create SDL window\n");
        return false;
    }

    SDL_RaiseWindow(win_);

    uint32_t sdl_renderer_flags = SDL_RENDERER_ACCELERATED;
    if (g_vsync) sdl_renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
    ren_ = SDL_CreateRenderer(win_, -1, sdl_renderer_flags);
    if (!ren_) {
        std::fprintf(stderr, "Renderer creation failed\n");
        return false;
    }

    SDL_RenderSetLogicalSize(ren_, 480, 360);  // SCREEN_WIDTH, SCREEN_HEIGHT

    SDL_RendererInfo ren_info;
    if (SDL_GetRendererInfo(ren_, &ren_info) == 0) {
        std::fprintf(stderr, "Renderer: %s\n", ren_info.name ? ren_info.name : "(unknown)");
        const char* video_driver = SDL_GetCurrentVideoDriver();
        char buf[160];
        std::snprintf(buf, sizeof(buf), "Backend: %s (vsync %s) renderer=%s video=%s",
                      backend_name(backend_),
                      g_vsync ? "on" : "off",
                      ren_info.name ? ren_info.name : "(unknown)",
                      video_driver ? video_driver : "(unknown)");
        g_backend_info_ = buf;
        g_backend_info = buf;  // Update global for compatibility
    }

    return true;
}

bool BackendManager::initialize_sdl_texture() {
    if (backend_ != PlatformBackend::SDL || !ren_) {
        return true; // Non-SDL backends don't need SDL texture
    }

    tex_ = SDL_CreateTexture(
        ren_, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        480, 360  // SCREEN_WIDTH, SCREEN_HEIGHT
    );
    if (!tex_) {
        std::fprintf(stderr, "Texture creation failed\n");
        return false;
    }

    return true;
}

void BackendManager::recreate_sdl_texture() {
    if (backend_ != PlatformBackend::SDL || !ren_) {
        return;
    }

    if (tex_) {
        SDL_DestroyTexture(tex_);
        tex_ = nullptr;
    }

    tex_ = SDL_CreateTexture(
        ren_, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        480, 360  // SCREEN_WIDTH, SCREEN_HEIGHT
    );
    if (!tex_) {
        std::fprintf(stderr, "Texture recreation failed\n");
    }
}

void BackendManager::present_frame(const std::vector<uint32_t>& framebuffer, bool use_platform_present) {
    if (use_platform_present && use_platform_present_) {
        present_backend(plat_ctx_, framebuffer.data(), 480, 360);  // SCREEN_WIDTH, SCREEN_HEIGHT
    } else if (backend_ == PlatformBackend::SDL && tex_ && ren_) {
        // Copy framebuffer to SDL texture
        void* pixels = nullptr;
        int pitch_bytes = 0;
        if (SDL_LockTexture(tex_, nullptr, &pixels, &pitch_bytes) == 0) {
            for (int y = 0; y < 360; ++y) {  // SCREEN_HEIGHT
                uint32_t* row = (uint32_t*)((uint8_t*)pixels + y * pitch_bytes);
                memcpy(row, &framebuffer[size_t(y) * 480], 480 * sizeof(uint32_t));  // SCREEN_WIDTH
            }
            SDL_UnlockTexture(tex_);

            SDL_SetRenderDrawColor(ren_, 0, 0, 0, 255);
            SDL_RenderClear(ren_);
            SDL_RenderCopy(ren_, tex_, nullptr, nullptr);
            SDL_RenderPresent(ren_);
        }
    }
}

void BackendManager::handle_window_resize(int new_w, int new_h, std::vector<uint32_t>& framebuffer, uint32_t clear_color) {
    if (backend_ != PlatformBackend::SDL || !ren_) {
        return;
    }

    SDL_RenderSetLogicalSize(ren_, 480, 360);  // SCREEN_WIDTH, SCREEN_HEIGHT
    recreate_sdl_texture();
    std::fill(framebuffer.begin(), framebuffer.end(), clear_color);
    std::fprintf(stderr, "[hydra] window resized, refreshed texture and cleared framebuffer\n");
}

void BackendManager::cleanup() {
    if (use_platform_present_) {
        shutdown_backend(plat_ctx_);
        use_platform_present_ = false;
    }

    if (tex_) {
        SDL_DestroyTexture(tex_);
        tex_ = nullptr;
    }

    if (ren_) {
        SDL_DestroyRenderer(ren_);
        ren_ = nullptr;
    }

    if (win_) {
        SDL_DestroyWindow(win_);
        win_ = nullptr;
    }
}

const char* BackendManager::backend_name(PlatformBackend b) const {
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

void BackendManager::log_backend_caps(PlatformBackend requested, PlatformBackend backend, bool vsync) {
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

void BackendManager::log_input_caps() {
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