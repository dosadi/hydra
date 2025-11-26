# Watermark FIFO & Flow Control TODOs

Focuses on FIFO thresholds, watermark logic, and flow control to prevent overrun/underrun between Hydra subsystems (DMA, HDMI, debug).

- **TODO [P1]:** Define watermark thresholds for DMA/HDMI FIFOs (high/low) and document them in `docs/watermarks.md` so automation can check if hardware respects the bounds.
- **TODO [P1]:** Add LUT/tables exposing watermark counters and status to registers so diagnostics know when thresholds are crossed; surface warnings via `scripts/ai_health_dashboard.py`.
- **TODO [P2]:** Create verification benches that inject bursts and confirm watermark signals trigger interrupts or backpressure as expected (log passes/fails to `out/watermark_validation.json`).
- **TODO [P3]:** Add user-level controls (env/hotkey) to force FIFO flush or drain for debugging/cleanup flows, and ensure the AI dashboard records usage stats per session.
