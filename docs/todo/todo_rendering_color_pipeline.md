# Rendering Color Pipeline TODOs

Tracks the color-processing, shading, and emission stages that sit between the ray engine and the viewer output, including HDR, tone-mapping, and color gamut support.

- TODO [P0]: Define the ideal RGB24 pipeline (per earlier question) and document why the current viewer is limited; spell out the color space transformations or hardware limits that need removal so the output can reach the full spectrum without hitting hardware gating.
- TODO [P1]: Separate the depth/reemissure logic (see `todo_depth_reemissure_overview.md`) from the color pipeline and capture how each stage contributes to smooth shading; feed the conclusion back into the shader math analysis (`docs/mathematical_surface_analysis.md`).
- TODO [P1]: Add HDR/tonemapping support plans, including double-buffering and chromatic adaptation, referencing `todo_hdmi_display.md` for sink capabilities.
- TODO [P2]: Tie color correction to automation by writing regression capture scripts that dump `out/render_color_spectrum.json` after each run; link those artifacts to `scripts/ai_health_dashboard.py`.
- TODO [P3]: Document future work (radiosity, photon marching, adaptive tone curves) inside this tracker so the renderer sector can spin up new TODOs with the correct dependency tags.
