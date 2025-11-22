/* SPDX-License-Identifier: BSD-3-Clause */
#pragma once

#include <linux/ioctl.h>
#include <linux/types.h>

#define HYDRA_IOCTL_MAGIC 'h'

struct hydra_reg_rw {
	__u32 offset;
	__u32 value;
};

#define HYDRA_IOCTL_INFO _IOR(HYDRA_IOCTL_MAGIC, 0x00, struct hydra_info)
#define HYDRA_IOCTL_RD32 _IOWR(HYDRA_IOCTL_MAGIC, 0x01, struct hydra_reg_rw)
#define HYDRA_IOCTL_WR32 _IOW (HYDRA_IOCTL_MAGIC, 0x02, struct hydra_reg_rw)
#define HYDRA_IOCTL_DMA  _IOW (HYDRA_IOCTL_MAGIC, 0x03, struct hydra_dma_req)

struct hydra_info {
	__u32 vendor;
	__u32 device;
	__s32 irq;
	__u64 bar0_start;
	__u64 bar0_len;
	__u64 bar1_start;
	__u64 bar1_len;
	__u64 irq_count;
};

/* Simple DMA request: copies len bytes from src to dst using device DMA (stub). */
struct hydra_dma_req {
	__u64 src;
	__u64 dst;
	__u32 len;
	__u32 flags; /* reserved */
};
