# Environment Variables Reference

This document lists all environment variables recognized by the Hydra simulator (`sim_voxel`).

## Display & Backend

### `HYDRA_BACKEND`
- **Type**: String (case-insensitive)
- **Values**: `SDL`, `GL`, `Vulkan`, `Wayland`, `X11`, `Fbdev`, `Win32`, `macOS`, `Headless`
- **Default**: Auto-detected (prefers GPU backends when available, falls back to SDL)
- **Description**: Selects the platform backend for rendering. Use `Headless` for CI/testing without a display server.
- **Example**: `HYDRA_BACKEND=headless ./sim_voxel`

## Camera & Movement

### `HYDRA_CAM_POS`
- **Type**: String (comma-separated floats)
- **Format**: `x,y,z`
- **Default**: `10.0,10.0,10.0`
- **Description**: Initial camera position in the voxel world.
- **Example**: `HYDRA_CAM_POS=32.0,32.0,50.0 ./sim_voxel`

### `HYDRA_CAM_ANG`
- **Type**: String (comma-separated floats)
- **Format**: `yaw,pitch`
- **Default**: `0.0,0.0`
- **Description**: Initial camera angles (yaw and pitch in radians).
- **Example**: `HYDRA_CAM_ANG=1.57,0.0 ./sim_voxel`

### `HYDRA_MOVE_SPEED`
- **Type**: Float
- **Default**: `0.10`
- **Description**: Normal camera movement speed (WASD keys).
- **Example**: `HYDRA_MOVE_SPEED=0.2 ./sim_voxel`

### `HYDRA_MOVE_SPEED_FAST`
- **Type**: Float
- **Default**: `0.35`
- **Description**: Fast camera movement speed (hold Shift + WASD).
- **Example**: `HYDRA_MOVE_SPEED_FAST=0.5 ./sim_voxel`

### `HYDRA_TURN_SPEED_KEYS`
- **Type**: Float
- **Default**: `0.04`
- **Description**: Camera rotation speed when using arrow keys.
- **Example**: `HYDRA_TURN_SPEED_KEYS=0.08 ./sim_voxel`

### `HYDRA_MOUSE_SENS`
- **Type**: Float
- **Default**: `0.0025`
- **Description**: Mouse sensitivity for look/aim.
- **Example**: `HYDRA_MOUSE_SENS=0.005 ./sim_voxel`

### `HYDRA_INVERT_Y`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Invert Y-axis for mouse look.
- **Example**: `HYDRA_INVERT_Y=1 ./sim_voxel`

### `HYDRA_MOUSE_CAPTURE`
- **Type**: String
- **Values**: `0` (disabled), any other value (enabled)
- **Default**: Enabled
- **Description**: Start with mouse capture enabled/disabled. Toggle with M key during runtime.
- **Example**: `HYDRA_MOUSE_CAPTURE=0 ./sim_voxel`

### `HYDRA_CAM_CLAMP`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Enable camera position clamping to prevent flying far outside the voxel volume during demos. Works with `HYDRA_CAM_BOUNDS` to define the bounded region.
- **Example**: `HYDRA_CAM_CLAMP=1 ./sim_voxel`

### `HYDRA_CAM_BOUNDS`
- **Type**: String (comma-separated floats)
- **Format**: `min,max`
- **Default**: `-1.0,65.0` (covers 64×64×64 voxel volume with margin)
- **Description**: Minimum and maximum coordinate bounds for camera clamping (applies to x, y, and z). Only used when `HYDRA_CAM_CLAMP` is enabled.
- **Example**: `HYDRA_CAM_CLAMP=1 HYDRA_CAM_BOUNDS=0,64 ./sim_voxel`

## Performance & Timing

### `HYDRA_FPS_TARGET`
- **Type**: Float
- **Default**: `0.0` (no pacing, runs as fast as possible)
- **Description**: Target frames per second for frame pacing. When set, the simulator will sleep to maintain the target FPS, making automated captures deterministic. Set to 0 to disable pacing.
- **Example**: `HYDRA_FPS_TARGET=30 ./sim_voxel`

### `HYDRA_SIM_IDLE_MS`
- **Type**: Integer
- **Default**: `0`
- **Description**: Additional milliseconds to sleep each frame iteration (for debugging/profiling).
- **Example**: `HYDRA_SIM_IDLE_MS=10 ./sim_voxel`

## Frame Capture & Output

### `FRAME_DUMP`
- **Type**: String (file path)
- **Default**: Not set
- **Description**: Path to save frame dump as PPM. Without `HYDRA_FRAME_BASE`, only one frame is saved.
- **Example**: `FRAME_DUMP=output.ppm AUTO_EXIT=1 ./sim_voxel`

### `HYDRA_FRAME_BASE`
- **Type**: String (base filename)
- **Default**: Not set
- **Description**: Base name for numbered frame dumps. Used with `HYDRA_MAX_FRAME_DUMPS` to create sequences like `frame_0.ppm`, `frame_1.ppm`, etc.
- **Example**: `HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=10 FRAME_DUMP=ignored ./sim_voxel`

### `HYDRA_MAX_FRAME_DUMPS`
- **Type**: Integer
- **Default**: `1`
- **Description**: Maximum number of frames to dump before stopping. Set to `0` for unlimited.
- **Example**: `HYDRA_MAX_FRAME_DUMPS=5 FRAME_DUMP=test.ppm ./sim_voxel`

### `AUTO_EXIT`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Exit automatically after rendering frames (useful for headless captures).
- **Example**: `AUTO_EXIT=1 FRAME_DUMP=test.ppm ./sim_voxel`

