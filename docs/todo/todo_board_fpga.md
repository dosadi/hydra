# Board Selection & FPGA Synthesis TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Hardware Platform Team
**Related Trackers:** `todo_hardware_validation.md`, `todo_ip_integration.md`, `todo_synthesis.md`

**Session Reference:** See [`docs/TODO_SESSION_CONTINUATION_2025_11_25.md`](../TODO_SESSION_CONTINUATION_2025_11_25.md) "Near-Term (Sprint 2-3)" section for P0 hardware track action items (resource estimates, board selection, procurement, synthesis setup).

---

## Overview

Tracks FPGA board selection, constraints files, synthesis flows, and board-specific optimizations. Focus areas: board evaluation, resource estimation, pin constraints, synthesis optimization.

**Priority Distribution:**
- **P0:** 6 items (~10 days) - Critical board selection and synthesis setup
- **P1:** 10 items (~15 days) - Synthesis flow and optimization
- **P2:** 7 items (~10 days) - Multi-board support
- **P3:** 3 items (~5 days) - Advanced platforms

**Total:** 26 items, ~40 engineer-days

---

## P0 - Critical Board Selection (Blocks Hardware)

### Board Selection and Resource Estimation
- **TODO [P0]:** Estimate RTL resource requirements (LUTs, FFs, BRAM, DSP) from synthesis
  - **Effort:** 2 days
  - **Priority:** P0 - Informs board selection
  - **Dependencies:** RTL finalized
  - **Validation:** Synthesis report shows resource counts
  - **Deliverable:** Resource estimate spreadsheet
  - **Notes:** Run synthesis on multiple targets for comparison

- **TODO [P0]:** Select primary target FPGA board based on resources, cost, availability
  - **Effort:** 3 days
  - **Priority:** P0 - Hardware path decision
  - **Dependencies:** Resource estimates complete
  - **Validation:** Board selected, procurement initiated
  - **Deliverable:** Board selection document with justification
  - **Candidates:**
    - **Arty A7-100T:** Xilinx Artix-7, 101,440 LUTs, 4.9 Mb BRAM, PCIe via FMC
    - **Nexys A7-100T:** Similar to Arty, more I/O, $300-400
    - **Genesys 2:** Xilinx Kintex-7, higher performance, $500-600
    - **Custom PCIe card:** Artix-7 or Kintex-7, full PCIe x4/x8
    - **Lattice ECP5:** Open-source toolchain friendly, moderate resources
  - **Selection Criteria:** Cost, PCIe support, BRAM capacity, community support

- **TODO [P0]:** Acquire or verify access to target FPGA board
  - **Effort:** 1 day + procurement time
  - **Priority:** P0 - Can't start without board
  - **Dependencies:** Board selected
  - **Validation:** Board in hand, tested with vendor tools
  - **Deliverable:** Board procurement and initial test

### Synthesis Flow Setup
- **TODO [P0]:** Set up Xilinx Vivado or Intel Quartus synthesis flow for target board
  - **Effort:** 2 days
  - **Priority:** P0 - Build prerequisite
  - **Dependencies:** Board selected, tools installed
  - **Validation:** Simple blink design synthesizes and loads
  - **Deliverable:** fpga/Makefile with synth targets
  - **Notes:** Include version pin (Vivado 2023.2 or similar)

- **TODO [P0]:** Create pin constraints file (.xdc or .pcf) for target board
  - **Effort:** 2 days
  - **Priority:** P0 - Synthesis prerequisite
  - **Dependencies:** Board pinout documentation
  - **Validation:** Constraints file compiles without errors
  - **Deliverable:** fpga/constraints/<board>.xdc
  - **Notes:** Include clock, reset, LEDs, PCIe if applicable

- **TODO [P0]:** Validate clock synthesis (PLL/MMCM) for 100 MHz Hydra core clock
  - **Effort:** 1 day
  - **Priority:** P0 - Timing prerequisite
  - **Dependencies:** Constraints file complete
  - **Validation:** Generated clock meets timing
  - **Deliverable:** Clock constraints in .xdc

---

## P1 - High Priority Synthesis and Optimization (Recommended for 0.0.7)

### Synthesis Optimization
- **TODO [P1]:** Optimize synthesis settings for area vs. speed tradeoff
  - **Effort:** 2 days
  - **Priority:** P1 - Resource utilization
  - **Dependencies:** Initial synthesis complete
  - **Validation:** Resource usage ≤80% of available, timing met
  - **Deliverable:** Optimized synthesis settings documented

