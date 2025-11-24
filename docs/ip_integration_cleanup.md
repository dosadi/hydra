# IP Integration Cleanup (Post-0.0.5)

## Overview

This document describes the architectural cleanup performed to separate simulation and FPGA integration concerns, remove excessive shell layering, and prepare for proper LiteX IP integration.

## Problem Statement

The original `voxel_axil_shell.sv` tried to serve two incompatible purposes:
1. **Simulation testbench** with internal AXI stubs (SDRAM, DMA, HDMI sink)
2. **FPGA integration shell** exposing external AXI ports for LitePCIe/LiteDRAM

This dual-personality approach resulted in:
- Hardcoded BAR0/BAR1 address decoding in RTL (should be PCIe endpoint's job)
- Manual crossbar muxing instead of using LiteX interconnect fabric
- Stubs always instantiated (wasting FPGA resources)
- Ambiguous DMA architecture (internal vs. host DMA)
- Confusing Python wrapper hierarchy (`HydraVoxelShell` → `HydraBoardShell` → board-specific)

## Solution: Split Sim and FPGA Paths

### New RTL Modules

#### `rtl/voxel_sim_harness.sv` (Simulation Only)
- **Purpose**: Complete testbench for Verilator/iverilog/cocotb
- **Contents**:
  - Instantiates `voxel_framebuffer_top` + `voxel_axil_csr`
  - Includes all stubs: `axi_sdram_stub`, `axi_dma_stub`, `axi_stream_sink_stub`
  - Internal crossbar and BAR address decoding (sim convenience)
- **Usage**: RTL tests (`sim/tests/rtl/*.sv`), cocotb tests
- **Not for FPGA synthesis** (safety check via `ifdef` in header)

#### `rtl/voxel_axi_core.sv` (FPGA Integration)
- **Purpose**: Clean wrapper for LiteX/LitePCIe/LiteDRAM integration
- **Interfaces**:
  - **AXI-Lite slave** (`s_axil_*`) ← connects to PCIe BAR0
  - **AXI4 master** (`m_axi_*`) → framebuffer writes to DRAM
  - **AXI-Stream master** (`m_axis_*`) → video output to HDMI encoder
- **No stubs, no address decoding, no crossbars** (all handled by LiteX)
- **Placeholder TODOs** for DMA/blitter/HDMI counters (to be wired to real IP)

### Updated LiteX Integration

#### `scripts/hydra_litex_shell.py`
- **Class**: `HydraCore` (renamed from `HydraVoxelShell`, `HydraBoardShell` removed)
- **RTL instance**: Uses `voxel_axi_core` (not `voxel_axil_shell`)
- **Attributes**:
  - `self.csr_bus` (AXI-Lite slave for BAR0)
  - `self.fb_master` (AXI4 master for framebuffer writes)
  - `self.video` (AXI-Stream master for HDMI)
- **Integration**:
  - Board SoCs connect `csr_bus` to LitePCIe BAR0
  - Board SoCs connect `fb_master` to LiteX AXIInterconnect → LiteDRAM
  - Board SoCs connect `video` to LiteVideo HDMI encoder

## Architectural Improvements

### 1. Sim vs. FPGA Separation ✓
- **Before**: One module tries to be both
- **After**: `voxel_sim_harness` (sim) vs. `voxel_axi_core` (FPGA)
- **Benefit**: No wasted FPGA resources on stubs, clearer intent

### 2. BAR Address Decoding ✓
- **Before**: RTL hardcodes `BAR1_BASE = 0x100_0000` and address translation
- **After**: LitePCIe handles BAR mapping, RTL just sees clean AXI ports
- **Benefit**: Flexible BAR sizing, follows PCIe conventions

### 3. Crossbar Logic (Partially Complete)
- **Before**: Manual muxing in `voxel_axil_shell` (DMA vs. host, voxel window decode)
- **After**: `voxel_axi_core` has single master port, LiteX `AXIInterconnect` arbitrates
- **Next Steps**: Wire up LiteX crossbar in `hydra_litex_nexysvideo.py` (see Phase 3)

### 4. Python Wrapper Hierarchy ✓
- **Before**: `HydraVoxelShell` → `HydraBoardShell` (no-op) → board SoC
- **After**: `HydraCore` → board SoC directly
- **Benefit**: One less abstraction layer, clearer naming

### 5. DMA Architecture (Documented, Not Yet Implemented)
See Phase 4 below for dual-DMA model:
- **DMA1**: Host ↔ FPGA (LitePCIe DMA engine)
- **DMA2**: FPGA-internal (LiteDMA for DRAM↔BRAM moves)

### 6. HDMI Data Path (Documented, Not Yet Implemented)
See Phase 5 below for scanout-from-DRAM model.

## Migration Guide

### For Simulation Tests
- **Old**: `voxel_axil_shell #(...) dut (...);`
- **New**: `voxel_sim_harness #(...) dut (...);`
- **Note**: Interface is identical (backwards compatible)

### For FPGA Integration (LiteX)
- **Old**:
  ```python
  from scripts.hydra_litex_shell import HydraBoardShell
  voxel = HydraBoardShell()
  # Connect voxel.axil, voxel.axi (external port), voxel.hdmi (sink)
  ```
- **New**:
  ```python
  from scripts.hydra_litex_shell import HydraCore
  voxel = HydraCore()
  # Connect voxel.csr_bus (slave), voxel.fb_master (master), voxel.video (master)
  pcie.bar0.add_slave("csr", voxel.csr_bus)
  axi_xbar.add_master("voxel_fb", voxel.fb_master)
  hdmi_encoder.connect_source(voxel.video)
  ```

### For Verilator Sim (No Change)
- `sim/Makefile` still uses `voxel_framebuffer_top` directly
- Interactive viewer (`live_sdl_main.cpp`) unchanged
- Can optionally switch to `voxel_sim_harness` for more realistic testing

## Remaining Work (Phases 3-5)

### Phase 3: LiteX Crossbar Integration
**Goal**: Replace manual crossbar logic with LiteX `AXIInterconnect`

**Tasks**:
1. Create `scripts/hydra_litex_nexysvideo.py` (board-specific SoC)
2. Wire `HydraCore.fb_master` to `AXIInterconnect`
3. Add masters: LitePCIe DMA, HDMI scanout DMA
4. Add slave: LiteDRAM port
5. Test with FPGA build and driver smoke test

**Files to Update**:
- `scripts/hydra_litex_nexysvideo.py` (new file)
- `docs/ip_integration.md` (update with crossbar diagram)

### Phase 4: Clarify DMA Architecture
**Goal**: Document and implement dual-DMA model

**DMA1: LitePCIe DMA (Host ↔ FPGA)**
- Purpose: Host uploads voxel data, host reads framebuffer
- Controlled via: LitePCIe CSRs (not BAR0 0x0060!)
- Driver API: `litepcie_dma_*()` functions

**DMA2: LiteDMA (FPGA Internal)**
- Purpose: DRAM ↔ BRAM voxel uploads, DRAM ↔ DRAM blits
- Controlled via: BAR0 0x0060-0x007F (hydra_spec.md)
- Driver API: `ioctl(HYDRA_DMA_START)`

**Tasks**:
1. Replace `axi_dma_stub` with LiteDMA instance (or similar LiteX DMA helper)
2. Connect to `AXIInterconnect` as separate master
3. Update `docs/hydra_spec.md` to clarify DMA register semantics
4. Update driver UAPI comments

**Files to Update**:
- `scripts/hydra_litex_nexysvideo.py` (add LiteDMA)
- `docs/hydra_spec.md` (DMA register clarification)
- `drivers/linux/uapi/hydra_regs.h` (comments)
- `docs/driver_integration.md` (DMA usage examples)

### Phase 5: HDMI Scanout from DRAM
**Goal**: Remove direct pixel streaming, implement DRAM-based scanout

**Current (Broken for Real Hardware)**:
- Voxel core streams pixels directly to HDMI encoder
- Works in sim (no timing constraints)
- Fails on FPGA (ray marching can't sustain 60fps pixel rate)

**New Design**:
1. Voxel core writes pixels to DRAM via AXI4 master (already exposed)
2. LiteVideo HDMI driver reads from DRAM at line rate
3. Frame buffer uses double-buffering (ping-pong)

**Tasks**:
1. Remove `m_axis_*` ports from `voxel_axi_core` (or make them optional)
2. Implement AXI4 burst writer in `voxel_axi_core` (currently stubbed)
3. Add LiteVideo with DMA reader in `hydra_litex_nexysvideo.py`
4. Update framebuffer CSRs in BAR0 (base address, stride)

**Files to Update**:
- `rtl/voxel_axi_core.sv` (implement AXI4 burst writer)
- `scripts/hydra_litex_nexysvideo.py` (add LiteVideo + DMA reader)
- `docs/hydra_spec.md` (framebuffer CSRs)
- `docs/ip_integration.md` (scanout architecture diagram)

## Testing Strategy

### Regression Tests (Must Pass)
1. `make -C sim test_frame` (Verilator golden frame)
2. `sim/tests/run_rtl_tests.sh` (iverilog DMA/HDMI benches)
3. `make -C sim/tests/cocotb_hydra SIM=icarus` (cocotb smoke)

### Integration Tests (Manual)
1. FPGA synthesis (Vivado targeting Nexys Video)
2. Linux driver load + BAR0 CSR read
3. DMA loopback test (host → DRAM → host)
4. HDMI output verification (monitor shows rendered frame)

## Known Limitations

### Still Using Stubs (Sim Only)
- `axi_sdram_stub`, `axi_dma_stub`, `axi_stream_sink_stub` remain in `voxel_sim_harness`
- This is **intentional** (sim needs self-contained testbench)
- FPGA never sees these (separate module)

### AXI4 Burst Writer Not Implemented
- `voxel_axi_core.sv` lines 100-150: placeholder stub
- Voxel core pixel stream currently unused in FPGA path
- Phase 5 will implement proper burst writer

### LiteX Nexys Video SoC Not Yet Written
- `scripts/hydra_litex_nexysvideo.py` referenced but doesn't exist
- Phase 3 will create this file
- Will integrate LitePCIe + LiteDRAM + HydraCore + LiteVideo

## Deprecation Plan

### Modules to Keep
- `voxel_framebuffer_top.sv` (core engine, unchanged)
- `voxel_axil_csr.sv` (CSR block, unchanged)
- `voxel_sim_harness.sv` (new sim-only testbench)
- `voxel_axi_core.sv` (new FPGA integration)

### Modules to Deprecate (After CI Updates)
- `voxel_axil_shell.sv` ← replaced by split sim/FPGA modules
  - **When**: After updating any external references in docs
  - **Action**: Move to `rtl/deprecated/` or delete after confirming no breakage

### Python Classes Removed
- `HydraBoardShell` ← no-op wrapper, removed
- `HydraVoxelShell` ← renamed to `HydraCore`

## Summary

**Phase 1 Complete**:
- ✅ Separated sim (`voxel_sim_harness`) and FPGA (`voxel_axi_core`) shells
- ✅ Removed BAR address decoding from FPGA RTL
- ✅ Updated LiteX Python wrapper (`HydraCore`)
- ✅ Updated all RTL tests and cocotb to use new harness
- ✅ Collapsed redundant Python wrapper hierarchy

**Next Steps** (Phases 3-5):
- Document LiteX crossbar integration strategy
- Clarify dual-DMA architecture in specs
- Document HDMI scanout-from-DRAM plan
- Implement missing burst writer and LiteVideo integration
- Create `hydra_litex_nexysvideo.py` board SoC

**Impact**:
- FPGA resource usage will decrease (no more stub BRAMs)
- Code is easier to understand (clear sim vs. FPGA separation)
- Future IP integration is straightforward (standard LiteX patterns)
- Driver development is unblocked (can now wire real DMA engines)
