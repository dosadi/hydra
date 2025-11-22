# Driver Integration Plan (Hydra PCIe Device)

Goal: prepare cross-platform driver scaffolding so the Hydra PCIe device can be brought up quickly on Linux, Windows, and macOS, while keeping stubs that do not break builds.

## Targets
- Linux: out-of-tree kernel module stub (PCIe); future path: DRM/KMS + VFIO; userspace GL/Vulkan can talk to a DRM node.
- Windows: KMDF/WDF PCIe driver stub; future path: WDDM miniport if presenting as a GPU.
- macOS: DriverKit/SystemExtensions PCIe driver stub; future path: IOUserClient-style interface.
- Mesa: Gallium stub (placeholder) to be dropped into Mesa tree when IOCTLs settle.

## Current Stubs (in-tree)
- `drivers/linux/hydra_pcie_drv.c`: PCI driver with BAR0 map, DMA masks, MSI/MSI-X/legacy IRQ, debugfs, misc-device IOCTLs.
- `drivers/linux/Makefile`: out-of-tree `obj-m` for PCIe + DRM stub build.
- `drivers/windows/README.md`: notes for KMDF setup (code TBD).
- `drivers/macos/README.md`: notes for DriverKit setup (code TBD).
- `drivers/linux/hydra_drm_stub.c`: DRM render-only stub using GEM shmem helpers; binds to PCI ID, maps BAR0, registers a DRM device (no planes/modes yet).
- `drivers/mesa/`: placeholder Gallium skeleton (`meson.build`, stub C) to guide Mesa integration later.
- `drivers/libhydra/`: tiny userspace helper library wrapping IOCTLs (info/rd/wr/dma/blit).

## Linux IOCTLs (misc device)
- `HYDRA_IOCTL_INFO`: vendor/device, IRQ, BAR0/1 info, IRQ count.
- `HYDRA_IOCTL_RD32` / `HYDRA_IOCTL_WR32`: aligned BAR0 accesses (bounds-checked).
- `HYDRA_IOCTL_DMA`: programs the BAR0 DMA stub (src/dst/len) and polls for done (stub today).

## Recommended next steps
1) Add BAR1 use in the blitter/DMA path and VFIO hooks once needed.
2) Grow the DRM stub with simple GEM IOCTLs and modes (render-only is present).
3) Windows/macOS: KMDF/DriverKit skeletons for BAR mapping and IOCTLs.
4) Toolchain/CI: optional driver builds and Mesa config checks; keep non-blocking.

## Toolchain install notes (manual)
- Linux driver build deps: `sudo apt-get install build-essential linux-headers-$(uname -r) pkg-config` then `make driver-linux`.
- Windows KMDF (when code exists): install Visual Studio Build Tools (Desktop C++), Windows SDK, and WDK (matching SDK); build with `msbuild` on the KMDF project.
- macOS DriverKit (when code exists): install Xcode + Command Line Tools; build with `xcodebuild` on the DriverKit target (signing/provisioning required for deploy).
- BAR0 register sketch lives in `docs/hydra_spec.md` and mirrored offsets in `drivers/linux/uapi/hydra_regs.h`; keep RTL/driver aligned.

## Userspace smoke test (Linux)
- A small helper to exercise BAR0 blitter CSRs lives at `scripts/hydra_blit_smoketest.c`.
- Build: `gcc -I drivers/linux/uapi -O2 -o hydra_blit_smoketest scripts/hydra_blit_smoketest.c` or `make blit-smoketest` (writes to `scripts/hydra_blit_smoketest`).
- Run (requires loaded driver + device present): `sudo ./hydra_blit_smoketest /dev/hydra_pcie`
- It clears/enables INTs, pushes a few words into the blitter FIFO, kicks a FIFO-driven blit, and reads back the destination pixels and INT/STATUS latches.
- Userspace helper lib: `make libhydra` builds `drivers/libhydra/libhydra.a` for simple IOCTL wrappers (info/rd/wr/blit).
- CI:
  - Builds: sim, blitter smoke test, libhydra. Attempts Linux driver build (non-blocking).
  - Mesa stub configure step (non-blocking) to catch wiring mistakes.
