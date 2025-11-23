# Hydra 0.0.4 Release Notes

## Highlights
- **Rendering & scene**: kept the existing orthographic voxel marcher and refined lighting stack (Lambertian term and improved emissive handling) while stabilizing a default camera/config for regression testing.
- **Frame regression & analysis**: added a deterministic frame-dump path to the Verilator+SDL sim (`FRAME_DUMP`/`AUTO_EXIT`) plus a Python comparator (`scripts/check_frame.py`) and a `make -C sim test_frame` target that compares against `sim/tests/golden_frame.ppm`.
- **CI**: introduced a GitHub Actions workflow that builds Linux host tools (CMake presets), Verilated sim, and runs the headless frame regression on each push/PR, plus optional jobs for RTL benches, a cocotb smoke test, a QEMU PCI stub guest smoke, and a FreeBSD kmod build (best-effort).
- **AXI shell / HDMI**: maintained the AXI-Lite + DMA + SDRAM + HDMI shell (`voxel_axil_shell`/stubs) with unit benches for DMA loopback and HDMI CRC golden, runnable via `sim/tests/run_rtl_tests.sh`.
- **Drivers & blitter**: tightened documentation and tooling around the Linux PCIe/DRM stubs, libhydra, and the 3D blitter stub, including the `hydra_blit_smoketest` path for BAR0/INT verification.

## Known limitations
- Renderer remains orthographic; perspective DDA and more advanced lighting/shadows are deferred to a future release.
- 3D blitter is a bring-up stub only (no full 3D pipeline or DMA command FIFO); Windows/macOS drivers are stubs and not covered by CI, and the FreeBSD stub is only built in a best-effort VM job.
- PCIe bus traffic and real SDRAM/HDMI PHY behavior are not modeled; the current shell uses simple AXI/BRAM/stream stubs.
- RTL benches (`sim/tests/run_rtl_tests.sh`) and the cocotb smoke are wired into CI on a best-effort basis but are not hard gates; only the frame-level regression gate is mandatory.

## Build/Run summary
- Sim: `cd sim && make` (Verilator + SDL); optional backends via `make GL=1`, `WAYLAND=1`, `X11=1`, `VULKAN=1` (where headers/libs are present).
- Frame regression: `make -C sim test_frame` (uses `FRAME_DUMP` + `scripts/check_frame.py` vs `sim/tests/golden_frame.ppm`).
- RTL benches: `chmod +x sim/tests/run_rtl_tests.sh && ./sim/tests/run_rtl_tests.sh` (requires iverilog/vvp).
- Host libs/tools: `cmake --preset linux-default && cmake --build build/linux` or `./scripts/setup_sdk.sh` for libhydra + userspace helpers.
- Linux drivers: build via `make -C drivers/linux` and follow `drivers/linux/README.md`; smoke-test BAR0 blitter CSRs with `scripts/hydra_blit_smoketest`.

## Notes
- See `docs/release_plan_0_0_4.md` for the original 0.0.4 planning checklist and `docs/component_status.md` for an updated component maturity snapshot.
- The QEMU PCI stub has a reference implementation and CI smoke hook, but still depends on an out-of-tree QEMU build and prepared guest image. Deeper cocotb/PCIe coverage and a perspective camera path remain on the roadmap and are explicitly out of scope for 0.0.4.
