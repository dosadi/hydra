# Driver Integration Plan (Hydra PCIe Device)

**Last Updated:** 2025-11-26
**Owner:** Driver Team
**Depends:** `hydra_spec.md`
**Related Trackers:** `todo/todo_dma_pcie.md`, `todo/todo_testing_ci.md`, `todo/todo_multiplatform_builds.md`

---

Goal: prepare cross-platform driver scaffolding so the Hydra PCIe device can be brought up quickly on Linux, Windows, and macOS, while keeping stubs that do not break builds.

## Targets
- Linux: out-of-tree kernel module stub (PCIe); future path: DRM/KMS + VFIO; userspace GL/Vulkan can talk to a DRM node.
- Windows: KMDF/WDF PCIe driver stub; future path: WDDM miniport if presenting as a GPU.
- macOS: DriverKit/SystemExtensions PCIe driver stub; future path: IOUserClient-style interface.
- FreeBSD: PCI driver stub mirroring the Linux UAPI for BAR mapping and IOCTLs (DMA stubbed).
- Mesa: Gallium stub (placeholder) to be dropped into Mesa tree when IOCTLs settle.

## Current Stubs (in-tree)
- `drivers/linux/hydra_pcie_drv.c`: PCI driver with BAR0 map, DMA masks, MSI/MSI-X/legacy IRQ, debugfs, misc-device IOCTLs.
- `drivers/linux/Makefile`: out-of-tree `obj-m` for PCIe + DRM stub build.
- `drivers/windows/README.md`: notes for KMDF setup (code TBD).
- `drivers/macos/README.md`: notes for DriverKit setup (code TBD).
- `drivers/linux/hydra_drm_stub.c`: DRM render-only stub using GEM shmem helpers; binds to PCI ID, maps BAR0, registers a DRM device (no planes/modes yet).
- `drivers/mesa/`: placeholder Gallium skeleton (`meson.build`, stub C) to guide Mesa integration later.
- `drivers/libhydra/`: tiny userspace helper library wrapping IOCTLs (info/rd/wr/dma/blit).
- `drivers/bsd/`: FreeBSD stub (`hydra_pci_stub.c`, `Makefile.kmod`) with BAR0/1 mapping, `/dev/hydra` mmap (BAR0 then BAR1), sysctl counters for IRQ/DMA stats, and IOCTLs for INFO/RD32/WR32/DMA (DMA stubbed, sets DMA_STATUS/INT_STATUS). Build with `make -C drivers/bsd -f Makefile.kmod` on a FreeBSD host with kernel sources/headers.
- See `docs/freebsd_qemu.md` for a quick QEMU-based FreeBSD setup to build/load the stub.
- For a quick maturity snapshot, see `docs/component_status.md`. Windows sim/build notes live in `docs/windows_sim.md`.

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

In addition:
- `scripts/hydra_cam_reset`, `scripts/hydra_irq_test`, and `scripts/hydra_bar1_hexdump` form the core of `scripts/driver_coverage.sh`, which collects logs under `out/driver-coverage/` to flag regressions quickly; see `docs/driver_coverage_guide.md` for usage notes.
- Running `scripts/setup_macos_env.sh` or `scripts/windows-env.ps1` primes SDL2/Python so that any driver-side cocotb/tooling smoke tests can compile/run on those hosts.

## Userspace smoke test (Linux)
- A small helper to exercise BAR0 blitter CSRs lives at `scripts/hydra_blit_smoketest.c`.
- Build: `gcc -I drivers/linux/uapi -O2 -o hydra_blit_smoketest scripts/hydra_blit_smoketest.c` or `make blit-smoketest` (writes to `scripts/hydra_blit_smoketest`).
- Run (requires loaded driver + device present): `sudo ./hydra_blit_smoketest /dev/hydra_pcie`.
- It clears/enables INTs, pushes a few words into the blitter FIFO, kicks a FIFO-driven blit, and reads back the destination pixels and INT/STATUS latches.
- Userspace helper lib: `make libhydra` builds `drivers/libhydra/libhydra.a` for simple IOCTL wrappers (info/rd/wr/blit/dma).
- Example Linux bring-up loop:
  1. Build SDK + tools: `./scripts/setup_sdk.sh` (builds libhydra, blitter smoke, and DRM info helper when libdrm is present).
  2. Build and load the Linux PCIe/DRM stubs per `drivers/linux/README.md` (out-of-tree kmod build + `modprobe hydra_pcie_drv hydra_drm_stub`).
  3. Run `sudo ./scripts/hydra_blit_smoketest /dev/hydra_pcie` and confirm STATUS/INT_STATUS and PIX reads look sane.
  4. Optionally run `./scripts/hydra_dma_blit_demo` (libhydra-based) or write your own tiny tool that calls `hydra_dma_copy()` followed by `hydra_blit_*()` to validate DMA+blit IRQ paths.
