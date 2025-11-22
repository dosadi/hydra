# Hydra 0.0.3 Release Checklist

Actionable tasks to close out the 0.0.3 release. Keep items checked off as they land; reference file paths for alignment.

## Interface freeze
- [ ] Lock vendor/device IDs and BAR0 map across `docs/hydra_spec.md`, `rtl/voxel_axil_csr.sv`, `drivers/linux/uapi/hydra_regs.h`, `drivers/linux/uapi/hydra_drm.h`; bump REV.
- [ ] Finalize blitter + reemissure semantics and the 0x0100 CSR region; document in `docs/hydra_spec.md`.
- [ ] Align IRQ bits/MSI wiring in RTL (`rtl/voxel_axil_shell.sv`, `rtl/axi_stream_sink_stub.sv`) with driver UAPI masks.

## RTL stabilization
- [ ] Validate/replace AXI stubs (`rtl/axi_dma_stub.sv`, `rtl/axi_crossbar_stub.sv`, `rtl/axi_sdram_stub.sv`, `rtl/axi_stream_sink_stub.sv`) and confirm BAR1 window decode in `rtl/voxel_axil_shell.sv`.
- [ ] Add fixed-camera HDMI CRC/line/pixel golden check; record expected CRC for regression.
- [ ] Add SDRAM loopback DMA sim test with INT_STATUS assertions.

## Driver and UAPI
- [ ] Finish Linux misc/PCIe driver TODOs in `drivers/linux/hydra_pcie_drv.c` (DMA start/done/error handling, IRQ clear/enable, BAR1 mmap path, timeouts).
- [ ] Grow DRM stub (`drivers/linux/hydra_drm_stub.c`) into minimal render/modeset path; keep CSR read/write ioctls in sync with frozen map.
- [ ] Freeze UAPI headers and update `drivers/libhydra` + tools (`scripts/hydra_drm_info.c`) to match.
- [ ] Bring up skeletal Windows/macOS BAR/IOCTL shims (KMDF/DriverKit) aligned to final IDs/map.

## User-mode and Mesa
- [ ] Flesh out Mesa Gallium stubs so they compile against the frozen UAPI (`drivers/mesa/hydra_screen.c`, `drivers/mesa/hydra_context.c`, `drivers/mesa/hydra_gallium_stub.c`, `drivers/mesa/meson.build`).

## Tests and CI
- [ ] Complete cocotb smoke/regression (`sim/tests/cocotb_hydra`): DMA start/done, INT_STATUS, HDMI CRC/line/pixel counters; keep optional CI job green.
- [ ] Implement QEMU PCIe stub device (sim/tests/qemu_stub) to exercise libhydra/drivers; add optional CI job when stable.
- [ ] Add SDRAM DMA loopback and HDMI CRC golden checks into CI once deterministic. (DMA loopback in CI; HDMI CRC golden now stable.)
- [ ] Verify render-node smoke via `scripts/hydra_drm_info` after DRM stub loads.
- [ ] HDMI CRC golden set in `sim/tests/rtl/test_hdmi_crc_golden.sv` (crc=0x00020500).

## IP and board bring-up
- [ ] Pin LitePCIe/LiteDRAM/LiteICLink/LiteDMA commits in `scripts/fetch_ip.sh` and `third_party/README.md` once fetched.
- [ ] Add Nexys Video (KC705 fallback) synthesis targets with LitePCIe x4 + LiteDRAM + LiteVideo; verify AXI-Lite/AXI-Stream boundaries.
- [ ] Optional: add Windows/MSVC and FreeBSD host build sanity (CMake presets, kmod stub build) to pre-release checks.

## Platform backends
- [ ] Replace SDL-only placeholders with initial GL/Vulkan/Wayland/X11/fbdev/Win32/macOS implementations under `sim/platform/backend_*.cpp`, keeping stub fallback.

## Release sign-off
- [ ] Run `cd sim && make` and exercise SDL viewer controls/flags; capture screenshots if visuals changed.
- [ ] Run cocotb/HDMI/DMA regression suite (and QEMU stub once available); archive logs/CRC golden values.
- [ ] Build host artifacts: `make drivers` (Linux/FreeBSD stubs), `make libhydra`, `make blit-smoketest`, `make drm-info` (if libdrm present).
- [ ] Update release notes and tag 0.0.3.
- [ ] Verify CMake presets build on Linux/MSVC; optionally run `make -C drivers/bsd` for FreeBSD kmod stub sanity.
- [ ] Ensure status/docs are up to date: `docs/component_status.md`, `docs/freebsd_qemu.md`, `docs/windows_sim.md`.
