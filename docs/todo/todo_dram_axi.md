# Hydra DRAM / AXI Path TODOs (0.0.7 Cycle)

**Focus:** Protocol compliance (SVAs), backpressure handling, formal validation.
See `docs/TODO_MASTER_INDEX.md` for complete tracker reference.

**Related Trackers:** `todo_dma_pcie.md`, `todo_hardware_validation.md`, `todo_ip_integration.md`

---

## P0 - Critical (Completed)

- DONE [P0]: Publish a DRAM/AXI integration note (clock/reset domains, address map, latency knobs) for FPGA bring-up (`docs/dram_axi_integration.md`).
- DONE [P0]: Add AXI backpressure handling in DMA path (stall/write buffering) for awready/wready deassertions (DMA stub now sequences AW/W/B with ready gating; burst writer still stubbed to zero data).
- DONE [P0]: Add SVAs around AXI write/read channels (valid/ready handshake correctness, no X/Z) (master stability SVAs added in voxel_axi_core).

## P1 - High Priority (Protocol Compliance & Core Functionality)

**Dependencies:** Requires P0 SVAs and backpressure handling to be complete

- TODO [P1]: Add AXI-lite SVAs for CSR accesses (address alignment, no mixed read/write hazards). *Depends on: P0 SVA framework*
- TODO [P1]: Add assertions that AXI signals are deasserted on reset and no X/Z propagate. *Depends on: P0 SVAs*
- TODO [P1]: Implement AXI burst support in DMA engine (awlen/wlast) or assert single-beat constraints clearly. *Critical for: DMA performance*
- TODO [P1]: Document AXI signal mapping and SDRAM stub behavior in the spec/README for bring-up. *Blocking: FPGA integration*
- TODO [P1]: Add a simple AXI compliance checklist (valid-before-ready, reset behavior, strobe usage). *Depends on: SVAs complete*
- TODO [P1]: Add coverage/assertions for AXI-lite response codes (always OKAY or documented errors). *Depends on: P0 SVAs*
- TODO [P1]: Implement a watchdog/assertion for AXI transactions stuck valid without ready (timeout). *Critical for: hang detection*
- TODO [P1]: Add AXI-lite register reset-value checks to ensure CSRs come up to spec defaults. *Blocking: driver integration*
- TODO [P1]: Provide documentation on AXI clock/reset domain expectations (single domain vs. separate). *Blocking: FPGA integration*
- TODO [P1]: Add coverage that AXI-lite read data is stable until rready is asserted. *Depends on: P0 SVAs*
- TODO [P1]: Implement parameterized AXI address width to align with BAR1 sizing and driver expectations. *Blocking: IP integration*

## P2 - Medium Priority (Testing & Validation)

**Dependencies:** Requires P1 protocol compliance items

