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
- (Optional) FreeBSD kmod stub build requires FreeBSD kernel headers/sources (see `drivers/bsd/`).

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

### Windows / Visual Studio (libhydra and tools)

This repo ships a minimal CMake build for host-side components (libhydra and optional POSIX tools).

```
cmake --preset windows-msvc
cmake --build build/windows
```

On Linux, you can also use CMake:

```
cmake --preset linux-default
cmake --build build/linux
```

The cocotb/Verilator/SDL sim flow remains Makefile-driven; the CMake path is for host-side libs/tools only.

#### MSYS2/MinGW
- Install SDL2/SDL2_ttf via pacman (e.g., `pacman -S mingw-w64-ucrt-x86_64-SDL2 mingw-w64-ucrt-x86_64-SDL2_ttf`).
- Use `cmake --preset windows-msvc` for MSVC or `cmake -G Ninja` with the MinGW toolchain for host-side builds; the Verilator/SDL sim still expects a POSIX-like environment.
- For the SDL sim on MinGW/Windows: ensure `sdl2-config` is available or set `SDL_CFLAGS`/`SDL_LIBS` manually in `sim/Makefile`; Verilator on Windows is community-supported—use a Linux build for the sim if that’s easier.
- The cocotb/icarus smoke test (`sim/tests/cocotb_hydra`) is Linux-friendly; on Windows you’ll need a compatible simulator and Python env or run it inside WSL/MSYS2.

#### Windows sim notes
- To attempt the SDL sim on Windows/MinGW: build Verilator or use a prebuilt package, set `VERILATOR`/`CXX` in `sim/Makefile`, and export `SDL_CFLAGS`/`SDL_LIBS` if `sdl2-config` is absent.
- If the Windows toolchain is cumbersome, run the sim under WSL2 with the Linux instructions above; CMake/MSVC remains available for host-only libs/tools.
- Prereqs for a native Windows sim attempt: Verilator (5.x), SDL2/SDL2_ttf dev libs, a MinGW/MSYS2 toolchain, and a POSIX-like shell for the Make-based flow. Cocotb is easiest under WSL/MSYS2.
- More: `docs/windows_sim.md` for Windows build/sim details, `docs/freebsd_qemu.md` for FreeBSD kmod testing, `docs/component_status.md` for a maturity snapshot.

Logging and debug:

- `LOG_FRAMES=1 ./sim_voxel` – print per-frame stats (pixels written, nonzero pixels, hit count).
- `LOG_KEYS=1 ./sim_voxel` – print key down/up events (for input debugging).
- HUD shows FPS, flags, and “Hits this frame” to confirm scene intersections.
- `[O]` toggles a diagnostic slice renderer on/off (handy if you want to peek inside the lit/shadow scene).

Scene notes:

- A warm emissive ceiling slab near y≈52 shines down onto a cool floor band near y≈10; the main cyan sphere casts a soft shadow on the floor.
- Stand near the floor looking upward to see the light slab; move above the floor to see the shadowed area beneath the sphere.
