# SDL viewer fails to initialize under X11-less environment

## Summary
`sim/sim_voxel` cannot start under headless or restricted environments: SDL initialization fails when the X11 video backend is unavailable, and EGL falls back to `/dev/dri/renderD128`, which is permission-restricted.

## Reproduction
1. Build in `sim/` with `make` (produces `sim_voxel`).
2. On a host without a working X11 server or GPU access, run:
   - `./sim_voxel`
   - or with software hints: `SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software LIBGL_ALWAYS_SOFTWARE=1 ./sim_voxel`
   - or under Xvfb (if installed): `DISPLAY=:99 SDL_VIDEODRIVER=x11 SDL_RENDER_DRIVER=software ./sim_voxel`

## Expected
Viewer starts using a software renderer (or at least reports a clear dependency error) without requiring GPU device access.

## Actual
- `libEGL warning: failed to open /dev/dri/renderD128: Permission denied`
- With Xvfb attempts: `Error: SDL_Init: x11 not available`
- Xvfb fails to start in this environment: `Cannot establish any listening sockets`.
The process hangs or exits before rendering a window.

## Environment Notes
- `/dev/dri/renderD128` exists but is `crw-rw---- root render`; user `jon` is not in group `render`.
- `xvfb` and some X11/SDL video backends are not present here; starting Xvfb fails to bind a socket.
- SDL2 TTF and SDL2 headers/libs are available for building; runtime lacks a software-only video path.

## Potential Fixes
- Ensure SDL is built/installed with the X11 video driver and software renderer available.
- For headless use, install `xvfb` (and dependencies) and run with `DISPLAY` pointing to it.
- Allow software GL (e.g., mesa llvmpipe) without requiring `renderD128`, or document the need to add users to the `render` group when GPU access is required.
