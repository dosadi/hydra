# Adding a New Hotkey to the Viewer

This guide explains how to add new hotkeys to the Hydra simulation viewer (`sim/viewer.cpp`). The viewer uses SDL2 for input handling and supports a comprehensive set of hotkeys for camera control, rendering flags, voxel editing, and debugging.

## Hotkey Architecture

Hotkeys are processed in the main event loop in `viewer.cpp` around line 742. The system uses:

- **SDL_KEYDOWN events** for key presses
- **Switch statement on SDL_Keycode** for most bindings
- **State variables** for toggles and continuous controls
- **Immediate actions** for one-shot commands (screenshot, state print, etc.)

## Key Binding Patterns

### 1. Toggle Flags
Most render flags use simple boolean toggles:

```cpp
case SDLK_j:
    ray_jitter = !ray_jitter;
    apply_flags_to_dut();
    std::fprintf(stderr, "[hydra] ray jitter %s\n", ray_jitter ? "ON" : "OFF");
    break;
```

**Pattern:**
- Toggle a boolean variable
- Call `apply_flags_to_dut()` to update the hardware
- Optional: Print status to stderr

### 2. Mode Cycling
Some features cycle through multiple states:

```cpp
case SDLK_v: {
    if (g_pixel_view_mode == PixelViewMode::Color) {
        g_pixel_view_mode = PixelViewMode::Word0;
    } else if (g_pixel_view_mode == PixelViewMode::Word0) {
        g_pixel_view_mode = PixelViewMode::Word2;
    } else if (g_pixel_view_mode == PixelViewMode::Word2) {
        g_pixel_view_mode = PixelViewMode::SidebandMix;
    } else {
        g_pixel_view_mode = PixelViewMode::Color;
    }
    std::fprintf(stderr, "[hydra] pixel view -> %s\n",
                 pixel_view_mode_name(g_pixel_view_mode));
    break;
}
```

**Pattern:**
- Use if-else chain or switch to cycle through enum values
- Print new state to stderr

### 3. Immediate Actions
One-shot actions like screenshots or state dumps:

```cpp
case SDLK_s: {
    // Screenshot: save current framebuffer as timestamped PPM
    auto now = std::chrono::system_clock::now();
    auto secs = std::chrono::duration_cast<std::chrono::seconds>(
        now.time_since_epoch()).count();
    char filename[256];
    std::snprintf(filename, sizeof(filename), "sim/screenshot_%ld.ppm", secs);
    // ... file writing code ...
    std::fprintf(stderr, "Screenshot saved: %s\n", filename);
    break;
}
```

**Pattern:**
- Perform action immediately
- Use timestamped filenames for output files
- Print confirmation to stderr

### 4. Selection-Based Actions
Actions that depend on having a voxel selected:

```cpp
case SDLK_f:
    if (root->voxel_framebuffer_top__DOT__cursor_hit_valid) {
        selection_active = true;
        selection_x = static_cast<uint8_t>(root->voxel_framebuffer_top__DOT__cursor_voxel_x);
        // ... set selection coordinates and data ...
        apply_selection_to_dut();
        sel_miss_timer = 0.0f;
    } else {
        sel_miss_timer = 1.5f;  // Show miss indicator
    }
    break;
```

**Pattern:**
- Check `cursor_hit_valid` before proceeding
- Set `sel_miss_timer` for user feedback on misses
- Call `apply_selection_to_dut()` to update hardware

### 5. Voxel Editing
Editing selected voxels happens in a separate block after the main switch:

```cpp
// Edit selected voxel
if (selection_active) {
    uint64_t w = selection_word;
    // Extract fields from the 64-bit voxel word
    uint8_t material_type = (w >> 4) & 0x0F;
    
    if (keycode == SDLK_c) {
        material_type = (material_type + 1) & 0x0F;
        w &= ~((uint64_t)0x0F << 4);
        w |= (uint64_t(material_type) << 4);
        // ... write back to hardware ...
    }
    // ... other edit keys ...
}
```

**Pattern:**
- Check `selection_active` first
- Extract voxel data fields from the 64-bit word
- Modify the desired field(s)
- Write back via debug interface

## Key Code Conventions

