TOPLEVEL_LANG = verilog
TOPLEVEL = voxel_axil_shell
MODULE = test_hydra_smoke

export RTL_DIR=$(abspath ../../../rtl)
export SIM_BUILD ?= $(abspath ./sim_build)
export IVERILOG_ARGS += -I$(RTL_DIR)
VERILOG_SOURCES = $(RTL_DIR)/voxel_axil_shell.sv \
                  $(RTL_DIR)/voxel_axil_csr.sv \
                  $(RTL_DIR)/voxel_framebuffer_top.sv \
                  $(RTL_DIR)/axi_dma_stub.sv \
                  $(RTL_DIR)/axi_sdram_stub.sv \
                  $(RTL_DIR)/axi_crossbar_stub.sv \
                  $(RTL_DIR)/axi_stream_sink_stub.sv \
                  $(RTL_DIR)/voxel_memory_64.sv \
                  $(RTL_DIR)/voxel_world_gen.sv \
                  $(RTL_DIR)/voxel_raycaster_core_pipelined.sv

SIM ?= icarus

include $(shell cocotb-config --makefiles)/Makefile.sim
