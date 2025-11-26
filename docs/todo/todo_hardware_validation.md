# Hardware Validation & FPGA Bring-Up TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Hardware Validation Team
**Related Trackers:** `todo_board_fpga.md`, `todo_ip_integration.md`, `todo_testing_ci.md`

---

## Overview

Tracks pre-silicon validation, FPGA bring-up, hardware testing, and physical deployment tasks. Focus areas: simulation validation before FPGA, board selection, synthesis flows, bring-up scripts, hardware regression tests.

**Priority Distribution:**
- **P0:** 10 items (~15 days) - Critical pre-silicon validation
- **P1:** 15 items (~25 days) - FPGA bring-up essentials
- **P2:** 14 items (~20 days) - Extended hardware testing
- **P3:** 7 items (~10 days) - Future hardware platforms

**Total:** 46 items, ~70 engineer-days

---

## P0 - Critical Pre-Silicon Validation (Blocks Hardware)

### Simulation Validation (Gate for FPGA)
- **TODO [P0]:** Run 1000-frame regression in sim with varied seeds to catch corner cases
  - **Effort:** 2 days
  - **Priority:** P0 - Pre-silicon gate
  - **Dependencies:** World seed override working
  - **Validation:** All 1000 frames complete, no hangs, no X propagation
  - **Deliverable:** `scripts/run_1000_frame_regression.sh`
  - **Notes:** Catches rare FSM states before FPGA burn

- **TODO [P0]:** Validate all CSR read/write paths with RTL testbench (BAR0 0x00-0xFF)
  - **Effort:** 2 days
  - **Priority:** P0 - Driver compatibility
  - **Dependencies:** test_voxel_axil_csr_simple.sv complete
  - **Validation:** All CSRs readable/writable with correct reset defaults
  - **Deliverable:** Passing RTL CSR testbench
  - **Notes:** Include read-only and write-ignore behavior

- **TODO [P0]:** Add SVAs for AXI-Lite protocol violations (valid/ready stability, address decode)
  - **Effort:** 3 days
  - **Priority:** P0 - IP integration safety
  - **Dependencies:** voxel_axil_csr.sv finalized
  - **Validation:** SVAs catch known violations in testbench
  - **Deliverable:** SVAs in voxel_axil_csr.sv, sim assertions pass
  - **Status:** Partially done - extend coverage

- **TODO [P0]:** Validate AXI-Stream backpressure under sustained tready=0 stress
  - **Effort:** 2 days
  - **Priority:** P0 - Pixel stream robustness
  - **Dependencies:** Backpressure handling in voxel_axi_core.sv
  - **Validation:** No pixel loss, no deadlock over 100 frames
  - **Deliverable:** RTL testbench with backpressure injection
  - **Notes:** Test skid buffer overflow path

- **TODO [P0]:** Add reset sequence validation (power-on, soft_reset, mid-frame reset)
  - **Effort:** 2 days
  - **Priority:** P0 - Robustness
  - **Dependencies:** Reset logic defined
  - **Validation:** All resets leave core in known state
  - **Deliverable:** RTL reset testbench
  - **Notes:** Ensure no lingering FSM states

### Pre-Silicon Verification
- **TODO [P0]:** Run cocotb smoke test suite to 100% pass (IRQ, DMA, frame_done)
  - **Effort:** 1 day
  - **Priority:** P0 - Integration confidence
  - **Dependencies:** Cocotb tests written
  - **Validation:** All tests pass with iverilog and verilator
  - **Deliverable:** CI gate on cocotb pass

- **TODO [P0]:** Validate interrupt generation (frame_done, dma_done, blit_done) with testbench
  - **Effort:** 2 days
  - **Priority:** P0 - IRQ wiring critical
  - **Dependencies:** INT_STATUS/INT_MASK implementation
  - **Validation:** IRQ_TEST pulse triggers msi_pulse, INT_MASK gates correctly
  - **Deliverable:** RTL IRQ testbench
  - **Notes:** Test all 8 interrupt sources independently

- **TODO [P0]:** Validate framebuffer write pattern (TOTAL_PIXELS, no gaps, monotonic addr)
  - **Effort:** 1 day
  - **Priority:** P0 - Visual output correctness
  - **Dependencies:** Pixel stream assertions in place
  - **Validation:** Scoreboard detects any missing/duplicate pixels
  - **Deliverable:** Scoreboard in voxel_axi_core.sv
  - **Status:** Done - extend to multi-frame validation

### Timing/Synthesis Pre-Check
- **TODO [P0]:** Run synthesis timing analysis in sim (lint for combinational loops, long paths)
  - **Effort:** 1 day
  - **Priority:** P0 - Synthesis readiness
  - **Dependencies:** None
  - **Validation:** Verilator --lint-only passes, no COMBDLY warnings
  - **Deliverable:** Clean lint report

