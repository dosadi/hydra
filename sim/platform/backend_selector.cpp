#include "backend_selector.h"
#include "platform.h"
#include <cstdlib>
#include <cstring>

static bool env_equals(const char* key, const char* val) {
    const char* v = std::getenv(key);
    return v && std::strcmp(v, val) == 0;
}

PlatformBackend select_default_backend() {
    // Env override
    if (const char* v = std::getenv("HYDRA_BACKEND")) {
        if (std::strcmp(v, "SDL") == 0)     return PlatformBackend::SDL;
        if (std::strcmp(v, "GL") == 0)      return PlatformBackend::GL;
        if (std::strcmp(v, "VULKAN") == 0)  return PlatformBackend::Vulkan;
        if (std::strcmp(v, "WAYLAND") == 0) return PlatformBackend::Wayland;
        if (std::strcmp(v, "X11") == 0)     return PlatformBackend::X11;
        if (std::strcmp(v, "FBDEV") == 0)   return PlatformBackend::Fbdev;
        if (std::strcmp(v, "WIN32") == 0)   return PlatformBackend::Win32;
        if (std::strcmp(v, "MACOS") == 0)   return PlatformBackend::MacOS;
    }
    // Preference order: SDL (existing), Vulkan, GL, Wayland, X11, fbdev, Win32, MacOS
    PlatformBackend prefs[] = {
        PlatformBackend::SDL,
        PlatformBackend::Vulkan,
        PlatformBackend::GL,
        PlatformBackend::Wayland,
        PlatformBackend::X11,
        PlatformBackend::Fbdev,
        PlatformBackend::Win32,
        PlatformBackend::MacOS
    };
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
