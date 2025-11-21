#include "platform.h"

struct BackendOps {
    bool (*init)(PlatformContext&, const PlatformConfig&) = nullptr;
    void (*present)(PlatformContext&, const uint32_t*, int, int) = nullptr;
    void (*shutdown)(PlatformContext&) = nullptr;
};

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

static bool stub_init(PlatformContext& ctx, const PlatformConfig&) {
    // Tag backend in the user pointer for easy inspection.
    ctx.user = reinterpret_cast<void*>(0x1);
    return true;
}

static void stub_present(PlatformContext&, const uint32_t*, int, int) {}
static void stub_shutdown(PlatformContext&) {}

static BackendOps get_ops(PlatformBackend) {
    BackendOps ops;
    ops.init     = &stub_init;
    ops.present  = &stub_present;
    ops.shutdown = &stub_shutdown;
    return ops;
}

bool platform_init(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx) {
    if (!platform_backend_supported(backend))
        return false;
    BackendOps ops = get_ops(backend);
    return ops.init ? ops.init(ctx, cfg) : false;
}

void platform_present(PlatformBackend backend, PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!platform_backend_supported(backend))
        return;
    BackendOps ops = get_ops(backend);
    if (ops.present) ops.present(ctx, pixels, w, h);
}

void platform_shutdown(PlatformBackend backend, PlatformContext& ctx) {
    if (!platform_backend_supported(backend))
        return;
    BackendOps ops = get_ops(backend);
    if (ops.shutdown) ops.shutdown(ctx);
}
