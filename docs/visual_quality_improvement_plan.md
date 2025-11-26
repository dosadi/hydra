# Visual Quality Improvement Plan

## Current State Analysis

### What's Working
✅ **Basic ray marching**: 64³ voxel grid, correct geometry
✅ **Simple lighting**: voxel_light field applied to colors
✅ **Lambert shading**: Dot product N·L for diffuse lighting
✅ **Emission**: Bright emissive voxels (ceiling light)
✅ **Sky gradient**: Vertical color fade for background
✅ **Selection highlight**: Visual feedback for picked voxels

### The "Flat Patches of Primary Color" Problem

**Root Cause**: Hard-coded colors in `voxel_world_gen.sv` are too saturated

Current scene colors:
```systemverilog
Floor:   RGB(64-72, 80-88, 96-104)  // Slightly blue-tinted concrete
Ceiling: RGB(255, 208, 160)         // Warm orange/yellow light
Sphere0: RGB(64, 192, 255)          // Bright cyan
Sphere1: RGB(255, 64, 255)          // Bright magenta
```

**Issues**:
1. **Too saturated**: Primary colors dominate (cyan = 64,192,255 = heavily blue/green)
2. **Limited palette**: Only 4 distinct base colors in entire scene
3. **No texture variation**: Each object is solid color
4. **Harsh emissive**: Ceiling light is uniform 255,208,160
5. **Missing detail**: No surface variation, scratches, or subtle color shifts

### What's Generated But Not Used

The raycaster computes rich 96-bit + 32-bit pixel data, but **only RGB24 is displayed**:

**Currently Generated** (from `voxel_raycaster_core_pipelined.sv`):
```systemverilog
pixel_word0 [31:0]:  reflection | refraction | attenuation | emission
pixel_word1 [31:0]:  R | G | B | material_id
pixel_word2 [31:0]:  normal_x | normal_y | normal_z | curvature
pixel_sidecar [31:0]: material_props | emissive | light | alpha  // reemissure32
```

**Currently Displayed** (from `sim/viewer.cpp`):
```cpp
static uint32_t pixel96_to_argb(uint32_t w0, uint32_t w1, uint32_t w2) {
    (void)w0; (void)w2;  // IGNORED!
    uint8_t r = (w1 >> 24) & 0xFF;
    uint8_t g = (w1 >> 16) & 0xFF;
    uint8_t b = (w1 >>  8) & 0xFF;
    return ARGB(255, r, g, b);
}
```

**Consequence**: All the computed reflection, refraction, normals, and curvature are **discarded**.

### Z/Depth Buffer Status

**Currently**: No depth buffer exists.

**What's Available**:
- `pixel_word0[15:8]` = `attenuation` = `ray_steps` (0-255, distance from camera)
- This can be used as a **Z-buffer proxy**

**Not Used For**:
- Depth-based fog
- Depth-based ambient occlusion approximation
- Z-buffer compositing (if multiple layers were supported)

### Reemissure32 Integration Status

**Defined**: `pixel_sidecar [31:0]` = `material_props | emissive | light | alpha`

**Generated**: Yes, in S_SHADE state:
```systemverilog
out_sidecar = {out_reflection, out_refraction, voxel_emissive, out_attenuation};
```

**Output From Core**: Yes, as `pixel_sidecar` port

**Connected in `voxel_framebuffer_top`**: No! The sidecar is **not wired to any output**.

**Status**: ❌ Implemented in raycaster, but **not exposed to simulation or framebuffer**.

---

## Improvement Strategy

### Phase 1: Richer Scene Colors (Low Performance Cost)
**Goal**: Replace flat primary colors with realistic, varied palette
**Complexity**: Low (just data changes)
**Performance**: Negligible (±0%)

#### 1A. Desaturate Base Colors
Replace primary-heavy colors with naturalistic tones:

```systemverilog
// OLD: Floor (blue-tinted)
floor_r = 8'd64 + x[3:1];
floor_g = 8'd80 + x[3:1];
floor_b = 8'd96 + x[3:1];

// NEW: Concrete with subtle warmth and texture variation
floor_r = 8'd92  + {5'd0, x[2:0]};  // 92-99 (neutral warm gray)
floor_g = 8'd88  + {5'd0, z[2:0]};  // 88-95 (slightly cooler)
floor_b = 8'd84  + {5'd0, (x^z)[2:0]};  // 84-91 (add XOR noise)
```

