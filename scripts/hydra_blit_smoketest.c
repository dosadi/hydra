// Minimal user-space smoke test for the Hydra blitter stub.
// Builds with: gcc -I drivers/linux/uapi -O2 -o hydra_blit_smoketest scripts/hydra_blit_smoketest.c

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#ifndef BIT
#define BIT(n) (1U << (n))
#endif

#include "hydra_regs.h"

#define HYDRA_IOCTL_MAGIC 'h'

struct hydra_reg_rw {
    uint32_t offset;
    uint32_t value;
};

struct hydra_info {
    uint32_t vendor;
    uint32_t device;
    int32_t  irq;
    uint64_t bar0_start;
    uint64_t bar0_len;
    uint64_t irq_count;
};

#define HYDRA_IOCTL_INFO _IOR(HYDRA_IOCTL_MAGIC, 0x00, struct hydra_info)
#define HYDRA_IOCTL_RD32 _IOWR(HYDRA_IOCTL_MAGIC, 0x01, struct hydra_reg_rw)
#define HYDRA_IOCTL_WR32 _IOW (HYDRA_IOCTL_MAGIC, 0x02, struct hydra_reg_rw)

static int rd32(int fd, uint32_t off, uint32_t* out)
{
    struct hydra_reg_rw r = { .offset = off, .value = 0 };
    if (ioctl(fd, HYDRA_IOCTL_RD32, &r) != 0)
        return -errno;
    *out = r.value;
    return 0;
}

static int wr32(int fd, uint32_t off, uint32_t val)
{
    struct hydra_reg_rw r = { .offset = off, .value = val };
    if (ioctl(fd, HYDRA_IOCTL_WR32, &r) != 0)
        return -errno;
    return 0;
}

static int do_info(int fd)
{
    struct hydra_info info;
    if (ioctl(fd, HYDRA_IOCTL_INFO, &info) != 0) {
        perror("HYDRA_IOCTL_INFO");
        return -errno;
    }
    printf("Hydra: vendor=0x%04x device=0x%04x irq=%d bar0=0x%llx len=0x%llx irq_count=%llu\n",
           info.vendor, info.device, info.irq,
           (unsigned long long)info.bar0_start,
           (unsigned long long)info.bar0_len,
           (unsigned long long)info.irq_count);
    return 0;
}

int main(int argc, char** argv)
{
    const char* dev = (argc > 1) ? argv[1] : "/dev/hydra_pcie";
    int fd = open(dev, O_RDWR);
    if (fd < 0) {
        perror("open /dev/hydra_pcie");
        return 1;
    }

    if (do_info(fd) != 0)
        return 1;

    /* Clear/enable interrupts. */
    if (wr32(fd, HYDRA_REG_INT_STATUS, 0xFFFFFFFF) ||
        wr32(fd, HYDRA_REG_INT_MASK, HYDRA_INT_FRAME_DONE | HYDRA_INT_DMA_DONE | HYDRA_INT_BLIT_DONE)) {
        fprintf(stderr, "Failed to program interrupts\n");
        return 1;
    }

    /* Seed FIFO data for a small blit (4 words). */
    for (uint32_t i = 0; i < 4; i++) {
        uint32_t word = 0xA0A00000 | i;
        if (wr32(fd, HYDRA_REG_BLIT_FIFO_DATA, word) != 0) {
            fprintf(stderr, "FIFO write failed at %u\n", i);
            return 1;
        }
    }

    /* Program blit: copy 16 bytes from FIFO into pixel RAM at dst index 0x40. */
    if (wr32(fd, HYDRA_REG_BLIT_SRC, 0) ||
        wr32(fd, HYDRA_REG_BLIT_DST, 0x100) ||
        wr32(fd, HYDRA_REG_BLIT_LEN, 16) ||
        wr32(fd, HYDRA_REG_BLIT_CTRL, BIT(0) | BIT(2))) {
        fprintf(stderr, "Failed to kick blit\n");
        return 1;
    }

    /* Poll for completion. */
    for (int i = 0; i < 1000; i++) {
        uint32_t status;
        if (rd32(fd, HYDRA_REG_STATUS, &status) == 0) {
            if (status & HYDRA_STATUS_BLIT_DONE)
                break;
        }
        usleep(1000);
    }

    uint32_t status, int_status;
    rd32(fd, HYDRA_REG_STATUS, &status);
    rd32(fd, HYDRA_REG_INT_STATUS, &int_status);
    printf("Final STATUS=0x%08x INT_STATUS=0x%08x\n", status, int_status);

    /* Read back the destination words to confirm the writes latched. */
    for (uint32_t i = 0; i < 4; i++) {
        wr32(fd, HYDRA_REG_BLIT_PIX_ADDR, 0x40 + i);
        rd32(fd, HYDRA_REG_BLIT_PIX_DATA, &status);
        printf("PIX[%u]=0x%08x\n", i, status);
    }

    return 0;
}
