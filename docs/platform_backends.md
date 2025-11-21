# Platform Backend Stubs

Purpose: keep the build ready for future GL/Vulkan/Wayland/X11/fbdev/Win32/macOS backends while remaining buildable everywhere today.

Current state:

- Stub API lives in `sim/platform/platform.h` with a minimal `PlatformBackend` enum and no-op lifecycle functions.
- Implementation is stubbed in `sim/platform/platform_stub.cpp`; `PlatformBackend::SDL` reports “supported”, while Linux-only backends (Wayland/X11/fbdev) and cross backends (GL/Vulkan) report “supported” based on host OS but still return false from init until implemented.
- Makefile builds the stub alongside `live_sdl_main.cpp` so downstream code can include the header without link errors.

Planned follow-ons (per-OS/driver):

- Linux: fbdev, X11, Wayland + GL/Vulkan contexts.
- Windows: Win32 + GL/Vulkan contexts.
- macOS: Cocoa/Metal (or MoltenVK) context.
- Cross: GL loader (glad/glew) and Vulkan loader (volk) if/when those backends are implemented.

Notes:

- No platform headers are pulled in yet; the stubs are pure C++ and should compile across Linux/Win/macOS.
- When adding real backends, gate them with `#ifdef` and keep a stub fallback to preserve portability and CI green.