**Result**: Concrete-like floor with subtle spatial variation instead of flat blue.

#### 1B. Add Procedural Texture Noise
Inject high-frequency detail using XOR-based pseudo-noise:

```systemverilog
// Micro-detail variation (±4 levels)
reg [2:0] texture_noise = x[1:0] ^ y[2:1] ^ z[1:0];
floor_r = floor_r + {5'd0, texture_noise};
floor_g = floor_g + {5'd0, texture_noise};
floor_b = floor_b + {5'd0, texture_noise};
```

**Result**: Breaks up flat surfaces, adds "grain" like concrete or stone.

#### 1C. Improve Sphere Colors
Replace garish cyan/magenta with sophisticated tones:

```systemverilog
// OLD: Bright cyan (64, 192, 255)
8'h40, 8'hC0, 8'hFF

// NEW: Matte teal ceramic (desaturated, natural)
8'h70, 8'hA8, 8'hB8  // (112, 168, 184) - teal with gray undertone
```

```systemverilog
// OLD: Bright magenta (255, 64, 255)
8'hFF, 8'h40, 8'hFF

// NEW: Warm amber emissive (more realistic light source)
8'hFF, 8'hB0, 8'h60  // (255, 176, 96) - warm glowing amber
```

**Result**: Spheres look like real materials (ceramic, glowing ember) instead of neon signs.

#### 1D. Improve Ceiling Light Color
Make emissive light more natural:

```systemverilog
// OLD: Warm ceiling light (255, 208, 160)
8'hFF, 8'hD0, 8'hA0

// NEW: Soft incandescent bulb (less orange, more realistic)
8'hFF, 8'hE8, 8'hC8  // (255, 232, 200) - warm white
```

**Result**: Lighting looks like real indoor lighting, not a sunset.

---

### Phase 2: Depth-Based Effects (Low-Medium Performance Cost)
**Goal**: Use `attenuation` field for distance-based shading
**Complexity**: Low (add fog/AO in pixel shader logic)
**Performance**: +2-5% (extra multiplies in S_SHADE)

#### 2A. Depth Fog
Add atmospheric perspective (distant objects fade toward sky color):

```systemverilog
// In compute_pixel_data task:
reg [7:0] fog_factor;
if (out_attenuation > 8'd192) begin
    fog_factor = (out_attenuation - 8'd192) << 2;  // 0-252 over last 64 steps
end else begin
    fog_factor = 8'd0;
end

// Blend toward sky color
sky_r = 8'd160;
sky_g = 8'd180;
sky_b = 8'd200;
out_r = ((out_r * (8'd255 - fog_factor)) + (sky_r * fog_factor)) >> 8;
out_g = ((out_g * (8'd255 - fog_factor)) + (sky_g * fog_factor)) >> 8;
out_b = ((out_b * (8'd255 - fog_factor)) + (sky_b * fog_factor)) >> 8;
```

**Result**: Depth cues, objects fade naturally into distance.

**Performance**: +2% (3 extra multiplies + shifts per pixel, only in S_SHADE)

#### 2B. Ambient Occlusion Approximation
Darken surfaces based on ray steps (proxy for cavity darkness):

```systemverilog
// Surfaces hit earlier are more exposed (lighter)
// Surfaces hit later are in crevices (darker)
reg [7:0] ao_darken;
if (out_attenuation < 8'd32) begin
    ao_darken = 8'd0;  // Close to camera = no darkening
end else begin
    ao_darken = (out_attenuation >> 1) - 8'd16;  // Gradual darken
end

out_r = (out_r > ao_darken) ? (out_r - ao_darken) : 8'd0;
out_g = (out_g > ao_darken) ? (out_g - ao_darken) : 8'd0;
out_b = (out_b > ao_darken) ? (out_b - ao_darken) : 8'd0;
```

**Result**: Crevices and concave areas appear darker (cheap fake AO).

**Performance**: +1% (simple subtractions, no multiplies)

---

### Phase 3: Wire Up Reemissure32 (Low Performance Cost)
**Goal**: Make `pixel_sidecar` available for future post-processing
**Complexity**: Medium (RTL + sim plumbing)
**Performance**: Negligible in RTL, +5% in sim (extra data transfer)

