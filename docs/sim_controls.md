# sim_voxel Controls & Shortcuts

Quick reference for the SDL viewer (Verilator + SDL2) in `sim/`.

## Movement & camera
- `W/A/S/D` – forward/strafe
- `Q` / `E` – down / up
- Arrow keys – yaw/pitch
- Mouse look (captured by default; toggle with `M`)
- `Shift` – fast move speed (hold)

## Rendering flags
- `1` – toggle smooth surfaces
- `2` – toggle curvature
- `3` – toggle extra light
- `O` – toggle diagnostic slice

## Selection & editing
- `F` – select voxel under cursor (if hit)
- `G` – clear selection
- `C` – cycle material type (selected voxel)
- `X` / `Z` – increase / decrease emissive (selected voxel)
- `B` – brighten RGB components (selected voxel)
- `P` – print current camera/flags/selection to stderr (for scripts/logging)

## Misc
- `M` – toggle mouse capture
- `H` – toggle HUD on/off
- `R` – reset camera/flags/selection to defaults
- `ESC` – exit
- CLI: `--backend <name>` (or `--backend=name`, `-b <name>`) overrides `HYDRA_BACKEND` for the run.

Notes:
- HUD shows current flags, camera, selection, hits, and memory utilization counters.
- `LOG_KEYS=1` prints key down/up events; `LOG_FRAMES=1` prints per-frame stats.
- `FRAME_DUMP=frame.ppm AUTO_EXIT=1` dumps a frame and exits (headless-friendly).
