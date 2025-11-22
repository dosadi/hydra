# Driver Integration Plan (Hydra PCIe Device)

Goal: prepare cross-platform driver scaffolding so the Hydra PCIe device can be brought up quickly on Linux, Windows, and macOS, while keeping stubs that do not break builds.

## Targets
- Linux: out-of-tree kernel module stub (PCIe); future path: DRM/KMS + VFIO; userspace GL/Vulkan can talk to a DRM node.
- Windows: KMDF/WDF PCIe driver stub; future path: WDDM miniport if presenting as a GPU.
- macOS: DriverKit/SystemExtensions PCIe driver stub; future path: IOUserClient-style interface.
- Mesa: Gallium stub (placeholder) to be dropped into Mesa tree when IOCTLs settle.

## Current Stubs (in-tree)
- `drivers/linux/hydra_pcie_drv.c`: minimal PCI driver that binds to a configurable vendor/device ID, logs probe/remove, and leaves BAR mapping TODO. Not built by default.
- `drivers/linux/Makefile`: out-of-tree `obj-m` stub for convenience.
- `drivers/windows/README.md`: notes for KMDF setup (code TBD).
- `drivers/macos/README.md`: notes for DriverKit setup (code TBD).
- `drivers/linux/hydra_drm_stub.c`: DRM render-only stub using GEM shmem helpers; binds to PCI ID, maps BAR0, and registers a DRM device (no planes/modes yet).
- `drivers/mesa/`: placeholder Gallium skeleton (`meson.build`, stub C) to guide Mesa integration later.
- `drivers/libhydra/`: tiny userspace helper library wrapping IOCTLs and blitter helpers.

## Recommended next steps
1) Define PCI IDs and BAR layout (register map, MSI usage) and fill into the Linux stub.
2) Add BAR mapping and a simple `debugfs` or `ioctl` path to poke CSRs (camera/flags).
3) For userspace rendering: add a DRM driver skeleton (mode-setting optional) or VFIO IOMMU hook for passthrough experiments.
4) Windows: create a KMDF skeleton (EvtDeviceAdd, BAR mapping, basic IOCTL).
5) macOS: create a DriverKit project with PCI matching and BAR mapping.
6) Toolchain/CI: add optional builds behind `make -C drivers/linux` and keep them off by default to avoid kernel header requirements in CI.

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
