#include "backend_ops.h"

#if defined(HYDRA_ENABLE_X11) && (defined(__has_include) ? __has_include(<X11/Xlib.h>) : 1)

#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <cstdint>
#include <cstdlib>
#include <cstring>

struct X11Context {
    Display* display = nullptr;
    Window   window = 0;
    GC       gc = 0;
    XImage*  image = nullptr;
    uint8_t* buffer = nullptr;
    int      width = 0;
    int      height = 0;
    int      depth = 0;
};

static void destroy_image(X11Context& xc) {
    if (xc.image) {
        xc.image->data = nullptr;
        XDestroyImage(xc.image);
        xc.image = nullptr;
    }
    std::free(xc.buffer);
    xc.buffer = nullptr;
    xc.width = 0;
    xc.height = 0;
}

static bool ensure_image(X11Context& xc, int w, int h) {
    if (xc.image && xc.width == w && xc.height == h)
        return true;

    destroy_image(xc);
    size_t sz = static_cast<size_t>(w) * static_cast<size_t>(h) * 4;
    xc.buffer = static_cast<uint8_t*>(std::malloc(sz));
    if (!xc.buffer)
        return false;

    xc.image = XCreateImage(
        xc.display,
        DefaultVisual(xc.display, DefaultScreen(xc.display)),
        static_cast<unsigned int>(xc.depth),
        ZPixmap,
        0,
        reinterpret_cast<char*>(xc.buffer),
        w,
        h,
        32,
        w * 4
    );
    if (!xc.image) {
        std::free(xc.buffer);
        xc.buffer = nullptr;
        return false;
    }
    xc.width = w;
    xc.height = h;
    return true;
}

static bool x11_init(PlatformContext& ctx, const PlatformConfig& cfg) {
    Display* dpy = XOpenDisplay(nullptr);
    if (!dpy)
        return false;

    int screen = DefaultScreen(dpy);
    int depth = DefaultDepth(dpy, screen);
    if (depth < 24) {
        XCloseDisplay(dpy);
        return false;
    }

    Window root = RootWindow(dpy, screen);
    Window win = XCreateSimpleWindow(
        dpy, root,
        0, 0,
        static_cast<unsigned int>(cfg.width * 2),
        static_cast<unsigned int>(cfg.height * 2),
        0,
        BlackPixel(dpy, screen),
        BlackPixel(dpy, screen)
    );
    XStoreName(dpy, win, "Hydra X11 Backend");
    XMapWindow(dpy, win);
    GC gc = XCreateGC(dpy, win, 0, nullptr);
    if (!gc) {
        XDestroyWindow(dpy, win);
        XCloseDisplay(dpy);
        return false;
    }

    X11Context* xc = new X11Context();
    xc->display = dpy;
    xc->window = win;
    xc->gc = gc;
    xc->depth = depth;
    ctx.user = xc;
    return true;
}

static void x11_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user || !pixels) return;
    X11Context* xc = static_cast<X11Context*>(ctx.user);
    if (!ensure_image(*xc, w, h))
        return;

    const size_t pitch = static_cast<size_t>(w) * 4;
    for (int y = 0; y < h; ++y) {
        std::memcpy(
            xc->buffer + static_cast<size_t>(y) * pitch,
            reinterpret_cast<const uint8_t*>(pixels) + static_cast<size_t>(y) * pitch,
            pitch
        );
    }

    XPutImage(
        xc->display,
        xc->window,
        xc->gc,
        xc->image,
        0, 0, 0, 0,
        static_cast<unsigned int>(w),
        static_cast<unsigned int>(h)
    );
    XFlush(xc->display);
}

static void x11_shutdown(PlatformContext& ctx) {
    if (!ctx.user) return;
    X11Context* xc = static_cast<X11Context*>(ctx.user);
    destroy_image(*xc);
    if (xc->gc) XFreeGC(xc->display, xc->gc);
    if (xc->window) XDestroyWindow(xc->display, xc->window);
    if (xc->display) XCloseDisplay(xc->display);
    delete xc;
    ctx.user = nullptr;
}

BackendOps get_ops_x11() {
    BackendOps ops;
    ops.init = x11_init;
    ops.present = x11_present;
    ops.shutdown = x11_shutdown;
    return ops;
}

#else

BackendOps get_ops_x11() {
    return make_stub_ops();
}

#endif
