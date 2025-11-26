# Hydra Rendering Pipeline TODOs (Raycaster / Shader Path) - 0.0.7 Cycle

**Focus:** Pipeline profiling, BRDF refinement, shader debugging.
See `docs/todo/todo_prioritization.md` for sprint plan. Most items are P2 (nice-to-have).

- TODO [P2]: Add a microbenchmark/profiler pass to break down time spent in ray loop vs. framebuffer copy vs. HUD (baseline numbers in docs).
- TODO: Separate render pipeline config into a struct and plumb through env/HUD so presets can toggle AA/fog/tonemap in one place.
- TODO: Add a simple correctness test scene (few voxels with known normals/emissive) and compare rendered pixels against golden hashes.
- TODO: Measure and document bandwidth for framebuffer uploads/copies; add an optional “skip HUD” flag in the pipeline to isolate cost.
- TODO: Provide a shader/pipeline debug dump (current MAX_RAY_STEPS, STEP_SIZE, shading flags) in the HUD for quick verification.
- TODO: Refine BRDF shading model (diffuse/specular balance) and normalize energy for emissive + lit surfaces.
- TODO: Add per-material roughness/metallic parameters and propagate into the raycaster for highlight shaping.
- TODO: Implement soft shadowing in the raystep loop (penumbra approximation) without large perf hit.
- TODO: Add ambient occlusion term in the ray marcher (raystep-based heuristic) with tunable radius/strength.
- TODO: Integrate temporal accumulation/denoise (with motion reset) to smooth noisy frames.
- TODO: Add a simple bloom/bright-pass stage after framebuffer write (configurable threshold/intensity).
- TODO: Support tone mapping/gamma correction as a post step (ACES-like and simple Reinhard options).
- IN-PROGRESS: Wire pixel_reemissure sideband fully through the pipeline and expose in HUD/debug (sim viewer can now switch to word2/sideband views; HUD stats still pending; RTL still drops reemissure on HDMI/AXI paths).
- TODO: Add depth/normal buffers export path for debug and potential SSR/SSAO experiments.
- TODO: Enable resolution scaling (internal render res vs. output res) and handle sampling/upsample cleanly.
- TODO: Add dithering to fog/sky gradients to reduce banding.
- TODO: Implement fog as a separate pass with configurable falloff/color and depth awareness.
- TODO: Expose ray step count/early-exit metrics for perf tuning; add a heatmap debug overlay.
- TODO: Add runtime-adjustable MAX_RAY_STEPS and STEP_SIZE (env/hotkey) for perf/quality sweeps.
- TODO: Provide a lightweight SSAO-lite using depth buffer once available (optional toggle).
- TODO: Add a debug view to visualize shadow rays/occluders for tuning lighting.
- TODO: Implement simple motion blur based on camera velocity (post-process).
- TODO [P2]: Add a “flat shading” debug mode that bypasses lighting to validate geometry/selection paths (helps isolate fog/AA tuning).
- TODO: Add per-pixel clamp on emissive/bright values to prevent blowouts (configurable).
- TODO: Provide a “flat shading” debug mode that bypasses lighting to validate geometry/selection paths.
