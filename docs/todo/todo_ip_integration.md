# IP Integration TODO Tracker (LiteX/LitePCIe/LiteDRAM/LiteVideo)

**Last Updated:** 2025-11-25
**Owner:** IP Integration Team
**Related Trackers:** `todo_board_fpga.md`, `todo_hardware_validation.md`, `todo_dma_pcie.md`, `todo_hdmi.md`

---

## Overview

Tracks integration of third-party IP cores (LitePCIe, LiteDRAM, LiteVideo, LiteX) to replace AXI stubs. This is a **separate track from 0.0.7 software release** and runs in parallel with hardware bring-up.

**Priority Distribution:**
- **P0:** 11 items (~55-80 days) - Critical IP integration for hardware
- **P1:** 20 items (~45-65 days) - High-value features and optimization
- **P2:** 14 items (~30-45 days) - Extended features
- **P3:** 5 items (~20-30 days) - Future enhancements

**Total:** 50 items, ~150-220 engineer-days (hardware track, separate from 0.0.7)

**Note:** This tracker documents the **hardware IP integration roadmap**. It is NOT blocking the 0.0.7 software release, which uses AXI stubs in simulation. Hardware bring-up follows its own timeline.

---

## P0 - Critical IP Integration (Blocks Hardware Deployment)

### LitePCIe Integration (PCIe Endpoint)
- **TODO [P0]:** Fetch LitePCIe from GitHub and integrate into third_party/
  - **Effort:** 2 days
  - **Priority:** P0 - Prerequisite for all PCIe work
  - **Dependencies:** None
  - **Validation:** LitePCIe sources in third_party/litepcie/
  - **Deliverable:** scripts/fetch_ip.sh updated
  - **Notes:** Pin to stable tag (e.g., 2024.04)

- **TODO [P0]:** Generate LitePCIe wrapper for target FPGA (Xilinx Artix-7 PCIe Gen2 x4)
  - **Effort:** 5 days
  - **Priority:** P0 - PCIe endpoint prerequisite
  - **Dependencies:** LitePCIe fetched, board selected
  - **Validation:** PCIe wrapper synthesizes
  - **Deliverable:** Generated LitePCIe core in third_party/litepcie/gen/
  - **Notes:** Use LiteX build scripts

- **TODO [P0]:** Wire LitePCIe BAR0 to voxel_axil_csr.sv (AXI-Lite master → CSR slave)
  - **Effort:** 5 days
  - **Priority:** P0 - CSR access from host
  - **Dependencies:** LitePCIe wrapper generated
  - **Validation:** Host can read/write BAR0 CSRs
  - **Deliverable:** Top-level integration with BAR0 mapping
  - **Notes:** Map BAR0 to CSR space at 0x0000-0x0FFF

- **TODO [P0]:** Integrate LitePCIe DMA engine for framebuffer transfers
  - **Effort:** 10 days
  - **Priority:** P0 - DMA critical for performance
  - **Dependencies:** LitePCIe BAR0 working
  - **Validation:** DMA transfers work, no data corruption
  - **Deliverable:** DMA engine wired to AXI master
  - **Notes:** Replace axi_dma_stub.sv

- **TODO [P0]:** Wire LitePCIe MSI interrupt to Hydra core INT_STATUS
  - **Effort:** 3 days
  - **Priority:** P0 - Interrupt delivery
  - **Dependencies:** LitePCIe integrated
  - **Validation:** IRQ_TEST triggers MSI to host
  - **Deliverable:** IRQ wiring in top-level
  - **Notes:** Map INT_STATUS bits to MSI vectors

### LiteDRAM Integration (DRAM Controller)
- **TODO [P0]:** Fetch LiteDRAM from GitHub and integrate into third_party/
  - **Effort:** 2 days
  - **Priority:** P0 - Prerequisite for DRAM
  - **Dependencies:** None
  - **Validation:** LiteDRAM sources in third_party/litedram/
  - **Deliverable:** scripts/fetch_ip.sh updated

- **TODO [P0]:** Generate LiteDRAM controller for target board (DDR3-1333 or similar)
  - **Effort:** 7 days
  - **Priority:** P0 - DRAM controller prerequisite
  - **Dependencies:** LiteDRAM fetched, board DRAM spec known
  - **Validation:** DRAM controller synthesizes, passes calibration
  - **Deliverable:** Generated LiteDRAM core
  - **Notes:** May need DRAM on custom board or FMC addon

