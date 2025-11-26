# HDMI Stream & Backpressure TODOs

Focuses on the raw pixel stream, tile/frame buffering, CRC registers, and fault/integration coverage needed for simulation/driver agreement.

- **TODO [P1]:** Document the pixel format (RGB888) packing in `m_axis_tdata` and add simulation asserts ensuring no other bits leak into CRC.
- **TODO [P1]:** Add a stream backpressure stress test (inject wait-states) to the DMA pipeline to ensure the HDMI path tolerates stalls.
- **TODO [P1]:** Extend HDMI stream telemetry (beat_count, crc_err) into `scripts/hardware_health_summary.py` and expose alerts in the AI dashboard when stream counters drift.
- **TODO [P1]:** Create a HDMI-to-DMA synchronization test that toggles stream pause/resume while DMA bursts continue, validating the FIFO fill-level tracking.
- **TODO [P2]:** Capture CRC compare logs in `sim/tests` and provide a script that highlights frame drops or mismatched CRCs.
- **TODO [P2]:** Add a driver verification test that toggles SDL backends while capturing CRCs for subsequent diff.
- **TODO [P2]:** Automate streaming capture via `scripts/ci_collect_logs.sh` to snapshot HDMI backpressure metrics and attach to the AI health dashboard artifact.
- **TODO [P2]:** Add coverage for HDMI stream timestamping (frame start/end markers) and ensure the logs include jitter metrics for each run.
- **TODO [P3]:** Provide a README section on HDMI drift (line/field jitter) for integrators, referencing required counters/thresholds.
- **TODO [P3]:** Document the HDMI stress-test checklist (injecting wait-states, CRC mismatch, forced backpressure) with expected log outputs.
- **TODO [P3]:** Explore hardware-assisted stream capture using ILA/VIO to record `m_axis_tdata` sequences for offline analysis, referencing `todo_hardware_validation.md`.
