# Platform Backend Stubs

Purpose: keep the build ready for future GL/Vulkan/Wayland/X11/fbdev/Win32/macOS backends while remaining buildable everywhere today.

Current state:

- Stub API lives in `sim/platform/platform.h` with a minimal `PlatformBackend` enum and lifecycle functions.
- Implementation in `sim/platform/platform_stub.cpp`:
  - Detects host OS to mark Wayland/X11/fbdev (Linux), Win32, and macOS as “supported”.
  - Returns success from `platform_init` for any OS-supported backend, with no-op present/shutdown; ready to be replaced with real backends.
- Makefile builds the stub alongside `live_sdl_main.cpp` so downstream code can include the header without link errors.
- Stub per-backend files exist (`backend_gl.cpp`, `backend_vulkan.cpp`, `backend_wayland.cpp`, `backend_x11.cpp`, `backend_fbdev.cpp`, `backend_win32.cpp`, `backend_macos.cpp`) returning the stub ops; replace these with real implementations as needed.
- FreeBSD: treated like Linux for backend availability (SDL-only today); add Wayland/X11/fbdev specifics when implemented.

Planned follow-ons (per-OS/driver):

- Linux: fbdev, X11, Wayland + GL/Vulkan contexts.
- Windows: Win32 + GL/Vulkan contexts.
- macOS: Cocoa/Metal (or MoltenVK) context.
- Cross: GL loader (glad/glew) and Vulkan loader (volk) if/when those backends are implemented.

Notes:

- No platform headers are pulled in yet; the stubs are pure C++ and should compile across Linux/Win/macOS.
- When adding real backends, gate them with `#ifdef` and keep a stub fallback to preserve portability and CI green.
