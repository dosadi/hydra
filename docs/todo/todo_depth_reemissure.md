# Hydra Depth and Reemissure Index

Depth and reemissure belong to two different signal domains—fog/depth processing lives in the camera/render pipeline, while reemissure deals with emissive-bandwidth telemetry from the ray pipeline. This landing page keeps them distinct so contributors land directly on the right tracker.

## Sector 1: Depth buffer (rendering pipeline)

- File: `docs/todo/todo_depth_buffer.md`
- Focus: depth ranges, fog/SSAO experiments, histogram counters, HUD overlays, and verifying camera clears/precision.
- Priority: P1 for fog/SSAO gating; P2/P3 for visualization tools and perf tuning.
- For automation: link to `scripts/check_frame.py` histograms when adding depth-based HUD stats.

## Sector 2: Reemissure semantics

- File: `docs/todo/todo_reemissure.md`
- Focus: emissive sideband instrumentation, differential assertions, math-driven shading improvements, and emissive histograms.
- Priority: P1 for emitter validation (reprojection, energy conservation), P2/P3 for advanced histogram tooling and narrative docs.
- For testing: capture emissive-region dumps via `sim/viewer.cpp` HUD overlays and archive to `docs/render_pipeline_layers.md` when adjusting shading logic.
