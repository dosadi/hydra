// ============================================================================
// backend_gl.h
// - OpenGL backend implementation using SDL2 for window management
// ============================================================================
#pragma once

#if defined(HYDRA_ENABLE_GL) && (defined(__has_include) ? __has_include(<SDL2/SDL.h>) && __has_include(<SDL2/SDL_opengl.h>) : 0)

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#include "backend_base.h"

class GLBackend : public Backend {
public:
    GLBackend();
    ~GLBackend() override;

    bool init(PlatformContext& ctx, const PlatformConfig& cfg) override;
    void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) override;
    void shutdown(PlatformContext& ctx) override;

private:
    struct GLContext {
        SDL_Window* window = nullptr;
        SDL_GLContext glctx = nullptr;
        int width = 0;
        int height = 0;
    };

    GLContext* context_ = nullptr;
};

#endif