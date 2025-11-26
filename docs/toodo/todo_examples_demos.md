# Hydra Examples, Demos & Benchmarks TODOs (0.0.7+ Cycle)

**Focus:** Sample scenes, benchmark suites, demo content, tutorials, showcase materials.
Complements documentation with hands-on examples and performance baseline data.

**Status:** Mostly P2/P3 work; examples improve onboarding and showcase capabilities.

---

## P1: High Priority Examples (0.0.7 Release)

### Basic Examples

- TODO [P1]: Create "Hello Hydra" minimal example
  - **Coverage:**
    - Minimal C program: open device, write camera CSR, read pixel
    - 50 lines of code, well-commented
    - Demonstrates libhydra basics
  - **Effort:** Small (4 hours)
  - **Dependencies:** libhydra stable
  - **Validation:** Example compiles and runs
  - **Deliverable:** `examples/hello_hydra/hello_hydra.c`

- TODO [P1]: Add benchmark scene presets to sim
  - **Coverage:**
    - Empty scene (baseline overhead)
    - Dense scene (stress test)
    - Cornell box (classic reference)
    - Sponza-like architecture (realistic complexity)
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Scene generation in world_gen
  - **Validation:** Scenes load and render correctly
  - **Deliverable:** Presets accessible via CLI flag or key

- TODO [P1]: Create camera movement example
  - **Coverage:**
    - Programmatic camera path
    - Demonstrates CSR writes for camera control
    - Useful for scripted demos
  - **Effort:** Small (4 hours)
  - **Dependencies:** libhydra
  - **Validation:** Camera moves smoothly
  - **Deliverable:** `examples/camera_path/camera_path.c`

---

## P2: Medium Priority Examples (Nice-to-Have)

### Rendering Examples

- TODO [P2]: Create voxel editing example
  - **Coverage:**
    - Use DBG_VOXEL_* CSRs to modify voxels
    - Build simple shapes programmatically
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Voxel write CSRs functional
  - **Validation:** Voxels update in real-time
  - **Deliverable:** `examples/voxel_edit/voxel_edit.c`

- TODO [P2]: Add DMA example
  - **Coverage:**
    - Set up DMA transfer
    - Copy framebuffer to host memory
    - Save to file
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** DMA functional, libhydra helpers
  - **Validation:** DMA completes, image saved correctly
  - **Deliverable:** `examples/dma_framebuffer/dma_fb.c`

- TODO [P2]: Create render flags demo
  - **Coverage:**
    - Toggle all render flags programmatically
    - Capture frames with different settings
    - Compare visual output
  - **Effort:** Small (1 day)
  - **Dependencies:** Render flags CSRs
  - **Validation:** Flags affect rendering as expected
  - **Deliverable:** `examples/render_flags/render_flags.c`

### Benchmark Suite

- TODO [P2]: Create performance benchmark script
  - **Coverage:**
    - Measure frame time at different resolutions
    - Measure DMA throughput
    - Measure interrupt latency
    - Generate CSV report
  - **Effort:** Large (3-5 days)
  - **Dependencies:** libhydra, hardware or sim
  - **Validation:** Benchmarks run on sim and hardware
  - **Deliverable:** `scripts/hydra_perf_bench.sh`

- TODO [P2]: Add stress test suite
  - **Coverage:**
    - Rapid camera movement (worst-case ray distribution)
    - Continuous voxel edits (memory pressure)
    - Sustained DMA transfers (bandwidth test)
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** libhydra
  - **Validation:** Stress tests complete without errors
  - **Deliverable:** `tests/stress/` directory

- TODO [P2]: Create visual quality comparison tool
  - **Coverage:**
    - Render same scene with different flags
    - Side-by-side image comparison
    - PSNR/SSIM metrics
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Image processing library
  - **Validation:** Metrics match expected values
  - **Deliverable:** `scripts/visual_compare.py`

### Demo Content

