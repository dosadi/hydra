# Hydra DRAM / AXI Integration Notes

Purpose: align SDRAM stub/AXI behavior with driver expectations for BAR1/framebuffer traffic.

Clocking/reset
- Assume single clock/reset for AXI-lite (CSRs) and AXI master (DMA/FB) unless explicitly split; document if dual-clock.
- Assert all AXI signals low on reset; add SVAs to catch X/Z during/after reset.

Addressing/widths
- Keep AXI address width aligned with BAR1 size; document any truncation or upper bits ignored.
- Define and document AXI data width (current 32-bit); keep strobes honored for partial writes.
- Forbid bursts crossing BAR1 size; add assertions in benches.

Latency/backpressure
- Use SDRAM stub params (READ_LATENCY/WRITE_LATENCY/JITTER) to emulate realistic waits; provide a “slow DRAM” preset.
- Add benches that inject backpressure on AW/W/AR/R and ensure DMA/CSR paths stall cleanly (no X propagation).
- Consider outstanding transaction limits; assert or parameterize if only single outstanding is supported.

Protocol hygiene
- SVAs for valid/ready handshakes, response codes (OKAY only unless errors injected), and stability of rdata until rready.
- Enforce valid-before-ready, wlast assertions (even for single-beat), and bresp/rresp values.
- Add a watchdog for transactions stuck valid without ready for N cycles in sim to catch deadlocks early.

Observability
- Expose counters (reads/writes, stall cycles) via CSR or debugfs for profiling.
- Provide a cocotb trace/CSV of AXI transactions in stress benches for debugging mismatches.
- Document expected latency/perf targets and how to tune stub params to approximate hardware.