#### 3A. Add Sidecar Output to `voxel_framebuffer_top`
Currently missing! Add output port:

```systemverilog
// In voxel_framebuffer_top.sv
output wire [31:0] pixel_sidecar,

// Connect from raycaster core
assign pixel_sidecar = core.pixel_sidecar;
```

#### 3B. Update Simulation Viewer
Capture and optionally display sidecar data:

```cpp
// In sim/viewer.cpp
uint32_t w0 = top->pixel_word0;
uint32_t w1 = top->pixel_word1;
uint32_t w2 = top->pixel_word2;
uint32_t sc = top->pixel_sidecar;  // NEW

// Visualize different channels via keyboard toggles
enum VisMode { VIS_RGB, VIS_REFLECTION, VIS_NORMALS, VIS_DEPTH, VIS_EMISSIVE };
VisMode vis_mode = VIS_RGB;

switch (vis_mode) {
    case VIS_RGB:
        framebuffer[addr] = pixel96_to_argb(w0, w1, w2);
        break;
    case VIS_REFLECTION:
        uint8_t refl = (w0 >> 24) & 0xFF;
        framebuffer[addr] = ARGB(255, refl, refl, refl);  // Grayscale
        break;
    case VIS_NORMALS:
        uint8_t nx = (w2 >> 24) & 0xFF;
        uint8_t ny = (w2 >> 16) & 0xFF;
        uint8_t nz = (w2 >> 8) & 0xFF;
        framebuffer[addr] = ARGB(255, nx, ny, nz);  // RGB = XYZ
        break;
    case VIS_DEPTH:
        uint8_t depth = (w0 >> 8) & 0xFF;
        framebuffer[addr] = ARGB(255, depth, depth, depth);
        break;
    case VIS_EMISSIVE:
        uint8_t emis = (sc >> 16) & 0xFF;
        framebuffer[addr] = ARGB(255, emis, emis, 0);  // Yellow = emissive
        break;
}
```

**Result**: Debug visualization modes for all computed data.

**Performance**: RTL unchanged, sim +5% (extra variable, conditionals in hot loop).

---

### Phase 4: Enhanced Lighting (Medium Performance Cost)
**Goal**: Multi-light support, softer shadows
**Complexity**: Medium-High (requires architectural changes)
**Performance**: +10-20% (multiple light samples, shadow rays)

#### 4A. Add Secondary Light Source
Currently only one point light (small emissive sphere @ 38,32,28).

**Approach**: Add second light at ceiling center:

```systemverilog
// Light 0: Small sphere (point light)
wire [5:0] light0_x = 6'd38;
wire [5:0] light0_y = 6'd32;
wire [5:0] light0_z = 6'd28;

// Light 1: Ceiling plane (area light approximation)
wire [5:0] light1_x = 6'd32;
wire [5:0] light1_y = 6'd54;
wire [5:0] light1_z = 6'd32;

// Compute two Lambert terms, take max or average
```

**Result**: More uniform lighting, less harsh shadows.

**Performance**: +5% (duplicate N·L calculation)

#### 4B. Soft Shadows via Multi-Sampling
Sample multiple points on light source instead of single point:

```systemverilog
// Jitter light position slightly (±2 voxels)
wire [5:0] light_jitter_x = light0_x + {4'd0, x[1:0]};
wire [5:0] light_jitter_z = light0_z + {4'd0, z[1:0]};

// Compute N·L with jittered position
// Result: Penumbra (soft shadow edges)
```

**Result**: Shadows fade gradually instead of hard cutoff.

**Performance**: +3% (adds XOR/addition overhead)

#### 4C. Simple Shadow Rays (Optional, Expensive)
March a ray from hit point toward light to check occlusion:

**Approach**: After hitting voxel, march mini-ray toward light0:
- If ray reaches light: full brightness
- If ray hits obstacle: shadowed (multiply by 0.3)

**Result**: Accurate shadows from sphere onto floor.

**Performance**: +20-40% (doubles ray marching work, only for shadowed pixels)

**Recommendation**: Defer to Phase 6 (too expensive for interactive sim).

---

### Phase 5: Material-Based Shading (Medium Performance Cost)
**Goal**: Different materials render differently (metal, glass, emissive)
**Complexity**: Medium (add material type switch in S_SHADE)
**Performance**: +5-10% (branching on material type)

