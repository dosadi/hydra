# Backend Triage (SDL/GL/Vulkan)

Common failures and quick fixes:
- `SDL_Init failed` / no video driver: set `SDL_VIDEODRIVER=dummy` for headless or install X11/Wayland packages; on Wayland, ensure `XDG_RUNTIME_DIR` is set.
- `CreateRenderer failed` / GL context missing: force software with `SDL_RENDER_DRIVER=software` or request SDL backend (`HYDRA_BACKEND=SDL`); install OpenGL drivers/mesa.
- `TTF_Init failed`: install `libsdl2-ttf-dev` (or platform equivalent); set `HYDRA_FONT=/path/to/font.ttf`.
- Vulkan missing: install `vulkan-loader`/GPU drivers; use `HYDRA_BACKEND=SDL` or `HYDRA_BACKEND=GL` as fallback.
- Backend mismatch: startup logs show requested vs. actual; adjust `HYDRA_BACKEND`, `SDL_VIDEODRIVER`, or compiled backend options.

Checklist before filing bugs:
1) Run `scripts/check_backends.sh` (skips if SDL missing) to list video drivers.
2) Capture stderr from `sim_voxel` startup (backend info, renderer name, vsync).
3) Note display server (X11/Wayland) and GPU/driver versions.
4) If headless, set `SDL_VIDEODRIVER=dummy HYDRA_BACKEND=SDL` and re-run.