- **TODO [P1]:** Add timing constraints (SDC/.xdc) for all clock domains
  - **Effort:** 2 days
  - **Priority:** P1 - Timing closure
  - **Dependencies:** Clock architecture defined
  - **Validation:** Timing analysis passes with no violations
  - **Deliverable:** Comprehensive timing constraints

- **TODO [P1]:** Optimize critical timing paths to meet 100 MHz target
  - **Effort:** 3 days
  - **Priority:** P1 - Performance
  - **Dependencies:** Timing reports available
  - **Validation:** All paths meet timing at 100 MHz
  - **Deliverable:** Timing closure report
  - **Notes:** May require pipeline adjustments in RTL

### Build Automation
- **TODO [P1]:** Create automated synthesis flow (one-command bitstream generation)
  - **Effort:** 2 days
  - **Priority:** P1 - Developer velocity
  - **Dependencies:** Synthesis flow working
  - **Validation:** `make fpga-bitstream` generates .bit file
  - **Deliverable:** Makefile or script in fpga/

- **TODO [P1]:** Add bitstream programming script (JTAG or USB)
  - **Effort:** 1 day
  - **Priority:** P1 - Bring-up speed
  - **Dependencies:** Board connection method known
  - **Validation:** `make fpga-program` loads bitstream
  - **Deliverable:** Programming script in fpga/

- **TODO [P1]:** Set up incremental synthesis for faster iteration
  - **Effort:** 2 days
  - **Priority:** P1 - Build speed
  - **Dependencies:** Synthesis flow stable
  - **Validation:** Incremental builds 2-3x faster
  - **Deliverable:** Incremental synthesis configuration

### Board-Specific Integration
- **TODO [P1]:** Integrate PCIe endpoint IP for selected board (LitePCIe or vendor IP)
  - **Effort:** 4 days
  - **Priority:** P1 - Critical functionality
  - **Dependencies:** Board selected, IP available
  - **Validation:** PCIe link trains successfully
  - **Deliverable:** PCIe IP integrated in top-level

- **TODO [P1]:** Wire up LEDs and switches for debug visibility
  - **Effort:** 1 day
  - **Priority:** P1 - Debugging
  - **Dependencies:** Pin constraints
  - **Validation:** LEDs show expected signals
  - **Deliverable:** Debug pin assignments in constraints

- **TODO [P1]:** Add temperature and voltage monitoring (if available on board)
  - **Effort:** 1 day
  - **Priority:** P1 - Reliability monitoring
  - **Dependencies:** System Monitor IP
  - **Validation:** Can read temperature/voltage via debugfs
  - **Deliverable:** Monitoring integration

- **TODO [P1]:** Test bitstream loading via JTAG and configuration flash
  - **Effort:** 1 day
  - **Priority:** P1 - Deployment options
  - **Dependencies:** Programming tools
  - **Validation:** Both JTAG and flash loading work
  - **Deliverable:** Dual loading method documented

---

## P2 - Medium Priority Multi-Board Support (Nice-to-Have)

### Alternative Boards
- **TODO [P2]:** Add support for secondary FPGA board (e.g., Nexys if Arty is primary)
  - **Effort:** 4 days
  - **Priority:** P2 - Platform diversity
  - **Dependencies:** Primary board working
  - **Validation:** Secondary board passes basic tests
  - **Deliverable:** Constraints and build for secondary board

- **TODO [P2]:** Evaluate Lattice ECP5 support with open-source toolchain (Yosys + nextpnr)
  - **Effort:** 5 days
  - **Priority:** P2 - Open-source enablement
  - **Dependencies:** ECP5 board available
  - **Validation:** Design synthesizes with Yosys
  - **Deliverable:** ECP5 synthesis flow

- **TODO [P2]:** Create board compatibility matrix (resources, features, cost)
  - **Effort:** 2 days
  - **Priority:** P2 - User guidance
  - **Dependencies:** Multiple boards tested
  - **Validation:** Users can select appropriate board
  - **Deliverable:** docs/board_compatibility.md

### Optimization and Variants
- **TODO [P2]:** Create area-optimized variant for smaller FPGAs
  - **Effort:** 3 days
  - **Priority:** P2 - Low-cost option
  - **Dependencies:** Resource bottlenecks identified
  - **Validation:** Fits in smaller FPGA (e.g., Artix-7 35T)
  - **Deliverable:** Area-optimized build config

