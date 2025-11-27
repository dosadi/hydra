# Fake vs Real Rendering Separation in Hydra

## Overview

Hydra implements a dual-path rendering architecture that separates **fake rendering** (headless/testing) from **real rendering** (display output). This separation enables automated testing, benchmarking, and CI while maintaining full interactive graphics capabilities.

## Architectural Structure

### 1. Backend Abstraction Layer

```
Backend (Abstract Base Class)
├── HeadlessBackend (Fake Rendering)
└── SDLBackend (Real Rendering)
    └── Future: VulkanBackend, GLBackend, etc.
```

#### Backend Interface
```cpp
class Backend {
public:
    virtual ~Backend() = default;
    virtual bool init(PlatformContext& ctx, const PlatformConfig& cfg) = 0;
    virtual void present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) = 0;
    virtual void shutdown(PlatformContext& ctx) = 0;
};
```

### 2. Rendering Path Separation

#### Fake Rendering Path (HeadlessBackend)
- **Purpose**: Testing, benchmarking, CI automation
- **Behavior**: Accepts pixel data but discards it
- **Environment**: `HYDRA_BACKEND=headless` or `SDL_VIDEODRIVER=dummy`
- **Output**: Console logging only, no visual output
- **Performance**: Minimal overhead, maximum simulation speed

```cpp
void HeadlessBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    // No-op: headless mode doesn't display anything
}
```

#### Real Rendering Path (SDLBackend)
- **Purpose**: Interactive visualization, development, demos
- **Behavior**: Creates window, manages SDL textures, displays graphics
- **Environment**: `HYDRA_BACKEND=sdl` (default) or auto-fallback
- **Output**: SDL window with rendered voxel graphics
- **Performance**: Full graphics pipeline with vsync/display sync

```cpp
void SDLBackend::present(PlatformContext& ctx, const uint32_t* pixels, int w, int h) {
    // Upload to SDL texture and render to window
    SDL_UpdateTexture(texture, nullptr, pixels, w * 4);
    SDL_RenderCopy(renderer, texture, nullptr, nullptr);
    SDL_RenderPresent(renderer);
}
```

### 3. Dual Rendering Pipeline

Hydra implements a **parallel rendering architecture** where both paths can execute simultaneously:

#### Primary Rendering (Always Active)
- **Direct SDL Path**: Legacy SDL rendering directly to window
- **Purpose**: Main interactive display
- **Components**:
  - SDL Window creation
  - SDL Renderer/Texture management
  - Direct framebuffer copy to GPU
  - HUD overlay rendering
  - Font rendering

#### Secondary Rendering (Conditional)
- **Platform Backend Path**: Abstracted backend system
- **Purpose**: Alternative rendering APIs, testing
- **Components**:
  - Backend selection via `select_default_backend()`
  - Backend initialization via `create_backend()`
  - Conditional presentation via `use_platform_present` flag

### 4. Framebuffer Flow Architecture

```
RTL Simulation → Pixel Generation → Framebuffer → Dual Rendering Paths

Pixel Generation:
├── voxel_framebuffer_top.sv (Verilog RTL)
├── Pixel write logic (pixel_write_en, pixel_addr, pixel_word0/1/2)
└── pixel96_to_argb() conversion

Framebuffer Management:
├── std::vector<uint32_t> framebuffer (CPU-side pixel buffer)
├── Frame completion detection (frame_done signal)
├── Framebuffer clearing (clear_each_frame, clear_color)
└── Pixel statistics (frame_color_stats)

Dual Rendering Output:
├── Fake Path: HeadlessBackend::present() → /dev/null
└── Real Path: SDLBackend::present() → SDL Window
           + Direct SDL Path → SDL Window (parallel)
```

### 5. Environment-Based Path Selection

#### Headless Mode Activation
```bash
# Environment variables for fake rendering
export HYDRA_BACKEND=headless
export SDL_VIDEODRIVER=dummy
export SDL_AUDIODRIVER=dummy

# Additional headless configuration
export LOG_FRAMES=1          # Enable frame logging
export AUTO_EXIT=1           # Exit after frame completion
export FRAME_DUMP=output.ppm # Save rendered frames
```

#### Interactive Mode (Default)
```bash
# Real rendering (default behavior)
export HYDRA_BACKEND=sdl     # Explicit SDL backend
# or let auto-selection choose based on availability
```

### 6. Conditional Logic Structure

#### Backend Selection Logic
```cpp
PlatformBackend requested_backend = select_default_backend();
bool headless_backend = (requested_backend == PlatformBackend::Headless);

if (headless_backend) {
    // Configure SDL for headless operation
    setenv("SDL_VIDEODRIVER", "dummy", 0);
    setenv("SDL_AUDIODRIVER", "dummy", 0);
    mouse_captured = false;  // Disable mouse capture
}
```

#### Rendering Path Control
```cpp
bool use_platform_present = false;

// Try platform backend first
if (requested_backend != PlatformBackend::SDL) {
    if (init_backend(requested_backend, plat_cfg, plat_ctx)) {
        backend = requested_backend;
        use_platform_present = true;
    }
}

// Always prepare direct SDL rendering as fallback
// ... SDL window/texture initialization ...

// In render loop:
if (use_platform_present) {
    present_backend(backend, plat_ctx, framebuffer.data(), w, h);
}
// Always do direct SDL rendering (primary path)
SDL_UpdateTexture(tex, nullptr, framebuffer.data(), w * 4);
SDL_RenderCopy(ren, tex, nullptr, nullptr);
SDL_RenderPresent(ren);
```

### 7. Testing and Automation Integration

#### Fake Rendering Benefits
- **CI/CD**: Automated testing without display requirements
- **Benchmarking**: Performance measurement without graphics overhead
- **Regression Testing**: Frame validation via pixel dumps
- **Cross-Platform**: Runs on headless servers, containers, CI systems

#### Real Rendering Benefits
- **Development**: Interactive debugging and visualization
- **User Experience**: Full graphics with HUD, controls, effects
- **Demos**: Showcase capabilities with real-time rendering
- **Profiling**: GPU performance analysis with actual display pipeline

### 8. Future Extensibility

The backend abstraction enables future rendering APIs:

```cpp
// Planned backend implementations
class VulkanBackend : public Backend { /* Vulkan rendering */ };
class GLBackend : public Backend { /* OpenGL rendering */ };
class WaylandBackend : public Backend { /* Native Wayland */ };
class X11Backend : public Backend { /* X11 rendering */ };
```

### 9. Configuration Matrix

| Mode | HYDRA_BACKEND | SDL_VIDEODRIVER | Window | Display | Mouse | Performance |
|------|---------------|-----------------|--------|---------|-------|-------------|
| Headless | headless | dummy | No | No | Disabled | Fast |
| SDL | sdl | system | Yes | Yes | Captured | Full |
| Auto | (empty) | system | Yes | Yes | Captured | Full |

### 10. Separation Benefits

1. **Testability**: Headless mode enables automated testing
2. **Performance**: Fake rendering removes graphics bottlenecks
3. **Portability**: Runs on systems without graphics hardware
4. **Modularity**: Backend abstraction enables multiple rendering APIs
5. **Reliability**: Fallback paths ensure rendering always works
6. **Debugging**: Separate paths for isolating graphics issues

This architecture provides a clean separation between simulation (always real) and visualization (fake vs real), enabling both automated workflows and interactive development.</content>
<parameter name="filePath">/workspaces/hydra/docs/rendering_separation.md