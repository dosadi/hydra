// SPDX-License-Identifier: BSD-3-Clause
// Simple mmap smoke: map BAR0 and read ID/REV/STATUS registers directly.

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include "../drivers/linux/uapi/hydra_regs.h"
#include "../drivers/linux/uapi/hydra_ioctl.h"

int main(int argc, char** argv) {
    const char* dev = (argc > 1) ? argv[1] : "/dev/hydra_pcie";
    int fd = open(dev, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open");
        return 77; // skip if missing
    }

    struct hydra_info info = {0};
    if (ioctl(fd, HYDRA_IOCTL_INFO, &info) != 0) {
        perror("HYDRA_IOCTL_INFO");
        close(fd);
        return 1;
    }

    size_t map_len = (size_t)info.bar0_len;
    if (map_len == 0 || map_len > HYDRA_BAR0_SIZE)
        map_len = HYDRA_BAR0_SIZE;

    void* bar0 = mmap(NULL, map_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (bar0 == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    volatile uint32_t* reg = (volatile uint32_t*)bar0;
    uint32_t id    = reg[HYDRA_REG_ID / 4];
    uint32_t rev   = reg[HYDRA_REG_REV / 4];
    uint32_t status= reg[HYDRA_REG_STATUS / 4];
    uint32_t int_status = reg[HYDRA_REG_INT_STATUS / 4];
    uint32_t int_mask   = reg[HYDRA_REG_INT_MASK / 4];

    printf("[hydra_mmap_smoke] ID=0x%08x REV=0x%08x STATUS=0x%08x INT_STATUS=0x%08x INT_MASK=0x%08x (len=%zu)\n",
           id, rev, status, int_status, int_mask, map_len);

    munmap((void*)bar0, map_len);
    close(fd);
    return 0;
}
