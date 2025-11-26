# Hydra Rendering Pipeline TODOs (Raycaster / Shader Path) - 0.0.7 Cycle

**Focus:** Pipeline profiling, BRDF refinement, shader debugging.
See `docs/todo/todo_prioritization.md` for sprint plan. Most items are P2 (nice-to-have).

- TODO [P1]: Capture a baseline instrumentation sweep (ray loop, framebuffer copy, HUD) and publish CSV/plot artifacts so `todo_system_fps.md` can cite concrete regression numbers.
- TODO [P2]: Separate render pipeline config into a struct and plumb through env/HUD so presets can toggle AA/fog/tonemap in one place.
- TODO [P2]: Add a simple correctness test scene (few voxels with known normals/emissive) and compare rendered pixels against golden hashes.
- TODO [P2]: Measure and document bandwidth for framebuffer uploads/copies; add an optional “skip HUD” flag in the pipeline to isolate cost.
- TODO [P2]: Provide a shader/pipeline debug dump (current MAX_RAY_STEPS, STEP_SIZE, shading flags) in the HUD for quick verification.
- TODO [P2]: Refine BRDF shading model (diffuse/specular balance) and normalize energy for emissive + lit surfaces.
- TODO [P2]: Add per-material roughness/metallic parameters and propagate into the raycaster for highlight shaping.
- TODO [P2]: Implement soft shadowing in the raystep loop (penumbra approximation) without large perf hit.
- TODO [P2]: Add a “surface extractor” pipeline stage that records the first hit’s normal/depth/color into a separate buffer (see `docs/mathematical_surface_analysis.md` for the shading math), then expose it via the viewer for downstream debug or SSAO tooling.
- TODO [P2]: Instrument the surface extractor to emit CSV logs of hit normals/curvature for a fixed sample column so offline scripts can verify shading changes across render updates.
- TODO [P1]: Model the surface extractor shading weight as a nonlinear summation of neighboring voxel normals (e.g., Shepard interpolation) and expose the recomputed normal vector via the debug overlay.
- TODO [P2]: Add a CLI config (`SURFACE_BAND_MODE=[linear|nonlinear]`) to switch between normal-based smoothing modes and tune the banding curves; log those settings in `scripts/todo_inspect.py`.
- TODO [P2]: Build a test harness that renders the same column at multiple angle increments to verify the smooth shading wrap produced by the normal summation and compare to the expected banded curve.
- TODO [P3]: Document the math used (normal vector summation, weighting kernel) so shaders can be tuned in sync with the viewer/hardware definitions; add to the surface extractor doc.
- TODO [P2]: Add an ambient occlusion term in the ray marcher (raystep-based heuristic) with tunable radius/strength.
- TODO [P2]: Integrate temporal accumulation/denoise (with motion reset) to smooth noisy frames.
- TODO [P3]: Build a surface-export helper that saves the surface/extractor buffer as a raw image (normal/depth map) plus metadata, so automation can compare successive commits automatically.
- TODO [P2]: Add a simple bloom/bright-pass stage after framebuffer write (configurable threshold/intensity).
- TODO [P2]: Support tone mapping/gamma correction as a post step (ACES-like and simple Reinhard options).
- IN-PROGRESS: Wire pixel_reemissure sideband fully through the pipeline and expose in HUD/debug (sim viewer can now switch to word2/sideband views; HUD stats still pending; RTL still drops reemissure on HDMI/AXI paths).
- TODO [P2]: Add depth/normal buffers export path for debug and potential SSR/SSAO experiments.
- TODO [P3]: Enable resolution scaling (internal render res vs. output res) and handle sampling/upsample cleanly.
- TODO [P3]: Add dithering to fog/sky gradients to reduce banding.
- TODO [P2]: Implement fog as a separate pass with configurable falloff/color and depth awareness.
- TODO [P2]: Expose ray step count/early-exit metrics for perf tuning; add a heatmap debug overlay.
- TODO [P2]: Add runtime-adjustable MAX_RAY_STEPS and STEP_SIZE (env/hotkey) for perf/quality sweeps.
- TODO [P3]: Provide a lightweight SSAO-lite using depth buffer once available (optional toggle).
- TODO [P3]: Add a debug view to visualize shadow rays/occluders for tuning lighting.
- TODO [P3]: Implement simple motion blur based on camera velocity (post-process).
- TODO [P2]: Add a “flat shading” debug mode that bypasses lighting to validate geometry/selection paths (helps isolate fog/AA tuning).
- TODO [P2]: Add per-pixel clamp on emissive/bright values to prevent blowouts (configurable).

## Instrumentation Baseline

- TODO [P1]: Define the instrumentation harness that records ray-loop time, framebuffer copy time, and HUD/prepresent costs for each frame and writes `out/render_pipeline_baseline.csv` so `todo_system_fps.md` can consume concrete breakdowns.
- TODO [P1]: Implement `scripts/render_pipeline_bench.py` to ingest those CSV rows, compute mean/percentile timings, and append a summary to `out/ai_health_dashboard.txt` so the automation dashboard can track regressions.
- TODO [P2]: Include “baseline scene” settings (camera path, resolution, render flags) in this tracker and capture the config in `out/render_pipeline_baseline.cfg` to guarantee instrumentation runs stay comparable across commits.
- TODO [P2]: Document how to replay the instrumentation harness locally (e.g., `cd sim && ./sim_voxel --instrument`) so contributors can reproduce the CSV and upload it to `out/render_pipeline_baseline.csv` for automation validation.
