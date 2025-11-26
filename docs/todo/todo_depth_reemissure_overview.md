# Depth & Reemissure Overview

Depth coverage for Hydra now splits cleanly between the depth buffer instrumentation/visualization work and the reemissure/emissive sidecar telemetry. This tracker helps contributors navigate the structure:

- **Depth buffer**: see `docs/todo/todo_depth_buffer.md` for range conventions, fog/SSAOs, histograms/HUD overlays, and regression coverage that keeps depth monotonic and reset values stable.
- **Reemissure**: see `docs/todo/todo_reemissure.md` for payload semantics, instrumentation (histograms, dumps, CLI/AI hooks), assertions that guard emissive writes, and viewer tooling for emissive-only analysis.
- **Dependencies**: both depth and reemissure feed back into the rendering color pipeline (`docs/todo/todo_rendering_color_pipeline.md`) and automation dashboards (`scripts/ai_health_dashboard.py`, `scripts/automation_watchdog.sh`); keep this overview in sync with `docs/todo/todo_sector_overview.md` whenever new depth/emissive trackers land.
