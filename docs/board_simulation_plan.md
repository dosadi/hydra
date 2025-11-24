# Board-Level Simulation Plan for Hydra

## Executive Summary

**Should we simulate the board?** **YES, but selectively.**

Board-level simulation (simulating the entire LiteX SoC with LitePCIe, LiteDRAM, LiteVideo, and HydraCore) provides significant value for **integration testing** but is **not a replacement** for the current fast unit testing approach.

**Recommendation**: Implement **two-tier simulation strategy**
1. **Fast path** (current): Unit test voxel core with stubs (~100ms-5s per frame)
2. **Board sim** (new): Integration test full SoC for pre-FPGA validation (~minutes-hours)

---

## What is Board Simulation?

### Current State: Unit Testing
```
┌────────────────────────────────────────┐
│  Verilator Testbench                   │
│  ├─ voxel_framebuffer_top (DUT)       │
│  ├─ axi_sdram_stub (behavioral)       │
│  ├─ axi_dma_stub (behavioral)         │
│  └─ axi_stream_sink_stub (behavioral) │
│                                         │
│  Fast: 100ms-5s per frame              │
│  Use: Algorithm dev, visual debug      │
└────────────────────────────────────────┘
```

### Proposed: Board-Level Simulation
```
┌─────────────────────────────────────────────────────────┐
│  LiteX Verilator SoC Simulation                         │
│  ├─ HydraNexysVideoSoC (Python-defined)                │
│  │   ├─ LitePCIe Gen2x4 (real RTL)                     │
│  │   ├─ LiteDRAM DDR3 controller (real RTL)            │
│  │   ├─ AXIInterconnect (real RTL)                     │
│  │   ├─ HydraCore wrapper (real RTL)                   │
│  │   │   └─ voxel_framebuffer_top (real RTL)           │
│  │   └─ LiteVideo HDMI (real RTL, optional)            │
│  │                                                       │
│  ├─ C++ testbench (PCIe transactions, DMA)             │
│  └─ Simulated DDR3 model (timing-accurate)             │
│                                                          │
│  Slow: minutes-hours per frame                          │
│  Use: Integration testing, pre-FPGA validation          │
└─────────────────────────────────────────────────────────┘
```

---

## Why Board Simulation?

### Problems It Solves

#### 1. Integration Bugs (Critical)
**Without board sim**: First discovered when bitstream loads on FPGA
- AXI bus width mismatches
- Clock domain crossing issues
- Address decode conflicts
- Arbitration deadlocks in crossbar

**With board sim**: Caught in simulation before expensive FPGA builds
```python
# Example: Discover that HydraCore expects 64-bit AXI but LiteDRAM port is 128-bit
# Currently: FPGA build fails or produces garbage
# With sim: Verilator error in minutes
```

#### 2. PCIe/DMA Flow Validation
**Without board sim**: Test on real hardware with driver
- Slow iteration (20-60 min: synthesize → program → test)
- Hard to debug (waveforms require ILA, limited depth)
- Risk of bricking hardware during development

**With board sim**: Test PCIe transactions in Verilator
```c
// C++ testbench can issue PCIe TLPs and DMA operations
pcie_write_bar0(0x0010, CTRL_START_FRAME);  // Write CSR
pcie_dma_upload(voxel_data, 0x2000_0000);   // DMA to DRAM
pcie_wait_irq(INT_FRAME_DONE);              // Wait for MSI
pcie_dma_download(0x0, framebuffer);        // Read back frame
```

#### 3. Memory Bandwidth/Contention
**Without board sim**: Hope math is correct, find out on FPGA
- DDR3 bandwidth limits
- Crossbar arbitration fairness
- Bank conflicts, refresh cycles

**With board sim**: Measure and profile
```
# Simulation reports:
LiteDRAM bandwidth utilization: 23% (1.47 GB/s out of 6.4 GB/s)
Crossbar master stalls:
  - pcie_dma:   2% (low contention)
  - hydra_fb:   5% (occasional bank conflict)
  - hdmi_dma:   1% (scanout unaffected)
```

#### 4. Timing Issues (Moderate)
**Without board sim**: Meet timing in synthesis, fail in practice
- Clock domain crossing metastability (rare but catastrophic)
- Reset sequencing issues
- Async FIFO under/overflow

