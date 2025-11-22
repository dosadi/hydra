#include <SDL2/SDL.h>
#include <cstring>

#include "backend_ops.h"

struct SdlContext {
    SDL_Window*   window   = nullptr;
    SDL_Renderer* renderer = nullptr;
    SDL_Texture*  texture  = nullptr;
    int           tex_w    = 0;
    int           tex_h    = 0;
};

static void destroy_context(SdlContext* sc) {
    if (!sc) return;
    if (sc->texture) {
        SDL_DestroyTexture(sc->texture);
        sc->texture = nullptr;
    }
    if (sc->renderer) {
        SDL_DestroyRenderer(sc->renderer);
        sc->renderer = nullptr;
    }
    if (sc->window) {
        SDL_DestroyWindow(sc->window);
        sc->window = nullptr;
    }
    delete sc;
}

static bool ensure_texture(SdlContext& sc, int w, int h) {
    if (sc.texture && sc.tex_w == w && sc.tex_h == h)
        return true;

    SDL_Texture* new_tex = SDL_CreateTexture(
        sc.renderer, SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING, w, h
    );
    if (!new_tex)
        return false;

    if (sc.texture)
        SDL_DestroyTexture(sc.texture);

    sc.texture = new_tex;
    sc.tex_w = w;
    sc.tex_h = h;
    SDL_RenderSetLogicalSize(sc.renderer, w, h);
    return true;
}

static void sdl_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user || !pixels || w <= 0 || h <= 0)
        return;

    SdlContext* sc = static_cast<SdlContext*>(ctx.user);
    if (!sc->renderer)
        return;

    if (!ensure_texture(*sc, w, h))
        return;

    void* tex_pixels = nullptr;
    int pitch_bytes = 0;
    if (SDL_LockTexture(sc->texture, nullptr, &tex_pixels, &pitch_bytes) == 0) {
        const uint8_t* src = reinterpret_cast<const uint8_t*>(pixels);
        uint8_t* dst = static_cast<uint8_t*>(tex_pixels);
        const size_t src_pitch = static_cast<size_t>(w) * 4;
        for (int y = 0; y < h; ++y) {
            std::memcpy(dst + static_cast<size_t>(y) * pitch_bytes,
                        src + static_cast<size_t>(y) * src_pitch,
                        src_pitch);
        }
        SDL_UnlockTexture(sc->texture);
    }

    SDL_SetRenderDrawColor(sc->renderer, 0, 0, 0, 255);
    SDL_RenderClear(sc->renderer);
    SDL_RenderCopy(sc->renderer, sc->texture, nullptr, nullptr);
    SDL_RenderPresent(sc->renderer);
}

BackendOps get_ops_sdl() {
    BackendOps ops;
    ops.init = [](PlatformContext& ctx, const PlatformConfig& cfg) -> bool {
        if (SDL_Init(SDL_INIT_VIDEO) != 0)
            return false;

        const int window_w = cfg.width * 2;
        const int window_h = cfg.height * 2;
        SDL_Window* window = SDL_CreateWindow(
            "Hydra SDL Backend",
            SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            window_w, window_h,
            SDL_WINDOW_RESIZABLE
        );
        if (!window) {
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
            return false;
        }

        Uint32 renderer_flags = SDL_RENDERER_ACCELERATED;
        if (cfg.vsync)
            renderer_flags |= SDL_RENDERER_PRESENTVSYNC;
        SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, renderer_flags);
        if (!renderer)
            renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
        if (!renderer) {
            SDL_DestroyWindow(window);
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
            return false;
        }

        SDL_RenderSetLogicalSize(renderer, cfg.width, cfg.height);

        SDL_Texture* texture = SDL_CreateTexture(
            renderer, SDL_PIXELFORMAT_ARGB8888,
            SDL_TEXTUREACCESS_STREAMING,
            cfg.width, cfg.height
        );
        if (!texture) {
            SDL_DestroyRenderer(renderer);
            SDL_DestroyWindow(window);
            SDL_QuitSubSystem(SDL_INIT_VIDEO);
            return false;
        }

        ctx.user = new SdlContext{
            window,
            renderer,
            texture,
            cfg.width,
            cfg.height
        };
        return true;
    };
    ops.present = sdl_present;
    ops.shutdown = [](PlatformContext& ctx) {
        destroy_context(static_cast<SdlContext*>(ctx.user));
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        ctx.user = nullptr;
    };
    return ops;
}
