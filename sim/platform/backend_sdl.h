#pragma once

#include "backend_base.h"

class SDLBackend : public Backend {

public:

    ~SDLBackend() override;

    bool init(PlatformContext& ctx, const PlatformConfig& cfg) override;

    void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) override;

    void shutdown(PlatformContext& ctx) override;

private:

    struct SdlContext* context = nullptr;

};