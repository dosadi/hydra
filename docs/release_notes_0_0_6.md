# Hydra 0.0.6 Release Notes

## Highlights
- Added a UAPI version/struct-size query (`HYDRA_IOCTL_VERSION`) and updated user tools to fail fast on ABI mismatches.
- Viewer/backend usability: HUD now shows backend/vsync/renderer, handles window resizes by recreating the texture and clearing the framebuffer, logs input device hints, and allows a CLI backend override (`--backend`/`-b`).
- New bring-up helpers: BAR layout reference, BAR1 hexdump tool, SDL backend probe script, and backend triage guide.
- Xschem scaffold and expanded TODO trackers for rendering, DMA/PCIe, DRAM/AXI, ray engine, HDMI, platform backends, and depth/reemissure paths.

## Driver/UAPI
- New `HYDRA_IOCTL_VERSION` reports ABI major/minor and struct sizes; userland `hydra_mmap_smoke` enforces the match.
- Added `hydra_bar1_hexdump` to map/dump BAR1 for quick sanity checks (skips if absent).
- DMA/PCIe bring-up guide now includes version checks and BAR1 dump steps.

## Viewer / Backends
- Startup logs include backend/vsync/renderer info; HUD shows backend summary.
- SDL viewer recreates its texture on window resize and clears the framebuffer to avoid stretched/hung frames.
- Input capability logging (keyboard hints, mouse capture hints, touch/joystick/controller counts).
- CLI backend override (`--backend name` or `-b name`) sets `HYDRA_BACKEND` without env.

## Docs / Tooling
- New references: `docs/bar_layout.md`, `docs/backend_triage.md`.
- Backend probe script (`scripts/check_backends.sh`, `make backend-probe`) lists SDL video drivers; exits 77 when SDL is missing.
- Xschem workspace scaffolding and render helper (`scripts/xschem_render.sh`).
- Expanded TODO files for rendering quality/pipeline, DMA/PCIe, DRAM/AXI, HDMI, ray engine, depth/reemissure, platform backends, and xschem integration.

## Known Issues / Follow-ups
- Backend preference/CLI vs. env precedence still needs a unit test; GL/Vulkan paths remain stubbed.
- DMA/AXI burst/backpressure handling and real hardware paths remain stubbed; RTL backpressure assertions and benches are still TODO.
- Rendering quality pipeline improvements (fog/AO/AA, reemissure/HUD overlays) remain open.

## Validation
- Not run in this cut; recommended checks:
  - `make docs-only`
  - `cd sim && make`
  - `make sdk-setup` (for tools)
  - `make backend-probe` (optional; requires SDL) and `make bar1-hexdump` on a device with BAR1 present.
