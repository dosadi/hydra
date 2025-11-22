/* SPDX-License-Identifier: BSD-3-Clause */
#pragma once

#include <linux/ioctl.h>
#include <linux/types.h>

#define HYDRA_IOCTL_MAGIC 'h'

struct hydra_reg_rw {
	__u32 offset;
	__u32 value;
};

#define HYDRA_IOCTL_RD32 _IOWR(HYDRA_IOCTL_MAGIC, 0x01, struct hydra_reg_rw)
#define HYDRA_IOCTL_WR32 _IOW (HYDRA_IOCTL_MAGIC, 0x02, struct hydra_reg_rw)
