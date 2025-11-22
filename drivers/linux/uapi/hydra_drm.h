/* SPDX-License-Identifier: BSD-3-Clause */
#pragma once

#include <drm/drm.h>
#include <linux/types.h>

#define DRM_HYDRA_IOCTL_INFO 0x00
#define DRM_HYDRA_IOCTL_CSROUT 0x01
#define DRM_HYDRA_IOCTL_CSRIN  0x02

struct drm_hydra_info {
	__u32 vendor;
	__u32 device;
	__u64 bar0_start;
	__u64 bar0_len;
	__u64 bar1_start;
	__u64 bar1_len;
};

#define HYDRA_DRM_CSROUT_MAX 16
struct drm_hydra_csraut {
	__u32 offsets[HYDRA_DRM_CSROUT_MAX];
	__u32 values[HYDRA_DRM_CSROUT_MAX];
	__u32 count; /* in/out */
};

struct drm_hydra_csrin {
	__u32 offsets[HYDRA_DRM_CSROUT_MAX];
	__u32 values[HYDRA_DRM_CSROUT_MAX];
	__u32 count;
};

#define DRM_IOCTL_HYDRA_INFO DRM_IOWR(DRM_COMMAND_BASE + DRM_HYDRA_IOCTL_INFO, struct drm_hydra_info)
#define DRM_IOCTL_HYDRA_CSROUT DRM_IOWR(DRM_COMMAND_BASE + DRM_HYDRA_IOCTL_CSROUT, struct drm_hydra_csraut)
#define DRM_IOCTL_HYDRA_CSRIN DRM_IOWR(DRM_COMMAND_BASE + DRM_HYDRA_IOCTL_CSRIN, struct drm_hydra_csrin)
