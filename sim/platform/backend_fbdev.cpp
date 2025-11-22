#include "backend_ops.h"

#if defined(__linux__)

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

struct FbdevContext {
    int      fd = -1;
    uint8_t* map = nullptr;
    size_t   map_size = 0;
    int      width = 0;
    int      height = 0;
    int      stride = 0;
    int      bpp = 0;
};

static void fbdev_shutdown(PlatformContext& ctx) {
    if (!ctx.user) return;
    FbdevContext* fc = static_cast<FbdevContext*>(ctx.user);
    if (fc->map && fc->map_size)
        munmap(fc->map, fc->map_size);
    if (fc->fd >= 0)
        close(fc->fd);
    delete fc;
    ctx.user = nullptr;
}

static bool fbdev_init(PlatformContext& ctx, const PlatformConfig&) {
    int fd = open("/dev/fb0", O_RDWR);
    if (fd < 0)
        return false;

    fb_fix_screeninfo finfo;
    fb_var_screeninfo vinfo;
    if (ioctl(fd, FBIOGET_FSCREENINFO, &finfo) != 0 ||
        ioctl(fd, FBIOGET_VSCREENINFO, &vinfo) != 0) {
        close(fd);
        return false;
    }

    if (vinfo.bits_per_pixel != 32) {
        close(fd);
        return false; // Only ARGB/XRGB 32bpp supported for now.
    }

    size_t map_size = static_cast<size_t>(finfo.line_length) *
                      static_cast<size_t>(vinfo.yres);
    void* map = mmap(nullptr, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        close(fd);
        return false;
    }

    FbdevContext* fc = new FbdevContext();
    fc->fd     = fd;
    fc->map    = static_cast<uint8_t*>(map);
    fc->map_size = map_size;
    fc->width  = static_cast<int>(vinfo.xres);
    fc->height = static_cast<int>(vinfo.yres);
    fc->stride = static_cast<int>(finfo.line_length);
    fc->bpp    = static_cast<int>(vinfo.bits_per_pixel);
    ctx.user = fc;
    return true;
}

static void fbdev_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user || !pixels) return;
    FbdevContext* fc = static_cast<FbdevContext*>(ctx.user);
    if (!fc->map || fc->stride <= 0) return;

    const int copy_w = (w < fc->width) ? w : fc->width;
    const int copy_h = (h < fc->height) ? h : fc->height;
    const size_t src_pitch = static_cast<size_t>(w) * 4;

    for (int y = 0; y < copy_h; ++y) {
        const uint8_t* src_row = reinterpret_cast<const uint8_t*>(pixels) + static_cast<size_t>(y) * src_pitch;
        uint8_t* dst_row = fc->map + static_cast<size_t>(y) * static_cast<size_t>(fc->stride);
        std::memcpy(dst_row, src_row, static_cast<size_t>(copy_w) * 4);
    }
}

BackendOps get_ops_fbdev() {
    BackendOps ops;
    ops.init = fbdev_init;
    ops.present = fbdev_present;
    ops.shutdown = fbdev_shutdown;
    return ops;
}

#else

BackendOps get_ops_fbdev() {
    return make_stub_ops();
}

#endif
