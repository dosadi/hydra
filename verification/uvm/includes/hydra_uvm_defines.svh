`ifndef HYDRA_UVM_DEFINES_SVH
`define HYDRA_UVM_DEFINES_SVH

// UVM Configuration and Reporting
`define HYDRA_UVM_REPORT_INFO(MSG, VERBOSITY=UVM_MEDIUM) \
  `uvm_info("HYDRA_UVM", MSG, VERBOSITY)

`define HYDRA_UVM_REPORT_ERROR(MSG) \
  `uvm_error("HYDRA_UVM", MSG)

`define HYDRA_UVM_REPORT_FATAL(MSG) \
  `uvm_fatal("HYDRA_UVM", MSG)

// Hydra-specific UVM settings
`define HYDRA_CLK_PERIOD 10ns
`define HYDRA_RESET_CYCLES 5

// Memory and register definitions
`define HYDRA_BAR0_BASE 'h0000_0000
`define HYDRA_BAR1_BASE 'h1000_0000

// CSR Register offsets (matching hydra_regs.h)
`define CTRL_OFFSET        'h0010
`define INT_MASK_OFFSET    'h0084
`define DMA_SRC_OFFSET     'h0060
`define DMA_DST_OFFSET     'h0064
`define DMA_LEN_OFFSET     'h0068
`define DMA_CMD_OFFSET     'h006C
`define INT_STATUS_OFFSET  'h0080
`define IRQ_TEST_OFFSET    'h0088
`define HDMI_CRC_OFFSET    'h00B0

// Blitter registers
`define BLIT_CTRL_OFFSET        'h0100
`define BLIT_STATUS_OFFSET      'h0104
`define BLIT_SRC_OFFSET         'h0108
`define BLIT_DST_OFFSET         'h010C
`define BLIT_LEN_OFFSET         'h0110
`define BLIT_STRIDE_OFFSET      'h0114
`define SURF_BASE_OFFSET        'h0118
`define SURF_LEN_OFFSET         'h011C
`define BLIT_PIX_ADDR_OFFSET    'h0120
`define BLIT_PIX_DATA_OFFSET    'h0124
`define BLIT_PIX_CMD_OFFSET     'h0128
`define BLIT_OBJ_IDX_OFFSET     'h0130
`define BLIT_OBJ_ATTR_OFFSET    'h0134
`define SURF_STATS_OFFSET       'h0138
`define BLIT_FIFO_DATA_OFFSET   'h0140
`define BLIT_FIFO_STATUS_OFFSET 'h0144

// Region 0 extractor
`define REGION0_CFG_OFFSET        'h0150
`define REGION0_MIN_OFFSET        'h0154
`define REGION0_MAX_OFFSET        'h0158
`define REGION0_STATUS_OFFSET     'h015C
`define REGION0_SURF_STATS_OFFSET 'h0160

// Interrupt bits
`define INT_FRAME_DONE 0
`define INT_DMA_DONE   1
`define INT_BLIT_DONE  2
`define INT_REGION0_DONE 3

// DMA commands
`define DMA_CMD_START 'h1

// Blitter operations
`define BLIT_OP_MEMCPY       0
`define BLIT_OP_DRAW_OBJECT  1
`define BLIT_OP_MOVE_OBJECT  2
`define BLIT_OP_SURFACE_EXTRACT 3

`endif