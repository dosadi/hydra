#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "../linux/uapi/hydra_ioctl.h"

#define HYDRA_LIBHYDRA_VERSION_MAJOR 0
#define HYDRA_LIBHYDRA_VERSION_MINOR 0
#define HYDRA_LIBHYDRA_VERSION_PATCH 5

const char* hydra_version_string(void);

struct hydra_handle {
    int fd;
};

#define HYDRA_HANDLE_INIT { .fd = -1 }

struct hydra_camera_state {
    int32_t cam_x;
    int32_t cam_y;
    int32_t cam_z;
    int32_t dir_x;
    int32_t dir_y;
    int32_t dir_z;
    int32_t plane_x;
    int32_t plane_y;
};

struct hydra_flags_state {
    bool smooth;
    bool curvature;
    bool extra_light;
    bool diag_slice;
};

struct hydra_selection_state {
    bool active;
    uint8_t x;
    uint8_t y;
    uint8_t z;
};

int hydra_open(struct hydra_handle* h, const char* path);
void hydra_close(struct hydra_handle* h);
int hydra_info_query(struct hydra_handle* h, struct hydra_info* info);
int hydra_rd32(struct hydra_handle* h, uint32_t off, uint32_t* val);
int hydra_wr32(struct hydra_handle* h, uint32_t off, uint32_t val);
int hydra_device_present(const char* path);
int hydra_get_int_status(struct hydra_handle* h, uint32_t* status);
int hydra_get_int_mask(struct hydra_handle* h, uint32_t* mask);
int hydra_clear_int_status(struct hydra_handle* h, uint32_t bits);

/* Blitter helpers (stub-friendly) */
int hydra_blit_fifo_push(struct hydra_handle* h, uint32_t word);
int hydra_blit_kick_fifo(struct hydra_handle* h, uint32_t dst, uint32_t len_bytes);
int hydra_wait_blit_done(struct hydra_handle* h, int timeout_ms, uint32_t* status_out);

/* Surface extraction (stub): issues a SURFACE_EXTRACT blit and reads SURF_STATS. */
int hydra_surface_extract_stub(struct hydra_handle* h,
                               uint32_t surf_base,
                               uint32_t surf_len_bytes,
                               uint32_t blit_len_bytes,
                               uint32_t* surf_stats_out);

/* Automatic region-0 extractor (stub): kicks REGION0 and waits for STATUS.valid. */
int hydra_region0_extract_stub(struct hydra_handle* h,
                               uint32_t region_min,
                               uint32_t region_max,
                               uint32_t* status_out,
                               uint32_t* surf_stats_out);

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
int hydra_apply_state(struct hydra_handle* h,
                      const struct hydra_camera_state* cam,
                      const struct hydra_flags_state* flags,
                      const struct hydra_selection_state* sel);
int hydra_soft_reset(struct hydra_handle* h);
int hydra_start_frame(struct hydra_handle* h);
