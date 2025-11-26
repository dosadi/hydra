# AXI Memory Subsystem TODOs

Complements `todo_dram_axi.md` by focusing on streaming/AXI memory interfaces, DMA reads/writes, and capture of AXI-related errors in both RTL and drivers.

- **TODO [P1]:** Document the expected AXI transaction patterns (burst lengths, IDs, QoS) for DMA and framebuffer paths; include annotated Waveform snapshots.
  - Effort: 1 day
  - Deliverable: Markdown doc with waveform screenshots

- **TODO [P1]:** Create a small RTL helper that logs AXI read/write bursts (addresses, burst length, ready/valid toggles) when `TRACE_AXI=1`, then collect logs during simulation.
  - Effort: 2 days
  - Deliverable: Logging module + docs describing the log format

- **TODO [P2]:** Add driver-side AXI error handling notes (SLVERR/DECERR semantics, retries, fallbacks) referencing `todo_dma_pcie.md`.
  - Effort: 1 day
  - Deliverable: Section in this tracker with cleanup steps

- **TODO [P2]:** Tie AXI metrics (backpressure counts, stalled cycles) into `docs/todo/todo_performance.md` and cross-link to `scripts/todo_sweep.py` for automated reporting.
  - Effort: 1 day
  - Deliverable: Cross-reference doc plus script mention
- **TODO [P1]:** Instrument the AXI paths with error injection knobs (flip DECERR/SLVERR, insert wait states) to verify driver and RTL guards handle the faults gracefully.
- **TODO [P2]:** Add a memory capture tool (`scripts/axi_capture.py`) that samples AXI transactions and writes JSON/CSV for offline visualization and diffing between simulator runs.
- **TODO [P3]:** Document AXI lane retry policies for high-latency peripherals (such as PCIe) to explain what the RTL/driver should do when downstream devices respond slowly.
- **TODO [P2]:** Include AXI coverage points (burst size, QoS combos) in `scripts/todo_rebalance.py` reports so under-tested modes get flagged automatically.