- DRM info tool: `make drm-info` builds `scripts/hydra_drm_info` (requires libdrm); queries DRM ioctl info and reads STATUS/INT_STATUS via CSROUT.
- CI:
  - Builds: Linux host tools, Verilated sim, and runs the frame regression (`make -C sim test_frame`).
  - Builds SDK tools via `scripts/setup_sdk.sh` and runs best-effort RTL benches and a cocotb smoke job (Icarus) when tools are available.
  - Optional QEMU smoke job (`qemu-smoke`) exercises a QEMU Hydra PCI stub and guest when configured; a best-effort FreeBSD kmod job (`freebsd-kmod`) builds the BSD stub in a VM.
  - Mesa stub configure step (non-blocking) can be added later to catch wiring mistakes.

## Driver bring-up checklist (Linux / FreeBSD)

Linux (PCIe stub + misc/DRM):
1. Build and load modules: `make -C drivers/linux` then `sudo insmod hydra_pcie_drv.ko` (and `hydra_drm_stub.ko` if needed).
2. Confirm devnode: `/dev/hydra_pcie` exists; `dmesg | grep hydra` shows BAR0/1 sizes and MSI/legacy status.
3. Sanity IOCTLs: `sudo ./scripts/hydra_blit_smoketest /dev/hydra_pcie` and `./scripts/hydra_irq_test /dev/hydra_pcie` (expect INT_STATUS clears and IRQ_TEST pulses).
4. ABI check: `./scripts/hydra_drm_info` (if libdrm present) reports HYDRA_IOCTL_VERSION match and BAR info; ABI mismatch should fail the tool.
5. BAR1 (if present): `./scripts/hydra_bar1_hexdump` reads a small range without faults; expect non-zero BAR1 length in INFO.

FreeBSD (PCI stub):
1. Build: `make -C drivers/bsd -f Makefile.kmod`; load with `sudo kldload ./hydra.ko`.
2. Confirm devnode: `/dev/hydra` exists; `dmesg | grep hydra` shows BAR0/1 mapping.
3. Sanity IOCTLs + mmap: `./scripts/hydra_irq_test /dev/hydra` (INFO/RD32/WR32/DMA stubs) and `./scripts/hydra_bsd_info /dev/hydra` for INFO + IRQ_TEST + DMA + sysctl stats; `/dev/hydra` mmap maps BAR0 followed by BAR1 if present.
4. ABI check: `./scripts/hydra_drm_info /dev/hydra` (best-effort; HYDRA_IOCTL_VERSION supported in the stub) to verify struct sizes.
5. Unload: `sudo kldunload hydra` cleanly frees BAR resources and cdev; sysctl nodes under `dev.hydra.*` should disappear.

Expected readings at probe (both OSes):
- `ID`: vendor `0x1BAD`, device `0x2024`; `REV`: rev `0x02`, build `0x01` (for 0.0.3-era map).
- Reset defaults: `FLAGS` smooth=1, curvature=1, extra_light=0, diag_slice=0; `INT_STATUS`/`INT_MASK`/`DMA_STATUS` zeroed; `FB_BASE`/`FB_STRIDE` zeroed; selection inactive.

## FreeBSD Driver Parity Status

### Current Implementation Status

