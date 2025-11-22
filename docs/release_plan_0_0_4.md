# Hydra 0.0.4 Plan (Draft)

## Priorities
- Make HDMI frame path deterministic and set a golden CRC for the SV bench; tighten RTL test coverage.
- Advance platform backends beyond stubs (GL/Vulkan/Wayland/X11/fbdev/Win32/macOS), starting with SDL-backed present ops or minimal GL/Vulkan.
- Grow driver parity:
  - Linux: strengthen DMA/IRQ handling and DRM modeset path.
  - FreeBSD: move beyond stub DMA/IRQ; mirror Linux UAPI behavior; add CI if feasible.
  - Windows/macOS: add BAR mapping/IOCTL skeletons.
- Add QEMU PCI stub device to exercise drivers/libhydra in CI.

## Tasks
1) **HDMI golden & RTL tests**
   - Expose/determinize frame start path for testbenches; capture CRC; set GOLDEN_CRC in `sim/tests/rtl/test_hdmi_crc_golden.sv`.
   - Expand cocotb or SV benches to cover INT_MASK semantics and DMA_ERR once implemented.
2) **Backends**
   - Implement real SDL present ops in `backend_sdl.cpp`; keep others stubbed but wired for future.
   - Optional: minimal GL/Vulkan/X11/Wayland/fbdev/Win32/macOS scaffolds with build guards.
3) **Drivers**
   - Linux: robust DMA/IRQ, DRM render/modeset path, align libhydra/tools.
   - FreeBSD: real DMA/IRQ handling, UAPI parity, and optional CI build on FreeBSD runner.
   - Windows/macOS: add BAR mapping/IOCTL skeletons (KMDF/DriverKit).
4) **QEMU PCI stub**
   - Author a QEMU device exposing BAR0/1 RAM to drive IOCTL paths; integrate optional CI job.
5) **CI**
   - Add CMake preset build on Windows/MSVC (if runner available).
   - Consider FreeBSD kmod build job (needs FreeBSD runner).
   - Keep RTL/cocotb tests green; enable HDMI golden once CRC is stable.

## Docs
- Update spec/UAPI if CSR bits change (e.g., DMA_ERR implementation).
- Refresh release notes and component status.
