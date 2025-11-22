/* SPDX-License-Identifier: BSD-3-Clause */
#pragma once

#include <drm/drm.h>
#include <linux/types.h>

#define DRM_HYDRA_IOCTL_INFO 0x00

struct drm_hydra_info {
	__u32 vendor;
	__u32 device;
	__u64 bar0_start;
	__u64 bar0_len;
	__u64 bar1_start;
	__u64 bar1_len;
};

#define DRM_IOCTL_HYDRA_INFO DRM_IOWR(DRM_COMMAND_BASE + DRM_HYDRA_IOCTL_INFO, struct drm_hydra_info)