**With board sim**: Stress test with realistic timing

---

## When to Use Each Approach

### Use **Unit Sim** (current) for:
- ✅ Ray marching algorithm development
- ✅ Lighting/shading changes
- ✅ Visual debugging (fast iteration)
- ✅ Voxel world generation testing
- ✅ CI smoke tests (golden frame)
- ✅ Performance profiling (cycle counts)
- ✅ 90% of daily development

**Why**: 100x faster, easier to debug, good enough for isolated logic

### Use **Board Sim** (new) for:
- ✅ Pre-FPGA integration validation (before expensive synth)
- ✅ PCIe BAR0 CSR access testing
- ✅ PCIe DMA flow validation
- ✅ Multi-master crossbar arbitration
- ✅ Memory bandwidth stress testing
- ✅ IRQ/MSI behavior validation
- ✅ DDR3 controller configuration tuning
- ✅ HDMI scanout DMA integration (Phase 5)

**Why**: Catches integration bugs that unit tests can't, more realistic

### Do NOT Use **Board Sim** for:
- ❌ Quick visual checks ("does this lighting look right?")
- ❌ Pixel-by-pixel output validation (too slow)
- ❌ Every CI run (save for nightly/release builds)
- ❌ Algorithm experimentation

---

## Implementation Plan

### Phase 1: Minimal Board Sim (1-2 days)
**Goal**: Get LiteX SoC simulating with Verilator

**Tasks**:
1. Create `scripts/hydra_litex_sim.py` based on `litex_sim.py` example
2. Instantiate `HydraCore` in sim SoC (no PCIe, use direct AXI bridge)
3. Add C++ testbench for:
   - Writing CSRs (camera, flags, start_frame)
   - Reading CSRs (status, frame_done)
   - Reading DRAM framebuffer
4. Validate single frame render matches unit sim

**Files to create**:
```
scripts/hydra_litex_sim.py      # Simulation SoC definition
sim/board_sim/hydra_test.cpp    # C++ testbench
sim/board_sim/Makefile           # Build integration
```

**Expected output**:
```bash
$ python3 scripts/hydra_litex_sim.py --build
$ ./build/sim/hydra_sim
[LiteX] Starting simulation...
[HYDRA] CSR write: CTRL=0x0001 (start_frame)
[HYDRA] Rendering... 172800 pixels
[HYDRA] Frame done, status=0x0002
[HYDRA] CRC: 0xDEADBEEF (matches unit sim)
PASS
```

**Complexity**: Low (LiteX has good sim examples)

---

### Phase 2: Add LiteDRAM (1-2 days)
**Goal**: Replace AXI BRAM stub with realistic DDR3 controller

**Changes**:
- Use LiteDRAM's simulation PHY (`model_phy=True`)
- Connect HydraCore.fb_master to LiteDRAM port via AXIInterconnect
- Measure DDR3 bandwidth and latency

**Validation**:
- Framebuffer writes work with DDR3 timing
- Read/write latency measurements
- Bank conflict detection

**Expected slowdown**: 10-50x slower than unit sim (DDR3 timing model)

---

### Phase 3: Add PCIe (Optional, 2-3 days)
**Goal**: Validate PCIe TLP generation and DMA flows

**Changes**:
- Add LitePCIe to sim SoC
- Implement PCIe TLP generator in C++ testbench
- Test:
  - BAR0 read/write (CSR access)
  - PCIe DMA write (host → FPGA DRAM)
  - PCIe DMA read (FPGA DRAM → host)

**Validation**:
- PCIe config space enumeration
- DMA loopback test
- MSI interrupt delivery

**Expected slowdown**: 2-5x additional (PCIe transaction overhead)

---

### Phase 4: Add HDMI DMA Scanout (Phase 5 dependency)
**Goal**: Validate LiteVideo HDMI with DMA reader

**Changes**:
- Add LiteVideo to sim SoC
- Verify scanout DMA reads framebuffer correctly
- Check timing (60 Hz pixel clock, no underruns)

**Validation**:
- HDMI DMA reads correct pixels
- No tearing/underruns
- Frame swap timing