### `HYDRA_VSYNC`
- **Type**: Boolean (presence/`1`/`true` to enable, `0`/`false` to disable)
- **Default**: Enabled
- **Description**: Toggle VSYNC for SDL/GL/Vulkan backends. Headless respects it as a no-op.
- **Example**: `HYDRA_VSYNC=0 ./sim_voxel`

### `HYDRA_CLEAR_EACH_FRAME`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Clear framebuffer before each frame to prevent stale pixels.
- **Example**: `HYDRA_CLEAR_EACH_FRAME=1 ./sim_voxel`

### `HYDRA_CLEAR_COLOR`
- **Type**: String (comma-separated RGB)
- **Format**: `r,g,b` (0-255)
- **Default**: `0,0,0` (black)
- **Description**: Background color when clearing framebuffer.
- **Example**: `HYDRA_CLEAR_COLOR=64,64,64 HYDRA_CLEAR_EACH_FRAME=1 ./sim_voxel`

## HUD & Display

### `HYDRA_FONT`
- **Type**: String (file path)
- **Default**: `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`
- **Description**: Path to TTF font file for HUD text. Falls back to default if file not found.
- **Example**: `HYDRA_FONT=/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf ./sim_voxel`

### `HYDRA_FONT_SCALE`
- **Type**: Float
- **Range**: `0.5` to `3.0`
- **Default**: `1.0` (11pt)
- **Description**: Font size scaling factor for HUD text.
- **Example**: `HYDRA_FONT_SCALE=1.5 ./sim_voxel`

### `HYDRA_HUD_THEME`
- **Type**: String (case-insensitive)
- **Values**: `light`, `dark`
- **Default**: `dark`
- **Description**: HUD color theme. Toggle with T key during runtime.
- **Example**: `HYDRA_HUD_THEME=light ./sim_voxel`

## Configuration & State

### `HYDRA_AUTOSAVE_CFG`
- **Type**: String (file path)
- **Default**: Not set
- **Description**: Path to save camera/flags configuration on each frame completion. Can be used to persist state.
- **Example**: `HYDRA_AUTOSAVE_CFG=hydra_state.cfg ./sim_voxel`

## Debugging & Logging

### `LOG_KEYS`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Log keyboard input events to stderr (first 200 events).
- **Example**: `LOG_KEYS=1 ./sim_voxel`

### `LOG_FRAMES`
- **Type**: Boolean (presence = true)
- **Default**: Not set (false)
- **Description**: Log per-frame statistics (FPS, pixel count, etc.) to stderr.
- **Example**: `LOG_FRAMES=1 ./sim_voxel`

## Keyboard Shortcuts

The following hotkeys are available during runtime:

| Key | Function |
|-----|----------|
| **WASD** | Move camera (forward/left/back/right) |
| **QE** | Move camera (up/down) |
| **Shift + WASD/QE** | Fast movement |
| **Arrow Keys** | Rotate camera |
| **Mouse** | Look around (when captured) |
| **M** | Toggle mouse capture |
| **H** | Toggle HUD display |
| **T** | Toggle HUD theme (light/dark) |
| **R** | Reset camera and flags to defaults |
| **P** | Print current camera/flag state to stderr |
| **S** | Save screenshot (timestamped PPM in `sim/`) |
| **1** | Toggle smooth surfaces flag |
| **2** | Toggle curvature flag |
| **3** | Toggle extra light flag |
| **O** | Toggle diagnostic slice renderer |
| **F** | Select voxel at cursor |
| **G** | Clear selection |
| **C** | Cycle material type (when voxel selected) |
| **X/Z** | Increase/decrease emissive (when voxel selected) |
| **B** | Brighten voxel color (when voxel selected) |
| **ESC** | Exit simulator |

## Examples

### Headless Frame Capture
```bash
HYDRA_BACKEND=headless \
  FRAME_DUMP=test.ppm \
  AUTO_EXIT=1 \
  ./sim_voxel
```

### Numbered Frame Sequence
```bash
HYDRA_BACKEND=headless \
  HYDRA_FRAME_BASE=frame \
  HYDRA_MAX_FRAME_DUMPS=10 \
  FRAME_DUMP=ignored \
  AUTO_EXIT=1 \
  ./sim_voxel
```

### Custom Camera Position for Demo
```bash
HYDRA_CAM_POS=32,32,48 \
  HYDRA_CAM_ANG=0.785,0.2 \
  HYDRA_MOVE_SPEED=0.05 \
  ./sim_voxel
```

### Bounded Camera for Guided Demos
```bash
HYDRA_CAM_CLAMP=1 \
  HYDRA_CAM_BOUNDS=0,64 \
  HYDRA_CAM_POS=32,32,32 \
  ./sim_voxel
```

### High-DPI Display
```bash
HYDRA_FONT_SCALE=2.0 \
  HYDRA_HUD_THEME=light \
  ./sim_voxel
```

### Deterministic Background for Testing
```bash
HYDRA_CLEAR_EACH_FRAME=1 \
  HYDRA_CLEAR_COLOR=0,0,0 \
  FRAME_DUMP=test.ppm \
  AUTO_EXIT=1 \
  ./sim_voxel
```

## See Also

- [`docs/sim_controls.md`](sim_controls.md) - Interactive controls and keybindings
- [`docs/testing_overview.md`](testing_overview.md) - Frame regression testing
- [`CLAUDE.md`](../CLAUDE.md) - Viewer controls and debugging
