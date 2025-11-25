# Hydra Component Status (0.0.6)

Quick maturity snapshot to track what’s stubbed vs. operational.

## RTL
- Operational (sim): voxel core, AXI-Lite CSR (rev 0x02/build 0x01), AXI shell, DMA/crossbar/SDRAM/stream stubs; builds with Verilator/icarus. Deterministic frame-path test wired into CI via `make -C sim test_frame`; additional RTL benches (DMA loopback, HDMI CRC golden) runnable via `sim/tests/run_rtl_tests.sh`.
- Stubbed: external IP replacements (LitePCIe/LiteDRAM/LiteVideo) and board-level PCIe endpoint; core IRQ/INT/`msi_pulse` paths are implemented and exercised in sim but not yet wired into a physical card.

## Drivers/UAPI
- Linux: misc PCIe + DRM render-only stubs, UAPI aligned to spec; libhydra + user tools build. UAPI now exposes a version/struct-size query for compatibility checks.
- FreeBSD: kmod stub with BAR0/1 map, INFO/RD32/WR32/DMA IOCTLs (DMA/INT emulated, INT_MASK honored for DMA). No real IRQ/DMA.
- Windows/macOS: README notes only (no code).
- UAPI headers: aligned to spec (HDMI regs, INT bits, DMA).

## Platform backends
- Stubbed: GL/Vulkan/Wayland/X11/fbdev/Win32/macOS backends (no-op). SDL path is functional via sim.

## Build/CI tooling
- Makeflow: sim build; optional cocotb smoke (icarus) for IRQ_TEST/DMA done; top-level targets for drivers/backends/sdk.
- CMake: host-side libhydra + tools for Linux/MSVC via presets; Linux preset built in CI.
- CI: GitHub Actions job builds Linux host tools, Verilated sim, and runs the headless frame regression (`make -C sim test_frame`). A best-effort RTL bench wrapper runs when iverilog/vvp are available, an optional cocotb job runs a smoke test via Icarus, and an optional QEMU smoke job is wired but off by default.
- FreeBSD: kmod builds via Makefile.kmod; a best-effort CI job uses a FreeBSD VM action to build the stub when available.
- Needs: expand cocotb coverage and consider a dedicated FreeBSD runner if available.

## Docs
- Spec, driver integration, IP plan, platform backends, hardware test plan, release checklist, FreeBSD QEMU guide, Windows sim notes.
- Needs: eventual Windows/macOS driver docs when code lands; more detailed Windows sim build guide when verified.
