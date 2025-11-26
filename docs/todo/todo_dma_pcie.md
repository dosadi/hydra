# Hydra DMA / PCIe Path TODOs (0.0.7 Cycle)

**Focus:** Protocol compliance, backpressure handling, hardware validation infrastructure.
See `docs/TODO_MASTER_INDEX.md` for complete tracker reference.

**Related Trackers:** `todo_dram_axi.md`, `todo_hardware_validation.md`, `todo_testing_ci.md`, `todo_dma_hang_policy.md`, `todo_dma_structured_logging.md`, `todo_dma_hotplug.md`, `todo_dma_trace_artifacts.md`

---

## P0 - Critical (All Complete)

- DONE [P0]: Define a minimal DMA/PCIe bring-up checklist (BAR sizes, MSI on/off, kselftest run) and add to docs/README (`docs/dma_pcie_bringup.md`).
- DONE [P0]: Add a BAR layout diagram (BAR0 CSRs vs. BAR1 framebuffer) to help debug address mismatches (`docs/bar_layout.md` added in 0.0.6).
- DONE [P0]: Add bounds/stride assertions in RTL DMA path (src/dst+len within BAR window) beyond current stub checks (voxel_axi_core DMA stub now checks src/dst/len against a parametric window and errors on zero/overflow).
- DONE [P0]: Implement DMA busy/err behavior in RTL stubs to mirror driver expectations (set/clear on violations; sticky err/done bits; busy gating).
- DONE [P0]: Add an RTL cover/assert that INT_STATUS.DMA_DONE only sets after DMA completes and clears on RW1C (dma_done pulses only on completion in voxel_axi_core stub).
- DONE [P0]: Add backpressure handling on AXI write channel in DMA path (stall/queue when awready/wready deassert) (DMA stub now sequences AW/W/B with ready gating; still writes zeros until full DMA engine is integrated).
- DONE [P0]: Provide a BAR1 hexdump tool (userspace) for sanity-checking mapped memory contents (`scripts/hydra_bar1_hexdump`, `make bar1-hexdump`).
- DONE [P0]: Add a driver ioctl/version struct size check to detect userspace/kernel mismatches early (`HYDRA_IOCTL_VERSION` + hydra_mmap_smoke guard).
- DONE [P0]: Provide a minimal UAPI version query (no-op ioctl) for compatibility probing (`HYDRA_IOCTL_VERSION` added in 0.0.6).

## P1 - High Priority (Core Functionality & Validation)

**Dependencies:** Requires P0 RTL stubs and driver infrastructure

- TODO [P1]: Drive non-zero DMA write data based on src/dst/offset (stub currently writes deterministic pattern {src+offset, dst+offset}). *Blocking: DMA data integrity testing*
- TODO [P1]: Add a kselftest script to exercise DMA IOCTLs (good/bad offsets) and verify return codes. *Critical for: release testing*
- TODO [P1]: Add regression scripts that inject PCIe errors (CRC, DLLP drops) so firmware can surface corner-case DMA behavior. *Critical for: robustness*
- TODO [P1]: Add an IOMMU/VT-d friendly path (dma_map/unmap helpers in driver) and document how to enable on distros. *Blocking: FPGA deployment*
- TODO [P1]: Provide a cocotb test that mirrors driver MSI/legacy module params to ensure RTL reacts the same way (msi_pulse gating). *Depends on: P0 IRQ infrastructure*
- TODO [P1]: Add a small driver/unit test that flips between MSI/MSI-X/INTx at runtime and verifies IRQ delivery. *Critical for: bring-up*
- TODO [P1]: Provide BAR1/BAR0 address window parameters in RTL for synthesis-time sizing and driver alignment. *Blocking: IP integration*
- TODO [P1]: Extend cocotb/RTL benches with negative DMA cases (wrap, misaligned, overlap) to validate guards. *Depends on: P0 bounds checks*
- TODO [P1]: Add MSI pulse coverpoints for DMA_DONE/ERR bits independent of frame_done. *Depends on: P0 IRQ framework*
- TODO [P1]: Add AXI-lite SVAs around DMA CSRs (alignment, busy gating, RW1C) to flag protocol violations. *Depends on: todo_dram_axi.md P0 SVAs*
- TODO [P1]: Add alignment checks and helpful -EINVAL logging in driver for misaligned DMA SRC/DST/LEN. *Critical for: user experience*

## P2 - Medium Priority (Testing & CI Infrastructure)

**Dependencies:** Requires P1 validation infrastructure

