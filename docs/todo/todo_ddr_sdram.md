# Hydra DDR/SDRAM TODOs (0.0.7 Cycle)

Focus: stub → real DRAM path, waitstate modeling, and validation for DDR/SDRAM integration.

## P0 (Critical for hardware bring-up)
- Hook DDR/SDRAM controller (LiteDRAM or vendor IP) in place of `axi_sdram_stub` for FPGA builds; keep stub for sim.
- Add AXI waitstate/jitter presets to SDRAM stub and run them in CI (stress awready/wready/arready/rvalid under stalls).
- Ensure DMA honors SDRAM backpressure: extend benches to inject stalls and verify no data loss/ordering issues.
- Add SDRAM size/addr-width checks (BAR1 sizing vs. AXI addr width) with assertions/bench coverage.

## P1 (High)
- Add SDRAM data integrity benches: walking 1s/0s, burst writes/reads under latency, wrap-around boundary checks.
- Expose SDRAM read/write/ stall counters via CSR or debugfs for profiling in sim/hw.
- Implement an error-injection mode in SDRAM stub (SLVERR/DECERR) and verify driver/RTL responses.
- Add SDRAM retention/refresh sanity test (long-run readback) in sim; document expectations for hardware.
- Provide a “slow DRAM” preset (high latency/jitter) and document how to enable it in benches/CI.

## P2 (Medium)
- Add AXI burst boundary coverage to ensure bursts do not cross SDRAM size; assert on overflow.
- Add configurable outstanding transaction limit parameters in SDRAM path to explore perf vs. resource trade-offs.
- Add cocotb SDRAM throughput/latency profiler for sim with optional stall injection.
- Add CI artifact capture (waveform snippets/logs) on SDRAM bench failures for faster triage.

## P3 (Future)
- Integrate a formal/proof-of-concept AXI memory model to check protocol compliance against the SDRAM bridge.
- Add multi-port arbitration tests if/when additional masters (e.g., HDMI reader) are introduced.

Related trackers: `docs/todo/todo_dram_axi.md` (AXI compliance/backpressure), `docs/todo/todo_dma_pcie.md` (DMA path), `docs/todo/todo_hdmi.md` (framebuffer scanout), `docs/todo/todo_hardware_validation` (when reintroduced).***
