# Rendering Presets & Presentation TODOs

Tracks the preset management, LUT/color grading, and documentation work around presentation modes so the viewer always ships with polished defaults and explainable options.

- **TODO [P1]:** Document and ship a "good defaults" preset (fog mild, AO on, tone map/gamma on, vsync on) as the demo default.
- **TODO [P1]:** Add HUD indicator + overlay showing the active preset and any custom tweaks so viewers know what they are seeing.
- **TODO [P2]:** Build a golden-screenshot script that captures key presets (default/cinematic/flat) for regression comparisons.
- **TODO [P2]:** Publish a render-quality checklist (fog, AO, tone map, HUD) to use before releases, including expected toggle states.
- **TODO [P2]:** Document display calibration guidance (gamma/brightness) plus a gray ramp test pattern for quick tuning.
- **TODO [P2]:** Expose preset saving/loading (JSON) and a “safe defaults” preset (low speed, stable defaults) for capture scripts.
- **TODO [P2]:** Provide colorblind-friendly presets and LUT-based grading hooks (loadable from file) with quick hotkeys.
- **TODO [P3]:** Add cinematic/day/night preset players that sequence LUTs, fog, bloom, and warm/cool light mixes.
- **TODO [P3]:** Add a "probes" overlay showing sampled ambient values and embed the preset list in docs for contributors.