- TODO [P2]: Create showcase demo scene
  - **Coverage:**
    - Visually impressive voxel scene
    - Demonstrates lighting, emissive, fog
    - Scripted camera flythrough
  - **Effort:** Large (5-7 days, includes art)
  - **Dependencies:** Scene save/load, camera path recording
  - **Validation:** Demo runs smoothly, looks good
  - **Deliverable:** `demos/showcase/` directory

- TODO [P2]: Add interactive demo mode
  - **Coverage:**
    - Guided tour of features
    - On-screen instructions
    - Auto-advance through demos
  - **Effort:** Large (3-5 days)
  - **Dependencies:** GUI or HUD overlay
  - **Validation:** Demo mode is intuitive
  - **Deliverable:** Demo mode in viewer

- TODO [P2]: Create video capture script
  - **Coverage:**
    - Record scripted demo to video
    - Use ffmpeg to encode frames
    - Generate promotional material
  - **Effort:** Medium (1-2 days)
  - **Dependencies:** Frame dump, ffmpeg
  - **Validation:** Video quality acceptable
  - **Deliverable:** `scripts/record_demo.sh`

---

## P3: Low Priority Examples (Future)

### Advanced Examples

- TODO [P3]: Create multi-device example
  - **Coverage:**
    - Detect multiple Hydra devices
    - Render different views on each
    - Useful for multi-monitor setups
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Multi-device driver support
  - **Validation:** Multiple devices work simultaneously
  - **Deliverable:** `examples/multi_device/multi_device.c`

- TODO [P3]: Add GPU interop example
  - **Coverage:**
    - Import Hydra framebuffer into OpenGL/Vulkan
    - Zero-copy display
    - Overlay UI on top
  - **Effort:** Very Large (10-15 days)
  - **Dependencies:** DRM/GL interop, Vulkan external memory
  - **Validation:** Framebuffer displays with no copy
  - **Deliverable:** `examples/gpu_interop/` directory

- TODO [P3]: Create compute shader example
  - **Coverage:**
    - Use Hydra as compute device
    - Run voxel processing kernels
    - Read back results
  - **Effort:** Very Large (15-20 days)
  - **Dependencies:** Compute shader support (future)
  - **Validation:** Compute completes correctly
  - **Deliverable:** `examples/compute/` directory

### Tutorials

- TODO [P3]: Write step-by-step tutorial series
  - **Coverage:**
    - Tutorial 1: First render
    - Tutorial 2: Camera control
    - Tutorial 3: Voxel editing
    - Tutorial 4: Performance tuning
    - Tutorial 5: Hardware bring-up
  - **Effort:** Very Large (15-20 days for all)
  - **Dependencies:** Stable APIs
  - **Validation:** Tutorials tested by newcomers
  - **Deliverable:** `docs/tutorials/` directory

- TODO [P3]: Create video tutorial series
  - **Coverage:**
    - Screen recordings of tutorials
    - Voiceover explanations
    - Upload to YouTube
  - **Effort:** Very Large (20-30 days, includes editing)
  - **Dependencies:** Written tutorials complete
  - **Validation:** Videos published
  - **Deliverable:** YouTube playlist

### Interactive Demos

- TODO [P3]: Build web-based demo (WASM)
  - **Coverage:**
    - Compile sim to WebAssembly
    - Run in browser
    - Interactive voxel editor
  - **Effort:** Very Large (20-30 days)
  - **Dependencies:** WASM build support, SDL WASM backend
  - **Validation:** Runs in modern browsers
  - **Deliverable:** `demos/web/` directory

- TODO [P3]: Create VR demo
  - **Coverage:**
    - Stereo rendering for VR headset
    - Head tracking for camera control
    - Immersive voxel experience
  - **Effort:** Very Large (30-40 days)
  - **Dependencies:** VR SDK integration
  - **Validation:** Works with major VR headsets
  - **Deliverable:** `demos/vr/` directory

---

## Benchmark Baselines

### Performance Targets

