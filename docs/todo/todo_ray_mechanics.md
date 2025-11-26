# Hydra Ray Mechanics TODOs

**Focus:** Ray traversal math, debugging hooks, and regression coverage for the marching engine.

## Math & Traversal Fundamentals
- **TODO [P1]:** Produce a concise “ray math” spec that spells out the coordinate system, handedness, voxel grid extents, and plane/origin vectors used by the RTL + viewer so future tweaks have a single source of truth.
- **TODO [P1]:** Add assertions/watchdogs that rays stay inside `VOXEL_GRID_SIZE`, return to `IDLE` within N cycles after `soft_reset`/`world_start`, and honor auto-start flags so stuck FSM states become assert failures.
- **TODO [P2]:** Expose runtime knobs for `RAY_STEP_SHIFT`, `MAX_RAY_STEPS`, bounding-box clamps, and per-material termination behavior so performance/quality explorers can stress different regimes.

## Debug & Visibility
- **TODO [P1]:** Extend the HUD/debug overlay with cursor-ray data (origin, direction), per-pixel hit info, and per-channel heatmaps so engineers can trace how rays interact with `pixel_word1`.
- **TODO [P2]:** Add a single-step ray mode plus “ray miss” coloring overlay for pixels that escape the volume; log the traced ray path to `stderr` when the mode is active.
- **TODO [P3]:** Surface an optional ray replay tool that records cursor ray parameters (origin + direction) and replays them later so regressions can be compared deterministically.
- **TODO [P3]:** Color-code rays by step count in a debug view/heatmap and expose the per-frame histogram (hits/misses/avg steps) via HUD or CSR for quick tuning feedback.

## Testing, Coverage & Automation
- **TODO [P2]:** Build cocotb/unit workflows that compare ray hits against a golden voxel layout with known hit counts; alert on deviations (cursor ray + fixed mesh).
- **TODO [P2]:** Add a regression script that toggles `diag_slice` mid-frame, runs with/without `HYDRA_RAY_JITTER`, records ray-step stats, and emits a CSV for `scripts/todo_inspect.py`.
- **TODO [P2]:** Surface ray hit/miss counters, avg/max steps into CSRs or structured logs so trace parsers can detect regressions without manual inspection.
- **TODO [P3]:** Provide a ray/voxel collision fuzz test (various camera angles/noise) that hunts boundary cases at the edges of the 64³ volume.

## Tooling & Metrics
- **TODO [P2]:** Add `scripts/todo_inspect.py` hooks that consume the new ray stats + color-range data from the HUD, flagging when RGB coverage collapses after RTL tweaks.
- **TODO [P3]:** Document the timing budget for the ray loop (cycles per pixel) and instrument the viewer to report slow frames when ray iterations spike.
- **TODO [P3]:** Expose a HUD toggle or env var that weakens/heightens the coordinate-based color bias so user-visible spikes in the spectrum can be dialed in without recompiling.
- **TODO [P2]:** Feed ray mechanics diagnostics (step counts, misses) into `scripts/ai_health_dashboard.py` so the AI dashboard highlights regressions when the mechanical heuristic distribution shifts.
- **TODO [P2]:** Build a ray profiler that dumps per-frame step histograms to `out/ray_mechanichs_profile.json`, letting automation track changes across bugfixes vs. big feature pushes.
- **TODO [P3]:** Maintain a ray mechanics changelog (versions, racks, per-todo impact) and link to this tracker, so the history captures everything from quick fixes to radical rewrites.
