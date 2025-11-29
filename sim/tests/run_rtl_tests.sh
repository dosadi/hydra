#!/usr/bin/env bash
set -euo pipefail

# Run RTL unit tests for the Hydra AXI shell: DMA loopback + HDMI CRC golden.
# Uses Icarus Verilog (iverilog/vvp). Set IVERILOG to override the binary.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

IVERILOG_BIN="${IVERILOG:-iverilog}"
VVP_BIN="${VVP:-vvp}"
VERILATOR_BIN="${VERILATOR:-verilator}"

# Optional SDRAM wait-state injection for the stub. Defaults to zero for speed.
SDRAM_LATENCY="${SDRAM_LATENCY:-0}"
SDRAM_JITTER="${SDRAM_JITTER:-0}"
APPLY_LATENCY_DMA="${APPLY_LATENCY_DMA:-0}" # default: keep DMA benches fast/deterministic

SDRAM_LATENCY_ARGS_HDMI=(
  -P axi_sdram_stub.READ_LATENCY="$SDRAM_LATENCY"
  -P axi_sdram_stub.WRITE_LATENCY="$SDRAM_LATENCY"
  -P axi_sdram_stub.WAIT_JITTER="$SDRAM_JITTER"
)

if [ "$APPLY_LATENCY_DMA" = "1" ]; then
  SDRAM_LATENCY_ARGS_DMA=("${SDRAM_LATENCY_ARGS_HDMI[@]}")
else
  SDRAM_LATENCY_ARGS_DMA=()
fi

# Common RTL sources (sim harness + stubs + voxel core path)
RTL_SOURCES=(
  rtl/axi_sdram_stub.sv
  rtl/axi_dma_stub.sv
  rtl/axi_stream_sink_stub.sv
  rtl/voxel_memory_64.sv
  rtl/voxel_world_gen.sv
  rtl/voxel_raycaster_core_pipelined.sv
  rtl/voxel_framebuffer_top.sv
  rtl/voxel_axil_csr.sv
  rtl/voxel_sim_harness.sv
)

mkdir -p sim/tests/rtl

echo "[rtl-tests] Running DMA loopback bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_dma_loopback.vvp \
  sim/tests/rtl/test_dma_loopback.sv "${SDRAM_LATENCY_ARGS_DMA[@]}" "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_dma_loopback.vvp

echo "[rtl-tests] Running HDMI CRC golden bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_hdmi_crc_golden.vvp \
  sim/tests/rtl/test_hdmi_crc_golden.sv "${SDRAM_LATENCY_ARGS_HDMI[@]}" "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_hdmi_crc_golden.vvp

echo "[rtl-tests] Running HDMI CRC full bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_hdmi_crc_full.vvp \
  sim/tests/rtl/test_hdmi_crc_full.sv "${SDRAM_LATENCY_ARGS_HDMI[@]}" "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_hdmi_crc_full.vvp

echo "[rtl-tests] Running HDMI CRC high-res bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_hdmi_crc_hr.vvp \
  sim/tests/rtl/test_hdmi_crc_hr.sv "${SDRAM_LATENCY_ARGS_HDMI[@]}" "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_hdmi_crc_hr.vvp

echo "[rtl-tests] Running BAR1 + DMA loopback bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_bar1_dma_loopback.vvp \
  sim/tests/rtl/test_bar1_dma_loopback.sv "${SDRAM_LATENCY_ARGS_DMA[@]}" "${RTL_SOURCES[@]}"
${VVP_BIN} sim/tests/rtl/test_bar1_dma_loopback.vvp

echo "[rtl-tests] Running DMA stub direct test..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_dma_stub_direct.vvp \
  sim/tests/rtl/test_dma_stub_direct.sv "${SDRAM_LATENCY_ARGS_DMA[@]}" rtl/axi_dma_stub.sv rtl/axi_sdram_stub.sv
${VVP_BIN} sim/tests/rtl/test_dma_stub_direct.vvp

echo "[rtl-tests] Running AXI-Lite CSR smoke bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_voxel_axil_csr_simple.vvp \
  sim/tests/rtl/test_voxel_axil_csr_simple.sv rtl/voxel_axil_csr.sv
${VVP_BIN} sim/tests/rtl/test_voxel_axil_csr_simple.vvp

echo "[rtl-tests] Running SDRAM stub SLVERR coverage bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_axi_sdram_error.vvp \
  sim/tests/rtl/test_axi_sdram_error.sv rtl/axi_sdram_stub.sv
${VVP_BIN} sim/tests/rtl/test_axi_sdram_error.vvp

echo "[rtl-tests] Running SDRAM stub poison coverage bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_axi_sdram_poison.vvp \
  sim/tests/rtl/test_axi_sdram_poison.sv rtl/axi_sdram_stub.sv
${VVP_BIN} sim/tests/rtl/test_axi_sdram_poison.vvp

echo "[rtl-tests] Running SDRAM stub burst coverage bench..."
${IVERILOG_BIN} -g2012 -Wall -Irtl -DIVERILOG -o sim/tests/rtl/test_axi_sdram_burst.vvp \
  sim/tests/rtl/test_axi_sdram_burst.sv sim/tests/axi_sdram_stub.sv
${VVP_BIN} sim/tests/rtl/test_axi_sdram_burst.vvp

echo "[rtl-tests] All RTL benches passed."
