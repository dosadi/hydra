#!/usr/bin/env bash
set -euo pipefail

# Run RTL unit tests for the Hydra AXI shell: DMA loopback + HDMI CRC golden.
# Uses Icarus Verilog (iverilog/vvp). Set IVERILOG to override the binary.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

IVERILOG_BIN="${IVERILOG:-iverilog}"
VVP_BIN="${VVP:-vvp}"

# Common RTL sources (shell + stubs + voxel core path)
RTL_SOURCES=(
  rtl/axi_crossbar_stub.sv
  rtl/axi_sdram_stub.sv
  rtl/axi_dma_stub.sv
  rtl/axi_stream_sink_stub.sv
  rtl/voxel_memory_64.sv
  rtl/voxel_world_gen.sv
  rtl/voxel_raycaster_core_pipelined.sv
  rtl/voxel_framebuffer_top.sv
  rtl/voxel_axil_csr.sv
  rtl/voxel_axil_shell.sv
)

mkdir -p sim/tests/rtl

echo "[rtl-tests] Running DMA loopback bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -o sim/tests/rtl/test_dma_loopback.vvp \
  sim/tests/rtl/test_dma_loopback.sv "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_dma_loopback.vvp

echo "[rtl-tests] Running HDMI CRC golden bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -o sim/tests/rtl/test_hdmi_crc_golden.vvp \
  sim/tests/rtl/test_hdmi_crc_golden.sv "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_hdmi_crc_golden.vvp

echo "[rtl-tests] Running BAR1 + DMA loopback bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -o sim/tests/rtl/test_bar1_dma_loopback.vvp \
  sim/tests/rtl/test_bar1_dma_loopback.sv "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_bar1_dma_loopback.vvp

echo "[rtl-tests] All RTL benches passed."
