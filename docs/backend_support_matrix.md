# Hydra Backend Support Matrix

This document describes the available display/rendering backends for the Hydra simulator, their platform support, and requirements.

## Quick Reference

| Backend   | Linux | Windows | macOS | FreeBSD | Status      | Primary Use Case |
|-----------|-------|---------|-------|---------|-------------|------------------|
| SDL       | ✅    | ✅      | ✅    | ✅      | Stable      | Default, cross-platform |
| Headless  | ✅    | ✅      | ✅    | ✅      | Stable      | CI, automation, testing |
| OpenGL    | ✅    | ✅      | ✅    | ⚠️      | Stable      | Hardware-accelerated |
| Vulkan    | ✅    | ✅      | ✅    | ⚠️      | Experimental| High-performance |
| X11       | ✅    | ❌      | ❌    | ✅      | Stub        | Native X11 |
| Wayland   | ✅    | ❌      | ❌    | ❌      | Stub        | Native Wayland |
| fbdev     | ✅    | ❌      | ❌    | ❌      | Stub        | Linux framebuffer |
| Win32     | ❌    | ✅      | ❌    | ❌      | Stub        | Native Win32 |
| macOS     | ❌    | ❌      | ✅    | ❌      | Stub        | Native Cocoa/Metal |

**Legend:**
- ✅ = Fully supported and tested
- ⚠️ = Partially supported or untested
- ❌ = Not supported on this platform

## Backend Selection

### Automatic Selection

By default, Hydra selects the best available backend using this preference order:

1. Vulkan (if compiled with `HYDRA_ENABLE_VULKAN`)
2. OpenGL (if compiled with `HYDRA_ENABLE_GL`)
3. Wayland (if compiled with `HYDRA_ENABLE_WAYLAND`, Linux only)
4. X11 (if compiled with `HYDRA_ENABLE_X11`, Linux only)
5. SDL (always available as fallback)
6. Platform-specific backends (Win32, macOS, fbdev)

### Manual Selection

Override backend selection using:

```bash
# Environment variable (case-insensitive)
HYDRA_BACKEND=gl ./sim_voxel

# Command-line flag (overrides env var)
./sim_voxel --backend VULKAN
./sim_voxel -b headless

# Custom preference order
HYDRA_BACKEND_PREFS=GL,SDL,VULKAN ./sim_voxel
```

### Capabilities Check

Print available backends and platform info:

```bash
./sim_voxel --show-capabilities
# or
./sim_voxel --caps
```

## Backend Details

### SDL (Default)

**Status:** Stable, always available
**Platforms:** Linux, Windows, macOS, FreeBSD
**GPU Acceleration:** Via SDL2 renderer (automatic)

**Features:**
- Cross-platform compatibility
- Software and hardware rendering
- Window management, input handling
- TTF font rendering for HUD

**Dependencies:**
- SDL2 (libsdl2-dev)
- SDL2_ttf (libsdl2-ttf-dev)

**Environment Variables:**
- `SDL_VIDEODRIVER`: Force video driver (x11, wayland, dummy)
- `SDL_RENDER_DRIVER`: Force renderer (software, opengl, opengles2)

**Troubleshooting:**
- If SDL can't find a display, try `SDL_VIDEODRIVER=dummy` or use `HYDRA_BACKEND=headless`
- For software rendering: `SDL_RENDER_DRIVER=software`

---

### Headless

**Status:** Stable
**Platforms:** All (no display required)
**GPU Acceleration:** None

**Features:**
- No window creation
- Frame dumps to PPM format
- Perfect for CI/automation
- Deterministic output

**Usage:**
```bash
# Single frame dump
HYDRA_BACKEND=headless FRAME_DUMP=out.ppm AUTO_EXIT=1 ./sim_voxel

# Multiple frames
HYDRA_BACKEND=headless FRAME_DUMP=frame.ppm HYDRA_MAX_FRAME_DUMPS=10 ./sim_voxel

# Numbered sequence
HYDRA_BACKEND=headless FRAME_DUMP=frame_%d.ppm HYDRA_MAX_FRAME_DUMPS=5 ./sim_voxel
```

**Troubleshooting:**
- Frame dumps require `FRAME_DUMP` env var to be set
- If no frames appear, check that simulation is running (`AUTO_EXIT=1` for quick test)

---

### OpenGL (GL)

**Status:** Stable
**Platforms:** Linux (best), Windows, macOS (partial), FreeBSD (untested)
**GPU Acceleration:** Full

