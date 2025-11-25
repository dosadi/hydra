#define _DEFAULT_SOURCE
#include "hydra.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../linux/uapi/hydra_regs.h"
#include "../linux/uapi/hydra_ioctl.h"

#ifndef BIT
#define BIT(nr) (1UL << (nr))
#endif

const char* hydra_version_string(void)
{
    return "0.0.6";
}

static int do_ioctl(int fd, unsigned long cmd, void* arg)
{
    int ret = ioctl(fd, cmd, arg);
    if (ret < 0)
        return -errno;
    return ret;
}

int hydra_open(struct hydra_handle* h, const char* path)
{
    if (!h) return -EINVAL;
    h->fd = open(path ? path : "/dev/hydra_pcie", O_RDWR);
    if (h->fd < 0)
        return -errno;
    return 0;
}

void hydra_close(struct hydra_handle* h)
{
    if (!h || h->fd < 0)
        return;
    close(h->fd);
    h->fd = -1;
}

int hydra_info_query(struct hydra_handle* h, struct hydra_info* info)
{
    if (!h || h->fd < 0 || !info)
        return -EINVAL;
    return do_ioctl(h->fd, HYDRA_IOCTL_INFO, info);
}

int hydra_rd32(struct hydra_handle* h, uint32_t off, uint32_t* val)
{
    if (!h || h->fd < 0 || !val)
        return -EINVAL;
    struct hydra_reg_rw rw = { .offset = off, .value = 0 };
    int ret = do_ioctl(h->fd, HYDRA_IOCTL_RD32, &rw);
    if (ret == 0)
        *val = rw.value;
    return ret;
}

int hydra_wr32(struct hydra_handle* h, uint32_t off, uint32_t val)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    struct hydra_reg_rw rw = { .offset = off, .value = val };
    return do_ioctl(h->fd, HYDRA_IOCTL_WR32, &rw);
}

int hydra_device_present(const char* path)
{
    struct hydra_handle h = HYDRA_HANDLE_INIT;
    int ret = hydra_open(&h, path);
    if (ret == 0)
        hydra_close(&h);
    return ret;
}

int hydra_get_int_status(struct hydra_handle* h, uint32_t* status)
{
    if (!h || h->fd < 0 || !status)
        return -EINVAL;
    return hydra_rd32(h, HYDRA_REG_INT_STATUS, status);
}

int hydra_get_int_mask(struct hydra_handle* h, uint32_t* mask)
{
    if (!h || h->fd < 0 || !mask)
        return -EINVAL;
    return hydra_rd32(h, HYDRA_REG_INT_MASK, mask);
}

int hydra_clear_int_status(struct hydra_handle* h, uint32_t bits)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    return hydra_wr32(h, HYDRA_REG_INT_STATUS, bits);
}

int hydra_dma_copy(struct hydra_handle* h, uint64_t src, uint64_t dst, uint32_t len_bytes)
{
    struct hydra_dma_req req = {
        .src = src,
        .dst = dst,
        .len = len_bytes,
        .flags = 0,
    };
    return do_ioctl(h->fd, HYDRA_IOCTL_DMA, &req);
}

int hydra_blit_fifo_push(struct hydra_handle* h, uint32_t word)
{
    return hydra_wr32(h, HYDRA_REG_BLIT_FIFO_DATA, word);
}

int hydra_blit_kick_fifo(struct hydra_handle* h, uint32_t dst, uint32_t len_bytes)
{
    int ret = 0;
    ret = hydra_wr32(h, HYDRA_REG_BLIT_DST, dst);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_BLIT_LEN, len_bytes);
    if (ret) return ret;
    return hydra_wr32(h, HYDRA_REG_BLIT_CTRL, BIT(0) | BIT(2));
}

int hydra_surface_extract_stub(struct hydra_handle* h,
                               uint32_t surf_base,
                               uint32_t surf_len_bytes,
                               uint32_t blit_len_bytes,
                               uint32_t* surf_stats_out)
{
    if (!h || h->fd < 0)
        return -EINVAL;

    int ret = 0;
    uint32_t ctrl = 0;

    ret = hydra_wr32(h, HYDRA_REG_SURF_BASE, surf_base);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_SURF_LEN, surf_len_bytes);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_BLIT_LEN, blit_len_bytes);
    if (ret) return ret;

    ctrl = (HYDRA_BLIT_OP_SURFACE_EXTRACT << HYDRA_BLIT_CTRL_OP_SHIFT) | BIT(0);
    ret = hydra_wr32(h, HYDRA_REG_BLIT_CTRL, ctrl);
    if (ret) return ret;

    ret = hydra_wait_blit_done(h, 100, NULL);
    if (ret)
        return ret;

    if (surf_stats_out)
        return hydra_rd32(h, HYDRA_REG_SURF_STATS, surf_stats_out);
    return 0;
}

