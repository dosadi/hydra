#include "backend_ops.h"

#if defined(__linux__) && defined(HYDRA_ENABLE_WAYLAND) && __has_include(<wayland-client.h>) && __has_include(<wayland-client-protocol.h>)

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#include <wayland-client-core.h>
#include <wayland-client-protocol.h>

struct WaylandContext {
    wl_display*        display = nullptr;
    wl_registry*       registry = nullptr;
    wl_compositor*     compositor = nullptr;
    wl_shell*          shell = nullptr;
    wl_shell_surface*  shell_surface = nullptr;
    wl_surface*        surface = nullptr;
    wl_shm*            shm = nullptr;
    wl_buffer*         buffer = nullptr;
    void*              shm_data = nullptr;
    size_t             shm_size = 0;
    int                shm_fd = -1;
    int                width = 0;
    int                height = 0;
    int                stride = 0;
};

static void wl_cleanup_buffer(WaylandContext& wc) {
    if (wc.buffer) {
        wl_buffer_destroy(wc.buffer);
        wc.buffer = nullptr;
    }
    if (wc.shm_data && wc.shm_size)
        munmap(wc.shm_data, wc.shm_size);
    wc.shm_data = nullptr;
    wc.shm_size = 0;
    if (wc.shm_fd >= 0) {
        close(wc.shm_fd);
        wc.shm_fd = -1;
    }
}

static int create_shm_file(size_t size) {
#ifdef MFD_CLOEXEC
    int fd = memfd_create("hydra_wayland_shm", MFD_CLOEXEC);
    if (fd < 0)
        return -1;
    if (ftruncate(fd, static_cast<off_t>(size)) != 0) {
        close(fd);
        return -1;
    }
    return fd;
#else
    static int counter = 0;
    std::string name = "/hydra-wl-" + std::to_string(::getpid()) + "-" + std::to_string(counter++);
    int fd = shm_open(name.c_str(), O_RDWR | O_CREAT | O_EXCL, 0600);
    shm_unlink(name.c_str());
    if (fd < 0)
        return -1;
    if (ftruncate(fd, static_cast<off_t>(size)) != 0) {
        close(fd);
        return -1;
    }
    return fd;
#endif
}

static wl_buffer* create_buffer(WaylandContext& wc, int w, int h) {
    wl_cleanup_buffer(wc);
    const int stride = w * 4;
    const size_t size = static_cast<size_t>(stride) * static_cast<size_t>(h);

    int fd = create_shm_file(size);
    if (fd < 0)
        return nullptr;

    void* data = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        close(fd);
        return nullptr;
    }

    wl_shm_pool* pool = wl_shm_create_pool(wc.shm, fd, static_cast<int>(size));
    if (!pool) {
        munmap(data, size);
        close(fd);
        return nullptr;
    }
    wl_buffer* buffer = wl_shm_pool_create_buffer(pool, 0, w, h, stride, WL_SHM_FORMAT_XRGB8888);
    wl_shm_pool_destroy(pool);
    if (!buffer) {
        munmap(data, size);
        close(fd);
        return nullptr;
    }

    wc.shm_fd = fd;
    wc.shm_data = data;
    wc.shm_size = size;
    wc.stride = stride;
    wc.width = w;
    wc.height = h;
    return buffer;
}

static void handle_ping(void*, wl_shell_surface* shell_surface, uint32_t serial) {
    wl_shell_surface_pong(shell_surface, serial);
}

static const wl_shell_surface_listener shell_surface_listener = {
    handle_ping,
    nullptr,
    nullptr
};

static void handle_global(void* data, wl_registry* registry, uint32_t name,
                          const char* interface, uint32_t version) {
    WaylandContext* wc = static_cast<WaylandContext*>(data);
    if (std::strcmp(interface, "wl_compositor") == 0) {
        wc->compositor = static_cast<wl_compositor*>(
            wl_registry_bind(registry, name, &wl_compositor_interface, 3));
    } else if (std::strcmp(interface, "wl_shell") == 0) {
        wc->shell = static_cast<wl_shell*>(
            wl_registry_bind(registry, name, &wl_shell_interface, 1));
    } else if (std::strcmp(interface, "wl_shm") == 0) {
        wc->shm = static_cast<wl_shm*>(
            wl_registry_bind(registry, name, &wl_shm_interface, 1));
    }
}

