# Homepage, FAQ & Legacy Video TODOs

Tracks killer marketing/support touchpoints (home page, FAQ) plus VGA/legacy video integration requirements to cover older hardware standards.

## P1 - Homepage & FAQ
- **TODO [P1]:** Draft a new home page / landing page outline that highlights Hydra’s core differentiators (voxels, AI automation, multi-board scaling) and links to the machine-readable dashboards.
- **TODO [P1]:** Build a FAQ section (docs/faq.md) covering “How to run Hydra?”, “How to hook into gaming engines?”, “How to interpret AI dashboard outputs?” and link it to `docs/todo/todo_go_to_market.md`.
- **TODO [P1]:** Add a marketing “hero asset” (video, screenshot time-lapse) plus a downloadable asset pack referenced on the home page; include instructions for verifying assets via `out/hydra_assets.json`.
- **TODO [P1]:** Ensure the new home page includes live automation stats (AI dashboard summary, tracker counts) so visitors see current TODO/metta health.

## P2 - Legacy VGA / (S)VGA Support
- **TODO [P2]:** Document VGA / SVGA timing requirements (resolutions, sync, refresh) so Hydra can interface with legacy monitors when needed; store them in `docs/vga_compatibility.md`.
- **TODO [P2]:** Add driver/display adapter code paths (for VGA/SVGA, legacy CRT, or framebuffer mirroring) with appropriate TODOs referencing `todo_hdmi.md`/`todo_hdmi_display.md` for parity.
- **TODO [P2]:** Build a VGA regression harness that converts HDMI output to VGA scanline data for logs (inline emulation) and flags mismatched timings as TODO entries when automation sees the difference.
- **TODO [P2]:** Provide VGA connector work instructions in `docs/todo/todo_board_hardware_design.md` and cross-check with `todo_platform_backends.md` so legacy paths are not forgotten.

## P3 - Support Content & Legacy Notes
- **TODO [P3]:** Maintain a “legacy hardware notes” section describing VGA/CRT quirks, DPI scaling, and power/connector differences; update this tracker when those notes change.
- **TODO [P3]:** Add a mini-site note describing how to transition from legacy displays to HDMI (docs/legacy_transition.md) and tie that note into this tracker for awareness.