- **TODO [P0]:** Wire LiteDRAM AXI slave to framebuffer AXI master (replace axi_sdram_stub.sv)
  - **Effort:** 10 days
  - **Priority:** P0 - Framebuffer storage
  - **Dependencies:** LiteDRAM controller working
  - **Validation:** Framebuffer writes to DRAM, host can read back
  - **Deliverable:** AXI interconnect with DRAM
  - **Notes:** AXI4 or AXI3 depending on LiteDRAM version

- **TODO [P0]:** Validate DRAM bandwidth meets framebuffer requirements (480x360x60Hz → ~40 MB/s)
  - **Effort:** 3 days
  - **Priority:** P0 - Performance validation
  - **Dependencies:** LiteDRAM integrated
  - **Validation:** Sustained 60 FPS with DRAM framebuffer
  - **Deliverable:** Bandwidth test results

### LiteVideo Integration (HDMI Output)
- **TODO [P0]:** Fetch LiteICLink (for HDMI PHY) and integrate into third_party/
  - **Effort:** 2 days
  - **Priority:** P0 - Prerequisite for HDMI
  - **Dependencies:** None
  - **Validation:** LiteICLink sources in third_party/
  - **Deliverable:** scripts/fetch_ip.sh updated

- **TODO [P0]:** Generate LiteVideo HDMI encoder for 480x360@60Hz output
  - **Effort:** 8 days
  - **Priority:** P0 - HDMI output prerequisite
  - **Dependencies:** LiteICLink fetched, board HDMI port available
  - **Validation:** HDMI encoder synthesizes
  - **Deliverable:** Generated LiteVideo core
  - **Notes:** May use Digilent PMOD or FMC HDMI addon

---

## P1 - High Priority Features (Recommended for Hardware V1)

### LitePCIe Advanced Features
- **TODO [P1]:** Implement scatter-gather DMA for efficient transfers
  - **Effort:** 7 days
  - **Priority:** P1 - Performance optimization
  - **Dependencies:** Basic DMA working
  - **Validation:** S/G DMA handles fragmented buffers correctly
  - **Deliverable:** S/G DMA implementation

- **TODO [P1]:** Add MSI-X support for more interrupt vectors (>8 sources)
  - **Effort:** 5 days
  - **Priority:** P1 - Interrupt scalability
  - **Dependencies:** Basic MSI working
  - **Validation:** MSI-X vectors delivered correctly
  - **Deliverable:** MSI-X configuration

- **TODO [P1]:** Optimize PCIe TLP (Transaction Layer Packet) size for bandwidth
  - **Effort:** 4 days
  - **Priority:** P1 - Bandwidth optimization
  - **Dependencies:** DMA working
  - **Validation:** DMA bandwidth increases by ≥20%
  - **Deliverable:** Optimized TLP configuration

- **TODO [P1]:** Add PCIe link training monitoring and error handling
  - **Effort:** 3 days
  - **Priority:** P1 - Robustness
  - **Dependencies:** LitePCIe integrated
  - **Validation:** Link errors detected and logged
  - **Deliverable:** Link status monitoring

- **TODO [P1]:** Implement PCIe AER (Advanced Error Reporting)
  - **Effort:** 5 days
  - **Priority:** P1 - Production readiness
  - **Dependencies:** PCIe working
  - **Validation:** PCIe errors reported via AER
  - **Deliverable:** AER support in IP

### LiteDRAM Advanced Features
- **TODO [P1]:** Add DRAM ECC (Error-Correcting Code) support if available
  - **Effort:** 5 days
  - **Priority:** P1 - Data integrity
  - **Dependencies:** ECC DRAM modules
  - **Validation:** Single-bit errors corrected
  - **Deliverable:** ECC-enabled DRAM controller

- **TODO [P1]:** Optimize DRAM refresh scheduling for latency
  - **Effort:** 4 days
  - **Priority:** P1 - Performance
  - **Dependencies:** LiteDRAM working
  - **Validation:** Refresh doesn't block framebuffer writes
  - **Deliverable:** Optimized refresh config

- **TODO [P1]:** Add DRAM training debug outputs (for bring-up)
  - **Effort:** 3 days
  - **Priority:** P1 - Bring-up debugging
  - **Dependencies:** LiteDRAM integrated
  - **Validation:** Training failures diagnosed easily
  - **Deliverable:** Debug signals exported

