# Testing & Debugging Overview

This repo has several layers of tests and debug tools, from pure RTL up to driver/PCIe stubs.
This document summarizes the main entry points.

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
- `test_dma_loopback.sv` – issues a DMA copy inside the SDRAM stub, checks source/dest and INT_STATUS/STATUS bits.
- `test_hdmi_crc_golden.sv` – checks `hdmi_crc_last` against a golden for a fixed camera/config.

In CI, these are run best-effort via `scripts/rtl_ci_wrapper.sh` and logged to `artifacts/rtl_tests.log` when tools are present.

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
