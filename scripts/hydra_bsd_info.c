/* SPDX-License-Identifier: BSD-3-Clause */
/* Minimal FreeBSD userland probe for the Hydra PCI stub.
 * Build: cc -Wall -Wextra -O2 -I ../drivers/linux/uapi -o hydra_bsd_info hydra_bsd_info.c
 * Run:   ./hydra_bsd_info [/dev/hydra]
 */

#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/sysctl.h>
#include <unistd.h>

#include "../drivers/linux/uapi/hydra_regs.h"
#include "../drivers/linux/uapi/hydra_ioctl.h"

static int do_ioctl(int fd, unsigned long req, void *arg, const char *name) {
    int ret = ioctl(fd, req, arg);
    if (ret < 0) {
        fprintf(stderr, "ioctl %s failed: %s\n", name, strerror(errno));
    }
    return ret;
}

static int rd32(int fd, uint32_t off, uint32_t *out) {
    struct hydra_reg_rw rw = { .offset = off, .value = 0 };
    if (do_ioctl(fd, HYDRA_IOCTL_RD32, &rw, "HYDRA_IOCTL_RD32") != 0)
        return -1;
    *out = rw.value;
    return 0;
}

static int wr32(int fd, uint32_t off, uint32_t val) {
    struct hydra_reg_rw rw = { .offset = off, .value = val };
    return do_ioctl(fd, HYDRA_IOCTL_WR32, &rw, "HYDRA_IOCTL_WR32");
}

static void dump_sysctl_stat(const char *name, const char *label) {
    uint64_t v = 0;
    size_t len = sizeof(v);
    if (sysctlbyname(name, &v, &len, NULL, 0) == 0 && len == sizeof(v)) {
        printf("  %s: %llu\n", label, (unsigned long long)v);
    }
}

static void dump_sysctls(void) {
    /* Unit is always 0 in the stub; ignore errors for missing keys. */
    dump_sysctl_stat("dev.hydra.0.bar0_len", "bar0_len");
    dump_sysctl_stat("dev.hydra.0.bar1_len", "bar1_len");
    dump_sysctl_stat("dev.hydra.0.irq_count", "irq_count");
    dump_sysctl_stat("dev.hydra.0.dma_count", "dma_count");
    dump_sysctl_stat("dev.hydra.0.dma_irq_count", "dma_irq_count");
    dump_sysctl_stat("dev.hydra.0.test_irq_count", "test_irq_count");
}

int main(int argc, char **argv) {
    const char *node = (argc > 1) ? argv[1] : "/dev/hydra";
    int fd = open(node, O_RDWR);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    int rc = 0;
    struct hydra_info info = {0};
    if (do_ioctl(fd, HYDRA_IOCTL_INFO, &info, "HYDRA_IOCTL_INFO") != 0) {
        rc = 1;
        goto out;
    }

    printf("Hydra device: vendor=0x%04x device=0x%04x irq=%d\n",
           info.vendor, info.device, info.irq);
    printf("  BAR0: start=0x%llx len=0x%llx\n",
           (unsigned long long)info.bar0_start,
           (unsigned long long)info.bar0_len);
    printf("  BAR1: start=0x%llx len=0x%llx\n",
           (unsigned long long)info.bar1_start,
           (unsigned long long)info.bar1_len);
    printf("  irq_count=%llu\n", (unsigned long long)info.irq_count);

    struct hydra_version ver = {0};
    if (ioctl(fd, HYDRA_IOCTL_VERSION, &ver) == 0) {
        printf("Kernel ABI %u.%u (sizeof info=%u dma_req=%u reg_rw=%u)\n",
               ver.abi_major, ver.abi_minor,
               ver.sizeof_info, ver.sizeof_dma_req, ver.sizeof_reg_rw);
        if (ver.abi_major != HYDRA_ABI_MAJOR) {
            fprintf(stderr, "ABI mismatch: user %u.%u vs kernel %u.%u\n",
                    HYDRA_ABI_MAJOR, HYDRA_ABI_MINOR, ver.abi_major, ver.abi_minor);
            rc = 1;
            goto out;
        }
    } else if (errno != ENOTTY) {
        perror("HYDRA_IOCTL_VERSION");
        rc = 1;
        goto out;
    }

    uint32_t int_status = 0, int_mask = 0;
    if (rd32(fd, HYDRA_REG_INT_STATUS, &int_status) == 0 &&
        rd32(fd, HYDRA_REG_INT_MASK, &int_mask) == 0) {
        printf("INT_STATUS=0x%08x INT_MASK=0x%08x\n", int_status, int_mask);
    }

    printf("Pulsing IRQ_TEST...\n");
    if (wr32(fd, HYDRA_REG_IRQ_TEST, 0x1) != 0) {
        rc = 1;
        goto out;
    }
    if (rd32(fd, HYDRA_REG_INT_STATUS, &int_status) == 0) {
        printf("INT_STATUS after IRQ_TEST: 0x%08x\n", int_status);
    }

    printf("Issuing stub DMA len=16 within BAR0...\n");
    struct hydra_dma_req dma = { .src = 0, .dst = 16, .len = 16, .flags = 0 };
    if (do_ioctl(fd, HYDRA_IOCTL_DMA, &dma, "HYDRA_IOCTL_DMA") != 0) {
        rc = 1;
        goto out;
    }
    if (rd32(fd, HYDRA_REG_DMA_STATUS, &int_status) == 0) {
        printf("DMA_STATUS after stub DMA: 0x%08x\n", int_status);
    }

    printf("FreeBSD sysctl stats (best-effort):\n");
    dump_sysctls();

out:
    close(fd);
    return rc;
}
