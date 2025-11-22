#pragma once
#include <stdint.h>
#include <stdbool.h>

struct hydra_handle {
    int fd;
};

struct hydra_info {
    uint32_t vendor;
    uint32_t device;
    int32_t  irq;
    uint64_t bar0_start;
    uint64_t bar0_len;
    uint64_t irq_count;
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