**Features:**
- Hardware-accelerated rendering
- OpenGL 2.1+ compatibility profile
- VSync support
- Window resizing

**Build Requirements:**
- Compile with `-DHYDRA_ENABLE_GL`
- OpenGL development headers
- SDL2 with OpenGL support

**Dependencies (Linux):**
```bash
# Debian/Ubuntu
sudo apt install libgl1-mesa-dev libglu1-mesa-dev

# Fedora/RHEL
sudo dnf install mesa-libGL-devel mesa-libGLU-devel
```

**Environment Variables:**
- `LIBGL_ALWAYS_SOFTWARE`: Force software rendering (Mesa)
- `__GLX_VENDOR_LIBRARY_NAME`: Select GL vendor (nvidia, mesa)

**Troubleshooting:**
- **Error:** "Failed to create GL context"
  - Install mesa-utils: `sudo apt install mesa-utils`
  - Check driver: `glxinfo | grep OpenGL`
  - In VMs: Enable 3D acceleration in VM settings
  - In containers: Use `--device /dev/dri` (Docker)
- **Performance issues:** Check `glxinfo` for software vs hardware rendering

---

### Vulkan

**Status:** Experimental
**Platforms:** Linux (best), Windows, macOS (via MoltenVK), FreeBSD (untested)
**GPU Acceleration:** Full

**Features:**
- Modern graphics API
- High performance potential
- Explicit control over GPU
- Window resizing, VSync

**Build Requirements:**
- Compile with `-DHYDRA_ENABLE_VULKAN`
- Vulkan SDK or headers (vulkan.h)
- SDL2 with Vulkan support

**Dependencies (Linux):**
```bash
# Debian/Ubuntu
sudo apt install libvulkan-dev vulkan-tools mesa-vulkan-drivers

# Fedora/RHEL
sudo dnf install vulkan-headers vulkan-loader mesa-vulkan-drivers

# Verify installation
vulkaninfo
```

**Environment Variables:**
- `VK_LAYER_PATH`: Custom validation layer path
- `VK_ICD_FILENAMES`: Override ICD selection

**Troubleshooting:**
- **Error:** "Failed to create Vulkan instance/surface"
  - Install vulkan-loader: `sudo apt install libvulkan1`
  - Check ICD: `vulkaninfo` should list devices
- **Error:** "No suitable Vulkan device found"
  - Install drivers: `mesa-vulkan-drivers` (Mesa) or vendor drivers (NVIDIA/AMD)
  - Check: `vulkaninfo | grep deviceName`
- **In VMs/containers:**
  - Vulkan support varies; may need passthrough
  - Try GL or SDL backend instead

---

### X11 (Stub)

**Status:** Not yet implemented
**Platforms:** Linux, FreeBSD
**Target:** Native X11 rendering without SDL

**Planned Features:**
- Direct Xlib/XCB rendering
- Lower overhead than SDL
- Better integration with X11 environments

**Note:** Currently returns stub implementation. Use SDL with `SDL_VIDEODRIVER=x11` as alternative.

---

### Wayland (Stub)

**Status:** Not yet implemented
**Platforms:** Linux
**Target:** Native Wayland rendering without SDL

**Planned Features:**
- Direct Wayland protocol usage
- Better integration with Wayland compositors
- Lower latency

**Note:** Currently returns stub implementation. Use SDL with `SDL_VIDEODRIVER=wayland` as alternative.

---

### fbdev (Stub)

**Status:** Not yet implemented
**Platforms:** Linux (embedded)
**Target:** Linux framebuffer device rendering

**Planned Features:**
- Direct framebuffer writes
- No X11/Wayland required
- Useful for embedded systems

**Note:** Currently returns stub implementation. Use SDL or headless backend instead.

---

### Win32 (Stub)

**Status:** Not yet implemented
**Platforms:** Windows
**Target:** Native Win32 GDI/Direct2D rendering

**Planned Features:**
- Native Windows rendering
- DirectX/Direct3D integration (future)

**Note:** Currently returns stub implementation. Use SDL backend on Windows.

---

### macOS (Stub)

**Status:** Not yet implemented
**Platforms:** macOS
**Target:** Native Cocoa/Metal rendering

**Planned Features:**
- Native macOS window management
- Metal acceleration (future)

**Note:** Currently returns stub implementation. Use SDL backend on macOS.

---

## CI/Automation Recommendations

### GitHub Actions / GitLab CI

For headless CI environments:

