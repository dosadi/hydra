// ============================================================================
// backend_ops.h
// - Shared backend ops struct and stub helper.
// ============================================================================
#pragma once

#include <cstdint>
#include "platform.h"

struct BackendOps {
    bool (*init)(PlatformContext&, const PlatformConfig&) = nullptr;
    void (*present)(PlatformContext&, const uint32_t*, int, int) = nullptr;
    void (*shutdown)(PlatformContext&) = nullptr;
};

BackendOps make_stub_ops();
BackendOps get_ops_sdl();
BackendOps get_ops_gl();
BackendOps get_ops_vulkan();
BackendOps get_ops_wayland();
BackendOps get_ops_x11();
BackendOps get_ops_fbdev();
BackendOps get_ops_win32();
BackendOps get_ops_macos();