- **TODO [P1]:** Implement DRAM self-test mode (BIST)
  - **Effort:** 5 days
  - **Priority:** P1 - Manufacturing test
  - **Dependencies:** LiteDRAM working
  - **Validation:** BIST detects bad DRAM
  - **Deliverable:** BIST implementation

### LiteVideo Advanced Features
- **TODO [P1]:** Add support for multiple resolutions (720p, 1080p via CSR)
  - **Effort:** 6 days
  - **Priority:** P1 - Display flexibility
  - **Dependencies:** Basic HDMI working
  - **Validation:** Multiple resolutions work
  - **Deliverable:** Resolution switching via CSR

- **TODO [P1]:** Implement HDMI audio passthrough (if needed)
  - **Effort:** 7 days
  - **Priority:** P1 - Audio output
  - **Dependencies:** HDMI working
  - **Validation:** Audio plays through HDMI
  - **Deliverable:** I2S to HDMI audio

- **TODO [P1]:** Add EDID readback for display auto-configuration
  - **Effort:** 4 days
  - **Priority:** P1 - User experience
  - **Dependencies:** HDMI working
  - **Validation:** Display capabilities detected
  - **Deliverable:** EDID read via I2C

- **TODO [P1]:** Optimize pixel packing for HDMI (RGB888 or YUV422)
  - **Effort:** 3 days
  - **Priority:** P1 - Bandwidth optimization
  - **Dependencies:** HDMI working
  - **Validation:** Reduced bandwidth, same quality
  - **Deliverable:** Optimized pixel format

### LiteX SoC Integration (Optional)
- **TODO [P1]:** Integrate LiteX SoC builder for top-level generation
  - **Effort:** 5 days
  - **Priority:** P1 - Build automation
  - **Dependencies:** LitePCIe/LiteDRAM working
  - **Validation:** LiteX generates integrated SoC
- **Deliverable:** LiteX build script

### LiteX Stubs & Surface Work
- **TODO [P1]:** Turn `rtl/litex/litex_pcie_bridge.sv` into a working bridge with AXI translation, descriptor parsing, and MSI-X handling; log progress in this tracker for visibility.
- **TODO [P2]:** Build out `rtl/litex/litex_dma_engine.sv` so it produces AXI bursts (read/write) mapped to LiteX descriptors, and connect the module to `docs/todo/todo_dma_pcie.md` for DMA parity testing.
- **TODO [P2]:** Add documentation/reference in this tracker describing how the LiteX stubs tie into rails/clocking/power; use `docs/mixed_signal_environment.md` or `docs/todo/todo_board_hardware_design.md` as needed.
- **TODO [P1]:** Add LiteX CPU (VexRiscv or similar) for boot/config if needed
  - **Effort:** 7 days
  - **Priority:** P1 - Advanced control
  - **Dependencies:** LiteX SoC integrated
  - **Validation:** CPU can configure Hydra core
  - **Deliverable:** CPU integrated in SoC

- **TODO [P1]:** Implement LiteX BIOS for hardware initialization
  - **Effort:** 6 days
  - **Priority:** P1 - Boot sequence
  - **Dependencies:** LiteX CPU working
  - **Validation:** BIOS initializes DRAM, PCIe
  - **Deliverable:** BIOS binary

- **TODO [P1]:** Add LiteX Ethernet for remote debug/config (optional)
  - **Effort:** 5 days
  - **Priority:** P1 - Debug infrastructure
  - **Dependencies:** LiteX SoC, Ethernet PHY
  - **Validation:** Can debug via Ethernet
  - **Deliverable:** Ethernet integration

### AXI Interconnect
- **TODO [P1]:** Replace ad-hoc AXI wiring with proper crossbar (LiteX or custom)
  - **Effort:** 6 days
  - **Priority:** P1 - Scalability
  - **Dependencies:** Multiple AXI masters/slaves
  - **Validation:** Crossbar routes correctly
  - **Deliverable:** AXI crossbar integration

- **TODO [P1]:** Add AXI protocol checkers for integration validation
  - **Effort:** 4 days
  - **Priority:** P1 - Correctness
  - **Dependencies:** Crossbar integrated
  - **Validation:** Protocol violations caught
  - **Deliverable:** AXI checker instantiations

