# Hydra 0.0.3 Release Notes

## Highlights
- **Interface freeze**: CSR/UAPI/spec aligned at REV `0x02`, BUILD `0x01`; HDMI line/pixel regs present; DMA_ERR noted as stubbed.
- **Cross-platform build scaffolding**: root CMake (Linux/MSVC presets), SDK setup helper, top-level driver/backends targets; SDL build guard in sim.
- **Drivers**: Linux misc/DRM stubs aligned to UAPI (DMA polling fixed to STATUS done bit); FreeBSD kmod stub with BAR0/1 mapping and INFO/RD32/WR32/DMA IOCTLs (INT_MASK-gated, DMA/IRQ emulated). Windows/macOS remain stubs.
- **Tests**: Verilator sim builds; cocotb smoke (icarus) for IRQ_TEST/DMA done; RTL DMA loopback SV test in CI; HDMI CRC SV test with golden CRC (0x00020500) in CI. Optional CMake host build runs in CI.
- **Docs**: component status snapshot, Windows sim guide, FreeBSD QEMU quickstart, updated release checklist and driver/platform docs.

## Known limitations
- Platform backends beyond SDL are stubbed (GL/Vulkan/Wayland/X11/fbdev/Win32/macOS no-op).
- FreeBSD kmod and Windows/macOS drivers are stubs; no CI for FreeBSD (requires FreeBSD runner).
- DMA_ERR bit is stubbed in UAPI/RTL.

## Build/Run
- Sim: `cd sim && make` (Verilator + SDL); cocotb smoke: `make -C sim/tests/cocotb_hydra SIM=icarus` (optional).
- RTL tests: DMA loopback and HDMI CRC SV benches (icarus in CI).
- Host libs/tools: `cmake --preset linux-default` (Linux) or `cmake --preset windows-msvc` (MSVC); `./scripts/setup_sdk.sh` builds libhydra + tools.
- FreeBSD kmod stub: `make -f drivers/bsd/Makefile.kmod` on FreeBSD (see `docs/freebsd_qemu.md`).

## TODO (post-0.0.3)
- Make HDMI frame path deterministic and set a golden CRC; improve RTL tests accordingly.
- Flesh out platform backends and Windows/macOS/FreeBSD drivers; add CI for FreeBSD if feasible.
- Implement QEMU PCI stub device and broader deterministic RTL/driver tests.
