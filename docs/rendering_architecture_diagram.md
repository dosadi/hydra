# Rendering Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    HYDRA RENDERING SYSTEM                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐ │
│  │   RTL Simulation│    │  Pixel Generation│    │ Framebuffer │ │
│  │                 │    │                  │    │             │ │
│  │ • voxel_frameb. │    │ • pixel_write_en │    │ • CPU pixel │ │
│  │ • Verilog HDL   │    │ • pixel96_to_argb│    │ • ARGB8888  │ │
│  │ • Ray tracing   │    │ • Frame completion│    │ • Statistics│ │
│  └─────────────────┘    └──────────────────┘    └─────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    DUAL RENDERING PATHS                         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                FAKE RENDERING (Headless)                   │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  Backend Selection → HeadlessBackend → /dev/null           │ │
│  │                                                             │ │
│  │  • No window creation                                       │ │
│  │  • Pixel data discarded                                     │ │
│  │  • Console logging only                                     │ │
│  │  • Maximum performance                                      │ │
│  │  • Used for: Testing, CI, Benchmarking                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                REAL RENDERING (Interactive)                │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │         Platform Backend Path (SDLBackend)             │ │ │
│  │  ├─────────────────────────────────────────────────────────┤ │ │
│  │  │                                                         │ │ │
│  │  │ Backend Selection → SDLBackend → SDL Window            │ │ │
│  │  │                                                         │ │ │
│  │  │ • SDL window/texture management                         │ │ │
│  │  │ • Hardware acceleration                                  │ │ │
│  │  │ • Vsync support                                          │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │         Direct SDL Path (Primary)                      │ │ │
│  │  ├─────────────────────────────────────────────────────────┤ │ │
│  │  │                                                         │ │ │
│  │  │ Legacy SDL → SDL Window (Always Active)                │ │ │
│  │  │                                                         │ │ │
│  │  │ • Direct texture upload                                 │ │ │
│  │  │ • HUD overlay rendering                                 │ │ │
│  │  │ • Font rendering                                        │ │ │
│  │  │ • Screenshot support                                    │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │ Used for: Development, Demos, Interactive Use               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                CONFIGURATION MATRIX                         │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  Mode      │ HYDRA_BACKEND │ SDL_VIDEODRIVER │ Window      │ │
│  │  ──────────┼───────────────┼─────────────────┼─────────────│ │
│  │  Headless  │ headless      │ dummy           │ No          │ │
│  │  SDL       │ sdl           │ system          │ Yes         │ │
│  │  Auto      │ (empty)       │ system          │ Yes         │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                BENEFITS & USE CASES                        │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                             │ │
│  │  Fake Rendering:                                           │ │
│  │  • Automated testing without display                       │ │
│  │  • CI/CD pipeline integration                              │ │
│  │  • Performance benchmarking                                │ │
│  │  • Cross-platform compatibility                            │ │
│  │                                                             │ │
│  │  Real Rendering:                                           │ │
│  │  • Interactive development                                 │ │
│  │  • User experience with HUD/controls                       │ │
│  │  • Demo and showcase capabilities                          │ │
│  │  • GPU performance profiling                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Architectural Insights

1. **Parallel Paths**: Both fake and real rendering can run simultaneously
2. **Fallback Design**: Direct SDL path ensures rendering always works
3. **Abstraction Layer**: Backend system enables future rendering APIs
4. **Environment Control**: Runtime selection via environment variables
5. **Performance Optimization**: Headless mode removes graphics bottlenecks
6. **Testing Enablement**: Fake rendering enables automated workflows

## Data Flow Summary

```
Input Events → Simulation → Pixel Generation → Framebuffer → Rendering Paths

Fake Path: Framebuffer → HeadlessBackend → Discard → Console Logs
Real Path: Framebuffer → SDLBackend + Direct SDL → Window Display
```</content>
<parameter name="filePath">/workspaces/hydra/docs/rendering_architecture_diagram.md