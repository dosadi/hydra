// ============================================================================
// backend_base.h
// - Base class for platform backends.
// ============================================================================
#pragma once

#include <memory>
#include "platform.h"

class Backend {
public:
    virtual ~Backend() = default;
    virtual bool init(PlatformContext& ctx, const PlatformConfig& cfg) = 0;
    virtual void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) = 0;
    virtual void shutdown(PlatformContext& ctx) = 0;
};

using BackendPtr = std::unique_ptr<Backend>;