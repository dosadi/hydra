# Backend Environment Variables Reference

This document lists all environment variables that control Hydra backend behavior, display settings, and debugging options.

## Table of Contents

- [Backend Selection](#backend-selection)
- [SDL Configuration](#sdl-configuration)
- [OpenGL Configuration](#opengl-configuration)
- [Vulkan Configuration](#vulkan-configuration)
- [Frame Output](#frame-output)
- [Logging and Debugging](#logging-and-debugging)
- [Performance Tuning](#performance-tuning)

---

## Backend Selection

### `HYDRA_BACKEND`

**Description:** Select which rendering backend to use.

**Values:** `SDL`, `GL`, `VULKAN`, `WAYLAND`, `X11`, `FBDEV`, `WIN32`, `MACOS`, `HEADLESS` (case-insensitive)

**Default:** Auto-selected based on availability (Vulkan > GL > Wayland > X11 > SDL)

**Examples:**
```bash
# Use headless backend for CI
HYDRA_BACKEND=headless ./sim_voxel

# Force OpenGL backend
HYDRA_BACKEND=gl ./sim_voxel

# Try Vulkan, fallback to defaults if unavailable
HYDRA_BACKEND=vulkan ./sim_voxel
```

**Notes:**
- Can be overridden by `--backend` CLI flag
- Unavailable backends will fallback to SDL with a warning
- Use `./sim_voxel --caps` to see available backends

---

### `HYDRA_BACKEND_PREFS`

**Description:** Customize backend preference order when auto-selecting.

**Format:** Comma-separated list of backend names

**Default:** `VULKAN,GL,WAYLAND,X11,SDL,FBDEV,WIN32,MACOS`

**Example:**
```bash
# Prefer SDL over GPU backends
HYDRA_BACKEND_PREFS=SDL,GL,VULKAN ./sim_voxel

# Only try headless or SDL
HYDRA_BACKEND_PREFS=HEADLESS,SDL ./sim_voxel
```

---

## SDL Configuration

### `SDL_VIDEODRIVER`

**Description:** Force SDL to use a specific video driver.

**Values:** `x11`, `wayland`, `dummy`, `windows`, `cocoa`, etc.

**Default:** Auto-detected by SDL

**Examples:**
```bash
# Force X11 on a Wayland system
SDL_VIDEODRIVER=x11 ./sim_voxel

# Use dummy driver for headless operation
SDL_VIDEODRIVER=dummy ./sim_voxel

# Let SDL auto-detect
unset SDL_VIDEODRIVER
```

**CLI Equivalent:** `--sdl-driver <driver>` or `--video-driver <driver>`

---

### `SDL_AUDIODRIVER`

**Description:** SDL audio driver selection.

**Values:** `pulseaudio`, `alsa`, `dummy`, etc.

**Default:** Auto-detected by SDL

**Example:**
```bash
# Disable audio completely
SDL_AUDIODRIVER=dummy ./sim_voxel
```

**Notes:**
- Hydra sets this to `dummy` automatically when using headless backend
- Audio is not used by Hydra, but SDL may init it by default

---

### `SDL_RENDER_DRIVER`

**Description:** Force SDL to use a specific render driver.

**Values:** `software`, `opengl`, `opengles2`, `direct3d`, `metal`

**Default:** Auto-selected by SDL (usually hardware-accelerated)

**Examples:**
```bash
# Force software rendering (for debugging)
SDL_RENDER_DRIVER=software ./sim_voxel

# Force OpenGL renderer within SDL backend
SDL_RENDER_DRIVER=opengl HYDRA_BACKEND=sdl ./sim_voxel
```

---

### `HYDRA_VSYNC`

**Description:** Enable or disable vertical sync.

**Values:** `1` or `true` to enable, `0` or `false` to disable

**Default:** Disabled

**Example:**
```bash
# Enable vsync to cap framerate
HYDRA_VSYNC=1 ./sim_voxel
```

**Notes:**
- May reduce tearing but caps FPS to display refresh rate
- Not all backends support vsync

---

## OpenGL Configuration

### `LIBGL_ALWAYS_SOFTWARE`

**Description:** Force Mesa to use software rendering (llvmpipe).

**Values:** `1` to enable, `0` or unset to disable

**Default:** `0` (hardware rendering)

**Example:**
```bash
# Test with software rendering
LIBGL_ALWAYS_SOFTWARE=1 HYDRA_BACKEND=gl ./sim_voxel
```

**Notes:**
- Mesa/Linux specific
- Useful for debugging GL issues or testing without GPU

---

### `__GLX_VENDOR_LIBRARY_NAME`

**Description:** Select which OpenGL vendor library to use.

**Values:** `nvidia`, `mesa`

**Default:** Auto-detected

**Example:**
```bash
# Force NVIDIA proprietary drivers
__GLX_VENDOR_LIBRARY_NAME=nvidia ./sim_voxel

# Force Mesa drivers
__GLX_VENDOR_LIBRARY_NAME=mesa ./sim_voxel
```

---

## Vulkan Configuration

### `VK_LAYER_PATH`

**Description:** Path to Vulkan validation layers.

**Format:** Colon-separated list of directories

**Default:** System default

**Example:**
```bash
# Use custom validation layers
VK_LAYER_PATH=/opt/vulkan/layers ./sim_voxel
```

---

### `VK_ICD_FILENAMES`

**Description:** Override Vulkan ICD (Installable Client Driver) selection.

**Format:** Path to ICD JSON file

**Default:** System default

**Example:**
```bash
# Force specific Vulkan driver
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json ./sim_voxel
```

---

### `VK_INSTANCE_LAYERS`

**Description:** Enable Vulkan validation layers.

**Values:** Colon-separated layer names

**Example:**
```bash
# Enable validation layers for debugging
VK_INSTANCE_LAYERS=VK_LAYER_KHRONOS_validation ./sim_voxel
```

**Notes:**
- Requires Vulkan SDK or validation layers package
- Significantly impacts performance (debugging only)

---

## Frame Output

### `FRAME_DUMP`

**Description:** Path to save rendered frames as PPM images.

**Format:** File path (with or without `.ppm` extension)

**Default:** Not set (no frame dumps)

**Examples:**
```bash
# Save single frame
FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel

# Save multiple frames (with HYDRA_MAX_FRAME_DUMPS)
FRAME_DUMP=frame.ppm HYDRA_MAX_FRAME_DUMPS=10 ./sim_voxel

# Numbered sequence
FRAME_DUMP=frame_%d.ppm HYDRA_MAX_FRAME_DUMPS=5 ./sim_voxel
```

**Notes:**
- Works with all backends
- Essential for headless backend usage
- See also: `HYDRA_MAX_FRAME_DUMPS`, `AUTO_EXIT`

---

### `HYDRA_MAX_FRAME_DUMPS`

**Description:** Maximum number of frames to dump before stopping.

**Format:** Positive integer

**Default:** `1` (single frame)

**Examples:**
```bash
# Dump 10 frames then stop
FRAME_DUMP=out.ppm HYDRA_MAX_FRAME_DUMPS=10 ./sim_voxel

# Unlimited dumps
FRAME_DUMP=out.ppm HYDRA_MAX_FRAME_DUMPS=0 ./sim_voxel
```

---

### `AUTO_EXIT`

**Description:** Exit automatically after first frame is rendered.

**Values:** `1` or any non-empty value to enable

**Default:** Not set (interactive mode)

**Example:**
```bash
# Render one frame and exit (CI mode)
FRAME_DUMP=test.ppm AUTO_EXIT=1 ./sim_voxel
```

**Notes:**
- Extremely useful for CI and automation
- Combines well with `FRAME_DUMP` for regression testing

---

## Logging and Debugging

### `HYDRA_QUIET`

**Description:** Suppress non-essential backend messages.

**Values:** `1` to enable quiet mode

**Default:** `0` (normal logging)

**Examples:**
```bash
# Quiet mode for batch operations
HYDRA_QUIET=1 ./sim_voxel

# Verbose batch render
HYDRA_QUIET=1 ./scripts/batch_render.sh -n 100
```

**CLI Equivalent:** `--quiet` or `-q`

**Notes:**
- Errors are always shown
- Warnings and info messages are suppressed
- Ideal for CI where you only want errors

---

### `HYDRA_VERBOSE`

**Description:** Enable verbose debug logging.

**Values:** `1` to enable verbose mode

**Default:** `0` (normal logging)

**Example:**
```bash
# Debug backend initialization
HYDRA_VERBOSE=1 ./sim_voxel
```

**CLI Equivalent:** `--verbose` or `-v`

**Notes:**
- Shows detailed backend operations
- Includes frame timing, initialization steps
- Mutually exclusive with `HYDRA_QUIET`

---

### `LOG_FRAMES`

**Description:** Log frame statistics to stderr.

**Values:** `1` to enable

**Default:** `0`

**Example:**
```bash
# Log each frame's pixel statistics
LOG_FRAMES=1 ./sim_voxel
```

**Output:**
```
frame 0 done, pixels_written=172800 nonzero=125643 sample0=ff0a1520 mid=ff1a2530
```

---

### `HYDRA_PROFILE_BACKEND`

**Description:** Enable backend performance profiling.

**Values:** `1` to enable

**Default:** `0`

**Example:**
```bash
# Profile backend operations
HYDRA_PROFILE_BACKEND=1 ./sim_voxel
```

**Output:**
```
[profile] Headless::present took 245 µs (0.245 ms)
[profile] Headless::present stats (n=100): avg=0.235ms min=0.180ms max=0.450ms
```

**Notes:**
- Tracks init, present, and shutdown timing
- Reports statistics every 100 operations
- Useful for performance optimization

---

## Performance Tuning

### `HYDRA_FPS_TARGET`

**Description:** Target framerate for frame pacing.

**Format:** Floating-point FPS value

**Default:** Not set (unlimited)

**Example:**
```bash
# Cap at 60 FPS
HYDRA_FPS_TARGET=60 ./sim_voxel

# Cap at 30 FPS
HYDRA_FPS_TARGET=30.0 ./sim_voxel
```

**CLI Equivalent:** `--fps-target <fps>`

**Notes:**
- Uses frame pacing (sleep) to hit target
- Different from VSYNC (not tied to display refresh)

---

### `HYDRA_SIM_IDLE_MS`

**Description:** Additional idle time (sleep) per frame in milliseconds.

**Format:** Non-negative integer

**Default:** `0`

**Example:**
```bash
# Add 16ms delay per frame (~60 FPS)
HYDRA_SIM_IDLE_MS=16 ./sim_voxel
```

---

### `HYDRA_CLEAR_EACH_FRAME`

**Description:** Clear framebuffer before each frame.

**Values:** `1` to enable

**Default:** Not set (no clearing)

**Example:**
```bash
# Clear to black each frame
HYDRA_CLEAR_EACH_FRAME=1 ./sim_voxel
```

---

### `HYDRA_CLEAR_COLOR`

**Description:** Color to use when clearing framebuffer.

**Format:** `R,G,B` (0-255)

**Default:** `0,0,0` (black)

**Example:**
```bash
# Clear to dark blue
HYDRA_CLEAR_COLOR=0,0,64 HYDRA_CLEAR_EACH_FRAME=1 ./sim_voxel
```

---

## Display Configuration

### `DISPLAY`

**Description:** X11 display server to connect to.

**Format:** `hostname:display.screen`

**Default:** `:0` (local display)

**Examples:**
```bash
# Default X11 display
DISPLAY=:0 ./sim_voxel

# Remote X11 display
DISPLAY=remote-host:10.0 ./sim_voxel

# Xvfb virtual display
DISPLAY=:99 ./sim_voxel
```

**Notes:**
- Required for X11-based backends (SDL with x11 driver, native X11)
- Not needed for Wayland or headless

---

### `WAYLAND_DISPLAY`

**Description:** Wayland compositor socket.

**Format:** Socket name

**Default:** `wayland-0`

**Example:**
```bash
# Custom Wayland display
WAYLAND_DISPLAY=wayland-1 ./sim_voxel
```

---

## Quick Reference Table

| Variable | Purpose | CLI Flag | Default |
|----------|---------|----------|---------|
| `HYDRA_BACKEND` | Select backend | `--backend` | Auto |
| `HYDRA_QUIET` | Suppress messages | `--quiet` | `0` |
| `HYDRA_VERBOSE` | Debug logging | `--verbose` | `0` |
| `SDL_VIDEODRIVER` | SDL driver | `--sdl-driver` | Auto |
| `HYDRA_VSYNC` | Enable vsync | - | `0` |
| `FRAME_DUMP` | Save frames | - | Not set |
| `AUTO_EXIT` | Exit after frame | - | Not set |
| `HYDRA_PROFILE_BACKEND` | Profile performance | - | `0` |
| `HYDRA_FPS_TARGET` | Cap framerate | `--fps-target` | Unlimited |

---

## Common Scenarios

### CI/Automation

```bash
# Minimal output, headless, single frame
HYDRA_BACKEND=headless \
HYDRA_QUIET=1 \
FRAME_DUMP=test.ppm \
AUTO_EXIT=1 \
./sim_voxel
```

### Benchmarking

```bash
# Profile performance, specific backend
HYDRA_BACKEND=gl \
HYDRA_PROFILE_BACKEND=1 \
./scripts/batch_render.sh -n 100 --benchmark
```

### Debugging Backend Issues

```bash
# Verbose logging, software rendering
HYDRA_VERBOSE=1 \
LIBGL_ALWAYS_SOFTWARE=1 \
HYDRA_BACKEND=gl \
./sim_voxel
```

### Regression Testing

```bash
# Deterministic output, quiet mode
HYDRA_BACKEND=headless \
HYDRA_QUIET=1 \
HYDRA_WORLD_SEED=42 \
FRAME_DUMP=golden.ppm \
AUTO_EXIT=1 \
./sim_voxel
```

---

## See Also

- [Backend Support Matrix](backend_support_matrix.md) - Platform compatibility
- [CI Integration Guide](ci_integration.md) - Using backends in CI/CD
- [Testing Overview](testing_overview.md) - Test suite documentation
