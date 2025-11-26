# Rendering Effects TODOs

Focuses on the shading/effect pipeline: fog, AO, bloom, motion blur, LUTs, volumetrics, and depth-based artistry.

- **TODO [P1]:** Add depth-based fog pass with tunable color/curve, exposed via HUD/env var.
- **TODO [P1]:** Implement ambient occlusion approximation (raystep or screen-space heuristics) with strength + threshold controls.
- **TODO [P1]:** Add tone mapping/gamma correction toggle to normalize brightness and integrate with LUTs.
- **TODO [P2]:** Add bloom/bright-pass filter with adjustable intensity for emissive highlights.
- **TODO [P2]:** Provide debug normals/depth display overlay for editing and select toggling.
- **TODO [P2]:** Add SSAO-lite and SSR-lite toggles for quick experiments.
- **TODO [P2]:** Implement volumetric light shafts for emissive ceiling in fog mode.
- **TODO [P2]:** Add noise dither, film grain, chromatic aberration, and motion blur options.
- **TODO [P2]:** Create LUT staging workflow (preview, load, snapshot) so operators can view multiple grading presets quickly.
- **TODO [P3]:** Add volumetric scattering intensity/decay debug logging for fog/shafts to tune effect parameters.
- **TODO [P3]:** Add dynamic exposure controls with user-defined min/max EV and responsiveness.
- **TODO [P3]:** Implement depth-of-field with focus distance/aperture + focus peaking overlay.
- **TODO [P3]:** Add per-material anisotropy/roughness presets and metallic/roughness sliders.
- **TODO [P3]:** Evaluate adding radiosity-style global illumination from voxels (soft indirect light) with per-frame stats exported to `out/radiosity_stats.json` so the AI dashboard can measure its performance impact.
