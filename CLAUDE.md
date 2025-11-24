# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hydra is a voxel-based 3D graphics accelerator with a SystemVerilog raycaster core, PCIe device interface, and Verilator+SDL2 interactive viewer. It implements a 64×64×64 voxel volume with hardware ray marching, live camera control, and voxel editing.

## Core Commands

### Building and Testing

```bash
# Main development loop (builds sim, runs frame regression, builds SDK, optional RTL/QEMU)
./scripts/hydra_dev_loop.sh

# Build and run the interactive viewer
cd sim && make && ./sim_voxel

# Run frame regression test only
make -C sim test_frame

# Build SDK tools (libhydra + smoketests)
./scripts/setup_sdk.sh

# Build Linux driver (requires kernel headers)
make -C drivers/linux

# Run RTL benches (requires iverilog/vvp)
sim/tests/run_rtl_tests.sh
```

### Viewer Controls and Debugging

```bash
# Enable per-frame stats logging
LOG_FRAMES=1 ./sim_voxel

# Log keyboard events
LOG_KEYS=1 ./sim_voxel

# Non-interactive: dump single frame as PPM and exit
FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel

# Interactive viewer controls:
# - WASD/QE: fly camera
# - Mouse: look around
# - F: select voxel at screen center
# - Number keys: toggle render flags
# - O: toggle diagnostic slice renderer
```

### Build System Variants

```bash
# CMake build for host libs/tools (Linux)
cmake --preset linux-default && cmake --build build/linux

# CMake build (Windows/MSVC)
cmake --preset windows-msvc && cmake --build build/windows

# Optional backend builds
make GL=1           # OpenGL backend
make X11=1          # X11 backend
make WAYLAND=1      # Wayland backend
make VULKAN=1       # Vulkan backend

# Runtime backend selection
HYDRA_BACKEND=SDL ./sim_voxel
```

## Architecture

### Top-Level Structure

- **`rtl/`** - SystemVerilog core modules
  - `voxel_framebuffer_top.sv` - Top-level integration module
  - `voxel_raycaster_core_pipelined.sv` - Pipelined ray marching engine
  - `voxel_memory_64.sv` - 64×64×64 voxel BRAM
  - `voxel_world_gen.sv` - Procedural world generator
  - `voxel_axil_shell.sv` - AXI-Lite CSR wrapper for PCIe integration
  - `axi_*.sv` - AXI/AXI-Lite stubs for DMA/SDRAM/stream interfaces

- **`sim/`** - Verilator+SDL viewer and test harness
  - `live_sdl_main.cpp` - Main sim harness
  - `platform/` - Backend implementations (SDL, GL, Vulkan, Wayland, X11, fbdev, Win32, macOS)
  - `tests/` - Frame regression, RTL benches, cocotb tests, QEMU PCI stub
  - Outputs: `obj_dir/` (Verilated C++), `sim_voxel` (executable)

- **`drivers/`** - OS driver stubs and userspace libraries
  - `libhydra/` - Userspace helper library for IOCTLs
  - `linux/` - Linux PCIe + DRM render-only stub
  - `bsd/` - FreeBSD kmod stub with BAR0/1 mapping
  - `windows/`, `macos/` - Placeholder docs (no code yet)

- **`scripts/`** - Build and test automation
  - `hydra_dev_loop.sh` - Primary development loop
  - `setup_sdk.sh` - Build libhydra and tools
  - `check_frame.py` - Frame diff for visual regression
  - `fetch_ip.sh` - Fetch third-party IP (LitePCIe/LiteDRAM/LiteX)

- **`docs/`** - Specifications and integration guides
  - `hydra_spec.md` - Device register map (BAR0 CSR layout)
  - `driver_integration.md` - Driver bring-up guide
  - `testing_overview.md` - Test infrastructure tour
  - `ip_integration.md` - PCIe/DRAM/HDMI IP integration plan
  - `hardware_test_plan.md` - FPGA validation strategy