#### 5A. Reflective Materials
Use `out_reflection` value to blend in reflected environment:

```systemverilog
if (out_reflection > 8'd128) begin
    // Cheap reflection: sample sky color based on normal
    sky_sample_r = (out_normal_y > 8'd64) ? sky_r : 8'd40;
    sky_sample_g = (out_normal_y > 8'd64) ? sky_g : 8'd50;
    sky_sample_b = (out_normal_y > 8'd64) ? sky_b : 8'd60;

    // Blend toward sky
    out_r = ((out_r * (8'd255 - out_reflection)) + (sky_sample_r * out_reflection)) >> 8;
    out_g = ((out_g * (8'd255 - out_reflection)) + (sky_sample_g * out_reflection)) >> 8;
    out_b = ((out_b * (8'd255 - out_reflection)) + (sky_sample_b * out_reflection)) >> 8;
end
```

**Result**: Metallic/glossy surfaces show environmental color.

**Performance**: +3% (conditional blending)

#### 5B. Emissive Glow (Bloom Approximation)
Brighten emissive materials beyond 255 (HDR → tone map):

```systemverilog
if (voxel_emissive > 8'd200) begin
    // Oversaturate, then clamp (creates "bloom" effect)
    tmp_r = out_r + (voxel_emissive >> 1);
    tmp_g = out_g + (voxel_emissive >> 1);
    tmp_b = out_b + (voxel_emissive >> 1);
    out_r = (tmp_r > 9'd255) ? 8'd255 : tmp_r[7:0];
    out_g = (tmp_g > 9'd255) ? 8'd255 : tmp_g[7:0];
    out_b = (tmp_b > 9'd255) ? 8'd255 : tmp_b[7:0];
end
```

**Result**: Bright lights "glow" and saturate sensor (like real camera).

**Performance**: +2% (already partially implemented, just needs tuning)

---

### Phase 6: Advanced Techniques (High Performance Cost)
**Goal**: Professional rendering quality
**Complexity**: High
**Performance**: +50-200% (significantly slower)

**Defer until FPGA or GPU acceleration available.**

#### Deferred Techniques:
- **Real reflections/refractions**: Recursive ray tracing
- **Global illumination**: Light bounces between surfaces
- **Soft shadows**: Shadow rays to area lights
- **Subsurface scattering**: Light penetrates materials
- **HDR + tone mapping**: Higher bit depth, exposure control
- **Anti-aliasing**: 4x/8x MSAA or TAA
- **Motion blur**: Temporal accumulation

---

## Performance Impact Summary

| Phase | Description | Cycles/Pixel | FPS Impact | Sim Time Impact |
|-------|-------------|--------------|------------|-----------------|
| **Baseline** | Current | 100% | 1.0× | 2s/frame @ 480×360 |
| **Phase 1** | Richer colors | +0% | 1.0× | 2s (no change) |
| **Phase 2** | Depth fog + AO | +3% | 0.97× | 2.06s (+3%) |
| **Phase 3** | Reemissure32 wire-up | +0% RTL<br>+5% sim | 1.0× RTL<br>0.95× sim | 2s RTL<br>2.1s sim |
| **Phase 4** | Multi-light | +10% | 0.91× | 2.2s (+10%) |
| **Phase 5** | Material shading | +8% | 0.93× | 2.16s (+8%) |
| **Phase 6** | Advanced (deferred) | +50-200% | 0.5-0.33× | 4-6s |

**Cumulative Phases 1-5**: ~21% slower (2.42s per frame instead of 2s @ 480×360)

**Mitigation**: Use Fast Mode (120×90, 16 steps) during development → still ~500ms/frame

---

## Implementation Priority

### Tier 1: Quick Wins (Do First)
1. **Phase 1A-D**: Richer scene colors (~30 min work, 0% perf cost)
   - Immediate visual improvement
   - No performance penalty
   - Easy to validate

### Tier 2: Low-Hanging Fruit (Do Next)
2. **Phase 2A**: Depth fog (~1 hour, +2% cost)
3. **Phase 3A-B**: Wire up reemissure32 (~2 hours, +5% sim cost)