int hydra_region0_extract_stub(struct hydra_handle* h,
                               uint32_t region_min,
                               uint32_t region_max,
                               uint32_t* status_out,
                               uint32_t* surf_stats_out)
{
    if (!h || h->fd < 0)
        return -EINVAL;

    int ret = 0;
    uint32_t status = 0;

    ret = hydra_wr32(h, HYDRA_REG_REGION0_MIN, region_min);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_REGION0_MAX, region_max);
    if (ret) return ret;

    /* Enable + kick with lod_hint=0. */
    ret = hydra_wr32(h, HYDRA_REG_REGION0_CFG, 0x3u);
    if (ret) return ret;

    /* Poll REGION0_STATUS.valid with a simple timeout. */
    const int sleep_us = 1000;
    int loops = 100;
    while (loops-- > 0) {
        ret = hydra_rd32(h, HYDRA_REG_REGION0_STATUS, &status);
        if (ret)
            return ret;
        if (status & BIT(1))
            break;
        usleep(sleep_us);
    }

    if (!(status & BIT(1)))
        return -ETIMEDOUT;

    if (status_out)
        *status_out = status;
    if (surf_stats_out)
        return hydra_rd32(h, HYDRA_REG_REGION0_SURF_STATS, surf_stats_out);
    return 0;
}

int hydra_wait_blit_done(struct hydra_handle* h, int timeout_ms, uint32_t* status_out)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    const int sleep_us = 1000;
    int loops = timeout_ms > 0 ? (timeout_ms * 1000 / sleep_us) : 1000;
    uint32_t status = 0;
    while (loops-- > 0) {
        hydra_rd32(h, HYDRA_REG_STATUS, &status);
        if (status & HYDRA_STATUS_BLIT_DONE)
            break;
        usleep(sleep_us);
    }
    if (status_out)
        *status_out = status;
    return (status & HYDRA_STATUS_BLIT_DONE) ? 0 : -ETIMEDOUT;
}

int hydra_set_camera_raw(struct hydra_handle* h,
                         int32_t cam_x, int32_t cam_y, int32_t cam_z,
                         int32_t dir_x, int32_t dir_y, int32_t dir_z,
                         int32_t plane_x, int32_t plane_y)
{
    if (!h || h->fd < 0)
        return -EINVAL;

    int ret = 0;
    ret = hydra_wr32(h, HYDRA_REG_CAM_X, (uint32_t)cam_x);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_Y, (uint32_t)cam_y);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_Z, (uint32_t)cam_z);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_DIR_X, (uint32_t)dir_x);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_DIR_Y, (uint32_t)dir_y);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_DIR_Z, (uint32_t)dir_z);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_CAM_PLANE_X, (uint32_t)plane_x);
    if (ret) return ret;
    return hydra_wr32(h, HYDRA_REG_CAM_PLANE_Y, (uint32_t)plane_y);
}

int hydra_set_flags(struct hydra_handle* h,
                    bool smooth, bool curvature,
                    bool extra_light, bool diag_slice)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    uint32_t flags = 0;
    if (smooth)      flags |= BIT(0);
    if (curvature)   flags |= BIT(1);
    if (extra_light) flags |= BIT(2);
    if (diag_slice)  flags |= BIT(3);
    return hydra_wr32(h, HYDRA_REG_FLAGS, flags);
}

int hydra_set_selection(struct hydra_handle* h,
                        bool active, uint8_t x, uint8_t y, uint8_t z)
{
    if (!h || h->fd < 0)
        return -EINVAL;

    int ret = 0;
    ret = hydra_wr32(h, HYDRA_REG_SEL_ACTIVE, active ? 1u : 0u);
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_SEL_X, (uint32_t)(x & 0x3F));
    if (ret) return ret;
    ret = hydra_wr32(h, HYDRA_REG_SEL_Y, (uint32_t)(y & 0x3F));
    if (ret) return ret;
    return hydra_wr32(h, HYDRA_REG_SEL_Z, (uint32_t)(z & 0x3F));
}

int hydra_apply_state(struct hydra_handle* h,
                      const struct hydra_camera_state* cam,
                      const struct hydra_flags_state* flags,
                      const struct hydra_selection_state* sel)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    int ret = 0;
    if (cam) {
        ret = hydra_set_camera_raw(h,
            cam->cam_x, cam->cam_y, cam->cam_z,
            cam->dir_x, cam->dir_y, cam->dir_z,
            cam->plane_x, cam->plane_y);
        if (ret) return ret;
    }
    if (flags) {
        ret = hydra_set_flags(h, flags->smooth, flags->curvature, flags->extra_light, flags->diag_slice);
        if (ret) return ret;
    }
    if (sel) {
        ret = hydra_set_selection(h, sel->active, sel->x, sel->y, sel->z);
        if (ret) return ret;
    }
    return 0;
}

int hydra_soft_reset(struct hydra_handle* h)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    uint32_t ctrl = 0;
    int ret = hydra_rd32(h, HYDRA_REG_CTRL, &ctrl);
    if (ret)
        return ret;
    ctrl |= HYDRA_CTRL_SOFT_RESET;
    ret = hydra_wr32(h, HYDRA_REG_CTRL, ctrl);
    if (ret)
        return ret;
    ctrl &= ~HYDRA_CTRL_SOFT_RESET;
    return hydra_wr32(h, HYDRA_REG_CTRL, ctrl);
}

int hydra_start_frame(struct hydra_handle* h)
{
    if (!h || h->fd < 0)
        return -EINVAL;
    uint32_t ctrl = 0;
    int ret = hydra_rd32(h, HYDRA_REG_CTRL, &ctrl);
    if (ret)
        return ret;
    ctrl |= HYDRA_CTRL_START_FRAME;
    ret = hydra_wr32(h, HYDRA_REG_CTRL, ctrl);
    if (ret)
        return ret;
    ctrl &= ~HYDRA_CTRL_START_FRAME;
    return hydra_wr32(h, HYDRA_REG_CTRL, ctrl);
}
