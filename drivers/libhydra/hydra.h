#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "../linux/uapi/hydra_ioctl.h"

struct hydra_handle {
    int fd;
};

int hydra_open(struct hydra_handle* h, const char* path);
void hydra_close(struct hydra_handle* h);
int hydra_info_query(struct hydra_handle* h, struct hydra_info* info);
int hydra_rd32(struct hydra_handle* h, uint32_t off, uint32_t* val);
int hydra_wr32(struct hydra_handle* h, uint32_t off, uint32_t val);

/* Blitter helpers (stub-friendly) */
int hydra_blit_fifo_push(struct hydra_handle* h, uint32_t word);
int hydra_blit_kick_fifo(struct hydra_handle* h, uint32_t dst, uint32_t len_bytes);
int hydra_wait_blit_done(struct hydra_handle* h, int timeout_ms, uint32_t* status_out);

/* DMA helper (stub): uses device DMA registers */
int hydra_dma_copy(struct hydra_handle* h, uint64_t src, uint64_t dst, uint32_t len_bytes);
