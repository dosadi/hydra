# Testing & Debugging Overview

**Last Updated:** 2025-11-26
**Owner:** Testing Team
**Depends:** `hydra_spec.md`, `driver_integration.md`, `ip_integration.md`
**Related Trackers:** `todo/todo_testing_ci.md`, `todo/todo_dma_pcie.md`, `todo/todo_hardware_validation.md`
**Touches:** `hardware_test_plan.md`, `todo/todo_testing_ci.md`

---

This repo has several layers of tests and debug tools, from pure RTL up to driver/PCIe stubs.
This document summarizes the main entry points.

## Quick first run (new contributors)

1. Install deps: `verilator`, `libsdl2-dev`, `libsdl2-ttf-dev`, `g++`, `make`.
2. From repo root: `make -C sim test_frame` (builds and runs the frame regression).
3. Launch the viewer: `cd sim && ./sim_voxel` (mouse-look + WASD; see keybinds in README).
4. Optional: `LOG_FRAMES=1 ./sim_voxel` (per-frame stats) or `LOG_KEYS=1 ./sim_voxel` (input debug).
5. Need a keybind refresher? See `docs/sim_controls.md`.

## 1. Sim-only tests (no drivers required)

### Build and run the SDL viewer

```bash
cd sim
make           # builds sim_voxel (Verilator + SDL2)
./sim_voxel    # launches the window (480x360 logical)
```

Useful env vars:

- `LOG_FRAMES=1 ./sim_voxel` – per-frame stats (pixels written, nonzero pixels, hit count).
- `LOG_KEYS=1 ./sim_voxel` – key down/up events for input debugging.
- `FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel` – dump a single frame as PPM and exit.
- `HYDRA_BACKEND=<SDL|GL|X11|WAYLAND|VULKAN>` – request a specific backend (falls back to SDL if unavailable).

### Frame regression test

```bash
make -C sim test_frame
```

This will:
- Build the sim (if needed).
- Run a non-interactive frame dump into `sim/build/frame_test.ppm`.
- Compare against `sim/tests/golden_frame.ppm` using `scripts/check_frame.py`.
- Print per-channel statistics and fail if the image diverges beyond thresholds.

## 2. RTL benches (AXI shell, DMA, HDMI)

Location: `sim/tests/rtl/` with a helper script:

```bash
chmod +x sim/tests/run_rtl_tests.sh
sim/tests/run_rtl_tests.sh
```

Requires: `iverilog` and `vvp` on PATH.

Benches:
- `test_dma_loopback.sv` – Issues a DMA copy inside the SDRAM stub, checks source/dest and INT_STATUS/STATUS bits.
- `test_hdmi_crc_golden.sv` – HDMI CRC using the full voxel pipeline at 16x12 (TEST_FORCE_WORLD_READY=1, AUTO_START_FRAMES=1), golden CRC `0x00010600` (single-frame run; checks beat count bounds and CSR mirrors).
- `test_hdmi_crc_full.sv` – HDMI CRC at 32x24, golden CRC `0x00020500` (single-frame run; CSR + beat checks).
- `test_bar1_dma_loopback.sv` – BAR1 + DMA copy using the SDRAM stub directly (fast seeding + forced DMA start for simulation speed).
- `test_dma_stub_direct.sv` – Direct DMA-to-SDRAM validation bench (tests DMA and SDRAM stubs).

Notes:
- The SDRAM stub (`axi_sdram_stub.sv`) supports optional `READ_LATENCY`/`WRITE_LATENCY` parameters if you want to inject wait states for stress; defaults are zero for fast benches.

All tests use `voxel_sim_harness.sv` which provides a complete simulation environment with AXI stubs.

In CI, these are run best-effort via `scripts/rtl_ci_wrapper.sh` and logged to `artifacts/rtl_tests.log` when tools are present.

### Headless / batch frame dumps

- Single frame: `FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel` (480x360 PPM ≈ 520 KiB).
- Multiple frames: `HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=10 FRAME_DUMP=ignored AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS ./sim_voxel`
- Headless backend: set `HYDRA_BACKEND=HEADLESS` to force SDL's dummy driver (no display server needed). Pairs well with `AUTO_EXIT=1` for CI.
- Numbered dumps: set `HYDRA_FRAME_BASE=frame` and `HYDRA_MAX_FRAME_DUMPS=N` to emit `frame_0.ppm...frame_(N-1).ppm`.
- Other useful envs: `HYDRA_CLEAR_COLOR=r,g,b` to init the framebuffer; `HYDRA_CAM_POS=x,y,z` / `HYDRA_CAM_ANG=yaw,pitch` for initial pose; `HYDRA_MOVE_SPEED`, `HYDRA_MOVE_SPEED_FAST`, `HYDRA_TURN_SPEED_KEYS`, `HYDRA_MOUSE_SENS`, `HYDRA_INVERT_Y`, `HYDRA_MOUSE_CAPTURE` for movement feel; `HYDRA_FONT` / `HYDRA_FONT_SCALE` for HUD font; `HYDRA_VSYNC` to toggle vsync; `HYDRA_FPS_TARGET` to pace frames (if implemented in your build).

## 3. SDK + Linux driver loop

### Build SDK tools

From the repo root:

```bash
./scripts/setup_sdk.sh
```

