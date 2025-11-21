#include "platform.h"

static bool is_linux() {
#if defined(__linux__)
    return true;
#else
    return false;
#endif
}

static bool is_windows() {
#if defined(_WIN32)
    return true;
#else
    return false;
#endif
}

static bool is_macos() {
#if defined(__APPLE__)
    return true;
#else
    return false;
#endif
}

bool platform_backend_supported(PlatformBackend backend) {
    switch (backend) {
        case PlatformBackend::SDL:    return true;
        case PlatformBackend::Wayland:return is_linux();
        case PlatformBackend::X11:    return is_linux();
        case PlatformBackend::Fbdev:  return is_linux();
        case PlatformBackend::GL:     return is_linux() || is_windows() || is_macos();
        case PlatformBackend::Vulkan: return is_linux() || is_windows() || is_macos();
        case PlatformBackend::Win32:  return is_windows();
        case PlatformBackend::MacOS:  return is_macos();
        default: return false;
    }
}

bool platform_init(PlatformBackend backend, const PlatformConfig&, PlatformContext& ctx) {
    // Stub only: report success for SDL; others return false until implemented.
    (void)ctx;
    return backend == PlatformBackend::SDL;
}

void platform_present(PlatformBackend, PlatformContext&, const uint32_t*, int, int) {
    // Stub: nothing to do.
}

void platform_shutdown(PlatformBackend, PlatformContext&) {
    // Stub: nothing to do.
}
