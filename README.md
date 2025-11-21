# Voxel-Based 3D Graphics Accelerator (Alpha)

This repo contains a **voxel raycaster core in SystemVerilog** plus a **Verilator + SDL2** interactive viewer.

Features (alpha):

- 64×64×64 voxel volume, 64-bit voxels.
- Procedural world generator (lit floor, emissive ceiling, and two spheres).
- Simple hardware ray marcher producing 96-bit extended pixels with a ceiling-light / shadow demo.
- Live SDL window with:
  - Mouse-look and WASD/QE fly camera.
  - HUD with FPS, camera, flags.
  - Cursor ray: shows which voxel the center of the screen hits.
  - Selection: aim + **F** to select; selection is highlighted in hardware.
  - Editing: change material/emission/color via keys; changes go straight into BRAM.

## Build & Run (native)

Requirements:

- `verilator` (5.x recommended)
- `libsdl2-dev`, `libsdl2-ttf-dev`
- `g++`, `make`

On Ubuntu/Debian:

```bash
sudo apt-get install verilator libsdl2-dev libsdl2-ttf-dev build-essential
```

Build and run the SDL viewer:

```bash
cd sim
make           # builds sim_voxel
./sim_voxel    # launches the window (480x360 logical)
```

Logging and debug:

- `LOG_FRAMES=1 ./sim_voxel` – print per-frame stats (pixels written, nonzero pixels, hit count).
- `LOG_KEYS=1 ./sim_voxel` – print key down/up events (for input debugging).
- HUD shows FPS, flags, and “Hits this frame” to confirm scene intersections.
- `[O]` toggles a diagnostic slice renderer on/off (handy if you want to peek inside the lit/shadow scene).

Scene notes:

- A warm emissive ceiling (y≈52) shines down onto a cool floor (y≈12); the main cyan sphere casts a soft shadow on the floor.
- Stand near the floor looking upward to see the light plane; move above the floor to see the shadowed area beneath the sphere.
