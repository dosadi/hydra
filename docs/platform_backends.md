# Platform Backend Stubs

Purpose: keep the build ready for future GL/Vulkan/Wayland/X11/fbdev/Win32/macOS backends while remaining buildable everywhere today.

Current state:

- API lives in `sim/platform/platform.h` with a minimal `PlatformBackend` enum and lifecycle functions.
- SDL backend (`backend_sdl.cpp`) is live: creates a resizable window, ARGB8888 streaming texture, and presents frames; respects `PlatformConfig` width/height and `vsync` flag (falls back to software renderer if accel+vsync are unavailable).
- Wayland: native path is available behind `HYDRA_ENABLE_WAYLAND` (enable via `make WAYLAND=1` in `sim/Makefile`; requires `wayland-client` headers/libs). It sets up a wl_shell surface with a wl_shm buffer and presents ARGB frames. Without the flag or headers it falls back to stub.
- fbdev: native Linux fbdev backend writes ARGB8888 frames into `/dev/fb0` via mmap; only 32bpp framebuffers are supported. Non-Linux builds fall back to stub.
- X11: optional native X11 backend gated by `make X11=1` (needs Xlib headers/libs). Creates an X11 window and uses an XImage blit for ARGB frames; without the flag it falls back to the stub.
- GL: optional OpenGL backend gated by `make GL=1` (needs SDL2 with OpenGL headers and GL libs). Uses an SDL-created GL context and `glDrawPixels` to blit ARGB frames (BGRA upload) with window-size scaling; without the flag it falls back to the stub.
- Vulkan: optional Vulkan backend gated by `make VULKAN=1` (needs Vulkan SDK headers/libs and SDL2 Vulkan helpers). Creates a Vulkan instance/surface via SDL, swapchain, staging buffer upload, and presents frames; without the flag it falls back to the stub.
- Win32/macOS: temporarily reuse the SDL path on their respective platforms; elsewhere they compile as stubs. Replace with native Win32/Cocoa implementations when available.
- Viewer integration: `sim/live_sdl_main.cpp` now consults `HYDRA_BACKEND` (via `select_default_backend`) and, when a non-SDL backend is selected and initialized, passes rendered frames through `present_backend` while still running the SDL HUD/window for input.
- CLI override: `--backend <name>` (or `--backend=name`, `-b <name>`) sets `HYDRA_BACKEND` for a run without exporting env vars.
- `platform_stub.cpp` still brokers backend selection and reports platform support (Wayland/X11/fbdev on Linux; Win32; macOS).
- VNC: optional VNC server backend gated by `make VNC=1` (needs libvncserver headers/libs). Creates a VNC server on port 5900 that remote clients can connect to for viewing; frames are streamed as they render. Useful for remote access, automation, and mobile viewing.
- Makefile builds the platform layer alongside `live_sdl_main.cpp` so downstream code can include the header without link errors.
- FreeBSD: treated like Linux for backend availability (SDL today); add Wayland/X11/fbdev specifics when implemented.

Planned follow-ons (per-OS/driver):

- Linux: fbdev, X11, Wayland + GL/Vulkan contexts.
- Windows: Win32 + GL/Vulkan contexts.
- macOS: Cocoa/Metal (or MoltenVK) context.
- Cross: GL loader (glad/glew) and Vulkan loader (volk) if/when those backends are implemented.

Notes:

- No platform headers are pulled in yet; the stubs are pure C++ and should compile across Linux/Win/macOS.
- When adding real backends, gate them with `#ifdef` and keep a stub fallback to preserve portability and CI green.

## Backend compatibility matrix (current coverage)

| OS/Env  | SDL (default) | GL | Vulkan | X11 | Wayland | fbdev | VNC | Headless/dummy | CI coverage |
|---------|---------------|----|--------|-----|---------|-------|-----|----------------|-------------|
| Linux   | ✅ (primary)  | ⚪ stub impl | ⚪ stub impl | ⚪ stub | ⚪ stub  | ⚪ experimental | ✅ (libvncserver) | ✅ (dummy/headless) | Dummy/headless smoke only |
| FreeBSD | ✅ (SDL path) | ⚪ stub | ⚪ stub | ⚪ stub | ⚪ stub | ⚪ stub | ✅ (libvncserver) | ✅ (dummy/headless) | Not in CI |
| Windows | ✅ (SDL path) | ⚪ stub | ⚪ stub | n/a | n/a | n/a | ✅ (libvncserver) | ✅ (SDL dummy) | Not in CI |
| macOS   | ✅ (SDL path) | ⚪ stub | ⚪ stub | n/a | n/a | n/a | ✅ (libvncserver) | ✅ (SDL dummy) | Not in CI |

Legend: ✅ implemented/used, ⚪ placeholder/stub today. SDL dummy/headless is the regression path; GPU backends are not exercised in CI yet.

## CI guidance
- GL/Vulkan jobs should be skipped (not failed) when drivers/tooling are missing; capture backend capability logs as artifacts when present.
- Primary regression path uses SDL dummy/headless; enable GL/Vulkan/X11/Wayland jobs best-effort only when runners provide the dependencies.