- **TODO [P1]:** Optimize AXI pipeline for latency (data width matching, bursts)
  - **Effort:** 5 days
  - **Priority:** P1 - Performance
  - **Dependencies:** Crossbar working
  - **Validation:** Latency reduced by ≥15%
  - **Deliverable:** Optimized AXI config

---

## P2 - Medium Priority Extended Features (Nice-to-Have)

### PCIe Extended Features
- **TODO [P2]:** Add PCIe hotplug support
  - **Effort:** 5 days
  - **Priority:** P2 - Advanced feature
  - **Validation:** Hotplug works correctly
  - **Deliverable:** Hotplug support

- **TODO [P2]:** Implement PCIe power management (L0s, L1)
  - **Effort:** 6 days
  - **Priority:** P2 - Power efficiency
  - **Validation:** Power states transition correctly
  - **Deliverable:** PM implementation

- **TODO [P2]:** Add PCIe SR-IOV for virtualization
  - **Effort:** 10 days
  - **Priority:** P2 - Advanced feature
  - **Validation:** Virtual functions work
  - **Deliverable:** SR-IOV support

### DRAM Extended Features
- **TODO [P2]:** Add DRAM compression for framebuffer (if bandwidth-limited)
  - **Effort:** 8 days
  - **Priority:** P2 - Bandwidth optimization
  - **Validation:** Bandwidth reduced by ≥30%
  - **Deliverable:** Compression engine

- **TODO [P2]:** Implement DRAM scrubbing for ECC correction
  - **Effort:** 5 days
  - **Priority:** P2 - Data integrity
  - **Validation:** Multi-bit errors detected
  - **Deliverable:** Scrubbing logic

- **TODO [P2]:** Add DRAM performance counters (read/write bandwidth, latency)
  - **Effort:** 4 days
  - **Priority:** P2 - Performance monitoring
  - **Validation:** Counters accurate
  - **Deliverable:** Performance counters

### HDMI Extended Features
- **TODO [P2]:** Add HDCP (High-bandwidth Digital Content Protection) support
  - **Effort:** 10 days
  - **Priority:** P2 - Content protection
  - **Validation:** HDCP handshake works
  - **Deliverable:** HDCP implementation

- **TODO [P2]:** Implement DisplayPort output as alternative to HDMI
  - **Effort:** 12 days
  - **Priority:** P2 - Display flexibility
  - **Validation:** DP output works
  - **Deliverable:** DP encoder

- **TODO [P2]:** Add multi-display support (2+ HDMI outputs)
  - **Effort:** 8 days
  - **Priority:** P2 - Advanced feature
  - **Validation:** Dual displays work
  - **Deliverable:** Multi-display config

### Integration Testing
- **TODO [P2]:** Create IP integration testbench (PCIe + DRAM + HDMI together)
  - **Effort:** 7 days
  - **Priority:** P2 - Integration validation
  - **Validation:** All IPs work together
  - **Deliverable:** Integration testbench

- **TODO [P2]:** Add IP-level stress tests (sustained max bandwidth)
  - **Effort:** 5 days
  - **Priority:** P2 - Reliability
  - **Validation:** No failures under stress
  - **Deliverable:** Stress test suite

- **TODO [P2]:** Create IP debugging guide (common issues, solutions)
  - **Effort:** 3 days
  - **Priority:** P2 - Documentation
  - **Validation:** Guide helps debug issues
  - **Deliverable:** docs/ip_integration_debug.md

### Performance Optimization
- **TODO [P2]:** Optimize AXI burst sizes for maximum throughput
  - **Effort:** 4 days
  - **Priority:** P2 - Performance
  - **Validation:** Throughput increased by ≥10%
  - **Deliverable:** Optimized burst config

- **TODO [P2]:** Add clock domain crossing (CDC) FIFOs for multi-clock domains
  - **Effort:** 5 days
  - **Priority:** P2 - Clock flexibility
  - **Validation:** No metastability issues
  - **Deliverable:** CDC FIFOs

- **TODO [P2]:** Implement zero-copy framebuffer (DRAM directly mapped to host)
  - **Effort:** 6 days
  - **Priority:** P2 - Latency reduction
  - **Validation:** Host reads framebuffer without DMA copy
  - **Deliverable:** Zero-copy implementation

---

## P3 - Low Priority Future Enhancements (Future Work)

