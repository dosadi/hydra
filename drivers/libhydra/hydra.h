#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "../linux/uapi/hydra_ioctl.h"

#define HYDRA_LIBHYDRA_VERSION_MAJOR 0
#define HYDRA_LIBHYDRA_VERSION_MINOR 0
#define HYDRA_LIBHYDRA_VERSION_PATCH 5

/**
 * @brief Get the version string for libhydra
 * @return Version string in format "major.minor.patch"
 */
const char* hydra_version_string(void);

/**
 * @brief Handle for Hydra device operations
 *
 * This structure represents an open connection to a Hydra device.
 * Initialize with HYDRA_HANDLE_INIT before use.
 */
struct hydra_handle {
    int fd; /**< File descriptor for the device */
};

#define HYDRA_HANDLE_INIT { .fd = -1 }

/**
 * @brief Camera state structure for 3D positioning and orientation
 *
 * Contains the camera parameters used by the ray tracing engine.
 * All values are fixed-point with FX = 256 scale.
 */
struct hydra_camera_state {
    int32_t cam_x;    /**< Camera X position (fixed-point) */
    int32_t cam_y;    /**< Camera Y position (fixed-point) */
    int32_t cam_z;    /**< Camera Z position (fixed-point) */
    int32_t dir_x;    /**< View direction X component (fixed-point) */
    int32_t dir_y;    /**< View direction Y component (fixed-point) */
    int32_t dir_z;    /**< View direction Z component (fixed-point) */
    int32_t plane_x;  /**< View plane X component (fixed-point) */
    int32_t plane_y;  /**< View plane Y component (fixed-point) */
};

/**
 * @brief Rendering flags state structure
 *
 * Controls various rendering features and debug modes.
 */
struct hydra_flags_state {
    bool smooth;      /**< Enable surface smoothing */
    bool curvature;   /**< Enable curvature shading */
    bool extra_light; /**< Enable extra lighting */
    bool diag_slice;  /**< Enable diagonal slice debug view */
    bool ray_jitter;  /**< Enable ray jittering for anti-aliasing */
};

/**
 * @brief Voxel selection state structure
 *
 * Represents the currently selected voxel for editing operations.
 */
struct hydra_selection_state {
    bool active; /**< Whether a voxel is currently selected */
    uint8_t x;   /**< Selected voxel X coordinate (0-255) */
    uint8_t y;   /**< Selected voxel Y coordinate (0-255) */
    uint8_t z;   /**< Selected voxel Z coordinate (0-255) */
};

/**
 * @brief Open a connection to a Hydra device
 *
 * @param h Handle to initialize
 * @param path Device path (e.g., "/dev/hydra0") or NULL for auto-detection
 * @return 0 on success, negative errno on failure
 */
int hydra_open(struct hydra_handle* h, const char* path);

/**
 * @brief Close a Hydra device connection
 *
 * @param h Handle to close
 */
void hydra_close(struct hydra_handle* h);

/**
 * @brief Query device information
 *
 * @param h Device handle
 * @param info Pointer to hydra_info structure to fill
 * @return 0 on success, negative errno on failure
 */
int hydra_info_query(struct hydra_handle* h, struct hydra_info* info);

/**
 * @brief Read a 32-bit register from the device
 *
 * @param h Device handle
 * @param off Register offset in BAR0
 * @param val Pointer to store the read value
 * @return 0 on success, negative errno on failure
 */
int hydra_rd32(struct hydra_handle* h, uint32_t off, uint32_t* val);

/**
 * @brief Write a 32-bit register to the device
 *
 * @param h Device handle
 * @param off Register offset in BAR0
 * @param val Value to write
 * @return 0 on success, negative errno on failure
 */
int hydra_wr32(struct hydra_handle* h, uint32_t off, uint32_t val);

/**
 * @brief Check if a Hydra device is present at the given path
 *
 * @param path Device path to check
 * @return 1 if present, 0 if not present, negative errno on error
 */
int hydra_device_present(const char* path);

/**
 * @brief Get the current interrupt status
 *
 * @param h Device handle
 * @param status Pointer to store interrupt status bits
 * @return 0 on success, negative errno on failure
 */
int hydra_get_int_status(struct hydra_handle* h, uint32_t* status);

/**
 * @brief Get the current interrupt mask
 *
 * @param h Device handle
 * @param mask Pointer to store interrupt mask bits
 * @return 0 on success, negative errno on failure
 */
int hydra_get_int_mask(struct hydra_handle* h, uint32_t* mask);

/**
 * @brief Clear interrupt status bits
 *
 * @param h Device handle
 * @param bits Bits to clear (write 1 to clear)
 * @return 0 on success, negative errno on failure
 */
int hydra_clear_int_status(struct hydra_handle* h, uint32_t bits);

/* Blitter helpers (stub-friendly) */

/**
 * @brief Push a word to the blitter FIFO
 *
 * @param h Device handle
 * @param word 32-bit word to push
 * @return 0 on success, negative errno on failure
 */
int hydra_blit_fifo_push(struct hydra_handle* h, uint32_t word);

