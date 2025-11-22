/* SPDX-License-Identifier: BSD-3-Clause */
#pragma once

/*
 * Hydra BAR0 register sketch (must align with RTL when implemented).
 * Offsets are byte offsets from BAR0 base.
 */

#define HYDRA_BAR0_SIZE         0x00010000

#define HYDRA_REG_ID            0x0000  /* [31:16]=vendor, [15:0]=device */
#define HYDRA_REG_REV           0x0004  /* [7:0]=rev, [15:8]=build */
#define HYDRA_REG_CTRL          0x0010
#define  HYDRA_CTRL_SOFT_RESET  BIT(0)
#define  HYDRA_CTRL_START_FRAME BIT(1)
#define  HYDRA_CTRL_DIAG_SLICE  BIT(2)
#define  HYDRA_CTRL_EXTRA_LIGHT BIT(3)
#define HYDRA_REG_STATUS        0x0014
#define  HYDRA_STATUS_BUSY      BIT(0)
#define  HYDRA_STATUS_FRAME_DONE BIT(1)
#define  HYDRA_STATUS_DMA_BUSY  BIT(2)
#define  HYDRA_STATUS_DMA_DONE  BIT(3)
#define  HYDRA_STATUS_BLIT_BUSY BIT(4)
#define  HYDRA_STATUS_BLIT_DONE BIT(5)

#define HYDRA_REG_CAM_X         0x0020
#define HYDRA_REG_CAM_Y         0x0024
#define HYDRA_REG_CAM_Z         0x0028
#define HYDRA_REG_CAM_DIR_X     0x002C
#define HYDRA_REG_CAM_DIR_Y     0x0030
#define HYDRA_REG_CAM_DIR_Z     0x0034
#define HYDRA_REG_CAM_PLANE_X   0x0038
#define HYDRA_REG_CAM_PLANE_Y   0x003C

#define HYDRA_REG_FLAGS         0x0040  /* [0]=smooth, [1]=curv, [2]=extra_light, [3]=diag_slice */

#define HYDRA_REG_SEL_ACTIVE    0x0044
#define HYDRA_REG_SEL_X         0x0048
#define HYDRA_REG_SEL_Y         0x004C
#define HYDRA_REG_SEL_Z         0x0050

#define HYDRA_REG_FB_BASE       0x0054
#define HYDRA_REG_FB_STRIDE     0x0058

#define HYDRA_REG_DMA_SRC       0x0060
#define HYDRA_REG_DMA_DST       0x0064
#define HYDRA_REG_DMA_LEN       0x0068
#define HYDRA_REG_DMA_CMD       0x006C  /* [0]=start */
#define HYDRA_REG_DMA_STATUS    0x0070  /* [0]=done, [1]=busy, [2]=err */

#define HYDRA_REG_INT_STATUS    0x0080  /* RW1C */
#define HYDRA_REG_INT_MASK      0x0084
#define  HYDRA_INT_FRAME_DONE   BIT(0)
#define  HYDRA_INT_DMA_DONE     BIT(1)
#define  HYDRA_INT_DMA_ERR      BIT(2)
#define  HYDRA_INT_TEST         BIT(3)
#define  HYDRA_INT_BLIT_DONE    BIT(4)

#define HYDRA_REG_DBG_ADDR      0x00A0
#define HYDRA_REG_DBG_DATA_LO   0x00A4
#define HYDRA_REG_DBG_DATA_HI   0x00A8
#define HYDRA_REG_DBG_CTRL      0x00AC  /* [0]=write_pulse */

/* 3D blitter stub (0x0100 region) */
#define HYDRA_REG_BLIT_CTRL       0x0100  /* [0]=start, [1]=dir(readback), [2]=use_fifo */
#define HYDRA_REG_BLIT_STATUS     0x0104  /* [0]=busy, [1]=done, [2]=fifo_empty, [3]=fifo_full */
#define HYDRA_REG_BLIT_SRC        0x0108  /* src address */
#define HYDRA_REG_BLIT_DST        0x010C  /* dst address */
#define HYDRA_REG_BLIT_LEN        0x0110  /* bytes */
#define HYDRA_REG_BLIT_STRIDE     0x0114  /* bytes per line */
#define HYDRA_REG_BLIT_PIX_ADDR   0x0120  /* pixel index */
#define HYDRA_REG_BLIT_PIX_DATA   0x0124  /* pixel payload */
#define HYDRA_REG_BLIT_PIX_CMD    0x0128  /* [0]=write, [1]=read */
#define HYDRA_REG_BLIT_OBJ_IDX    0x0130  /* object index */
#define HYDRA_REG_BLIT_OBJ_ATTR   0x0134  /* object attribute rw */
#define HYDRA_REG_BLIT_FIFO_DATA  0x0140  /* push/pop data */
#define HYDRA_REG_BLIT_FIFO_STATUS 0x0144 /* depth/flags */
