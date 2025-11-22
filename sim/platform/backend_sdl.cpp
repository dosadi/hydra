#include "backend_ops.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>

struct SdlContext {
    SDL_Window*   window;
    SDL_Renderer* renderer;
    SDL_Texture*  texture;
    int           tex_w;
    int           tex_h;
};

static bool sdl_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user) return false;
    SdlContext* sc = static_cast<SdlContext*>(ctx.user);
    if (w != sc->tex_w || h != sc->tex_h) {
        SDL_DestroyTexture(sc->texture);
        sc->texture = SDL_CreateTexture(sc->renderer, SDL_PIXELFORMAT_ABGR8888,
                                        SDL_TEXTUREACCESS_STREAMING, w, h);
        sc->tex_w = w;
        sc->tex_h = h;
    }
    void* tex_pixels = nullptr;
    int pitch = 0;
    if (SDL_LockTexture(sc->texture, nullptr, &tex_pixels, &pitch) == 0) {
        const uint8_t* src = reinterpret_cast<const uint8_t*>(pixels);
        uint8_t* dst = static_cast<uint8_t*>(tex_pixels);
        for (int y = 0; y < h; ++y) {
            memcpy(dst + y * pitch, src + y * w * 4, w * 4);
        }
        SDL_UnlockTexture(sc->texture);
    }
    SDL_RenderClear(sc->renderer);
    SDL_RenderCopy(sc->renderer, sc->texture, nullptr, nullptr);
    SDL_RenderPresent(sc->renderer);
    return true;
}

BackendOps get_ops_sdl() {
    BackendOps ops;
    ops.init = [](PlatformContext& ctx, const PlatformConfig&) -> bool {
        if (SDL_Init(SDL_INIT_VIDEO) != 0)
            return false;
        SDL_Window* win = SDL_CreateWindow("Hydra SDL Backend",
                                           SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                           800, 600, SDL_WINDOW_SHOWN);
        if (!win)
            return false;
        SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
        if (!ren)
            return false;
        SdlContext* sc = new SdlContext();
        sc->window = win;
        sc->renderer = ren;
        sc->texture = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ABGR8888,
                                        SDL_TEXTUREACCESS_STREAMING, 1, 1);
        sc->tex_w = 1;
        sc->tex_h = 1;
        ctx.user = sc;
        return true;
    };
    ops.present = sdl_present;
    ops.shutdown = [](PlatformContext& ctx) {
        if (!ctx.user) return;
        SdlContext* sc = static_cast<SdlContext*>(ctx.user);
        SDL_DestroyTexture(sc->texture);
        SDL_DestroyRenderer(sc->renderer);
        SDL_DestroyWindow(sc->window);
        delete sc;
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        ctx.user = nullptr;
    };
    return ops;
}
#include "backend_ops.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include <cstring>

struct SdlContext {
    SDL_Window*   window;
    SDL_Renderer* renderer;
    SDL_Texture*  texture;
    int           tex_w;
    int           tex_h;
};

static bool sdl_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user) return false;
    SdlContext* sc = static_cast<SdlContext*>(ctx.user);
    if (w != sc->tex_w || h != sc->tex_h) {
        SDL_DestroyTexture(sc->texture);
        sc->texture = SDL_CreateTexture(sc->renderer, SDL_PIXELFORMAT_ABGR8888,
                                        SDL_TEXTUREACCESS_STREAMING, w, h);
        sc->tex_w = w;
        sc->tex_h = h;
    }
    void* tex_pixels = nullptr;
    int pitch = 0;
    if (SDL_LockTexture(sc->texture, nullptr, &tex_pixels, &pitch) == 0) {
        const uint8_t* src = reinterpret_cast<const uint8_t*>(pixels);
        uint8_t* dst = static_cast<uint8_t*>(tex_pixels);
        for (int y = 0; y < h; ++y) {
            std::memcpy(dst + y * pitch, src + y * w * 4, w * 4);
        }
        SDL_UnlockTexture(sc->texture);
    }
    SDL_RenderClear(sc->renderer);
    SDL_RenderCopy(sc->renderer, sc->texture, nullptr, nullptr);
    SDL_RenderPresent(sc->renderer);
    return true;
}

BackendOps get_ops_sdl() {
    BackendOps ops;
    ops.init = [](PlatformContext& ctx, const PlatformConfig&) -> bool {
        if (SDL_Init(SDL_INIT_VIDEO) != 0)
            return false;
        SDL_Window* win = SDL_CreateWindow("Hydra SDL Backend",
                                           SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                           800, 600, SDL_WINDOW_SHOWN);
        if (!win)
            return false;
        SDL_Renderer* ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED);
        if (!ren)
            return false;
        SdlContext* sc = new SdlContext();
        sc->window = win;
        sc->renderer = ren;
        sc->texture = SDL_CreateTexture(ren, SDL_PIXELFORMAT_ABGR8888,
                                        SDL_TEXTUREACCESS_STREAMING, 1, 1);
        sc->tex_w = 1;
        sc->tex_h = 1;
        ctx.user = sc;
        return true;
    };
    ops.present = sdl_present;
    ops.shutdown = [](PlatformContext& ctx) {
        if (!ctx.user) return;
        SdlContext* sc = static_cast<SdlContext*>(ctx.user);
        SDL_DestroyTexture(sc->texture);
        SDL_DestroyRenderer(sc->renderer);
        SDL_DestroyWindow(sc->window);
        delete sc;
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        ctx.user = nullptr;
    };
    return ops;
}
