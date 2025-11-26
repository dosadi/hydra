# System FPS TODO Tracker

**Focus:** Keep the renderer/router/present pipeline as close to the target frame rate as possible by instrumenting metrics, improving fast paths, and capturing regressions.

## Instrumentation & Monitoring
- **TODO [P1]:** Add HUD and backend logging for `frames_rendered`, `pixels_written_this_frame`, and `frame_time` so runs clearly show whether the simulator is hitting 60 FPS (or whatever `HYDRA_FPS_TARGET` is) in real time.
- **TODO [P2]:** Emit structured FPS metrics (timestamp, fps, frame_time, pixel coverage) to `scripts/todo_inspect.py` via JSON or CSV so nightly sweeps can trend regressions.
- **TODO [P2]:** Integrate `scripts/hydra_fps_benchmark` (referenced in `docs/hdmi_scanout_architecture.md`) into CI jobs so commits can flag FPS drops automatically.
- **TODO [P3]:** Track GPU/backend present latency (SDL vs. platform backend) and surface it in a HUD overlay line labeled “present lag” to correlate render time vs. display handshake.

## Optimization Targets
- **TODO [P1]:** Add a fast mode that skips HUD/minor overlays when frames are under the FPS target (`HYDRA_RENDER_FASTPATH` idea from `docs/render_pipeline_layers.md`), letting the renderer dedicate CPU cycles to ray marching.
- **TODO [P2]:** Profile `cycles_per_chunk` vs. `frame_time` to detect when the ray loop exceeds the budget; if a frame is taking too long, automatically reduce `RAY_STEP_SHIFT` or limit extra-light passes for that frame only.
- **TODO [P2]:** Add an `fps_guard` flag that clamps camera updates or pauses `ray_jitter` when FPS dips below a threshold, giving users gradual control to restore smoothness without restarting the sim.
- **TODO [P3]:** Instrument `framebuffer` coverage (how many pixels were actually written) and log when the raycaster fails to write all 480×360 pixels, highlighting wasted cycles or early exits that kill throughput.

## Benchmarks & Regression Tasks
- **TODO [P1]:** Define a golden `fps_bench.cfg` (camera path + render flags) that reproduces the slowest known scene; run it nightly and diff `frame_time`/`pixel_word` stats to guard against regressions.  
- **TODO [P2]:** Capture the “fast path” vs. “slow path” frame times (e.g., `diag_slice` on/off, extra light on/off) so the team knows which toggles cost how much and can document them in HUD hints.
- **TODO [P2]:** Add unit tests that assert `frame_time` stays under a budget for synthetic scenes (small number of voxels) so RTL changes that blow up ray steps fail fast.
