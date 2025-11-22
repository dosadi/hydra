#include "platform.h"

#include "backend_ops.h"

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

BackendOps make_stub_ops() {
    BackendOps ops;
    ops.init = [](PlatformContext& ctx, const PlatformConfig&) -> bool {
        ctx.user = reinterpret_cast<void*>(0x1);
        return true;
    };
    ops.present = [](PlatformContext&, const uint32_t*, int, int) {};
    ops.shutdown= [](PlatformContext&) {};
    return ops;
}

// Backend-specific ops (strong definitions can override these stubs in other files)
BackendOps get_ops_sdl();
BackendOps get_ops_gl();
BackendOps get_ops_vulkan();
BackendOps get_ops_wayland();
BackendOps get_ops_x11();
BackendOps get_ops_fbdev();
BackendOps get_ops_win32();
BackendOps get_ops_macos();

static BackendOps get_ops(PlatformBackend backend) {
    switch (backend) {
        case PlatformBackend::SDL:    return get_ops_sdl();
        case PlatformBackend::GL:     return get_ops_gl();
        case PlatformBackend::Vulkan: return get_ops_vulkan();
        case PlatformBackend::Wayland:return get_ops_wayland();
        case PlatformBackend::X11:    return get_ops_x11();
        case PlatformBackend::Fbdev:  return get_ops_fbdev();
        case PlatformBackend::Win32:  return get_ops_win32();
        case PlatformBackend::MacOS:  return get_ops_macos();
        default: return make_stub_ops();
    }
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