- **TODO [P2]:** Create performance-optimized variant for high-end FPGAs
  - **Effort:** 3 days
  - **Priority:** P2 - High-performance option
  - **Dependencies:** Baseline working
  - **Validation:** Achieves >150 MHz on Kintex/Virtex
  - **Deliverable:** Performance-optimized build config

### Power and Thermal
- **TODO [P2]:** Add power estimation and optimization for battery/embedded use
  - **Effort:** 3 days
  - **Priority:** P2 - Mobile platforms
  - **Dependencies:** Power analysis tools
  - **Validation:** Power consumption measured and optimized
  - **Deliverable:** Power optimization report

- **TODO [P2]:** Test thermal performance under sustained load (thermal camera or probes)
  - **Effort:** 2 days
  - **Priority:** P2 - Reliability
  - **Dependencies:** FPGA bitstream running
  - **Validation:** Temperature <85°C under load
  - **Deliverable:** Thermal test report

---

## P3 - Low Priority Advanced Platforms (Future Work)

### Cloud and ASIC
- **TODO [P3]:** Evaluate cloud FPGA platforms (AWS F1, Azure) for scalability
  - **Effort:** 4 days
  - **Priority:** P3 - Cloud deployment
  - **Dependencies:** Cloud FPGA access
  - **Validation:** Runs on cloud FPGA
  - **Deliverable:** Cloud deployment guide

- **TODO [P3]:** Prepare for ASIC flow (synthesizable RTL, no FPGA primitives)
  - **Effort:** 5 days
  - **Priority:** P3 - ASIC readiness
  - **Dependencies:** ASIC synthesis tools
  - **Validation:** Synthesizes with ASIC tools
  - **Deliverable:** ASIC-compatible RTL

- **TODO [P3]:** Evaluate SoC FPGA platforms (Zynq, Cyclone V SoC) for ARM integration
  - **Effort:** 5 days
  - **Priority:** P3 - Embedded systems
  - **Dependencies:** SoC FPGA board
  - **Validation:** ARM can access Hydra core
  - **Deliverable:** SoC integration guide

---

## Board Comparison Matrix (Reference)

| Board | FPGA | LUTs | BRAM | DSP | PCIe | Cost | Toolchain | Notes |
|-------|------|------|------|-----|------|------|-----------|-------|
| **Arty A7-100T** | XC7A100T | 101K | 4.9Mb | 240 | FMC | $300 | Vivado | Good starter, PCIe via addon |
| **Nexys A7-100T** | XC7A100T | 101K | 4.9Mb | 240 | FMC | $400 | Vivado | More I/O than Arty |
| **Genesys 2** | XC7K325T | 326K | 16Mb | 840 | FMC | $600 | Vivado | High-end, overkill? |
| **Custom PCIe** | XC7A100T+ | 101K+ | 4.9Mb+ | 240+ | Native | $500+ | Vivado | Best for production |
| **ECP5 Versa** | LFE5UM5G | 84K | 3.7Mb | 156 | FMC | $250 | Yosys | Open-source tools |
| **ULX3S** | LFE5U-85F | 84K | 3.7Mb | 156 | - | $150 | Yosys | Hobbyist, no PCIe |

**Recommendation for 0.0.7:** Start with **Arty A7-100T** or **Nexys A7-100T** (proven, affordable, good Vivado support). Add **ECP5** as P2 for open-source toolchain support.

---

## Cross-References

**Related Work:**
- See `todo_hardware_validation.md` for FPGA testing
- See `todo_ip_integration.md` for PCIe/DRAM IP
- See `todo_synthesis.md` for synthesis optimization techniques
- See `todo_fpga.md` for general FPGA tasks

**Blocking Items:**
- P0 board selection blocks all hardware work
- P0 synthesis flow blocks bitstream generation
- P1 PCIe integration blocks driver testing on hardware

---

## Notes

- Board selection (P0) is the critical path decision
- Arty A7 or Nexys A7 recommended for initial bring-up
- ECP5 support (P2) enables open-source community
- Custom PCIe card (P2/P3) for production deployment

**Next Actions:**
1. Generate resource estimate from synthesis (P0)
2. Select primary board (P0)
3. Procure board (P0)
4. Set up synthesis flow (P0)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for board selection and synthesis