- **TODO [P0]:** Document all clock domain crossings (if any) and add CDC assertions
  - **Effort:** 1 day
  - **Priority:** P0 - Timing closure
  - **Dependencies:** RTL review
  - **Validation:** No async crossings without synchronizers
  - **Deliverable:** CDC documentation, assertions in RTL
  - **Notes:** Currently single-clock, but document for future multi-clock

---

## P1 - High Priority FPGA Bring-Up (Recommended for 0.0.7)

### FPGA Board Selection & Setup
- **TODO [P1]:** Select target FPGA board (Arty A7, Nexys, custom) based on resources
  - **Effort:** 3 days
  - **Priority:** P1 - Hardware path decision
  - **Dependencies:** Resource estimates (LUTs, BRAM, DSP)
  - **Validation:** Board has sufficient resources for Hydra core + LitePCIe
  - **Deliverable:** Board selection document
  - **Notes:** See `todo_board_fpga.md` for detailed comparison

- **TODO [P1]:** Create pin constraints file for selected board (.xdc or .pcf)
  - **Effort:** 2 days
  - **Priority:** P1 - Synthesis prerequisite
  - **Dependencies:** Board selected, pinout available
  - **Validation:** Constraints file compiles without errors
  - **Deliverable:** constraints/hydra_<board>.xdc

- **TODO [P1]:** Set up synthesis flow (Vivado/Quartus/Yosys) with build scripts
  - **Effort:** 3 days
  - **Priority:** P1 - Build automation
  - **Dependencies:** Board selected
  - **Validation:** `make fpga-synth` generates bitstream
  - **Deliverable:** fpga/Makefile or synthesis scripts

### Initial FPGA Testing
- **TODO [P1]:** Create minimal FPGA top-level (core + LED heartbeat, no PCIe)
  - **Effort:** 2 days
  - **Priority:** P1 - Bring-up incremental
  - **Dependencies:** Synthesis flow working
  - **Validation:** Bitstream loads, LED blinks at expected rate
  - **Deliverable:** fpga/top_minimal.sv

- **TODO [P1]:** Add FPGA test script to exercise CSRs via UART or JTAG
  - **Effort:** 3 days
  - **Priority:** P1 - Bring-up testing
  - **Dependencies:** Minimal top-level working
  - **Validation:** Can read/write CSRs from host
  - **Deliverable:** scripts/fpga_csr_test.py (via UART or xsdb)

- **TODO [P1]:** Validate clock frequency meets timing (100 MHz target for Hydra core)
  - **Effort:** 2 days
  - **Priority:** P1 - Performance
  - **Dependencies:** Synthesis complete
  - **Validation:** Timing report shows no negative slack
  - **Deliverable:** Timing report in fpga/timing_report.txt

### Driver Integration on Hardware
- **TODO [P1]:** Test Linux driver probe on FPGA board (BAR0 access, ID reg readback)
  - **Effort:** 2 days
  - **Priority:** P1 - Driver/HW integration
  - **Dependencies:** PCIe endpoint working
  - **Validation:** dmesg shows successful probe, ID reg matches
  - **Deliverable:** FPGA bring-up log

- **TODO [P1]:** Validate interrupt delivery from FPGA to host (MSI or legacy)
  - **Effort:** 2 days
  - **Priority:** P1 - IRQ functionality
  - **Dependencies:** IRQ wiring in FPGA top-level
  - **Validation:** IRQ_TEST pulse triggers host IRQ handler
  - **Deliverable:** IRQ validation script

- **TODO [P1]:** Run libhydra smoke tests on FPGA (camera, flags, selection)
  - **Effort:** 1 day
  - **Priority:** P1 - Functional validation
  - **Dependencies:** Driver working
  - **Validation:** libhydra tools control camera successfully
  - **Deliverable:** FPGA test pass log

### Debugging Infrastructure
- **TODO [P1]:** Add ILA (Integrated Logic Analyzer) probes for key signals
  - **Effort:** 2 days
  - **Priority:** P1 - Debug capability
  - **Dependencies:** Synthesis flow working
  - **Validation:** Can capture waveforms on FPGA
  - **Deliverable:** ILA instantiation in top-level, capture scripts

- **TODO [P1]:** Create FPGA waveform dump script for key debug signals
  - **Effort:** 1 day
  - **Priority:** P1 - Debugging
  - **Dependencies:** ILA or VIO probes
  - **Validation:** Waveforms viewable in Vivado/Quartus
  - **Deliverable:** scripts/fpga_capture_waveform.sh

