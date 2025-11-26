# Voxel-Based 3D Graphics Accelerator (Alpha)

This repo contains a **voxel raycaster core in SystemVerilog** plus a **Verilator + SDL2** interactive viewer.
Licensed under BSD-3-Clause (see `LICENSE`).

## Quickstart (Linux)

```bash
# Install minimal deps on Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y \
  verilator libsdl2-dev libsdl2-ttf-dev build-essential cmake ninja-build python3

# Clone and run the developer loop from the repo root
./scripts/hydra_dev_loop.sh

# Then run the interactive viewer
cd sim
./sim_voxel
```

That script builds the sim, runs the frame regression, builds SDK tools (libhydra + smoketests), and, where possible, runs RTL benches and QEMU smoke.

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

Optional backends (opt-in at build time):

- `make GL=1` – enable OpenGL backend (needs SDL2 OpenGL headers and GL libs).
- `make X11=1` – enable X11 backend (needs Xlib headers/libs).
- `make WAYLAND=1` – enable Wayland backend (needs wayland-client headers/libs).
- `make VULKAN=1` – enable Vulkan backend (needs Vulkan SDK headers/libs + SDL2 Vulkan helpers).
- Use `HYDRA_BACKEND=<SDL|GL|X11|WAYLAND|VULKAN|FBDEV|WIN32|MACOS|HEADLESS>` at runtime to request a compiled backend; falls back to SDL if unavailable and still uses the SDL window/HUD for input.
- Headless mode: set `HYDRA_BACKEND=HEADLESS` to force the dummy SDL driver (no window/display server needed). Combine with `FRAME_DUMP=frame.ppm AUTO_EXIT=1` for CI-friendly frame dumps; files are raw binary PPMs (P6).

### Windows / Visual Studio (libhydra and tools)

For contributor notes and a more detailed development workflow, see `CONTRIBUTING.md`.

This repo ships a minimal CMake build for host-side components (libhydra and optional POSIX tools).

Open work items live in `docs/todo_master.md` (shared tracker). Please skim it before filing issues or PRs so we stay aligned.

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
CI coverage (main): sim build/frame test, cocotb smoke (when tools present), and host CMake builds. Drivers are stubbed; hardware bring-up is manual for now.
User-space tools: see `docs/user_tools.md` for `hydra_blit_smoketest`, `hydra_dma_blit_demo`, `hydra_drm_info`, and `hydra_irq_test` usage/exit codes.
Udev rule example: `docs/udev_rules_example.md` shows how to set permissions for `/dev/hydra_pcie`.
Cross-compile notes: see `docs/cross_compile.md` for aarch64 driver/libhydra examples.
Systemd example: see `docs/systemd_service_example.md` for auto-loading the driver and setting devnode permissions.

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

## Testing & debugging

See also: `docs/testing_overview.md` for a full tour of sim, RTL, SDK, and QEMU tests.

Logging, debug, and tests:

- `LOG_FRAMES=1 ./sim_voxel` – print per-frame stats (pixels written, nonzero pixels, hit count).
- `LOG_KEYS=1 ./sim_voxel` – print key down/up events (for input debugging).
- `FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel` – non-interactive run that dumps a single frame as PPM and exits.
- `HYDRA_BACKEND=<SDL|GL|X11|WAYLAND|VULKAN>` – request a specific backend (falls back to SDL if unavailable).
- `HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=5 FRAME_DUMP=ignored AUTO_EXIT=1 ./sim_voxel` – dump numbered frames `frame_0.ppm...frame_4.ppm`.
- `make -C sim test_frame` – build the sim, dump a frame with a dummy SDL backend, and compare against `sim/tests/golden_frame.ppm` using `scripts/check_frame.py`.
- `./scripts/hydra_dev_loop.sh` – convenience script that runs the sim build + frame regression, SDK build, and (optionally) RTL benches and QEMU smoke if tools/images are available.
- HUD shows FPS, flags, and “Hits this frame” to confirm scene intersections.
- `[O]` toggles a diagnostic slice renderer on/off (handy if you want to peek inside the lit/shadow scene).

Scene notes:

- A warm emissive ceiling slab near y≈52 shines down onto a cool floor band near y≈10; the main cyan sphere casts a soft shadow on the floor.
- Stand near the floor looking upward to see the light slab; move above the floor to see the shadowed area beneath the sphere.

## Driver readiness

- Linux: PCIe + DRM stubs live under `drivers/linux/`; IOCTLs are documented in `drivers/linux/uapi/hydra_regs.h` and `docs/driver_integration.md`.
- FreeBSD: PCI stub in `drivers/bsd/` maps BAR0/1, supports `/dev/hydra` mmap (BAR0 then BAR1), and exposes IRQ/DMA counters via `dev.hydra.*` sysctls; `scripts/hydra_bsd_info` prints IOCTL + sysctl stats.
- Coverage: `./scripts/driver_coverage.sh` runs small IOCTL helpers and drops logs under `out/driver-coverage/` (see `docs/driver_coverage_guide.md`).
- Platform notes: Windows/macOS build hints in `docs/macos_windows_build.md`; wider bring-up checklist in `docs/driver_integration.md`.

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **`docs/hydra_spec.md`** - Device register map (BAR0 CSR layout)
- **`docs/testing_overview.md`** - Complete test infrastructure guide
- **`docs/driver_integration.md`** - Driver bring-up and integration guide
- **`docs/hardware_test_plan.md`** - FPGA validation strategy
- **`docs/rtl_coding_standards.md`** - RTL coding conventions
- **`docs/architecture_cleanup_summary.md`** - Recent architecture improvements
- **`docs/dma_architecture.md`** - DMA data path, BAR1 decode, and sim harness layout
- **`docs/hdmi_scanout_architecture.md`** - HDMI scanout path and CRC instrumentation
- **`docs/litex_crossbar_integration.md`** - LiteX AXI fabric hookup for HydraCore
- **`docs/ip_integration_cleanup.md`** - Split of simulation vs. FPGA shells and next steps
- **`docs/component_status.md`** - Component maturity and status
- **`docs/sim_controls.md`** - sim_voxel keybinds and editing shortcuts

See `CLAUDE.md` for guidance on working with Claude Code in this repository.

## Contributing

Contributions are welcome! Please see `CONTRIBUTING.md` for:

- Development workflow and branch strategy
- Commit message conventions
- Testing requirements
- Code review process
- Shared task list: see `docs/todo_master.md` for the current 0.0.6 TODOs.

## License

This project is licensed under the BSD 3-Clause license (see `LICENSE`).

## Status

**Current Version**: 0.0.6 (Alpha)

**Maturity**: Early development - suitable for experimentation and research. Not production-ready.

**Platforms**:
- Linux: Primary development platform (full support)
- FreeBSD: Kernel module stub (basic support)
- Windows: Host tools via CMake/MSVC (partial support)
- macOS: Documented but not tested

For detailed component status, see `docs/component_status.md`.
