#include "platform.h"
#include "backend_base.h"
#include "backend_selector.h"

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
        case PlatformBackend::Headless: return true;
        case PlatformBackend::Wayland:
#if defined(HYDRA_ENABLE_WAYLAND)
            return is_linux();
#else
            return false;
#endif
        case PlatformBackend::X11:
#if defined(HYDRA_ENABLE_X11)
            return is_linux();
#else
            return false;
#endif
        case PlatformBackend::Fbdev:  return is_linux();
        case PlatformBackend::GL:
#if defined(HYDRA_ENABLE_GL)
            return is_linux() || is_windows() || is_macos();
#else
            return false;
#endif
        case PlatformBackend::Vulkan:
#if defined(HYDRA_ENABLE_VULKAN)
            return is_linux() || is_windows() || is_macos();
#else
            return false;
#endif
        case PlatformBackend::Win32:  return is_windows();
        case PlatformBackend::MacOS:  return is_macos();
            case PlatformBackend::AALIB: return true;
        case PlatformBackend::VNC:
#if defined(HYDRA_ENABLE_VNC)
            return true;
#else
            return false;
#endif
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
static BackendOps get_ops(PlatformBackend backend) {
    switch (backend) {
        case PlatformBackend::SDL:    return get_ops_sdl();
        case PlatformBackend::Headless: return get_ops_headless();
        case PlatformBackend::GL:     return get_ops_gl();
        case PlatformBackend::Vulkan: return get_ops_vulkan();
        case PlatformBackend::Wayland:return get_ops_wayland();
        case PlatformBackend::X11:    return get_ops_x11();
        case PlatformBackend::AALIB: return get_ops_aalib();
        case PlatformBackend::Fbdev:  return get_ops_fbdev();
        case PlatformBackend::Win32:  return get_ops_win32();
        case PlatformBackend::MacOS:  return get_ops_macos();
        default: return make_stub_ops();
    }
}

bool platform_init(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx) {
    return init_backend(backend, cfg, ctx);
}

void platform_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (ctx.backend) ctx.backend->present(ctx, pixels, w, h);
}

void platform_shutdown(PlatformContext& ctx) {
    if (ctx.backend) ctx.backend->shutdown(ctx);
    ctx.backend.reset();
}