### Preferred Key Codes
- Use `SDLK_` constants for letter/number keys (SDLK_a, SDLK_1, etc.)
- Use `SDLK_` for function keys (SDLK_F1, SDLK_F2, etc.)
- Support both keypad and main keyboard versions where applicable (`SDLK_1` and `SDLK_KP_1`)

### Scancode vs Keycode
The viewer supports both scancodes and keycodes for compatibility:

```cpp
// In update_key_state() function
switch (sc) {
    case SDL_SCANCODE_W: keys.forward = pressed; break;
    // ... scancode handling for movement ...
}
SDL_Keycode kc = keycode;
if (kc >= 'A' && kc <= 'Z') kc = kc - 'A' + 'a';
switch (kc) {
    case SDLK_w: keys.forward = pressed; break;
    // ... keycode handling for same keys ...
}
```

**Movement keys** use scancodes for consistent behavior across keyboard layouts.

## Adding a New Hotkey

### Step 1: Choose a Key
- Check existing hotkeys in the switch statement
- Pick an unused key that makes sense for the feature
- Consider both main keyboard and keypad versions if applicable

### Step 2: Add the Case
Add a new case in the main switch statement (around line 742):

```cpp
case SDLK_your_key:
    // Your hotkey logic here
    break;
```

### Step 3: Implement the Logic
Follow one of the patterns above based on your feature type.

### Step 4: Update Help Text
Add your hotkey to the help overlay in the `help_lines[]` array (around line 2200):

```cpp
const char* help_lines[] = {
    "F1: toggle help overlay   /: show briefly",
    "Move: WASD/QE + mouse (M toggles capture)  Shift=fast  F2: safe defaults",
    "Flags: 1 smooth  2 curvature  3 extra  O diag slice  J jitter  T HUD theme",
    "Select: F pick voxel  G clear  Edit: C material, X/Z emissive, B brighten",
    "View: V cycle pixel view (color/word0/word2/sideband)  H HUD on/off",
    "Misc: S screenshot  P print state  R reset  ESC quit",
    "Your new feature: [Y] your description here"
};
```

### Step 5: Test
- Build and run the viewer
- Test your hotkey functionality
- Verify help text appears correctly
- Check stderr output for status messages

## Hardware Integration

### Updating DUT Flags
For render flags that affect the hardware:

```cpp
void apply_flags_to_dut() {
    root->voxel_framebuffer_top__DOT__cfg_smooth_surfaces = smooth_surfaces ? 1 : 0;
    root->voxel_framebuffer_top__DOT__cfg_curvature = curvature ? 1 : 0;
    // ... other flags ...
}
```

### Camera Updates
For camera position/orientation changes:

```cpp
void apply_camera_to_dut() {
    root->voxel_framebuffer_top__DOT__cam_x = int16_t(pos_x * FX);
    // ... other camera registers ...
}
```

### Selection Updates
For voxel selection changes:

```cpp
void apply_selection_to_dut() {
    root->voxel_framebuffer_top__DOT__sel_active = selection_active ? 1 : 0;
    // ... other selection registers ...
}
```

## Debug Output

Always include informative debug output:

- Use `std::fprintf(stderr, "[hydra] feature_name %s\n", state ? "ON" : "OFF");` for toggles
- Use `std::fprintf(stderr, "[hydra] feature_name -> %s\n", new_value);` for mode changes
- Include relevant values in state dumps (triggered by 'P' key)

## Example: Adding a Fog Density Toggle

Here's a complete example of adding a new hotkey:

```cpp
// Add near the top with other globals
static float g_fog_density = 1.0f;

// In the switch statement
case SDLK_d:
    g_fog_density = (g_fog_density == 1.0f) ? 0.5f : 1.0f;
    std::fprintf(stderr, "[hydra] fog density -> %.1f\n", g_fog_density);
    break;

// In apply_fog() function
float factor = d * g_fog_density;  // Use the variable instead of constant

// Update help text
"Fog: [D] toggle density  [F4] toggle on/off"
```

This pattern can be applied to add any new interactive feature to the viewer.</content>
<parameter name="filePath">/workspaces/hydra/docs/adding_hotkeys.md