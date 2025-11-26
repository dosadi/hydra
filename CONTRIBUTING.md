# Contributing to Hydra

This document is a quick guide for people who want to work on this repo (core RTL, sim, drivers, or docs).
It's a summary of existing practices from `AGENTS.md` and the docs.

## Quick Start

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install verilator libsdl2-dev libsdl2-ttf-dev build-essential cmake python3

# Run full development cycle
./scripts/hydra_dev_loop.sh

# Or step by step:
make sim              # Build Verilator sim
make test             # Run frame regression test
make sdk-setup        # Build SDK tools

# See available targets:
make help
```

For detailed instructions, continue reading below.

## Development workflow

### 1. Install dependencies (Linux dev machine)

On a Debian/Ubuntu-like system:

```bash
sudo apt-get update
sudo apt-get install -y \
  verilator libsdl2-dev libsdl2-ttf-dev build-essential cmake ninja-build python3
```

Optional (for RTL benches and cocotb experiments):

```bash
sudo apt-get install -y iverilog
```

### 2. Run the main dev loop

From the repo root:

```bash
./scripts/hydra_dev_loop.sh
```

This will:
- Build the Verilator+SDL sim and run the frame regression (`make -C sim test_frame`).
- Build the SDK tools (libhydra, blitter smoketest, DMA+blit demo).
- Optionally run RTL benches (if `iverilog`/`vvp` are installed).
- Optionally run the QEMU PCI stub smoke test if you have QEMU + a prepared guest image configured.

Re-run this script after making changes to ensure you haven’t broken the basic flows.

### 3. Iterate on your change

- RTL changes: touch files under `rtl/` and rebuild via `./scripts/hydra_dev_loop.sh` or `make -C sim`.
- Sim harness/backends: touch `sim/` (C++ SDL/GL/Vulkan/etc.) and rerun the sim (`cd sim && ./sim_voxel`).
- Drivers/libhydra: touch `drivers/` and rebuild SDK via `./scripts/setup_sdk.sh` (or the dev loop).
- Docs: update `docs/*.md` and, if relevant, the release notes.

### 4. Run focused tests

Some useful targeted commands:

- Visual regression only:
  ```bash
  make -C sim test_frame
  ```
- SDK + userspace tools only:
  ```bash
  ./scripts/setup_sdk.sh
  ```
- RTL benches (if iverilog/vvp installed):
  ```bash
  chmod +x sim/tests/run_rtl_tests.sh
  sim/tests/run_rtl_tests.sh
  ```
- QEMU PCI stub smoke (requires a QEMU build with `hydra-pci` and a prepared guest image):
  ```bash
  QEMU_BIN=qemu-system-x86_64 HYDRA_QEMU_GUEST_IMG=/path/to/guest.qcow2 \
    sim/tests/qemu_stub/qemu_hydra_smoke.sh
  ```

## Coding style and layout

- C++ (sim and tools):
  - 4-space indents, snake_case locals, minimal globals.
  - Order includes: standard library, then third-party, then project headers.
  - Favor small helpers over macros in SDL/Verilator setup code.
- SystemVerilog (RTL):
  - Snake_case for signals/modules, with logical prefixes (e.g., `cam_`, `cfg_`, `sel_`, `dbg_`).
  - Keep combinational and sequential blocks separate; add light comments where behavior is subtle.
- Keep diffs tight; avoid reformatting unrelated code.

## Where to touch what

- `rtl/` – core voxel framebuffer and shell RTL. Top is `voxel_framebuffer_top.sv`.
- `sim/` – Verilator+SDL viewer and platform backends; main is `sim/viewer.cpp`.
- `drivers/` – Linux/FreeBSD/Windows/macOS driver stubs and `drivers/libhydra` userspace helper lib.
- `scripts/` – helper tools (frame diffing, SDK build, QEMU smoke, etc.).
- `docs/` – spec, driver integration, platform backends, hardware test plan, release plans.

## Pull requests

- Keep PRs focused; short, imperative commit messages (e.g., `Clamp camera bounds`, `Wire RTL benches into CI`).
- Describe what changed, how you validated it (commands you ran), and any new dependencies.
- Link related issues and mention known limitations or TODOs you deferred.

For more detailed project notes, see `AGENTS.md`, `docs/component_status.md`, and `docs/hardware_test_plan.md`.