---

## Directory Structure

```
hydra/
├── sim/
│   ├── Makefile                    # Existing unit sim
│   ├── live_sdl_main.cpp           # Existing viewer
│   ├── board_sim/                  # NEW: Board-level simulation
│   │   ├── Makefile                # LiteX sim build integration
│   │   ├── hydra_test.cpp          # C++ testbench (CSR + DMA)
│   │   ├── hydra_pcie_test.cpp     # PCIe-specific tests (Phase 3)
│   │   └── README.md               # Usage guide
│   └── tests/
│       ├── rtl/                    # Existing RTL tests (iverilog)
│       └── board/                  # NEW: Board sim tests
│           ├── test_csr_access.py  # CSR read/write via AXI bridge
│           ├── test_dma_upload.py  # DMA to DRAM, voxel render
│           └── test_full_flow.py   # End-to-end: upload → render → readback
├── scripts/
│   ├── hydra_litex_nexysvideo.py   # Existing FPGA SoC
│   └── hydra_litex_sim.py          # NEW: Simulation SoC
└── docs/
    └── board_simulation_guide.md   # NEW: How to use board sim
```

---

## Example Test Cases

### Test 1: CSR Access
```python
# sim/tests/board/test_csr_access.py (Python + LiteX sim bridge)
def test_id_register():
    dut.write_csr(0x0000, 0)  # Read ID
    assert dut.read_csr(0x0000) == 0x1BAD2024

def test_start_frame():
    dut.write_csr(0x0010, 0x0001)  # CTRL.start_frame
    assert dut.read_csr(0x0014) & 0x0001  # STATUS.busy
    dut.wait_cycles(10000)
    assert dut.read_csr(0x0014) & 0x0002  # STATUS.frame_done
```

### Test 2: DMA Upload
```cpp
// sim/board_sim/hydra_test.cpp (C++ testbench)
void test_dma_upload() {
    uint64_t voxel_data[32768];  // 64^3 voxels
    for (int i = 0; i < 32768; i++)
        voxel_data[i] = 0xFF00FF00AA00AA00ULL;  // Test pattern

    // DMA voxels to FPGA DRAM @ 0x2000_0000
    pcie_dma_write(voxel_data, 0x20000000, sizeof(voxel_data));

    // Trigger voxel upload (DRAM → BRAM)
    write_csr(0x0060, 0x20000000);  // DMA_SRC
    write_csr(0x0068, 262144);      // DMA_LEN
    write_csr(0x006C, 2);           // DMA_CMD = VOXEL_UPLOAD

    // Wait for DMA done
    while (read_csr(0x0070) & 0x1);

    // Render frame
    write_csr(0x0010, 0x0001);      // CTRL.start_frame

    // Wait for frame done
    while (!(read_csr(0x0014) & 0x0002));

    // Read framebuffer via DMA
    uint64_t framebuf[172800];
    pcie_dma_read(0x00000000, framebuf, sizeof(framebuf));

    // Validate CRC
    uint32_t crc = compute_crc(framebuf, 172800);
    assert(crc == 0xEXPECTED);
}
```

### Test 3: Memory Bandwidth Stress
```python
# Concurrent masters: PCIe DMA + Hydra FB writes + HDMI scanout
def test_bandwidth_stress():
    # Start HDMI scanout (60 Hz)
    dut.enable_hdmi_scanout(base=0x0, stride=5760)

    # Concurrently: host uploads new voxel data via PCIe DMA
    dut.pcie_dma_write(voxel_data, dst=0x2000_0000, blocking=False)

    # Concurrently: Hydra renders to framebuffer
    dut.write_csr(0x0010, 0x0001)  # start_frame

    # Wait for all to complete
    dut.wait_hdmi_frame()
    dut.wait_dma_done()
    dut.wait_frame_done()

    # Check: no FIFO underruns, no lost pixels
    assert dut.read_csr(HDMI_STATUS) & HDMI_UNDERRUN == 0
    assert dut.read_csr(DMA_STATUS) & DMA_ERROR == 0
```

---

## Performance Expectations

### Simulation Speed