- **TODO [P1]:** Add GPIO debug outputs (frame_done, busy, error flags) to LEDs/header
  - **Effort:** 1 day
  - **Priority:** P1 - Visual debugging
  - **Dependencies:** Board pinout
  - **Validation:** LEDs reflect expected states
  - **Deliverable:** LED mapping in constraints

### Performance Validation
- **TODO [P1]:** Measure frame rate on FPGA (target: 30+ FPS at 480x360)
  - **Effort:** 2 days
  - **Priority:** P1 - Performance target
  - **Dependencies:** FPGA bitstream running
  - **Validation:** Achieves ≥30 FPS
  - **Deliverable:** Performance measurement log

- **TODO [P1]:** Validate BRAM utilization matches synthesis estimate
  - **Effort:** 1 day
  - **Priority:** P1 - Resource verification
  - **Dependencies:** Synthesis complete
  - **Validation:** BRAM usage ≤80% of available
  - **Deliverable:** Resource utilization report

- **TODO [P1]:** Check power consumption and thermal profile under sustained rendering
  - **Effort:** 2 days
  - **Priority:** P1 - Thermal design
  - **Dependencies:** FPGA running
  - **Validation:** Board temperature <85°C under load
  - **Deliverable:** Thermal measurement log

---

## P2 - Medium Priority Hardware Testing (Nice-to-Have)

### Extended Hardware Testing
- **TODO [P2]:** Run 24-hour soak test on FPGA (continuous rendering, no hangs)
  - **Effort:** 1 day setup + 1 day monitoring
  - **Priority:** P2 - Reliability validation
  - **Dependencies:** FPGA stable
  - **Validation:** No crashes, hangs, or thermal issues over 24hr
  - **Deliverable:** Soak test pass log

- **TODO [P2]:** Validate DMA transfer correctness on hardware (scatter-gather if supported)
  - **Effort:** 3 days
  - **Priority:** P2 - DMA validation
  - **Dependencies:** LitePCIe DMA integrated
  - **Validation:** DMA loopback test passes, no data corruption
  - **Deliverable:** DMA validation script

- **TODO [P2]:** Test BAR1 framebuffer read from host (if BAR1 mapped)
  - **Effort:** 2 days
  - **Priority:** P2 - Framebuffer path
  - **Dependencies:** BAR1 mapping configured
  - **Validation:** Host can read pixels from BAR1
  - **Deliverable:** BAR1 read test script

- **TODO [P2]:** Validate HDMI output on hardware (if LiteVideo integrated)
  - **Effort:** 3 days
  - **Priority:** P2 - Video output
  - **Dependencies:** HDMI IP integrated
  - **Validation:** Monitor displays rendered frames
  - **Deliverable:** HDMI validation photos/video

### Power and Performance Optimization
- **TODO [P2]:** Run power analysis and optimize for low-power operation
  - **Effort:** 3 days
  - **Priority:** P2 - Power efficiency
  - **Dependencies:** Synthesis tools with power analysis
  - **Validation:** Power consumption reduced by ≥20%
  - **Deliverable:** Power optimization report

- **TODO [P2]:** Optimize critical timing paths to increase max clock frequency
  - **Effort:** 4 days
  - **Priority:** P2 - Performance
  - **Dependencies:** Timing reports
  - **Validation:** Max clock ≥150 MHz (50% improvement)
  - **Deliverable:** Timing optimization report

- **TODO [P2]:** Add clock gating or power gating for idle periods
  - **Effort:** 3 days
  - **Priority:** P2 - Power saving
  - **Dependencies:** Power analysis
  - **Validation:** Idle power reduced by ≥30%
  - **Deliverable:** Clock gating implementation

### Multi-Board Testing
- **TODO [P2]:** Test on alternative FPGA boards (Nexys, ECP5, iCE40 if feasible)
  - **Effort:** 4 days per board
  - **Priority:** P2 - Portability
  - **Dependencies:** Board available
  - **Validation:** Core functions on alternative boards
  - **Deliverable:** Multi-board test matrix

- **TODO [P2]:** Create board compatibility matrix (resource usage, max freq, features)
  - **Effort:** 2 days
  - **Priority:** P2 - Platform documentation
  - **Dependencies:** Multi-board testing
  - **Validation:** Users can select appropriate board
  - **Deliverable:** docs/board_compatibility.md

### Compliance Testing
- **TODO [P2]:** Run PCIe compliance tests (if available) on FPGA prototype
  - **Effort:** 3 days
  - **Priority:** P2 - Standards compliance
  - **Dependencies:** PCIe compliance suite
  - **Validation:** Passes PCIe Gen2/Gen3 compliance
  - **Deliverable:** Compliance test report

