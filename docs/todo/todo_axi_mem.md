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
