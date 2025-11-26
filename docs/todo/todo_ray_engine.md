# Hydra Ray Engine TODOs (0.0.7 Cycle)

**Focus:** Ray math validation, debug visualization, performance profiling.
See `docs/todo/todo_prioritization.md` for sprint plan. Most items are P2/P3 (defer advanced features).

- TODO: Add a “ray math” spec note documenting coordinate system, handedness, and plane vectors to keep code/tests aligned.
- TODO: Provide a tiny fixed-scene golden test that logs first N ray hits/misses for reproducibility in CI.
- TODO: Add a watchdog/assert that the ray FSM returns to idle on soft_reset within N cycles (hang guard).
- DONE: Document how diag_slice should alter ray traversal (expected slice masks); matching assertions remain a follow-up.
- TODO: Add a debug knob to clamp rays to a bounding box smaller than the full volume for perf sweeps.
- TODO: Refine raystep algorithm (step size vs. voxel crossing) to reduce aliasing and overstepping.
- TODO: Add per-material ray termination rules (e.g., stop on opaque, continue on translucent).
- TODO: Implement max recursion/step clamp with runtime overrides for perf/quality sweeps.
- TODO: Add a debug mode to visualize ray paths/steps for selected pixels (HUD overlay).
- TODO: Provide ray depth histogram per frame to guide performance tuning (per-frame ray-step metrics now surfaced in the HUD).
- TODO: Add assertions that ray state resets on soft_reset/start_frame (no stale hits).
- TODO: Integrate support for runtime-adjustable RAY_STEP_SHIFT and MAX_RAY_STEPS (env/hotkey).
- TODO: Add coverage that selection rays (cursor) align with voxel edit coordinates (C/X/Z/B).
- TODO: Implement a “ray miss” visualization (mark pixels where rays escape the volume).
- TODO: Add a cocotb bench that compares ray hit coordinates vs. a known voxel scene (expected hits).
- DONE: Add a runtime “ray jitter” option to reduce banding and improve visual smoothing; toggled via the `J` key / `HYDRA_RAY_JITTER`.
- TODO: Provide a ray cache/per-frame stats HUD (hits/misses, avg steps, max steps).
- TODO: Implement a sanity check that rays respect VOXEL_GRID_SIZE bounds (assert on overflow).
- TODO: Add coverage for diag_slice flag impact on ray traversal (skip slices correctly).
- TODO: Expose ray origin/direction for the cursor ray via debug HUD for alignment debugging.
- TODO: Add a “single-step ray” debug mode to advance one ray step per keypress for inspection.
- TODO: Implement a per-material refractive/transparent mode (skip or attenuate) in the ray marcher.
- TODO: Add coverage that rays terminate on selection edits and resume correctly after updates.
- TODO: Provide a cocotb monitor that logs ray hits/misses for a small scene and compares to expected counts.
- TODO: Add a perf counter for ray loop iterations (total/avg) exposed via CSR/HUD for profiling.
- TODO: Add a debug mode to visualize ray directions as on-screen arrows for a grid of sample pixels.
- TODO: Implement runtime-adjustable ray seed/noise for reproducible vs. varied scenes.
- TODO: Add coverage that auto-start/soft-reset clears ray state and counters.
- TODO: Provide a “ray inspector” HUD showing hit voxel coords/material/emissive for the cursor.
- TODO: Add a small unit bench to validate ray-plane intersections against analytic expectations.
- TODO: Add coverage for different ray step sizes (small/large) to ensure stability across settings.
- TODO: Provide an env/hotkey to clamp max rays per frame for perf experiments.
- TODO: Add assertions that ray outputs (coords/material) are valid only when pixel_write_en is high.
- TODO: Implement a test that toggles diag_slice mid-frame and verifies ray traversal behavior.
- TODO: Add a debug toggle to color-code rays by step count (heatmap) in the framebuffer.
- TODO: Add a “ray replay” mode that logs cursor ray params and replays them for debugging.
- TODO: Implement a timeout/assertion for rays that exceed expected max steps (hang detection).
- TODO: Provide a small ray/voxel collision fuzz test to shake out edge cases at volume boundaries.
- TODO: Add coverage for negative/edge camera angles to ensure ray math holds across quadrants.
- TODO: Expose ray hit/miss counts via CSR for quick regression checks in benches.
