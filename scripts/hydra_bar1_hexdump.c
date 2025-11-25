// SPDX-License-Identifier: BSD-3-Clause
// Map BAR1 and dump a small range for sanity.

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

static void dump_bytes(const uint8_t* p, size_t len) {
    for (size_t i = 0; i < len; i += 16) {
        printf("%04zx:", i);
        for (size_t j = 0; j < 16 && (i + j) < len; ++j) {
            printf(" %02x", p[i + j]);
        }
        printf("\n");
    }
}

int main(int argc, char** argv) {
    const char* dev = (argc > 1) ? argv[1] : "/dev/hydra_pcie";
    size_t bytes = (argc > 2) ? (size_t)strtoul(argv[2], NULL, 0) : 256;
    size_t offset = (argc > 3) ? (size_t)strtoul(argv[3], NULL, 0) : 0;

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

    if (info.bar1_len == 0) {
        fprintf(stderr, "[hydra_bar1_hexdump] BAR1 unavailable; skipping\n");
        close(fd);
        return 77;
    }

    if (offset >= info.bar1_len || offset + bytes > info.bar1_len) {
        fprintf(stderr, "[hydra_bar1_hexdump] range out of bounds (offset=%zu len=%zu bar1_len=%llu)\n",
                offset, bytes, (unsigned long long)info.bar1_len);
        close(fd);
        return 1;
    }

    void* bar1 = mmap(NULL, info.bar1_len, PROT_READ | PROT_WRITE, MAP_SHARED, fd, getpagesize());
    if (bar1 == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    printf("[hydra_bar1_hexdump] BAR1 len=%llu offset=%zu bytes=%zu\n",
           (unsigned long long)info.bar1_len, offset, bytes);
    const uint8_t* base = (const uint8_t*)bar1 + offset;
    if (bytes > info.bar1_len - offset) {
        bytes = info.bar1_len - offset;
    }
    if (bytes > 4096) bytes = 4096; // cap to something readable
    dump_bytes(base, bytes);

    munmap(bar1, info.bar1_len);
    close(fd);
    return 0;
}
