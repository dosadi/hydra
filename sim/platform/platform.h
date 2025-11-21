// ============================================================================
// platform.h
// - Placeholder platform/backend API for future GL/Vulkan/Wayland/X11/fbdev/
//   Win64/macOS backends.
// - Current implementation is stub-only; all backends report unsupported.
// ============================================================================
#pragma once

#include <cstdint>

enum class PlatformBackend {
    SDL,
    GL,
    Vulkan,
    Wayland,
    X11,
    Fbdev,
    Win32,
    MacOS
};

struct PlatformConfig {
    int width  = 480;
    int height = 360;
    bool vsync = false;
};

struct PlatformContext {
    void* user = nullptr;
};

// Returns true if the backend is deemed supported (stub always false except SDL).
bool platform_backend_supported(PlatformBackend backend);

// Initialize backend (stub: returns false for non-SDL).
bool platform_init(PlatformBackend backend, const PlatformConfig& cfg, PlatformContext& ctx);

// Present one frame (stub: no-op).
void platform_present(PlatformBackend backend, PlatformContext& ctx, const uint32_t* pixels, int width, int height);

// Tear down backend (stub: no-op).
void platform_shutdown(PlatformBackend backend, PlatformContext& ctx);
