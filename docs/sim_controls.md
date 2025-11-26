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
- `V` – cycle pixel view (color, pixel_word0, pixel_word2, sideband mix)

## Selection & editing
- `F` – select voxel under cursor (if hit)
- `G` – clear selection
- `C` – cycle material type (selected voxel)
- `X` / `Z` – increase / decrease emissive (selected voxel)
- `B` – brighten RGB components (selected voxel)
- `P` – print current camera/flags/selection to stderr (for scripts/logging)
- HUD shows edit hints while a selection is active.
- Missed selection (F with no hit) shows a brief HUD warning.

## Overlays & misc
- `F1` – toggle keybind/help overlay (always on-screen, even if HUD is off)
- `/` – briefly show the keybind overlay (auto-hides after a few seconds)
- `F2` – toggle safe defaults preset (lower speed/sensitivity, camera clamped)
- `F3` – toggle safe capture mode (freeze input/camera for clean captures)
- `M` – toggle mouse capture
- `H` – toggle HUD on/off
- `R` – reset camera/flags/selection to defaults
- HUD warns in red when mouse capture is disabled.
- `ESC` – exit
- CLI:
  - `--backend <name>` (or `--backend=name`, `-b <name>`) overrides `HYDRA_BACKEND`.
  - `--cam-pos x,y,z` / `--cam-ang yaw,pitch` set the initial camera.
  - `--move-speed <v>` / `--move-speed-fast <v>` / `--turn-speed <v>` tune navigation.
  - `--mouse-sens <v>` adjusts mouse look sensitivity.
  - `--fps-target <v>` sets frame pacing; `--pixel-view <mode>` sets the initial pixel debug view (color/word0/word2/sideband).
  - `--seed <v>` passes a world seed to the procedural scene (HYDRA_WORLD_SEED; deterministic scene when set).
  - `HYDRA_SAFE_DEFAULTS=1` starts with the safe defaults preset enabled.
  - `HYDRA_SAFE_CAPTURE=1` starts with safe capture enabled (input frozen).

- HUD shows current flags, camera, selection, hits, ray-step metrics, and memory utilization counters.
- `J` toggles ray jitter (sub-voxel sampling) and the HUD line shows its assist state.
- `HYDRA_RAY_JITTER=1` starts with ray jitter enabled.
- `LOG_KEYS=1` prints key down/up events; `LOG_FRAMES=1` prints per-frame stats.
- `FRAME_DUMP=frame.ppm AUTO_EXIT=1` dumps a frame and exits (headless-friendly).