| Feature | Linux | FreeBSD | Notes |
|---------|-------|---------|-------|
| **PCI Device Detection** | ✅ Full | ✅ Stub | Both detect Hydra PCI devices |
| **BAR Mapping** | ✅ BAR0 + BAR1 | ❌ Not implemented | FreeBSD stub doesn't map BARs yet |
| **Interrupt Handling** | ✅ MSI/MSI-X/Legacy | ❌ Not implemented | FreeBSD stub lacks IRQ setup |
| **IOCTL Interface** | ✅ Full UAPI | ❌ Not implemented | FreeBSD has no IOCTLs yet |
| **Debugfs/sysctl** | ✅ Debugfs | ✅ Basic sysctl | FreeBSD has basic kmod loading stats |
| **DMA Support** | ✅ Stubbed | ❌ Not implemented | Neither has real DMA yet |
| **DRM/KMS** | ✅ Stub | ❌ Not planned | Linux-only graphics stack integration |
| **Build System** | ✅ Out-of-tree | ✅ Stub Makefile | Both support kmod building |
| **CI Integration** | ❌ Manual | ✅ Best-effort VM | FreeBSD builds in CI, Linux doesn't |

### IOCTL Parity Matrix

| IOCTL | Linux Status | FreeBSD Status | Description |
|-------|-------------|----------------|-------------|
| `HYDRA_IOCTL_INFO` | ✅ Implemented | ❌ Planned | Device info (vendor/device/IRQ/BARs) |
| `HYDRA_IOCTL_RD32` | ✅ Implemented | ❌ Planned | 32-bit BAR0 read |
| `HYDRA_IOCTL_WR32` | ✅ Implemented | ❌ Planned | 32-bit BAR0 write |
| `HYDRA_IOCTL_DMA` | ✅ Stubbed | ❌ Planned | DMA operation setup |
| `HYDRA_IOCTL_BLIT` | ✅ Stubbed | ❌ Planned | 3D blitter control |
| `DRM_IOCTL_HYDRA_INFO` | ✅ Implemented | ❌ N/A | DRM-specific device info |

### Build and Installation

**Linux:**
```bash
# Build
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# Install
sudo insmod hydra_pcie_drv.ko

# Verify
ls /dev/hydra_pcie
ls /sys/kernel/debug/hydra_pcie/
```

**FreeBSD:**
```bash
# Build (requires kernel sources)
cd drivers/bsd
make -f Makefile.kmod

# Install
sudo kldload ./hydra.ko

# Verify (limited functionality)
kldstat | grep hydra
sysctl dev.hydra  # Basic stats only
```

### Testing and Validation

**Linux Testing:**
- Full IOCTL test suite available
- Debugfs for register inspection
- Integration with libhydra userspace library
- DMA and blitter stub testing

**FreeBSD Testing:**
- Basic kmod load/unload testing
- QEMU VM setup for development
- Limited to kernel module validation
- No userspace integration yet

### Development Status

**FreeBSD Driver Roadmap:**
1. **Phase 1 (Current)**: PCI device detection and basic kmod framework
2. **Phase 2 (Planned)**: BAR mapping and basic IOCTLs (INFO/RD32/WR32)
3. **Phase 3 (Future)**: Full DMA and blitter support
4. **Phase 4 (Distant)**: DRM/KMS integration (if needed)

**Parity Timeline:**
- Basic BAR/IOCTL support: ~2-4 weeks development
- Full DMA integration: ~4-6 weeks (depends on Linux DMA work)
- Complete feature parity: ~8-12 weeks

### Usage Recommendations

**For Development:**
- Use Linux for full driver development and testing
- Use FreeBSD QEMU setup for basic kmod validation
- Cross-platform testing focuses on Linux first

**For Production:**
- Linux is the primary supported platform
- FreeBSD support is experimental/stub-level
- Windows/macOS support is not yet implemented

### Known Limitations

**FreeBSD Specific:**
- No BAR memory mapping (reads/writes not possible)
- No interrupt handling or MSI setup
- No userspace IOCTL interface
- Limited debugging facilities (basic sysctl only)
- QEMU-based development environment required

**Cross-Platform:**
- DMA implementation is stubbed on both platforms
- 3D blitter is bring-up level on both platforms
- DRM integration is Linux-only
- No Windows or macOS driver implementation yet

### Contributing

To improve FreeBSD support:
1. Study `drivers/bsd/hydra_pci_stub.c` and expand PCI attachment
2. Add BAR mapping similar to Linux driver
3. Implement IOCTL handlers using FreeBSD's ioctl framework
4. Add interrupt handling and MSI support
5. Create userspace library (libhydra-bsd)

See `docs/freebsd_qemu.md` for development environment setup.
