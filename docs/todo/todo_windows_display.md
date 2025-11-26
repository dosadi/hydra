# Windows Display Stack TODOs

Tracks Windows-specific display work (2D/3D drivers, legacy VGA/VESA BIOS compatibility, emulation layers) and ties it to automation health so cross-platform QA knows where regressions live.

## P1 - 2D / 3D Driver Work
- **TODO [P1]:** Implement Windows 2D driver support (GDI, DirectDraw) in the WDM/WDDM stack with clear IOCTL and DMA pathways; link coverage to `docs/todo/todo_mesa_drivers.md` for parity.
- **TODO [P1]:** Build Windows 3D support (Direct3D feature levels, OpenGL via EGL) so Hydra apps can render through user-mode APIs; document integration work in `docs/design_gaming_integration.md`.
- **TODO [P1]:** Add Windows shader/streamed texture helpers (`libhydra_win.dll`) that hook into GL32/GL64 pipelines and surface extension usage in `scripts/ai_health_dashboard.py`.
- **TODO [P1]:** Register Windows driver telemetry (present intervals, DMA stats) with `services/windows_monitoring` and capture the metrics in `out/windows_display_health.json` for AI dashboards.

## P2 - VGA / VESA / BIOS Compatibility
- **TODO [P2]:** Document VGA/VESA BIOS interfaces that Hydra should support (timings, registers, mode tables) and add BIOS emulation plans into `docs/vga_compatibility.md`.
- **TODO [P2]:** Provide a VGA BIOS emulation helper in the driver/SDK (possibly firmware) to expose legacy modes via `int10h` hooks for older software.
- **TODO [P2]:** Create fallback rendering paths that target VGA/SVGA output (via BIOS or direct CRT timing) so Hydra can service legacy hardware when HDMI/DP isn't available.
- **TODO [P2]:** Add Windows scripts for flashing/updating VGA BIOS/firmware images and tie them to release automation (documentation + automation dashboards).

## P3 - Automation & Legacy Preservation
- **TODO [P3]:** Maintain a legacy support checklist (VGA, VESA, BIOS) in this tracker so automation can count stability for older modes separately from modern drivers.
- **TODO [P3]:** Document how Windows display changes affect cross-platform automation (AI dashboard, metadata, sector map) so enabling legacy modes reports in the same dashboards.
- **TODO [P3]:** Explore creating virtualization/EMU-based VGA testing harness (UEFI/BIOS emulator) that logs before/after states for the AI health dashboard.