- TODO [P2]: Add a cocotb-based AXI protocol checker wrapper (or hook up axi-lite-bfm) to automate handshake validation. *Depends on: P1 SVAs*
- TODO [P2]: Provide a "slow DRAM" preset (high latency/jitter) in benches and run it in CI to catch marginal timing.
- TODO [P2]: Add a doc + test that cross-checks BAR1 size vs. AXI address width to avoid silent truncation. *Depends on: P1 param work*
- TODO [P2]: Add a regression that runs simultaneous DMA + CSR traffic while sampling stall counters to guard against starvation.
- TODO [P2]: Provide an AXI waitstate injector in benches to stress SDRAM stub under stalls.
- TODO [P2]: Add coverage that SDRAM stub wait parameters (READ_LATENCY/WRITE_LATENCY/JITTER) produce expected delays.
- TODO [P2]: Add a bench to validate AXI write data integrity under interleaved backpressure.
- TODO [P2]: Expose AXI/SDRAM counters (reads/writes, stalls) via CSR or debugfs for profiling.
- TODO [P2]: Add a "DRAM hexdump" bench to verify data consistency after DMA + SDRAM writes under latency.
- TODO [P2]: Provide a bench that randomizes AXI IDs (if supported) to validate interleaving or assert single-ID use.
- TODO [P2]: Add coverage that AXI write strobes are respected in SDRAM stub (masking partial writes).
- TODO [P2]: Implement an error injection mode in SDRAM stub (returning SLVERR/DECERR) and ensure driver responds gracefully.
- TODO [P2]: Add CI to run AXI waitstate stress benches and report stall/read/write counters.
- TODO [P2]: Add a bench that mixes read/write bursts to ensure arbitration fairness (or document single-port behavior).
- TODO [P2]: Implement configurable AXI outstanding transaction limits in SDRAM stub and verify backpressure.
- TODO [P2]: Add coverage for AXI burst boundaries not crossing SDRAM size (assert on overflow).
- TODO [P2]: Add a bench that validates AXI-lite CSR read/write ordering (no overlapping transactions).
- TODO [P2]: Add a "sanity" AXI-lite fuzzer to poke CSRs randomly and verify stable behavior/no X.
- TODO [P2]: Implement a hook to dump AXI transactions to a log for debugging (sim-only).
- TODO [P2]: Add a CI artifact upload for AXI waveform snippets when AXI benches fail.
- TODO [P2]: Provide an AXI-lite negative test (bad addresses/unaligned) and verify driver/RTL responses.
- TODO [P2]: Add a bench to verify CSR writes don't interfere with DMA/AXI master channels (no unintended coupling).
- TODO [P2]: Add back-to-back AXI write/read stress bench to check for missed ready/valid pulses.
- TODO [P2]: Add coverage that AXI-lite read data is stable until rready is asserted.
- TODO [P2]: Provide an AXI transaction trace in cocotb (JSON/CSV) for debugging mismatches.
- TODO [P2]: Add coverage that simultaneous DMA + CSR traffic does not deadlock or starve either channel.
- TODO [P2]: Provide a script to diff CSR map vs. RTL/driver headers to catch drift. *Related to: documentation.md*
- TODO [P2]: Add coverage that AXI-lite byte strobes work correctly (partial write merges) in CSR block.
- TODO [P2]: Implement a cocotb-based AXI protocol checker (or integrate existing library) for validation. *Depends on: P1 SVAs*
- TODO [P2]: Add CI job to run AXI-lite protocol lint (verilator --lint-only with AXI assertions enabled).
- TODO [P2]: Add backpressure coverage for AXI read channel (arready/rvalid under stalls).
- TODO [P2]: Provide a bench that exercises simultaneous AXI read/write to overlapping addresses to confirm ordering rules.
- TODO [P2]: Implement a CSR read-back self-test in sim that sweeps registers to catch unexpected side effects.
- TODO [P2]: Add coverage that AXI ID fields (if unused) stay constant/zero to avoid unused bits warnings.

## P3 - Low Priority (Advanced Features & Optimization)

**Dependencies:** Requires P2 testing infrastructure

- TODO [P3]: Provide a simple AXI performance counter (throughput/latency) exposed via CSR for profiling.
- TODO [P3]: Provide a pipeline depth parameter for AXI paths to explore timing/perf tradeoffs.
- TODO [P3]: Add doc notes on AXI-lite CSR address map stability and reserved ranges.
- TODO [P3]: Add lint-style checks for AXI signal naming/width consistency across modules.
- TODO [P3]: Add a simple AXI throughput benchmark (sim) to measure sustained bandwidth under zero stalls.
- TODO [P3]: Document expected AXI latency/perf targets and how to tune stub parameters to match hardware.
- TODO [P3]: Add documentation on AXI-lite timing expectations for external masters (min/max wait states).
- TODO [P3]: Implement parameterized AXI data width for future expansion (document constraints).

---

## Priority Summary

- **P0:** 3 items (all DONE) - Foundation complete ✅
- **P1:** 11 items - Protocol compliance & core functionality (blocking FPGA)
- **P2:** 35 items - Testing, validation, CI infrastructure
- **P3:** 8 items - Advanced features & optimization

**Next Steps:** Focus on P1 items for 0.0.7 release, especially AXI-lite SVAs and burst support.