- TODO [P2]: Implement a simple readback/checker in benches to verify DMA copied data correctly under wait-states. *Depends on: P1 non-zero data*
- TODO [P2]: Add a module param to force-disable MSI (use legacy INT) for platforms with broken MSI (mirror driver param).
- TODO [P2]: Provide a libhydra DMA test helper that exercises aligned/unaligned/overflow cases and checks driver return codes. *Depends on: P1 kself test*
- TODO [P2]: Add driver debugfs entry to dump last DMA request/offsets/status for debugging wrap issues.
- TODO [P2]: Integrate a BAR1 mmap smoke test into CI (map/read/write small ranges) to catch regressions.
- TODO [P2]: Add a driver module param to force legacy INTx even when MSI is available (for broken platforms).
- TODO [P2]: Expose DMA statistics (bytes moved, errors) via debugfs for postmortem analysis.
- TODO [P2]: Implement DMA timeout handling in driver (reset/err) and add a regression test.
- TODO [P2]: Add BAR0/BAR1 size reporting via driver ioctl or debugfs for bring-up sanity.
- TODO [P2]: Add a driver tracepoint for DMA start/done events (trace_printk or tracepoints) for lightweight tracing.
- TODO [P2]: Provide a userspace perf microbenchmark (ioctl loop) to measure DMA latency/throughput.
- TODO [P2]: Add AXI backpressure stress test bench (inject waitstates) to ensure DMA stubs behave under stalls. *Related to: todo_dram_axi.md*
- TODO [P2]: Expose DMA configuration (alignment requirements, BAR sizes) in README/driver docs for users.
- TODO [P2]: Add a driver module param to disable DMA entirely (fall back to stubbed behavior) for debugging.
- TODO [P2]: Add CI to run DMA negative tests (wrap/misaligned) best-effort and report results.
- TODO [P2]: Add a BAR1 window size check/assert in RTL benches to catch mismatches vs. driver expectations.
- TODO [P2]: Add a kselftest that toggles INT_MASK bits and counts interrupts for DMA_DONE vs. BLIT_DONE.
- TODO [P2]: Capture DMA_ERR propagation (stub + driver) and assert it clears correctly after RW1C.
- TODO [P2]: Add build docs for required kernel headers/config options to enable PCIe/MSI paths.
- TODO [P2]: Implement a debugfs toggle for verbose DMA logging (addresses/len/status) at runtime.
- TODO [P2]: Add a "DMA dry-run" ioctl flag (no write) to validate parameters without executing.
- TODO [P2]: Provide a PCI capability dump in driver probe logs (MSI/MSI-X/PCIe caps) for bring-up.
- TODO [P2]: Add a CI artifact to capture dmesg snippets on DMA test failures for quicker triage.
- TODO [P2]: Integrate DMA blit/IRQ tests into a single userspace harness for consolidated reporting.
- TODO [P2]: Build a DMA health dashboard (driver/libhydra metrics) showing in-flight bytes, pending ops, and long-running transfers for nightly checks. *Related to: todo_dma_structured_logging.md*
- TODO [P2]: Automate DMA descriptor validation (alignment, length, overlap) inside the driver and log erroneous descriptors via `scripts/todo_inspect.py`.
- TODO [P2]: Add validation that DMA aligns with PCIe maximal payload sizes (check `DMA_LEN` vs. negotiated MP) and document required driver behavior.
- TODO [P2]: Instrument BAR0/BAR1 register snapshots (with timestamp) so the trace artifacts include address windows for reproducing bad transfers. *Related to: todo_dma_trace_artifacts.md*
- TODO [P2]: Add AXI burst support or stubbed burst handling in the DMA engine (currently single-beat). *Depends on: todo_dram_axi.md P1 burst work*

## P3 - Low Priority (Advanced Features & Documentation)

**Dependencies:** Requires P2 testing infrastructure

- TODO [P3]: Implement MSI-X support with separate vectors for frame/DMA/blit if hardware permits.
- TODO [P3]: Document the DMA hang/retry policy and bring-up actions. *See: `docs/todo/todo_dma_hang_policy.md`*
- TODO [P3]: Define structured DMA logging schema and ingestion scripts. *See: `docs/todo/todo_dma_structured_logging.md`*
- TODO [P3]: Capture PCIe hotplug workflows and ensure DMA state cleans up. *See: `docs/todo/todo_dma_hotplug.md`*
- TODO [P3]: Build a DMA trace artifact pipeline for CI and nightly runs. *See: `docs/todo/todo_dma_trace_artifacts.md`*
- TODO [P3]: Document fallback behaviors (DMA disabled, legacy INTx) inside `docs/todo/todo_driver_integration.md` so bring-up teams know how to toggle modes quickly.

---

## Priority Summary

- **P0:** 9 items (all DONE) - Foundation complete ✅
- **P1:** 11 items - Core functionality, validation, FPGA deployment blockers
- **P2:** 29 items - Testing, CI, debugging infrastructure, stress testing
- **P3:** 6 items - Advanced features, specialized documentation

**Critical Path for 0.0.7:**
1. P1 DMA data integrity (non-zero writes)
2. P1 kselftest suite for IOCTL validation
3. P1 IOMMU/VT-d support for deployment

**Next Steps:** Focus on P1 items, especially DMA kselftests and PCIe error injection for robustness validation.