### Tier 3: Polish (After Tier 1-2 Validated)
4. **Phase 2B**: Ambient occlusion (~30 min, +1% cost)
5. **Phase 5A-B**: Material shading (~2 hours, +5% cost)

### Tier 4: Advanced (Defer Until Needed)
6. **Phase 4A-C**: Multi-light support (~3-4 hours, +10% cost)
7. **Phase 6**: Advanced techniques (weeks, +50-200% cost)

---

## Validation Strategy

### Visual Regression
After each phase, capture golden frame:
```bash
FRAME_DUMP=test_phase1.ppm AUTO_EXIT=1 ./sim_voxel
compare golden_frame.ppm test_phase1.ppm -metric AE diff_phase1.png
```

### Performance Regression
Measure frame time:
```bash
LOG_FRAMES=1 ./sim_voxel 2>&1 | grep "frame.*done"
# Look for "pixels_written" timing
```

### A/B Comparison
Use `HYDRA_PHASE1=1` env var to toggle improvements:
```systemverilog
`ifdef SYNTHESIS
    parameter ENABLE_PHASE1 = 1;
`else
    parameter ENABLE_PHASE1 = (/* check env var from testbench */);
`endif
```

---

## Example: Phase 1A Implementation

### Before
```systemverilog
// voxel_world_gen.sv, S_PLANES state
floor_r = 8'd64 + {5'd0, x[3:1]};
floor_g = 8'd80 + {5'd0, x[3:1]};
floor_b = 8'd96 + {5'd0, x[3:1]};
```

### After
```systemverilog
// Desaturated concrete with procedural texture
reg [2:0] noise = x[1:0] ^ y[2:1] ^ z[1:0];
floor_r = 8'd92  + {5'd0, x[2:0]} + {5'd0, noise};
floor_g = 8'd88  + {5'd0, z[2:0]} + {5'd0, noise};
floor_b = 8'd84  + {5'd0, (x^z)[2:0]} + {5'd0, noise};

// Clamp to prevent overflow
floor_r = (floor_r > 8'd110) ? 8'd110 : floor_r;
floor_g = (floor_g > 8'd106) ? 8'd106 : floor_g;
floor_b = (floor_b > 8'd102) ? 8'd102 : floor_b;
```

**Result**: Floor goes from flat cyan-tinted to realistic concrete with grain.

**Visual**:
- Before: Uniform blue-gray, obviously CG
- After: Natural gray with subtle spatial variation, looks real

---

## Stretch Goals (Future Work)

### Post-Processing in Sim Viewer
Move effects from RTL to C++ for faster iteration:

```cpp
// In sim/viewer.cpp, after pixel96_to_argb()
framebuffer[addr] = apply_post_fx(framebuffer[addr], w0, w2, sc);

uint32_t apply_post_fx(uint32_t argb, uint32_t w0, uint32_t w2, uint32_t sc) {
    // Depth fog (using w0[15:8] = attenuation)
    uint8_t depth = (w0 >> 8) & 0xFF;
    if (depth > 192) {
        uint8_t fog = (depth - 192) * 4;
        // Blend toward sky...
    }

    // Bloom (using sc[23:16] = emissive)
    uint8_t emis = (sc >> 16) & 0xFF;
    if (emis > 200) {
        // Brighten surrounding pixels...
    }

    return argb;
}
```

**Benefit**: Iterate on effects without re-synthesizing RTL.

### GPU Post-Processing
Use OpenGL/Vulkan shaders for real-time effects:
- Bloom (Gaussian blur on emissive channel)
- Depth of field (blur based on depth)
- Chromatic aberration
- Vignette
- Film grain

**Benefit**: 60 FPS with advanced effects, no RTL performance hit.

---

## Recommendation

**Start with Phase 1 (Richer Colors)** immediately:
- Takes 30-60 minutes
- Zero performance cost
- Massive visual improvement
- Proves out workflow

Then proceed to **Phase 2A (Depth Fog)** and **Phase 3 (Reemissure32)**:
- Combined ~3 hours work
- <10% performance cost
- Unlocks visualization modes
- Sets up future phases

Defer **Phase 4-6** until Phase 1-3 validated and visual quality goals met.

**Expected Result**: "True RGB24 experience" with natural colors, depth cues, and rich material variation, while keeping sim performance acceptable for interactive development.
