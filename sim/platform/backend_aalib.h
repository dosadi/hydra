// ============================================================================
// backend_aalib.h
// - ASCII Art (AAlib) backend for text-based rendering
// ============================================================================
#pragma once

#include "backend_base.h"

class AALibBackend : public Backend {
public:
    AALibBackend();
    ~AALibBackend() override;

    bool init(PlatformContext& ctx, const PlatformConfig& cfg) override;
    void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) override;
    void shutdown(PlatformContext& ctx) override;

private:
    static const char* luminance_chars;
    int last_width = 0;
    int last_height = 0;
};