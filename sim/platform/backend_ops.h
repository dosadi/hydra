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
