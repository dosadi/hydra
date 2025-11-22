#include "hydra.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../linux/uapi/hydra_regs.h"
#include "../linux/uapi/hydra_ioctl.h"

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