static void handle_global_remove(void*, wl_registry*, uint32_t) {}

static const wl_registry_listener registry_listener = {
    handle_global,
    handle_global_remove
};

static bool wayland_init(PlatformContext& ctx, const PlatformConfig& cfg) {
    WaylandContext* wc = new WaylandContext();
    wc->display = wl_display_connect(nullptr);
    if (!wc->display) {
        delete wc;
        return false;
    }

    wc->registry = wl_display_get_registry(wc->display);
    if (!wc->registry) {
        wl_display_disconnect(wc->display);
        delete wc;
        return false;
    }
    wl_registry_add_listener(wc->registry, &registry_listener, wc);
    wl_display_roundtrip(wc->display);

    if (!wc->compositor || !wc->shell || !wc->shm) {
        wl_display_disconnect(wc->display);
        delete wc;
        return false;
    }

    wc->surface = wl_compositor_create_surface(wc->compositor);
    if (!wc->surface) {
        wl_display_disconnect(wc->display);
        delete wc;
        return false;
    }
    wc->shell_surface = wl_shell_get_shell_surface(wc->shell, wc->surface);
    if (!wc->shell_surface) {
        wl_surface_destroy(wc->surface);
        wl_display_disconnect(wc->display);
        delete wc;
        return false;
    }
    wl_shell_surface_add_listener(wc->shell_surface, &shell_surface_listener, nullptr);
    wl_shell_surface_set_title(wc->shell_surface, "Hydra Wayland Backend");
    wl_shell_surface_set_toplevel(wc->shell_surface);

    wc->buffer = create_buffer(wc, cfg.width, cfg.height);
    if (!wc->buffer) {
        wl_shell_surface_destroy(wc->shell_surface);
        wl_surface_destroy(wc->surface);
        wl_display_disconnect(wc->display);
        delete wc;
        return false;
    }

    ctx.user = wc;
    return true;
}

static void wayland_present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    if (!ctx.user || !pixels) return;
    WaylandContext* wc = static_cast<WaylandContext*>(ctx.user);
    if (!wc->display || !wc->surface || !wc->buffer || !wc->shm_data)
        return;

    if (w != wc->width || h != wc->height) {
        wl_buffer* new_buf = create_buffer(*wc, w, h);
        if (!new_buf)
            return;
        wc->buffer = new_buf;
    }

    const size_t src_pitch = static_cast<size_t>(w) * 4;
    for (int y = 0; y < h; ++y) {
        const uint8_t* src_row = reinterpret_cast<const uint8_t*>(pixels) + static_cast<size_t>(y) * src_pitch;
        uint8_t* dst_row = static_cast<uint8_t*>(wc->shm_data) + static_cast<size_t>(y) * static_cast<size_t>(wc->stride);
        std::memcpy(dst_row, src_row, src_pitch);
    }

    wl_surface_attach(wc->surface, wc->buffer, 0, 0);
    wl_surface_damage(wc->surface, 0, 0, w, h);
    wl_surface_commit(wc->surface);
    wl_display_flush(wc->display);
}

static void wayland_shutdown(PlatformContext& ctx) {
    if (!ctx.user) return;
    WaylandContext* wc = static_cast<WaylandContext*>(ctx.user);

    wl_cleanup_buffer(*wc);
    if (wc->shell_surface) wl_shell_surface_destroy(wc->shell_surface);
    if (wc->surface) wl_surface_destroy(wc->surface);
    if (wc->registry) wl_registry_destroy(wc->registry);
    if (wc->display) wl_display_disconnect(wc->display);
    delete wc;
    ctx.user = nullptr;
}

BackendOps get_ops_wayland() {
    BackendOps ops;
    ops.init = wayland_init;
    ops.present = wayland_present;
    ops.shutdown = wayland_shutdown;
    return ops;
}

#else

BackendOps get_ops_wayland() {
    return make_stub_ops();
}

#endif
