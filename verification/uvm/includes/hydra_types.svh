`ifndef HYDRA_TYPES_SVH
`define HYDRA_TYPES_SVH

// Hydra-specific type definitions for UVM verification

// AXI-Lite transaction types
typedef enum {
  AXIL_READ,
  AXIL_WRITE
} axil_trans_type_e;

typedef enum {
  AXI_READ,
  AXI_WRITE
} axi_trans_type_e;

// Hydra operation types
typedef enum {
  HYDRA_OP_NONE,
  HYDRA_OP_FRAME_RENDER,
  HYDRA_OP_DMA_TRANSFER,
  HYDRA_OP_BLIT_OPERATION,
  HYDRA_OP_SURFACE_EXTRACT
} hydra_op_type_e;

// Interrupt types
typedef enum {
  INT_FRAME_DONE,
  INT_DMA_DONE,
  INT_BLIT_DONE,
  INT_REGION0_DONE
} hydra_int_type_e;

// DMA transfer types
typedef enum {
  DMA_HOST_TO_FPGA,
  DMA_FPGA_TO_HOST,
  DMA_FPGA_INTERNAL
} dma_direction_e;

// Blitter operation types
typedef enum {
  BLIT_MEMCPY,
  BLIT_DRAW_OBJECT,
  BLIT_MOVE_OBJECT,
  BLIT_SURFACE_EXTRACT
} blit_op_type_e;

// Configuration structures
typedef struct {
  bit [31:0] base_addr;
  bit [31:0] size;
  bit        enabled;
} bar_config_t;

typedef struct {
  bit [31:0] width;
  bit [31:0] height;
  bit [7:0]  bpp;
  bit [31:0] stride;
} surface_config_t;

typedef struct {
  bit [15:0] x, y;
  bit [15:0] width, height;
  bit [31:0] color;
} object_config_t;

// Error types
typedef enum {
  ERR_NONE,
  ERR_TIMEOUT,
  ERR_DATA_MISMATCH,
  ERR_PROTOCOL_VIOLATION,
  ERR_INVALID_CONFIG
} hydra_error_e;

// Coverage bins
typedef enum {
  COV_LOW,
  COV_MEDIUM,
  COV_HIGH
} coverage_level_e;

`endif

`endif
