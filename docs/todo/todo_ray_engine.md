# Hydra Ray Engine TODOs (0.0.7 Cycle)

**Focus:** Ray math validation, debug visualization, performance profiling.
See `docs/TODO_MASTER_INDEX.md` for complete tracker reference. Most items are P2/P3 (advanced features deferred post-0.0.7).

## P1 - High Priority (Validation & Safety)

- TODO [P1]: Add a "ray math" spec note documenting coordinate system, handedness, and plane vectors to keep code/tests aligned.
- TODO [P1]: Add a watchdog/assert that the ray FSM returns to idle on soft_reset within N cycles (hang guard).
- TODO [P1]: Add assertions that ray state resets on soft_reset/start_frame (no stale hits).
- TODO [P1]: Implement a sanity check that rays respect VOXEL_GRID_SIZE bounds (assert on overflow).
- TODO [P1]: Implement a timeout/assertion for rays that exceed expected max steps (hang detection).
- TODO [P1]: Add assertions that ray outputs (coords/material) are valid only when pixel_write_en is high.
- TODO [P1]: Add coverage that auto-start/soft-reset clears ray state and counters.
- DONE [P1]: Document how diag_slice should alter ray traversal (expected slice masks); matching assertions remain a follow-up.

## P2 - Medium Priority (Testing & Coverage)

- TODO [P2]: Provide a tiny fixed-scene golden test that logs first N ray hits/misses for reproducibility in CI.
- TODO [P2]: Add coverage that selection rays (cursor) align with voxel edit coordinates (C/X/Z/B).
- TODO [P2]: Add a cocotb bench that compares ray hit coordinates vs. a known voxel scene (expected hits).
- TODO [P2]: Add coverage for diag_slice flag impact on ray traversal (skip slices correctly).
- TODO [P2]: Add coverage that rays terminate on selection edits and resume correctly after updates.
- TODO [P2]: Provide a cocotb monitor that logs ray hits/misses for a small scene and compares to expected counts.
- TODO [P2]: Add a small unit bench to validate ray-plane intersections against analytic expectations.
- TODO [P2]: Add coverage for different ray step sizes (small/large) to ensure stability across settings.
- TODO [P2]: Implement a test that toggles diag_slice mid-frame and verifies ray traversal behavior.
- TODO [P2]: Provide a small ray/voxel collision fuzz test to shake out edge cases at volume boundaries.
- TODO [P2]: Add coverage for negative/edge camera angles to ensure ray math holds across quadrants.
- TODO [P2]: Expose ray hit/miss counts via CSR for quick regression checks in benches.
- TODO [P2]: Add directed tests that record ray step distributions and export JSON for the AI dashboard so regressions in the ray engine raise alerts via `scripts/ai_health_dashboard.py`.
- TODO [P2]: Create a ray engine performance harness that runs in headless mode, logs timing/pixel counters, and stores artifacts under `out/ray_performance/` for cross-tracker dashboards.

## P3 - Low Priority (Advanced Features & Debug Tools)

- TODO [P3]: Add a debug knob to clamp rays to a bounding box smaller than the full volume for perf sweeps.
- TODO [P3]: Refine raystep algorithm (step size vs. voxel crossing) to reduce aliasing and overstepping.
- TODO [P3]: Add per-material ray termination rules (e.g., stop on opaque, continue on translucent).
- TODO [P3]: Implement max recursion/step clamp with runtime overrides for perf/quality sweeps.
- TODO [P3]: Add a debug mode to visualize ray paths/steps for selected pixels (HUD overlay).
- TODO [P3]: Provide ray depth histogram per frame to guide performance tuning (per-frame ray-step metrics now surfaced in the HUD).
- TODO [P3]: Integrate support for runtime-adjustable RAY_STEP_SHIFT and MAX_RAY_STEPS (env/hotkey).
- TODO [P3]: Implement a "ray miss" visualization (mark pixels where rays escape the volume).
- TODO [P3]: Provide a ray cache/per-frame stats HUD (hits/misses, avg steps, max steps).
- TODO [P3]: Expose ray origin/direction for the cursor ray via debug HUD for alignment debugging.
- TODO [P3]: Add a "single-step ray" debug mode to advance one ray step per keypress for inspection.
- TODO [P3]: Implement a per-material refractive/transparent mode (skip or attenuate) in the ray marcher.
- TODO [P3]: Add a perf counter for ray loop iterations (total/avg) exposed via CSR/HUD for profiling.
- TODO [P3]: Add a debug mode to visualize ray directions as on-screen arrows for a grid of sample pixels.
- TODO [P3]: Implement runtime-adjustable ray seed/noise for reproducible vs. varied scenes.
- TODO [P3]: Provide a "ray inspector" HUD showing hit voxel coords/material/emissive for the cursor.
- TODO [P3]: Provide an env/hotkey to clamp max rays per frame for perf experiments.
- TODO [P3]: Add a debug toggle to color-code rays by step count (heatmap) in the framebuffer.
- TODO [P3]: Add a "ray replay" mode that logs cursor ray params and replays them for debugging.
- DONE [P3]: Add a runtime "ray jitter" option to reduce banding and improve visual smoothing; toggled via the `J` key / `HYDRA_RAY_JITTER`.
- TODO [P3]: Create a ray engine roadmap section (under this tracker) that outlines when new product lines or big features require additional TODO coverage, so the tracker remains flexible for everything from bugfixes to large system efforts.
