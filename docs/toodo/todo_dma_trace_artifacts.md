# DMA Trace Artifact TODOs

Details how to capture DMA events as reproducible artifacts (logs/vcd/dmesg) for CI triage and manual debugging.

- **TODO [P2]:** Specify what trace data should be captured when a DMA failure occurs (frame number, offsets, status bits, PCIE state) and store as JSON + raw log.
  - Effort: 1 day
  - Deliverable: Artifact schema doc + example artifacts

- **TODO [P2]:** Automate `scripts/todo_trace_collect.sh` that runs DMA tests, captures dmesg/syslog, copies logs into `out/driver-coverage/` and optionally archives them for CI.
  - Effort: 1.5 days
  - Deliverable: script + README entry

- **TODO [P3]:** Add CNA/perf-style snapshot hooking so failing DMA tests emit per-byte histograms and store them alongside frames in artifacts.
  - Effort: 2 days
  - Deliverable: `scripts/dma_artifact_snapshot.sh`
- **TODO [P3]:** Document artifact formats and thresholds (max latency, CRC variance) so triage knows when to escalate.
- **TODO [P3]:** Pipe artifact statuses into `scripts/todo_inspect.py` so the rebalance-runner sees DMA artifact coverage gaps.
- **TODO [P1]:** Capture VCD/trace dumps focused on DMA channels whenever a hang or error is detected, streaming the dumps into `out/dma-traces/` and linking them from nightly CI reports.
  - Effort: 1.5 days
  - Deliverable: Trace-capture workflow doc + updated CI job
- **TODO [P2]:** Build `scripts/dma_artifact_report.py` that summarizes captured trace/vlog artifacts, attaches metadata (frame, bar info), and publishes the report with PASS/FAIL heuristics.
  - Effort: 1 day
  - Deliverable: Report script + sample output JSON