- **TODO [P2]:** Validate AXI protocol compliance with formal verification or checker IP
  - **Effort:** 3 days
  - **Priority:** P2 - Protocol correctness
  - **Dependencies:** AXI checker IP
  - **Validation:** No AXI protocol violations
  - **Deliverable:** AXI compliance report

### Manufacturing Test
- **TODO [P2]:** Create manufacturing test script (self-test on power-up)
  - **Effort:** 3 days
  - **Priority:** P2 - Production readiness
  - **Dependencies:** Stable FPGA design
  - **Validation:** Self-test detects faults
  - **Deliverable:** scripts/fpga_self_test.py

- **TODO [P2]:** Add boundary scan (JTAG) test for board-level diagnostics
  - **Effort:** 2 days
  - **Priority:** P2 - Manufacturing
  - **Dependencies:** JTAG chain configured
  - **Validation:** Boundary scan detects board issues
  - **Deliverable:** JTAG test scripts

- **TODO [P2]:** Document RMA (return) diagnostic procedure
  - **Effort:** 1 day
  - **Priority:** P2 - Support
  - **Dependencies:** Diagnostic tools ready
  - **Validation:** Support can diagnose returned units
  - **Deliverable:** docs/rma_diagnostics.md

---

## P3 - Low Priority Future Platforms (Future Work)

### ASIC Preparation
- **TODO [P3]:** Run ASIC synthesis flow (Design Compiler or similar) for area estimate
  - **Effort:** 5 days
  - **Priority:** P3 - ASIC feasibility
  - **Dependencies:** ASIC tools access
  - **Validation:** Synthesis completes, area reasonable
  - **Deliverable:** ASIC synthesis report

- **TODO [P3]:** Add scan chain insertion for ASIC DFT (Design for Test)
  - **Effort:** 4 days
  - **Priority:** P3 - ASIC testing
  - **Dependencies:** ASIC tools
  - **Validation:** Scan coverage >95%
  - **Deliverable:** DFT insertion scripts

- **TODO [P3]:** Create ASIC timing constraints (SDC) for multi-corner analysis
  - **Effort:** 3 days
  - **Priority:** P3 - ASIC timing
  - **Dependencies:** ASIC library
  - **Validation:** Timing closure at all corners
  - **Deliverable:** asic/constraints.sdc

### Alternative Platforms
- **TODO [P3]:** Port to open-source FPGA toolchain (Yosys + nextpnr for iCE40/ECP5)
  - **Effort:** 5 days
  - **Priority:** P3 - Open tools support
  - **Dependencies:** Yosys-compatible RTL
  - **Validation:** Builds with open tools
  - **Deliverable:** Open synthesis flow

- **TODO [P3]:** Evaluate cloud FPGA platforms (AWS F1, Azure, etc.) for scalability
  - **Effort:** 4 days
  - **Priority:** P3 - Cloud deployment
  - **Dependencies:** Cloud FPGA access
  - **Validation:** Runs on cloud FPGA
  - **Deliverable:** Cloud deployment guide

### Advanced Testing
- **TODO [P3]:** Add formal verification for FSMs (raycaster, CSR arbiter)
  - **Effort:** 7 days
  - **Priority:** P3 - Formal correctness
  - **Dependencies:** Formal tools (JasperGold, SymbiYosys)
  - **Validation:** FSMs proven correct
  - **Deliverable:** Formal properties and proof

- **TODO [P3]:** Create hardware-in-the-loop (HIL) test framework for automated regression
  - **Effort:** 10 days
  - **Priority:** P3 - Test automation
  - **Dependencies:** FPGA boards, automation infrastructure
  - **Validation:** Regression runs nightly on hardware
  - **Deliverable:** HIL test framework

---

## Cross-References

**Related Work:**
- See `todo_board_fpga.md` for board selection details
- See `todo_ip_integration.md` for LitePCIe/LiteDRAM/LiteVideo
- See `todo_testing_ci.md` for CI integration of hardware tests
- See `todo_synthesis.md` for synthesis optimization

**Blocking Items:**
- P0 pre-silicon validation gates FPGA bring-up
- P1 FPGA bring-up enables hardware driver testing
- P1 debugging infrastructure critical for bring-up

---

## Notes

- P0 items should complete before first FPGA bitstream
- P1 items are essential for successful FPGA bring-up
- P2 items improve reliability and multi-board support
- P3 items are long-term platform expansion

**Next Actions:**
1. Complete 1000-frame sim regression (P0)
2. Add AXI-Lite SVAs (P0)
3. Select FPGA board (P1)
4. Create synthesis flow (P1)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for hardware bring-up
