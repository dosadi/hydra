# Voxel-Based 3D Graphics Accelerator (Alpha)

This repository contains a compact SystemVerilog voxel raycaster core and a Verilator + SDL2-based interactive viewer harness. It is intended as an experimental research and development project for hardware-accelerated voxel rendering.

License: BSD-3-Clause (see `LICENSE`).

**Key artifacts:**
- RTL top: `rtl/voxel_framebuffer_top.sv`
- Interactive viewer harness (SIM): `sim/viewer.cpp` (formerly `sim/live_sdl_main.cpp`)
- Simulation build & runner: `sim/Makefile` → produces `sim/sim_voxel`

**Note:** the interactive harness was renamed to `sim/viewer.cpp`. The Makefile now builds `viewer.cpp`; older references to `live_sdl_main.cpp` have been updated across docs, but the legacy file may still be present as a recovery copy.

**Quickstart (Linux)**

Install minimal deps (Debian/Ubuntu):

```bash
sudo apt-get update
sudo apt-get install -y \
  verilator libsdl2-dev libsdl2-ttf-dev build-essential cmake python3
```

Build and run the interactive sim:

```bash
cd sim
make          # runs Verilator and builds sim_voxel
./sim_voxel   # launches the interactive viewer (logical 480x360)
```

For CI or non-interactive runs you can request a headless flow and a single-frame dump:

```bash
cd sim
FRAME_DUMP=frame.ppm AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS ./sim_voxel
```

See `docs/PACKAGE_REQUIREMENTS.md` for a more complete dependency list and platform notes.

**Viewer / runtime knobs**
- `HYDRA_BACKEND`: request a specific backend (`SDL`, `GL`, `X11`, `WAYLAND`, `VULKAN`, `FBDEV`, `WIN32`, `MACOS`, `HEADLESS`)
- `LOG_FRAMES=1`: print per-frame instrumentation and pixel stats
- `LOG_KEYS=1`: print input events for debugging
- `FRAME_DUMP=<path>` + `AUTO_EXIT=1`: dump P6 PPM and exit

Visual-quality knobs added (Phase 2 work):
- `HYDRA_FOG=1` — enable depth fog in the viewer (linear proxy based on the sideband depth byte)
- `HYDRA_FOG_COLOR=0xRRGGBB` — fog blend color (hex or decimal accepted); default `0xE0E0E0`
- `HYDRA_FOG_DENSITY=<float>` — multiply the fog falloff; default `1.0`

The fog is currently environment-controlled; a runtime HUD toggle will be added (and is planned next).

**Optional build-time backends**
- `make GL=1` — include OpenGL backend
- `make VULKAN=1` — include Vulkan backend
- `make X11=1`, `make WAYLAND=1` — platform-specific backends

If requested backends are unavailable at runtime, the harness falls back to SDL and logs the reason.

**Testing & common runs**

- Build + smoke run:

```bash
cd sim
make
```

- Frame regression (build + compare against golden):

```bash
make -C sim test_frame
```

- Unit test for pixel conversion:

```bash
make -C sim test_pixel96
```

- Useful runtime examples:

```bash
# non-interactive numbered dumps (useful for CI)
HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=3 FRAME_DUMP=ignored AUTO_EXIT=1 ./sim_voxel

# enable fog while running the viewer
HYDRA_FOG=1 HYDRA_FOG_COLOR=0xA0B0FF HYDRA_FOG_DENSITY=0.9 ./sim_voxel
```

**Documentation & tracking**

- Design, TODOs and contributor guides live in `docs/`.
- Master TODO tracker: `docs/todo/todo_master.md` and `docs/todo/` subfiles.
- Viewer keybinds and HUD notes: `docs/sim_controls.md`.

**Contributing**

See `CONTRIBUTING.md` for the development workflow, commit message conventions, and testing requirements. Before opening PRs, consult `docs/todo/todo_master.md` to avoid duplication of effort.

**Status**

- Current branch: `main` (active development)
- Visual-quality work in progress (Phase 2: depth fog implemented; next: HUD toggle + SSAO approximation for 0.0.8)
- Maturity: experimental / early-development. Not production-ready.

For detailed component status and per-target TODOs see `docs/component_status.md` and the `docs/todo/` trackers.

## License

BSD 3-Clause (see `LICENSE`).
