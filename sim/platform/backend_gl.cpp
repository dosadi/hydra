#include "backend_gl.h"

#if defined(HYDRA_ENABLE_GL) && (defined(__has_include) ? __has_include(<SDL2/SDL.h>) && __has_include(<SDL2/SDL_opengl.h>) : 0)

GLBackend::GLBackend() : context_(nullptr) {}

GLBackend::~GLBackend() {
    if (context_) {
        if (context_->glctx) {
            SDL_GL_DeleteContext(context_->glctx);
            context_->glctx = nullptr;
        }
        if (context_->window) {
            SDL_DestroyWindow(context_->window);
            context_->window = nullptr;
        }
        delete context_;
        context_ = nullptr;
    }
}

bool GLBackend::init(PlatformContext& ctx, const PlatformConfig& cfg) {
    if (SDL_InitSubSystem(SDL_INIT_VIDEO) != 0)
        return false;

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);

    SDL_Window* window = SDL_CreateWindow(
        "Hydra GL Backend",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        cfg.width * 2, cfg.height * 2,
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
    );
    if (!window) {
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        return false;
    }

    SDL_GLContext glctx = SDL_GL_CreateContext(window);
    if (!glctx) {
        SDL_DestroyWindow(window);
        SDL_QuitSubSystem(SDL_INIT_VIDEO);
        return false;
    }

    if (cfg.vsync)
        SDL_GL_SetSwapInterval(1);
    else
        SDL_GL_SetSwapInterval(0);

    glViewport(0, 0, cfg.width, cfg.height);
    glDisable(GL_DEPTH_TEST);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

    context_ = new GLContext();
    context_->window = window;
    context_->glctx = glctx;
    context_->width = cfg.width;
    context_->height = cfg.height;
    ctx.user = context_;
    return true;
}

void GLBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!context_ || !pixels || w <= 0 || h <= 0) return;

    SDL_GL_MakeCurrent(context_->window, context_->glctx);

    int win_w = 0, win_h = 0;
    SDL_GetWindowSize(context_->window, &win_w, &win_h);
    glViewport(0, 0, win_w, win_h);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    float zoom_x = win_w > 0 ? static_cast<float>(win_w) / static_cast<float>(w) : 1.0f;
    float zoom_y = win_h > 0 ? static_cast<float>(win_h) / static_cast<float>(h) : 1.0f;

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    glPixelZoom(zoom_x, -zoom_y); // Flip Y to match top-left origin.
    glRasterPos2i(-1, 1);
    glDrawPixels(w, h, GL_BGRA, GL_UNSIGNED_BYTE, pixels);

    SDL_GL_SwapWindow(context_->window);
}

void GLBackend::shutdown(PlatformContext& ctx) {
    if (context_) {
        if (context_->glctx) {
            SDL_GL_DeleteContext(context_->glctx);
            context_->glctx = nullptr;
        }
        if (context_->window) {
            SDL_DestroyWindow(context_->window);
            context_->window = nullptr;
        }
        delete context_;
        context_ = nullptr;
    }
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
    ctx.user = nullptr;
}

#endif
