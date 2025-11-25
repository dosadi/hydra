// SPDX-License-Identifier: BSD-3-Clause
// Negative test for HYDRA_IOCTL_DMA: ensure bad offsets are rejected.

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../drivers/linux/uapi/hydra_ioctl.h"

static int rd32(int fd, uint32_t off, uint32_t* out) {
    struct hydra_reg_rw rw = { .offset = off, .value = 0 };
    if (ioctl(fd, HYDRA_IOCTL_RD32, &rw) != 0)
        return -errno;
    *out = rw.value;
    return 0;
}

int main(int argc, char** argv) {
    const char* dev = (argc > 1) ? argv[1] : "/dev/hydra_pcie";
    int fd = open(dev, O_RDWR);
    if (fd < 0) {
        perror("open");
        return 77; // skip if device missing
    }

    struct hydra_dma_req req = {
        .src = 0xFFFFFFF0u,
        .dst = 0xFFFFFFF0u,
        .len = 0x100,
        .flags = 0,
    };

    int ret = ioctl(fd, HYDRA_IOCTL_DMA, &req);
    if (ret == 0) {
        fprintf(stderr, "HYDRA_IOCTL_DMA unexpectedly succeeded on bad offsets\n");
        close(fd);
        return 1;
    }

    uint32_t status = 0;
    rd32(fd, HYDRA_REG_DMA_STATUS, &status);
    printf("DMA_STATUS after bad DMA: 0x%08x (ret=%d errno=%d)\n", status, ret, errno);
    close(fd);
    return 0;
}
