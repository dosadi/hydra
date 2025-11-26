# GL32 / GL64 & Graphics API TODOs

Tracks adding OpenGL 3.2/4.6-friendly rendering paths atop Hydra, ensuring integration with `libhydra`, Mesa driver, and higher-level retained APIs.

## P1 - GL API Integration
- **TODO [P1]:** Define Hydra texture/framebuffer bindings for GL32/GL64 contexts so `libhydra` exposes `glBindHydraTexture`, `glUploadHydraFrame`, and similar helpers.
- **TODO [P1]:** Create sample integrations (GL32, GL64) in `examples/gl` that render Hydra framebuffers through OpenGL to demonstrate retained API behavior.
- **TODO [P1]:** Document GL extensions needed (ARB_texture_view, ARB_multi_draw_indirect) and tie the notes back to `docs/todo/todo_mesa_drivers.md` and `docs/design_gaming_integration.md`.
- **TODO [P1]:** Add automation entries that log GL backend stability stats to `scripts/ai_health_dashboard.py` when switching between GL32/GL64 modes.
- **TODO [P1]:** Add GL32/GL64 shader fallback paths for environments lacking specific extensions (e.g., use fallback shaders when ARB multi-draw unavailable) and log which path was used via `scripts/ai_health_dashboard.py`.

## P2 - Meta Controls & Debugging
- **TODO [P2]:** Expose dashboard controls for GL toggles (shader, pipeline, color space) and record toggles in `out/gl_mode_switches.json` for the AI dashboard.
- **TODO [P2]:** Build a GL compatibility checklist (GLSL versions, buffer formats) referencing `docs/todo/todo_platforn_backends` (typo) so automation can skip unsupported combos via CI gating.
- **TODO [P2]:** Build a GL compatibility checklist (GLSL versions, buffer formats) referencing `docs/todo/todo_platform_backends.md` so automation can skip unsupported combos via CI gating.
- **TODO [P2]:** Provide a description of how Hydra’s shaders map to GL uniforms/states; document in `docs/mesa_driver_architecture.md` and link it from this tracker.
- **TODO [P2]:** Add regression scripts that run GL32/GL64 pipelines (maybe via GLFW) and compare output with Hydra frame logs, pushing artifacts into `out/gl_regress`.
- **TODO [P2]:** Add GL32/GL64 benchmarking (frame capture, shader compile times) comparing Hydra meshes to baseline GPU GPUs and logging results to `out/gl_benchmarks.json`.

## P3 - Future Graphics Compatibility
- **TODO [P3]:** Invent Hydra-specific GL shader pipelines (voxel preview, debug overlays) that other contributors can adopt as reusable templates.
- **TODO [P3]:** Outline how future graphics APIs (Vulkan, DirectX 12) may map to these GL concepts so the tracker stays flexible for larger spec expansions.
- **TODO [P3]:** Provide community-facing GL tutorials/demos (GL32/64) in `docs/tutorials/` and ensure they reference `todo_content_creation.md`.