- **`third_party/`** - Vendored IP cores (LitePCIe, LiteDRAM, LiteICLink, LiteX)

### Register Map (BAR0)

The device exposes an AXI-Lite CSR space documented in `docs/hydra_spec.md`:

- `0x0000-0x000F` - ID, REV (current: 0x02 rev, 0x01 build)
- `0x0010-0x001F` - CTRL (soft_reset, start_frame, diag_slice_en, extra_light_en), STATUS (busy, frame_done, dma_busy, etc.)
- `0x0020-0x003F` - Camera position/direction (signed 16-bit fixed-point)
- `0x0040-0x0053` - Render flags, selection control (sel_x/y/z 6-bit coords)
- `0x0054-0x005F` - Framebuffer base/stride for BAR1/SDRAM aperture
- `0x0060-0x007F` - DMA registers (SRC, DST, LEN, CMD, STATUS)
- `0x0080-0x008F` - Interrupt control (INT_STATUS, INT_MASK, IRQ_TEST)
- `0x00A0-0x00AF` - Debug voxel write (ADDR, DATA_LO, DATA_HI, CTRL)
- `0x0100-0x016F` - 3D blitter stub (CTRL, STATUS, SRC/DST/LEN, pixel/FIFO access)

UAPI headers: `drivers/linux/uapi/hydra_regs.h`

### Data Flow

1. **World generation** (hardware): `voxel_world_gen.sv` populates BRAM with procedural scene (lit floor, emissive ceiling, spheres)
2. **Raycaster core**: `voxel_raycaster_core_pipelined.sv` performs fixed-point ray marching, outputs 96-bit extended pixels
3. **Framebuffer output**: Pixel interface writes RGBA32 + reemissure32 sidecar to host memory or AXI-Stream video sink
4. **Host control**: AXI-Lite CSR shell (`voxel_axil_shell.sv`) exposes camera, flags, selection, DMA to driver
5. **Sim loop**: `live_sdl_main.cpp` drives clock, reads pixel stream, updates SDL window with HUD

## RTL Development Notes

- **Signals use snake_case with logical prefixes**: `cam_`, `cfg_`, `sel_`, `dbg_`
- **Keep combinational and sequential blocks separate**; comment subtle behavior
- **Verilator parameters**: `MAX_RAY_STEPS` (default 128), `RAY_STEP_SHIFT` (default FRAC_BITS-1)
  - For sim builds: `-GMAX_RAY_STEPS=32 -GRAY_STEP_SHIFT=8` (performance tuning)
- **Golden frame regression**: `sim/tests/golden_frame.ppm` is checked into git; update only with explicit validation
- **AXI stubs**: `axi_dma_stub.sv`, `axi_sdram_stub.sv`, `axi_stream_sink_stub.sv` model PCIe/DRAM/HDMI without external IP

## C++ Sim Harness Notes

- **4-space indents**, **snake_case locals**, minimal globals
- **Include order**: standard library, third-party (SDL2), project headers
- **Backend abstraction**: `platform/backend_selector.cpp` dispatches to SDL/GL/Vulkan/Wayland/X11 based on runtime `HYDRA_BACKEND` env var
- **Verilator integration**: `V<TOP_MODULE>` class instantiated in `live_sdl_main.cpp`; clock driven via `eval()`
- **HUD rendering**: SDL2_ttf used for FPS, camera coords, flags, hit count overlay

## Testing Strategy

### 1. Visual Regression (primary gate)
- **Command**: `make -C sim test_frame`
- **What it checks**: Deterministic frame output against `sim/tests/golden_frame.ppm`
- **Failure mode**: `scripts/check_frame.py` prints per-channel diffs; logs to `sim/build/frame_diff.log`

### 2. RTL Benches (iverilog/vvp)
- **Location**: `sim/tests/rtl/`
- **Coverage**: DMA loopback (INT_STATUS/STATUS validation), HDMI CRC golden check
- **Run**: `sim/tests/run_rtl_tests.sh` (best-effort in CI)

