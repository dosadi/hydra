# Hydra Component Status (0.0.3)

Quick maturity snapshot to track what’s stubbed vs. operational.

## RTL
- Operational (sim): voxel core, AXI-Lite CSR (rev 0x02/build 0x01), AXI shell, DMA/crossbar/SDRAM/stream stubs; builds with Verilator/icarus. Deterministic tests (DMA loopback, HDMI CRC golden) still needed.
- Stubbed: external IP replacements (LitePCIe/LiteDRAM/LiteVideo), real MSI/IRQ wiring.

## Drivers/UAPI
- Linux: misc PCIe + DRM render-only stubs, UAPI aligned to spec; libhydra + user tools build.
- FreeBSD: kmod stub with BAR0/1 map, INFO/RD32/WR32/DMA IOCTLs (DMA/INT emulated, INT_MASK honored for DMA). No real IRQ/DMA.
- Windows/macOS: README notes only (no code).
- UAPI headers: aligned to spec (HDMI regs, INT bits, DMA).

## Platform backends
- Stubbed: GL/Vulkan/Wayland/X11/fbdev/Win32/macOS backends (no-op). SDL path is functional via sim.

## Build/CI tooling
- Makeflow: sim build; cocotb smoke (icarus) for IRQ_TEST/DMA done; top-level targets for drivers/backends/sdk.
- CMake: host-side libhydra + tools for Linux/MSVC via presets.
- FreeBSD: kmod builds via Makefile.kmod (manual).
- Needs: CI coverage for CMake presets, deterministic RTL tests, optional FreeBSD build check.

## Docs
- Spec, driver integration, IP plan, platform backends, hardware test plan, release checklist, FreeBSD QEMU guide, Windows sim notes.
- Needs: eventual Windows/macOS driver docs when code lands; more detailed Windows sim build guide when verified.
