#include "backend_selector.h"
#include "platform.h"
#include <cstdlib>
#include <cstring>
#include <strings.h>

static bool env_equals(const char* key, const char* val) {
    const char* v = std::getenv(key);
    return v && strcasecmp(v, val) == 0;
}

PlatformBackend select_default_backend() {
    // Env override
    if (const char* v = std::getenv("HYDRA_BACKEND")) {
        if (strcasecmp(v, "SDL") == 0)     return PlatformBackend::SDL;
        if (strcasecmp(v, "GL") == 0)      return PlatformBackend::GL;
        if (strcasecmp(v, "VULKAN") == 0)  return PlatformBackend::Vulkan;
        if (strcasecmp(v, "WAYLAND") == 0) return PlatformBackend::Wayland;
        if (strcasecmp(v, "X11") == 0)     return PlatformBackend::X11;
        if (strcasecmp(v, "FBDEV") == 0)   return PlatformBackend::Fbdev;
        if (strcasecmp(v, "WIN32") == 0)   return PlatformBackend::Win32;
        if (strcasecmp(v, "MACOS") == 0)   return PlatformBackend::MacOS;
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