### 3. Cocotb Smoke (optional)
- **Location**: `sim/tests/cocotb_hydra/`
- **Target**: `make SIM=icarus` (requires cocotb + iverilog)
- **Coverage**: IRQ_TEST pulse, basic DMA done signaling

### 4. SDK Userspace Tools
- **libhydra + smoketests**: `./scripts/setup_sdk.sh`
- **Requires**: Linux kernel headers for driver stub build
- **Tools**: `hydra_blit_smoketest` (raw BAR0/blitter FIFO), `hydra_dma_blit_demo` (libhydra-based)

### 5. QEMU PCI Stub (optional)
- **Location**: `sim/tests/qemu_stub/`
- **Device model**: `hydra_pci.c` implements BAR0-compatible device for QEMU
- **Usage**: `QEMU_BIN=... HYDRA_QEMU_GUEST_IMG=... sim/tests/qemu_stub/qemu_hydra_smoke.sh`

## Known Limitations (as of 0.0.5)

- **PCIe/DRAM/HDMI integration**: AXI stubs in sim; real LitePCIe/LiteDRAM/LiteVideo integration pending
- **IRQ wiring**: Core INT_STATUS/INT_MASK implemented but not yet connected to physical PCIe MSI
- **3D blitter**: Functional bring-up stub at BAR0 0x0100; not connected to full 3D pipeline
- **Platform backends**: GL/Vulkan/Wayland/X11/fbdev/Win32/macOS are no-op stubs (SDL only)
- **Windows/macOS drivers**: README notes only; no kernel driver code

## BAR0 Register Access Patterns

When implementing driver IOCTLs or sim test benches:

```c
// Example: Camera update
writel(cam_x << 16 | cam_y, BAR0 + 0x0020);
writel(cam_z << 16 | cam_dir_x, BAR0 + 0x0024);
// ... (see hydra_spec.md for full layout)

// Example: Start frame and wait for done
writel(CTRL_START_FRAME, BAR0 + 0x0010);
while (!(readl(BAR0 + 0x0014) & STATUS_FRAME_DONE));

// Example: Enable interrupt on frame_done
writel(INT_MASK_FRAME_DONE, BAR0 + 0x0084);
```

Refer to `drivers/linux/uapi/hydra_regs.h` for symbolic constants.

## CMake vs. Makefile Flows

- **Makefile** (primary): RTL sim (`sim/Makefile`), driver stubs, top-level convenience targets
- **CMake** (optional): Host-only libhydra/tools build for cross-platform (Linux/MSVC)
  - Presets: `linux-default`, `windows-msvc`
  - Outputs to `build/linux/` or `build/windows/`
  - **Does not build Verilator sim** (that remains Makefile-driven)

## IP Integration (future)

When replacing AXI stubs with LiteX IP:

1. **Fetch IP**: `make ip-fetch` or `./scripts/fetch_ip.sh`
2. **LitePCIe**: Xilinx/Lattice PCIe endpoint wrapper (BAR0/BAR1 mapping)
3. **LiteDRAM**: DRAM controller for SDRAM aperture (framebuffer/voxel DMA)
4. **LiteVideo**: HDMI/DVI encoder for AXI-Stream video output
5. **LiteX SoC**: Optional soft CPU for boot/config if FPGA shell requires it

See `docs/ip_integration.md` for detailed integration plan.

## Commit Style

- **Short, imperative subjects** (e.g., `Clamp camera bounds`, `Wire RTL benches into CI`)
- **Describe what changed and how you validated** (commands run, visual checks)
- **Link related issues** and flag deferred TODOs
- **Keep diffs tight**; avoid reformatting unrelated code

## Additional Resources

- **Component maturity**: `docs/component_status.md`
- **Driver bring-up**: `docs/driver_integration.md`
- **Hardware validation**: `docs/hardware_test_plan.md`
- **Release workflow**: `CONTRIBUTING.md`, release notes in repo root
