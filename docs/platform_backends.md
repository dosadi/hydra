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
- `platform_stub.cpp` still brokers backend selection and reports platform support (Wayland/X11/fbdev on Linux; Win32; macOS).
- Other per-backend files (`backend_gl.cpp`, `backend_vulkan.cpp`, `backend_x11.cpp`) currently return stub ops; replace with real implementations as needed.
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
