#include "backend_selector.h"
#include "platform.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <strings.h>
#include <string>
#include <memory>

// Include backend classes
#include "backend_sdl.h"
#include "backend_headless.h"
#include "backend_aalib.h"
#if defined(HYDRA_ENABLE_GL) && (defined(__has_include) ? __has_include(<SDL2/SDL.h>) && __has_include(<SDL2/SDL_opengl.h>) : 0)
#include "backend_gl.h"
#endif
#if defined(HYDRA_ENABLE_VULKAN) && (defined(__has_include) ? __has_include(<vulkan/vulkan.h>) && __has_include(<SDL2/SDL_vulkan.h>) : 0)
#include "backend_vulkan.h"
#endif
// TODO: include others

static bool env_equals(const char* key, const char* val) {
    const char* v = std::getenv(key);
    return v && strcasecmp(v, val) == 0;
}

PlatformBackend select_default_backend() {
    PlatformBackend env_backend = PlatformBackend::SDL;
    bool env_backend_set = false;
    // Env override
    if (const char* v = std::getenv("HYDRA_BACKEND")) {
        if (strcasecmp(v, "SDL") == 0)     { env_backend = PlatformBackend::SDL; env_backend_set = true; }
        else if (strcasecmp(v, "GL") == 0)      { env_backend = PlatformBackend::GL; env_backend_set = true; }
        else if (strcasecmp(v, "VULKAN") == 0)  { env_backend = PlatformBackend::Vulkan; env_backend_set = true; }
        else if (strcasecmp(v, "WAYLAND") == 0) { env_backend = PlatformBackend::Wayland; env_backend_set = true; }
        else if (strcasecmp(v, "X11") == 0)     { env_backend = PlatformBackend::X11; env_backend_set = true; }
        else if (strcasecmp(v, "FBDEV") == 0)   { env_backend = PlatformBackend::Fbdev; env_backend_set = true; }
        else if (strcasecmp(v, "WIN32") == 0)   { env_backend = PlatformBackend::Win32; env_backend_set = true; }
        else if (strcasecmp(v, "MACOS") == 0)   { env_backend = PlatformBackend::MacOS; env_backend_set = true; }
        else if (strcasecmp(v, "AALIB") == 0)   { env_backend = PlatformBackend::AALIB; env_backend_set = true; }
        else if (strcasecmp(v, "HEADLESS") == 0) { env_backend = PlatformBackend::Headless; env_backend_set = true; }

        if (env_backend_set) {
            if (platform_backend_supported(env_backend)) {
                return env_backend;
            } else {
                std::fprintf(stderr, "[hydra] HYDRA_BACKEND=%s requested but not compiled/supported; falling back to defaults\n", v);
            }
        } else {
            std::fprintf(stderr, "[hydra] HYDRA_BACKEND=%s not recognized; falling back to defaults\n", v);
        }
    }
    // Preference order: GPU-capable backends first when available.
    PlatformBackend prefs[] = {
        PlatformBackend::Vulkan,
        PlatformBackend::GL,
        PlatformBackend::Wayland,
            PlatformBackend::AALIB,
        PlatformBackend::X11,
        PlatformBackend::SDL,
        PlatformBackend::Fbdev,
        PlatformBackend::Win32,
        PlatformBackend::MacOS
    };
    const char* pref_env = std::getenv("HYDRA_BACKEND_PREFS");
    if (pref_env && *pref_env) {
        // HYDRA_BACKEND_PREFS=GL,VULKAN,SDL,...
        const char* p = pref_env;
        while (*p) {
            while (*p == ' ' || *p == ',') ++p;
            const char* start = p;
            while (*p && *p != ',') ++p;
            std::string token(start, p - start);
            if (!token.empty()) {
                PlatformBackend b = env_backend; // default to env or SDL
                if (strcasecmp(token.c_str(), "SDL") == 0) b = PlatformBackend::SDL;
                else if (strcasecmp(token.c_str(), "GL") == 0) b = PlatformBackend::GL;
                else if (strcasecmp(token.c_str(), "VULKAN") == 0) b = PlatformBackend::Vulkan;
                else if (strcasecmp(token.c_str(), "WAYLAND") == 0) b = PlatformBackend::Wayland;
                else if (strcasecmp(token.c_str(), "X11") == 0) b = PlatformBackend::X11;
                else if (strcasecmp(token.c_str(), "FBDEV") == 0) b = PlatformBackend::Fbdev;
                else if (strcasecmp(token.c_str(), "WIN32") == 0) b = PlatformBackend::Win32;
                else if (strcasecmp(token.c_str(), "MACOS") == 0) b = PlatformBackend::MacOS;
                else if (strcasecmp(token.c_str(), "HEADLESS") == 0) b = PlatformBackend::Headless;
                if (platform_backend_supported(b)) {
                    return b;
                }
            }
        }
    }
    for (auto b : prefs) {
        if (platform_backend_supported(b))
            return b;
    }
    return PlatformBackend::SDL;
}

bool init_backend(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx) {
    ctx.backend = create_backend(backend);
    if (!ctx.backend) return false;
    return ctx.backend->init(ctx, cfg);
}

void present_backend(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (ctx.backend) ctx.backend->present(ctx, pixels, w, h);
}

void shutdown_backend(PlatformContext& ctx) {
    if (ctx.backend) ctx.backend->shutdown(ctx);
    ctx.backend.reset();
}

void platform_log_capabilities() {
    std::fprintf(stderr, "[hydra] compiled backends: SDL AAlib");
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

BackendPtr create_backend(PlatformBackend backend) {
    switch (backend) {
        case PlatformBackend::SDL:
            return std::make_unique<SDLBackend>();
        case PlatformBackend::Headless:
            return std::make_unique<HeadlessBackend>();
        case PlatformBackend::AALIB:
            return std::make_unique<AALibBackend>();
#if defined(HYDRA_ENABLE_GL) && (defined(__has_include) ? __has_include(<SDL2/SDL.h>) && __has_include(<SDL2/SDL_opengl.h>) : 0)
        case PlatformBackend::GL:
            return std::make_unique<GLBackend>();
#endif
#if defined(HYDRA_ENABLE_VULKAN) && (defined(__has_include) ? __has_include(<vulkan/vulkan.h>) && __has_include(<SDL2/SDL_vulkan.h>) : 0)
        case PlatformBackend::Vulkan:
            return std::make_unique<VulkanBackend>();
#endif
        // TODO: add other backends
        default:
            return nullptr;
    }
}
