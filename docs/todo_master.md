# Hydra TODO Tracker (toward 0.0.6)

Shared list so we stay aligned across runs/agents. Status tags: `TODO`, `IN-PROGRESS`, `DONE`, `WONTFIX-0.0.6` (with a short rationale). Keep entries concise; add owner/notes inline if useful.

## Simulation / Viewer
- IN-PROGRESS: Diagnose 'o' key (diagnostic slice toggle) not responding - added debug output (commit 708a373), awaiting user test results.
- DONE: Phase 1 visual quality improvements (commit 2e7d710) - desaturated scene colors, added procedural floor texture. See `docs/phase1_implementation_notes.md`.
- TODO: Phase 2 visual quality - add depth fog and ambient occlusion approximation (depends on Phase 1 validation).
- TODO: Phase 3 visual quality - wire up `pixel_reemissure` sidecar to framebuffer output and viewer.
- TODO: Guard `FRAME_DUMP` handling in `sim/live_sdl_main.cpp` so only the first frame (or a bounded count) writes a PPM to avoid runaway disk writes.
- TODO: Clear the framebuffer each frame in `sim/live_sdl_main.cpp` (or when fewer than NPIX pixels are produced) to prevent stale pixels if the RTL stalls early.
- TODO: Add env/CLI overrides for initial camera pos/yaw/pitch, move speed, and mouse sensitivity in `sim/live_sdl_main.cpp` for scriptable demos/regressions.
- TODO: Allow font path override (env) in `sim/live_sdl_main.cpp` to avoid silent HUD loss when DejaVuSans is absent.
- TODO: Expose a debug/HUD toggle to visualize the 96-bit pixel sidebands (`pixel_word0/2`) instead of dropping them in `pixel96_to_argb`.
- TODO: Relax/case-fold `HYDRA_BACKEND` parsing and prefer compiled GPU backends ahead of SDL in `sim/platform/backend_selector.cpp`.
- TODO: Add a headless/no-window mode switch to `sim_voxel` (reuse the dummy backend) so regression runs don't need a display server.
- TODO: Surface an on-screen help overlay (keybind list) in the HUD, gated by a hotkey, to improve discoverability.
- TODO: Clamp camera position to the voxel volume bounds (configurable) to avoid flying far outside the scene during demos.

## RTL Shell
- TODO: Handle AXI-Stream backpressure in `rtl/voxel_axi_core.sv` (buffer or stall when `m_axis_tready` deasserts).
- TODO: Tie off or assert stub AXI master signals in `rtl/voxel_axi_core.sv` to silence unused-interface warnings (aw/ar/w channels driven with valid=0 today).
- TODO: Surface or assert the `pixel_reemissure` sideband in `rtl/voxel_axi_core.sv` so the 96-bit format stays exercised.
- TODO: Add simple AXI-Lite SVAs in `rtl/voxel_axil_csr.sv` (handshakes, INT_STATUS RW1C correctness).
- TODO: Add a lightweight SV testbench that drives AXI-Lite writes/reads over the BAR0 map to flag regressions when CSRs change.

## Drivers / SDK / Tools
- TODO: Align `drivers/linux/hydra_pcie_drv.c` license tag with the BSD-3-Clause SPDX header (currently `MODULE_LICENSE("GPL")`).
- TODO: Add `.owner = THIS_MODULE` to `hydra_misc_fops` in `drivers/linux/hydra_pcie_drv.c` to block unload while open.
- TODO: Bounds-check `HYDRA_IOCTL_DMA` (`src+len`/`dst+len`) in `drivers/linux/hydra_pcie_drv.c` to prevent MMIO wrap.
- TODO: Mark BAR mmaps with `VM_IO|VM_DONTDUMP|VM_DONTEXPAND` in `drivers/linux/hydra_pcie_drv.c`.
- TODO: Strengthen parameter/error guards in `drivers/libhydra/hydra.c` (null/closed handles, ioctl failures) and provide an `HYDRA_HANDLE_INIT` helper.
- TODO: Switch `scripts/hydra_blit_smoketest.c` to shared UAPI headers instead of duplicating structs.
- TODO: Flesh out the FreeBSD stub (`drivers/bsd/hydra_pci_stub.c`) to mirror the Linux ioctl map and BAR1 exposure instead of placeholder comments.
- TODO: Make `scripts/hydra_drm_info.c` fail hard (non-zero) when DRM ioctls fail and print clearer error context.
- TODO: Add a small libhydra sample that exercises camera/flags/selection APIs so new users can sanity-check BAR0 writes.

## Build / CI / Tooling
- TODO: Fix `SDL_LIBS` tokenization in `sim/Makefile` (drop the stray `-LDFLAGS`) and ensure `-lSDL2_ttf` is linked when `sdl2-config` is absent.
- TODO: Extend `sim/clean` to remove `sim/build/` artifacts (frame_test.ppm, frame_diff.log).
- TODO: Emit the contents of `sim/build/frame_diff.log` on `test_frame` failures to make CI output self-contained.
- TODO: Broaden top-level `make clean` to drop libhydra objects, generated scripts binaries, and CMake `build/linux` outputs.
- TODO: Add PIC + install/export rules for libhydra in CMake for downstream consumers.
- TODO: Add a `make lint` (or similar) target that runs `verilator --lint-only`/`clang-tidy` on the sim C++ and RTL for quick hygiene checks.
- TODO: Teach CI to capture and publish `sim/build/frame_diff.log` and HUD screenshots on test failures for quicker triage.
- TODO: Provide a preset or helper to run CMake host builds from the top-level `Makefile` (delegating to `cmake --preset linux-default`).

## Docs
- TODO: Sync README license wording to the existing BSD-3-Clause `LICENSE`.
- TODO: Refresh IDs/rev/build in `docs/hydra_spec.md` to the current (0.0.5/next) values.
- TODO: Update platform backend status (GL path renders) in README/docs to avoid “stubbed” confusion.
- TODO: Document the backend selection/env vars and headless mode in README/test docs once implemented.
