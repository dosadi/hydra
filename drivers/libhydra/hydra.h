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

/* Camera/flags/selection helpers targeting BAR0 CSRs. */
int hydra_set_camera_raw(struct hydra_handle* h,
                         int32_t cam_x, int32_t cam_y, int32_t cam_z,
                         int32_t dir_x, int32_t dir_y, int32_t dir_z,
                         int32_t plane_x, int32_t plane_y);
int hydra_set_flags(struct hydra_handle* h,
                    bool smooth, bool curvature,
                    bool extra_light, bool diag_slice);
int hydra_set_selection(struct hydra_handle* h,
                        bool active, uint8_t x, uint8_t y, uint8_t z);
int hydra_soft_reset(struct hydra_handle* h);
int hydra_start_frame(struct hydra_handle* h);