### Advanced IP Integration
- **TODO [P3]:** Integrate LiteEth for Ethernet-based debug/control
  - **Effort:** 8 days
  - **Priority:** P3 - Alternative interface
  - **Validation:** Ethernet control works
  - **Deliverable:** LiteEth integration

- **TODO [P3]:** Add LiteSPI for SPI flash configuration storage
  - **Effort:** 5 days
  - **Priority:** P3 - Config persistence
  - **Validation:** Config stored/loaded from SPI flash
  - **Deliverable:** LiteSPI integration

- **TODO [P3]:** Integrate LiteJESD204B for high-speed serial (if needed)
  - **Effort:** 10 days
  - **Priority:** P3 - Advanced serial
  - **Validation:** JESD204B link works
  - **Deliverable:** JESD204B integration

### Performance and Power
- **TODO [P3]:** Add dynamic voltage/frequency scaling (DVFS) for power saving
  - **Effort:** 8 days
  - **Priority:** P3 - Power optimization
  - **Validation:** Power reduced in low-perf modes
  - **Deliverable:** DVFS implementation

- **TODO [P3]:** Implement multi-clock domain optimization (async clocks for PCIe/DRAM/Core)
  - **Effort:** 10 days
  - **Priority:** P3 - Advanced timing
  - **Validation:** Higher clock frequencies achieved
  - **Deliverable:** Multi-clock architecture

---

## IP Version Tracking

| IP | Version | Last Updated | Notes |
|---|---------|--------------|-------|
| LitePCIe | 2024.04 (example) | TBD | Pin to stable tag |
| LiteDRAM | 2024.04 (example) | TBD | Pin to stable tag |
| LiteVideo | 2024.04 (example) | TBD | May use LiteICLink |
| LiteX | 2024.04 (example) | TBD | SoC builder |
| LiteEth | 2024.04 (example) | TBD | Optional |

**Update Policy:** Pin to stable release tags, update quarterly or as needed for bug fixes.

---

## Cross-References

**Related Work:**
- See `todo_dma_pcie.md` for DMA/PCIe validation in sim (stubs)
- See `todo_dram_axi.md` for DRAM/AXI stub validation
- See `todo_hdmi.md` for HDMI stub validation
- See `todo_board_fpga.md` for board selection and synthesis
- See `todo_hardware_validation.md` for FPGA bring-up testing

**Blocking Items:**
- P0 IP integration blocks hardware deployment
- P0 does NOT block 0.0.7 software release (uses stubs in sim)

---

## Notes

- **This is a hardware-track roadmap, separate from 0.0.7 software release**
- 0.0.7 software release uses AXI stubs in simulation
- IP integration timeline: ~150-220 engineer-days (3-5 months with dedicated team)
- LitePCIe is highest priority (enables host communication)
- LiteDRAM and LiteVideo can be phased (use stubs initially on FPGA)

**Recommended Phasing:**
1. **Phase 1 (3-4 weeks):** LitePCIe integration, BAR0 CSR access
2. **Phase 2 (4-6 weeks):** LiteDRAM integration, framebuffer in DRAM
3. **Phase 3 (2-3 weeks):** LiteVideo integration, HDMI output
4. **Phase 4 (2-3 weeks):** Optimization and advanced features (P1)

**Next Actions:**
1. Fetch IP sources (P0)
2. Generate LitePCIe wrapper (P0)
3. Integrate BAR0 mapping (P0)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for IP integration (hardware track)

### Supplemental Integration TODOs
- **TODO [P1]:** Produce an integration checklist that lists CSR mappings, DMA descriptors, and debug hooks to cross-reference when replacing AXI stubs with LiteX IP; reference the list from `docs/todo/todo_dma_pcie.md` and `docs/todo/todo_build_tooling.md`.
- **TODO [P2]:** Create scripts (e.g., `scripts/litex_integration.sh`) that build only one IP core at a time to isolate integration issues and document how to enable them via env vars.
- **TODO [P2]:** Add latency/bandwidth expectations for the LiteX stack into `docs/todo/todo_performance.md` so software validation knows when DMA/PCIe throughput is constrained by stub vs. real IP.
- **TODO [P2]:** Run `scripts/test_litex_stubs.sh` from CI/automation (see `scripts/automation_watchdog.sh`) to ensure the stub RTL remains lint-clean before hooking in real LiteX IP.
