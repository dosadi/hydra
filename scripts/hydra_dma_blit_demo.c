// Simple libhydra-based smoke test for DMA + blitter paths.
// Usage: sudo ./hydra_dma_blit_demo /dev/hydra_pcie
// Requires: Linux PCIe stub driver loaded, libhydra built.

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "../drivers/libhydra/hydra.h"
#ifndef BIT
#define BIT(x) (1u << (x))
#endif
#include "../drivers/linux/uapi/hydra_regs.h"

static void die(const char* msg)
{
    perror(msg);
    exit(1);
}

int main(int argc, char** argv)
{
    const char* path = "/dev/hydra_pcie";
    if (argc > 1)
        path = argv[1];

    struct hydra_handle h = HYDRA_HANDLE_INIT;
    int ret = hydra_open(&h, path);
    if (ret == -ENOENT || ret == -ENODEV) {
        printf("[hydra_dma_blit_demo] device missing (%s), skipping (ret=77)\n", path);
        return 77;
    } else if (ret != 0) {
        die("hydra_open");
    }

    struct hydra_info info = {0};
    if (hydra_info_query(&h, &info) != 0) {
        die("hydra_info_query");
    }

    printf("[hydra_dma_blit_demo] Opened %s (vendor=0x%04x device=0x%04x, irq=%d)\n",
           path, info.vendor, info.device, info.irq);

    // Clear and enable interrupts (frame, dma, blit).
    if (hydra_wr32(&h, HYDRA_REG_INT_STATUS, 0xFFFFFFFF) != 0 ||
        hydra_wr32(&h, HYDRA_REG_INT_MASK,
                   HYDRA_INT_FRAME_DONE | HYDRA_INT_DMA_DONE | HYDRA_INT_BLIT_DONE) != 0) {
        die("INT_STATUS/INT_MASK");
    }

    // Kick a tiny DMA copy inside the device address space. The stub will
    // treat src/dst as device-local addresses; exact contents are unimportant
    // for this smoke test, we only care about DONE/IRQ behavior.
    const uint64_t dma_src = 0x00000000ull;
    const uint64_t dma_dst = 0x00000100ull;
    const uint32_t dma_len = 0x40; // 64 bytes

    printf("[hydra_dma_blit_demo] Starting DMA: src=0x%llx dst=0x%llx len=0x%x\n",
           (unsigned long long)dma_src,
           (unsigned long long)dma_dst,
           dma_len);

    if (hydra_dma_copy(&h, dma_src, dma_dst, dma_len) != 0)
        die("hydra_dma_copy");

    // Poll INT_STATUS for DMA_DONE.
    uint32_t int_status = 0;
    int dma_ok = 0;
    for (int i = 0; i < 1000; ++i) {
        if (hydra_rd32(&h, HYDRA_REG_INT_STATUS, &int_status) != 0)
            die("INT_STATUS read");
        if (int_status & HYDRA_INT_DMA_DONE) {
            dma_ok = 1;
            // Clear just the DMA_DONE bit.
            hydra_wr32(&h, HYDRA_REG_INT_STATUS, HYDRA_INT_DMA_DONE);
            break;
        }
        usleep(1000);
    }

    printf("[hydra_dma_blit_demo] INT_STATUS after DMA=0x%08x (dma_ok=%d)\n",
           int_status, dma_ok);

    // Seed a few FIFO words and kick a FIFO-driven blit to device memory.
    for (uint32_t i = 0; i < 4; ++i) {
        uint32_t word = 0xC0C00000u | i;
        if (hydra_blit_fifo_push(&h, word) != 0) {
            fprintf(stderr, "FIFO push failed at %u\n", i);
            hydra_close(&h);
            return 1;
        }
    }

    const uint32_t blit_dst = 0x200;   // arbitrary device-local address
    const uint32_t blit_len = 16;      // 4 words * 4 bytes

    printf("[hydra_dma_blit_demo] Kicking blit: dst=0x%x len=%u bytes\n",
           blit_dst, blit_len);

    if (hydra_blit_kick_fifo(&h, blit_dst, blit_len) != 0)
        die("hydra_blit_kick_fifo");

    uint32_t status = 0;
    if (hydra_wait_blit_done(&h, 100 /* ms */, &status) != 0) {
        fprintf(stderr, "[hydra_dma_blit_demo] Timed out waiting for blit; STATUS=0x%08x\n", status);
    } else {
        printf("[hydra_dma_blit_demo] Blit done, STATUS=0x%08x\n", status);
    }

    // Read back a few pixel words via BLIT_PIX_* if the RTL/driver wires them.
    for (uint32_t i = 0; i < 4; ++i) {
        if (hydra_wr32(&h, HYDRA_REG_BLIT_PIX_ADDR, 0x40 + i) != 0)
            die("BLIT_PIX_ADDR");
        uint32_t pix = 0;
        if (hydra_rd32(&h, HYDRA_REG_BLIT_PIX_DATA, &pix) != 0)
            die("BLIT_PIX_DATA");
        printf("[hydra_dma_blit_demo] PIX[%u]=0x%08x\n", i, pix);
    }

    hydra_close(&h);
    return dma_ok ? 0 : 1;
}
