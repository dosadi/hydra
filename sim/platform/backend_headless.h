#pragma once

#include "backend_base.h"

class HeadlessBackend : public Backend {
public:
    HeadlessBackend();
    ~HeadlessBackend() override;

    bool init(PlatformContext& ctx, const PlatformConfig& cfg) override;
    void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) override;
    void shutdown(PlatformContext& ctx) override;
};