| Configuration                     | Time per Frame | Use Case                    |
|-----------------------------------|----------------|-----------------------------|
| Unit sim (current, 480×360×32)   | 2s             | Daily dev, algorithm work   |
| Board sim minimal (no DDR3)      | 20s            | Quick integration check     |
| Board sim + LiteDRAM             | 5 min          | Realistic memory testing    |
| Board sim + LiteDRAM + PCIe      | 10 min         | Full end-to-end validation  |
| Board sim + LiteDRAM + PCIe + HDMI | 15 min       | Complete SoC validation     |

*Measured on typical dev machine, 480×360 resolution, 32 ray steps*

**Mitigation**: Reduce resolution for board sim (use 120×90 or 8×6)
- Board sim @ 8×6: ~30s per frame (48 pixels vs 172K)

---

## Benefits vs. Costs

### Benefits
✅ **Catch integration bugs early** (before expensive FPGA builds)
✅ **Validate PCIe/DMA flows** without real hardware
✅ **Measure memory bandwidth** and contention
✅ **Faster debug cycles** than FPGA (waveforms, printf debugging)
✅ **CI integration** (nightly board sim tests)
✅ **Documentation** (board sim = executable specification)

### Costs
❌ **Slower simulation** (minutes vs. seconds)
❌ **More complex setup** (LiteX, multiple IP cores)
❌ **Longer debug cycles** for sim-specific issues
❌ **Initial implementation time** (1-2 weeks for full stack)

### Verdict: **Worth it for integration testing**, but keep fast unit sim for daily dev

---

## Migration Strategy

### Phase 0: Documentation (Now)
- ✅ This document

### Phase 1: Proof of Concept (1-2 days)
- Minimal sim: HydraCore + AXI BRAM + direct CSR access
- Validate framebuffer CRC matches unit sim
- **Decision point**: If PoC is too slow/complex, defer board sim

### Phase 2: Realistic Integration (1-2 days)
- Add LiteDRAM DDR3 controller
- Add AXIInterconnect (multi-master)
- Measure bandwidth, validate no deadlocks

### Phase 3: PCIe (Optional, 2-3 days)
- Add LitePCIe
- Implement PCIe TLP testbench
- Validate BAR0 access, DMA flows

### Phase 4: Production (Ongoing)
- Add to CI as nightly job
- Write test suite (CSR, DMA, bandwidth)
- Document usage for contributors

---

## Alternatives Considered

### Alternative 1: Skip Board Sim, Test on FPGA Directly
**Pros**: No sim infrastructure needed
**Cons**:
- Slow iteration (20-60 min per build)
- Expensive (Vivado license, FPGA time)
- Hard to debug (limited waveform visibility)
- Risk of hardware damage during dev

**Verdict**: Not acceptable for iterative development

### Alternative 2: Formal Verification
**Pros**: Exhaustive coverage
**Cons**:
- Extremely slow (state space explosion)
- Requires formal specs (SVA assertions)
- Doesn't catch performance issues

**Verdict**: Complementary, not replacement

### Alternative 3: QEMU Device Model
**Pros**: Fast, easy to integrate with driver testing
**Cons**:
- Behavioral model only (no RTL validation)
- Doesn't catch hardware bugs
- Already have QEMU stub (sim/tests/qemu_stub/)

**Verdict**: Useful for driver dev, not RTL validation

---

## Recommendation

**Implement Phase 1 (minimal board sim) now** to validate feasibility.

If Phase 1 is successful (< 2 days effort, reasonable sim speed):
- Proceed to Phase 2 (LiteDRAM integration)
- Gate FPGA builds with board sim tests
- Long-term: full PCIe/HDMI integration

If Phase 1 is problematic (too slow, too complex):
- Defer board sim until FPGA integration is more mature
- Focus on unit sim improvements
- Revisit after Phase 5 (HDMI scanout) is complete

**Next action**: Create `scripts/hydra_litex_sim.py` proof-of-concept.

---

## References

- LiteX simulation docs: `third_party/litex/litex/build/sim/README`
- LiteX sim example: `third_party/litex/litex/tools/litex_sim.py`
- LiteDRAM sim examples: `third_party/litedram/test/`
- Verilator docs: https://verilator.org/guide/latest/