- TODO [P2]: Establish baseline performance metrics
  - **Coverage:**
    - Sim FPS at 720p, 1080p, 4K
    - Verilator compile time
    - DMA throughput (sim vs. hardware)
    - Interrupt latency
  - **Effort:** Medium (2-3 days)
  - **Dependencies:** Benchmark suite (#P2 item above)
  - **Validation:** Metrics documented
  - **Deliverable:** `docs/performance_baselines.md`

- TODO [P2]: Create regression tracking for benchmarks
  - **Coverage:**
    - Store historical benchmark results
    - Plot trends over time
    - Alert on >10% regressions
  - **Effort:** Large (3-5 days)
  - **Dependencies:** Benchmark suite, CI integration
  - **Validation:** Regressions detected in CI
  - **Deliverable:** CI job for performance tracking

- TODO [P3]: Add hardware benchmark comparison
  - **Coverage:**
    - Compare FPGA vs. sim performance
    - Different FPGA families (Artix-7 vs. Kintex-7)
    - Document bottlenecks
  - **Effort:** Large (5-7 days)
  - **Dependencies:** Hardware available
  - **Validation:** Comparison documented
  - **Deliverable:** `docs/hardware_benchmarks.md`

---

## Example Repository Structure

```
examples/
├── hello_hydra/              # P1: Minimal example
│   ├── hello_hydra.c
│   └── Makefile
├── camera_path/              # P1: Camera movement
│   ├── camera_path.c
│   └── Makefile
├── voxel_edit/               # P2: Voxel manipulation
│   ├── voxel_edit.c
│   └── Makefile
├── dma_framebuffer/          # P2: DMA demo
│   ├── dma_fb.c
│   └── Makefile
├── render_flags/             # P2: Flag toggling
│   ├── render_flags.c
│   └── Makefile
├── multi_device/             # P3: Multi-device
│   └── ...
├── gpu_interop/              # P3: GL/Vulkan interop
│   └── ...
└── README.md                 # Index of examples

demos/
├── showcase/                 # P2: Showcase demo
│   ├── scene.hydra
│   ├── camera_path.json
│   └── run_demo.sh
├── web/                      # P3: WASM demo
│   └── ...
└── vr/                       # P3: VR demo
    └── ...

benchmarks/
├── perf_bench.sh             # P2: Performance suite
├── stress_test.sh            # P2: Stress tests
├── visual_compare.py         # P2: Visual quality
└── results/                  # Benchmark output
    └── baseline_2025_11_25.csv
```

---

## Documentation for Examples

### Example README Template

Each example should include:
- **Purpose:** What this example demonstrates
- **Prerequisites:** Dependencies, hardware requirements
- **Build:** Compilation instructions
- **Run:** Execution instructions
- **Expected Output:** What success looks like
- **See Also:** Related examples, documentation links

### Example Code Standards

- **Commented:** Inline comments explain every step
- **Error Handling:** Check all return values
- **Cleanup:** Properly close devices, free memory
- **Portable:** Works on Linux, FreeBSD, macOS (when drivers available)
- **Minimal:** Focused on one concept per example

---

## Cross-References

- **Benchmark suite:** `todo_performance.md` P2 #310
- **Scene management:** `todo_simulation_viewer.md` P2 (scene save/load)
- **Camera path recording:** `todo_simulation_viewer.md` P2
- **Documentation:** `todo_documentation.md` P2 (tutorials)
- **Testing:** `todo_testing_ci.md` (benchmark integration)

---

## Estimated Effort (Examples & Demos)

| Priority | Items | Effort (days) |
|----------|-------|---------------|
| **P1**   | 3     | 2-4           |
| **P2**   | 11    | 25-40         |
| **P3**   | 7     | 100-170       |
| **Total**| **21**| **127-214**   |

**Note:** P1 items (basic examples) help with onboarding in 0.0.7. P2 items (benchmarks, demos) showcase capabilities. P3 items (advanced examples, tutorials) are long-term.

**Recommendation:** Prioritize P1 basic examples in Sprint 4 (polish phase). Defer P2 benchmarks/demos to 0.0.8. P3 advanced examples are future work.

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Target Release:** P1 in 0.0.7, P2 in 0.0.8+, P3 long-term
**Owner:** Examples team (TBD)
