// Simple IRQ_TEST exerciser for Hydra PCIe stub.
// Usage: ./hydra_irq_test [/dev/hydra_pcie] [mask=0x...]

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>

#include "../drivers/linux/uapi/hydra_regs.h"
#include "../drivers/linux/uapi/hydra_ioctl.h"

static int rd32(int fd, uint32_t off, uint32_t* out)
{
    struct hydra_reg_rw rw = { .offset = off, .value = 0 };
    if (ioctl(fd, HYDRA_IOCTL_RD32, &rw) != 0)
        return -errno;
    *out = rw.value;
    return 0;
}

static int wr32(int fd, uint32_t off, uint32_t val)
{
    struct hydra_reg_rw rw = { .offset = off, .value = val };
    if (ioctl(fd, HYDRA_IOCTL_WR32, &rw) != 0)
        return -errno;
    return 0;
}

int main(int argc, char** argv)
{
    const char* dev = "/dev/hydra_pcie";
    uint32_t mask = HYDRA_INT_FRAME_DONE | HYDRA_INT_DMA_DONE | HYDRA_INT_TEST | HYDRA_INT_BLIT_DONE;

    for (int i = 1; i < argc; ++i) {
        if (strncmp(argv[i], "mask=", 5) == 0) {
            mask = (uint32_t)strtoul(argv[i] + 5, NULL, 0);
        } else {
            dev = argv[i];
        }
    }

    int fd = open(dev, O_RDWR);
    if (fd < 0) {
        perror("open device");
        return 1;
    }

    struct hydra_info info = {0};
    if (ioctl(fd, HYDRA_IOCTL_INFO, &info) != 0) {
        perror("HYDRA_IOCTL_INFO");
        close(fd);
        return 1;
    }

    printf("Device: %s vendor=0x%04x device=0x%04x irq=%d\n",
           dev, info.vendor, info.device, info.irq);

    // Program mask and clear status.
    if (wr32(fd, HYDRA_REG_INT_MASK, mask) != 0) {
        perror("write INT_MASK");
    }
    if (wr32(fd, HYDRA_REG_INT_STATUS, 0xFFFFFFFFu) != 0) {
        perror("clear INT_STATUS");
    }

    uint32_t st_before = 0, mask_read = 0;
    rd32(fd, HYDRA_REG_INT_STATUS, &st_before);
    rd32(fd, HYDRA_REG_INT_MASK, &mask_read);
    printf("INT_STATUS before=0x%08x mask=0x%08x\n", st_before, mask_read);

    // Trigger IRQ_TEST.
    if (wr32(fd, HYDRA_REG_IRQ_TEST, 1) != 0) {
        perror("write IRQ_TEST");
    }
    usleep(1000);

    uint32_t st_after = 0;
    rd32(fd, HYDRA_REG_INT_STATUS, &st_after);
    printf("INT_STATUS after IRQ_TEST=0x%08x (mask=0x%08x)\n", st_after, mask_read);

    // Clear again before exit.
    wr32(fd, HYDRA_REG_INT_STATUS, st_after);

    close(fd);
    return 0;
}