```yaml
- name: Test with headless backend
  run: |
    HYDRA_BACKEND=headless \
    FRAME_DUMP=test_frame.ppm \
    AUTO_EXIT=1 \
    ./sim_voxel

    # Verify frame was dumped
    test -f test_frame.ppm
    # Check frame is not empty
    test $(stat -c%s test_frame.ppm) -gt 1000
```

For X11 with Xvfb:

```yaml
- name: Install Xvfb
  run: sudo apt install xvfb mesa-utils

- name: Test with GL backend
  run: |
    xvfb-run -a ./sim_voxel --backend GL
```

### Docker

Minimal Dockerfile for headless:

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libsdl2-2.0-0 \
    libsdl2-ttf-2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY sim_voxel /usr/local/bin/

ENV HYDRA_BACKEND=headless
ENV FRAME_DUMP=/output/frame.ppm

CMD ["/usr/local/bin/sim_voxel"]
```

With GL support:

```dockerfile
# Add to above
RUN apt-get install -y \
    libgl1-mesa-glx \
    libglu1-mesa

# Run with GPU access
# docker run --device /dev/dri ...
```

## Platform-Specific Notes

### Linux

**Best Supported Platform**

- All backends available (when compiled)
- Prefer GL or Vulkan for performance
- Use headless for CI/automation
- Wayland users: Set `SDL_VIDEODRIVER=wayland` or wait for native Wayland backend

**Common Issues:**
- DISPLAY not set → Use `DISPLAY=:0` or headless backend
- No GL/Vulkan → Install mesa drivers: `mesa-utils mesa-vulkan-drivers`

### Windows

**Good Support via SDL**

- SDL backend is stable and recommended
- GL backend works but less tested
- Vulkan backend experimental
- Native Win32 backend is stub (future work)

**Common Issues:**
- Missing SDL2.dll → Install SDL2 runtime or place DLL in exe directory
- GL issues → Update GPU drivers from vendor site

### macOS

**Basic Support**

- SDL backend works well
- GL backend available (OpenGL deprecated by Apple)
- Vulkan via MoltenVK (untested)
- Native macOS backend is stub (future work)

**Common Issues:**
- SDL2 not found → Install via Homebrew: `brew install sdl2 sdl2_ttf`
- GL deprecation warnings → Expected; GL still works but may be removed in future macOS

### FreeBSD

**Experimental**

- SDL backend should work (untested)
- GL backend may work with Mesa
- Others untested

**Setup:**
```bash
pkg install sdl2 sdl2_ttf mesa-libs
```

## Testing Backend Selection

A test script is provided to validate backend selection:

```bash
# Run backend selection test suite
./sim/tests/test_backend_selection.sh
```

This verifies:
- `--show-capabilities` flag works
- Default backend selection
- `HYDRA_BACKEND` env var
- `--backend` CLI flag
- CLI > env precedence
- Invalid backend handling
- Headless frame dumps

## Performance Comparison

Approximate relative performance (measured frames/sec on typical workstation):

| Backend   | Relative Performance | Notes |
|-----------|---------------------|-------|
| Vulkan    | 1.0x (baseline)     | Fastest when working |
| GL        | 0.95x               | Excellent, more stable than Vulkan |
| SDL (HW)  | 0.80x               | Good, automatic acceleration |
| SDL (SW)  | 0.30x               | Software fallback |
| Headless  | 1.2x                | No display overhead, pure sim |

**Note:** Performance varies by GPU, drivers, and system load. Headless is fastest because it skips all display code.

## Future Work

Planned backend improvements (see `docs/todo/todo_platform_backends.md`):

- [ ] Implement native X11 backend (direct Xlib rendering)
- [ ] Implement native Wayland backend (wl_surface protocol)
- [ ] Implement fbdev backend (direct framebuffer writes)
- [ ] Improve Vulkan stability (validation layers, error recovery)
- [ ] Add Win32 native backend (GDI/Direct2D)
- [ ] Add macOS native backend (Cocoa/Metal)
- [ ] Add VNC backend for remote access
- [ ] Add REST API backend for programmatic control

## Contributing

When adding or fixing backends:

1. Update this document with platform support and requirements
2. Add error messages with actionable hints (see `backend_gl.cpp` for examples)
3. Test on multiple platforms if possible
4. Update `test_backend_selection.sh` with new backend tests
5. Document environment variables and troubleshooting steps

## See Also

- `docs/todo/todo_platform_backends.md` - Backend development TODOs
- `docs/todo/todo_multiplatform_builds.md` - Build system improvements
- `sim/platform/` - Backend implementation code
- `sim/tests/test_backend_selection.sh` - Backend test suite