/**
 * @brief Kick off a blitter operation
 *
 * @param h Device handle
 * @param dst Destination address for the blit
 * @param len_bytes Length of data to blit in bytes
 * @return 0 on success, negative errno on failure
 */
int hydra_blit_kick_fifo(struct hydra_handle* h, uint32_t dst, uint32_t len_bytes);

/**
 * @brief Wait for blitter operation to complete
 *
 * @param h Device handle
 * @param timeout_ms Timeout in milliseconds (0 for no timeout)
 * @param status_out Pointer to store final status (can be NULL)
 * @return 0 on success, negative errno on failure
 */
int hydra_wait_blit_done(struct hydra_handle* h, int timeout_ms, uint32_t* status_out);

/* Surface extraction (stub): issues a SURFACE_EXTRACT blit and reads SURF_STATS. */

/**
 * @brief Extract surface data using blitter (stub implementation)
 *
 * Issues a SURFACE_EXTRACT blit operation and reads surface statistics.
 *
 * @param h Device handle
 * @param surf_base Base address of surface buffer
 * @param surf_len_bytes Length of surface buffer in bytes
 * @param blit_len_bytes Length of data to blit
 * @param surf_stats_out Pointer to store surface statistics
 * @return 0 on success, negative errno on failure
 */
int hydra_surface_extract_stub(struct hydra_handle* h,
                               uint32_t surf_base,
                               uint32_t surf_len_bytes,
                               uint32_t blit_len_bytes,
                               uint32_t* surf_stats_out);

/* Automatic region-0 extractor (stub): kicks REGION0 and waits for STATUS.valid. */

/**
 * @brief Extract region 0 data automatically (stub implementation)
 *
 * Kicks off a REGION0 extraction and waits for completion.
 *
 * @param h Device handle
 * @param region_min Minimum region value
 * @param region_max Maximum region value
 * @param status_out Pointer to store final status
 * @param surf_stats_out Pointer to store surface statistics
 * @return 0 on success, negative errno on failure
 */
int hydra_region0_extract_stub(struct hydra_handle* h,
                               uint32_t region_min,
                               uint32_t region_max,
                               uint32_t* status_out,
                               uint32_t* surf_stats_out);

/* DMA helper (stub): uses device DMA registers */

/**
 * @brief Perform DMA copy operation (stub implementation)
 *
 * @param h Device handle
 * @param src Source address
 * @param dst Destination address
 * @param len_bytes Length of data to copy in bytes
 * @return 0 on success, negative errno on failure
 */
int hydra_dma_copy(struct hydra_handle* h, uint64_t src, uint64_t dst, uint32_t len_bytes);

/* Camera/flags/selection helpers targeting BAR0 CSRs. */

/**
 * @brief Set camera parameters with raw fixed-point values
 *
 * @param h Device handle
 * @param cam_x Camera X position
 * @param cam_y Camera Y position
 * @param cam_z Camera Z position
 * @param dir_x View direction X
 * @param dir_y View direction Y
 * @param dir_z View direction Z
 * @param plane_x View plane X
 * @param plane_y View plane Y
 * @return 0 on success, negative errno on failure
 */
int hydra_set_camera_raw(struct hydra_handle* h,
                         int32_t cam_x, int32_t cam_y, int32_t cam_z,
                         int32_t dir_x, int32_t dir_y, int32_t dir_z,
                         int32_t plane_x, int32_t plane_y);

/**
 * @brief Set rendering flags
 *
 * @param h Device handle
 * @param smooth Enable surface smoothing
 * @param curvature Enable curvature shading
 * @param extra_light Enable extra lighting
 * @param diag_slice Enable diagonal slice debug view
 * @param ray_jitter Enable ray jittering
 * @return 0 on success, negative errno on failure
 */
int hydra_set_flags(struct hydra_handle* h,
                    bool smooth, bool curvature,
                    bool extra_light, bool diag_slice,
                    bool ray_jitter);

/**
 * @brief Set voxel selection
 *
 * @param h Device handle
 * @param active Whether selection is active
 * @param x X coordinate (0-255)
 * @param y Y coordinate (0-255)
 * @param z Z coordinate (0-255)
 * @return 0 on success, negative errno on failure
 */
int hydra_set_selection(struct hydra_handle* h,
                        bool active, uint8_t x, uint8_t y, uint8_t z);

/**
 * @brief Apply complete state (camera, flags, selection)
 *
 * Convenience function to update all state at once.
 *
 * @param h Device handle
 * @param cam Camera state (can be NULL to skip)
 * @param flags Rendering flags (can be NULL to skip)
 * @param sel Selection state (can be NULL to skip)
 * @return 0 on success, negative errno on failure
 */
int hydra_apply_state(struct hydra_handle* h,
                      const struct hydra_camera_state* cam,
                      const struct hydra_flags_state* flags,
                      const struct hydra_selection_state* sel);

/**
 * @brief Perform soft reset of the device
 *
 * @param h Device handle
 * @return 0 on success, negative errno on failure
 */
int hydra_soft_reset(struct hydra_handle* h);

/**
 * @brief Start a new frame rendering
 *
 * @param h Device handle
 * @return 0 on success, negative errno on failure
 */
int hydra_start_frame(struct hydra_handle* h);
