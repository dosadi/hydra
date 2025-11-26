# DMA Structured Logging TODOs

Tracks improvements to DMA logging so automation and CI can parse transfer stats, error counts, and latency without manual grep.

- **TODO [P2]:** Define structured DMA log schema (JSON or YAML) that includes timestamp, IRQ type, offset, len, status bits, and latency; document fields in `docs/dma_logging_spec.md`.
  - Effort: 1 day
  - Deliverable: Schema doc + example log snippet

- **TODO [P2]:** Emit structured logs from the driver when DMA starts/finishes/errors; send to `trace_printk`/tracepoint with consistent tag for converters.
  - Effort: 1.5 days
  - Deliverable: driver patch + sample log

- **TODO [P2]:** Add `scripts/parse_dma_logs.py` that aggregates structured logs into counters (bytes, errors, avg latency) and writes CSV for CI artifacts.
  - Effort: 1 day
  - Deliverable: Python script + usage docs

- **TODO [P3]:** Integrate log ingestion into `todo_sweep.py` or a companion script to highlight regressions (e.g., latencies spiking vs. baseline).
  - Effort: 1.5 days
  - Deliverable: Optional extension or documentation note

- **TODO [P3]:** Define structured log retention/rotation policy and publish `scripts/log_cleanup.sh` to rotate JSON/CSV logs after CI runs.
- **TODO [P3]:** Link the structured logs to `todo_debugging_tools.md` by documenting how to feed them into `scripts/todo_inspect.py` for quick DMA diagnostics.
- **TODO [P1]:** Extend `scripts/todo_inspect.py` with a DMA log parser that surfaces running latency/bytes stats on the HUD, so that CI traces show when a transfer is missing.
  - Effort: 1.5 days
  - Deliverable: Parser module + README snippet that shows the JSON fields and HUD mapping
- **TODO [P2]:** Provide a `scripts/dma_log_timeline.py` helper that stitches driver/RTL structured logs together into a flame-graph-friendly CSV, enabling `todo_rebalance.py` to flag regressions by timestamp.
  - Effort: 1 day
  - Deliverable: Python helper + CI sample output
