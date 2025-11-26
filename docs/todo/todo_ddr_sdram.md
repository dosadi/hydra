# Hydra DDR/SDRAM TODOs (0.0.7 Cycle)

Focus: stub → real DRAM path, waitstate modeling, and validation for DDR/SDRAM integration.

## P0 (Critical for hardware bring-up)
- Hook DDR/SDRAM controller (LiteDRAM or vendor IP) in place of `axi_sdram_stub` for FPGA builds; keep stub for sim.
- Add AXI waitstate/jitter presets to SDRAM stub and run them in CI (stress awready/wready/arready/rvalid under stalls).
- Ensure DMA honors SDRAM backpressure: extend benches to inject stalls and verify no data loss/ordering issues.
- Add SDRAM size/addr-width checks (BAR1 sizing vs. AXI addr width) with assertions/bench coverage.
- TODO [P0]: Add DDR PHY timing calibration flow (write leveling, read delay training) to the FPGA bring-up checklist and capture sweep data in `out/`.
- TODO [P0]: Document and verify refresh window bounds (tREFI/tRFC) plus retention tests to prove the real PHY meets SDRAM window requirements (link to `docs/hardware_validation.md` once the section reappears).

## P1 (High)
- Add SDRAM data integrity benches: walking 1s/0s, burst writes/reads under latency, wrap-around boundary checks.
- Expose SDRAM read/write/ stall counters via CSR or debugfs for profiling in sim/hw.
- Implement an error-injection mode in SDRAM stub (SLVERR/DECERR) and verify driver/RTL responses.
- Add SDRAM retention/refresh sanity test (long-run readback) in sim; document expectations for hardware.
- Provide a “slow DRAM” preset (high latency/jitter) and document how to enable it in benches/CI.
- TODO [P1]: Capture DDR training failure signatures (phase mismatches, calibration loops) in `scripts/capture_training.py` so firmware can diagnose PHY issues during bring-up.
- TODO [P1]: Add a DDR/SDRAM clocking independence test that toggles the DDR clock domain (gating/prerun) while checking AXI handshake stability via SVAs.
- TODO [P1]: Create a DDR stress playlist (rapid burst+random backpressure) that can be triggered via `scripts/automated_ddr_check.sh` and relies on the existing bench infrastructure.

## P2 (Medium)
- Add AXI burst boundary coverage to ensure bursts do not cross SDRAM size; assert on overflow.
- Add configurable outstanding transaction limit parameters in SDRAM path to explore perf vs. resource trade-offs.
- Add cocotb SDRAM throughput/latency profiler for sim with optional stall injection.
- Add CI artifact capture (waveform snippets/logs) on SDRAM bench failures for faster triage.
- TODO [P2]: Generate DDR power/timing reports by capturing PHY timing registers (tRCD/tRP/tRAS) in `docs/todo/todo_hardware_validation.md` when available.
- TODO [P2]: Automate `scripts/ai_health_dashboard.py` to include DDR-specific metrics (unknown counters from this tracker) in the AI briefing so the dashboard highlights DDR regression risk.
- TODO [P2]: Document the mapping between SDRAM ability and the `todo_dependency_map` sectors so we know which TODOs block the PCIe/HDMI stack.

## P3 (Future)
- Integrate a formal/proof-of-concept AXI memory model to check protocol compliance against the SDRAM bridge.
- Add multi-port arbitration tests if/when additional masters (e.g., HDMI reader) are introduced.
- TODO [P3]: Explore a combined Verilog/SystemVerilog + DDR model that lets Cocotb drive hisense DDR sequences and validates them, pushing toward next-level automation.
- TODO [P3]: Draft a “DDR playbook” doc referencing this tracker, the AI dashboard, and the hardware validation checklist so contributors can respond to regression alerts quickly.

Related trackers: `docs/todo/todo_dram_axi.md` (AXI compliance/backpressure), `docs/todo/todo_dma_pcie.md` (DMA path), `docs/todo/todo_hdmi.md` (framebuffer scanout), `docs/todo/todo_hardware_validation` (when reintroduced).***
