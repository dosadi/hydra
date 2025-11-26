#include "backend_selector.h"
#include "platform.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <strings.h>
#include <string>

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
    return platform_init(backend, cfg, ctx);
}

void present_backend(PlatformBackend backend, PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    platform_present(backend, ctx, pixels, w, h);
}

void shutdown_backend(PlatformBackend backend, PlatformContext& ctx) {
    platform_shutdown(backend, ctx);
}

void platform_log_capabilities() {
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