This builds:
- `drivers/libhydra/libhydra.a` – userspace helper library for IOCTLs.
- `scripts/hydra_blit_smoketest` – raw BAR0/INT/blitter FIFO smoketest.
- `scripts/hydra_dma_blit_demo` – libhydra-based DMA + blitter demo.
- `scripts/hydra_irq_test` – triggers IRQ_TEST, dumps INT_STATUS/INT_MASK.

### Linux driver bring-up (requires Linux kernel headers and a hydra_pcie device)

High-level steps (see `docs/driver_integration.md` for details):

1. Build and load the Linux PCIe/DRM stubs in `drivers/linux/`.
2. Ensure `/dev/hydra_pcie` is present.
3. Run:
   ```bash
   sudo ./scripts/hydra_blit_smoketest /dev/hydra_pcie
   sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie
   ```

These exercise BAR0 CSRs, INT_MASK/INT_STATUS, DMA stubs, and the 3D blitter stub.

## 4. QEMU PCIe stub (optional)

Location: `sim/tests/qemu_stub/`.

- `hydra_pci.c` – reference QEMU device model implementing a `hydra-pci` device with BAR0 compatible with `hydra_regs.h`.
- `qemu_hydra_smoke.sh` – host-side harness that:
  - Checks for QEMU + a guest image (`HYDRA_QEMU_GUEST_IMG`).
  - Boots a Linux guest with `-device hydra-pci`.
  - Captures the guest console to `artifacts/qemu_console.log`.

The guest image is expected to auto-load the Hydra drivers and run the SDK smoketests, then power off.
In CI, the `qemu-smoke` job will run this script when a guest image URL/env is configured.

## 5. One-command loop

For day-to-day development, use:

```bash
./scripts/hydra_dev_loop.sh
```

This script:
- Builds the sim and runs the frame regression.
- Builds SDK tools.
- Optionally runs RTL benches.
- Optionally runs the QEMU PCI stub smoke (if configured).

Artifacts from CI runs (frame images, frame diff, SDK build log, RTL logs, QEMU console) are collected under `artifacts/` and uploaded when CI fails, to help debug regressions.

## Filing good bug reports (what to include)

- Command used and commit hash (or describe local changes).
- Logs: `LOG_FRAMES=1` / `LOG_KEYS=1` output if relevant; `HYDRA_BACKEND`, `HYDRA_VSYNC`, `HYDRA_FRAME_BASE` settings; note if running headless (`HYDRA_BACKEND=HEADLESS`).
- Frame dumps: attach `FRAME_DUMP` PPMs (or numbered `HYDRA_FRAME_BASE` sequence) for visual issues.
- Env: tool versions (`make env-probe`), OS/display server, SDL backend hints.
- For driver issues: INT_STATUS/INT_MASK values, DMA/BLIT params, and user tool outputs (`hydra_blit_smoketest`, `hydra_dma_blit_demo`, `hydra_irq_test`).

## Troubleshooting sim build/runs (quick checks)
- Missing `SDL_ttf`: install `libsdl2-ttf-dev` (or equivalent) and ensure `sdl2-config` is on PATH; HUD will be blank without it.
- Verilator version: target 5.x; run `make env-probe` to see detected tools. If Verilator changed, run `make purge-obj-dir` to avoid stale builds.
- Headless runs: set `HYDRA_BACKEND=HEADLESS` or `SDL_VIDEODRIVER=dummy` plus `AUTO_EXIT=1` to avoid display errors in CI.
- Input capture stuck: press `M` to toggle mouse capture; `HYDRA_MOUSE_CAPTURE=0` forces keyboard-only for headless logs.
- Frame dump size surprises: 480x360 PPMs are ~520 KiB; reduce resolution via `SCREEN_WIDTH/HEIGHT` build params if needed for logs.

## Negative/edge tests (quick commands)
- Bad IOCTLs: `HYDRA_IOCTL_DMA` with out-of-range offsets should return `-EINVAL` (Linux) / `EINVAL` (BSD); run `./scripts/hydra_dma_blit_demo --bad-offset` if available, or patch `scripts/hydra_drm_info` to poke RD32/WR32 bounds.
- INT masking: `./scripts/hydra_irq_test` should show masked interrupts not incrementing irq_count (Linux) or int_status (BSD) until unmasked.
- Headless frame dump: `FRAME_DUMP=frame.ppm AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS ./sim_voxel` should exit cleanly and write a single PPM without a display server.

## FAQ (common setup/running fixes)
- **HUD missing text?** Ensure `libsdl2-ttf-dev` installed and `HYDRA_FONT` points to a real TTF; check stderr for font load warnings.
- **Viewer hangs on start?** Try `SDL_VIDEODRIVER=dummy` or `HYDRA_BACKEND=HEADLESS` to rule out windowing issues; verify `SDL2` and GPU drivers.
- **Verilator build errors after upgrade?** Run `make purge-obj-dir` then rebuild to clear stale generated files.
- **Mouse not captured?** Press `M`; HUD shows mouse capture status. In logs, `HYDRA_MOUSE_CAPTURE=0` disables capture for headless.
- **ABI mismatch tool errors?** Update both kernel driver and userspace headers; `scripts/hydra_drm_info` now checks `HYDRA_IOCTL_VERSION` when supported and will fail on size/version mismatch.
