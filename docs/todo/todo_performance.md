# Performance Optimization TODO Tracker

**Last Updated:** 2025-11-25
**Owner:** Performance Team
**Related Trackers:** `todo_ray_engine.md`, `todo_rendering.md`, `todo_build_tooling.md`

---

## Overview

Tracks performance optimization across RTL, simulation, and software. Focus areas: RTL cycle optimization, Verilator simulation speed, ray marching efficiency, memory bandwidth, build performance.

**Priority Distribution:**
- **P0:** 0 items - No performance blockers for 0.0.7
- **P1:** 0 items - Performance optimization post-functionality
- **P2:** 25 items (~45 days) - Simulation and RTL optimization
- **P3:** 22 items (~55 days) - Advanced optimizations

**Total:** 47 items, ~100 engineer-days (mostly P2/P3, post-0.0.7)

**Note:** Performance optimization is primarily **post-0.0.7** work. Initial focus is on functionality and correctness, then optimization.

---

## P2 - Medium Priority Performance Optimization (Nice-to-Have for 0.0.7)

### Verilator Simulation Performance
- **TODO [P2]:** Profile Verilator simulation with gprof/perf to identify hotspots
  - **Effort:** 2 days
  - **Priority:** P2 - Identify bottlenecks
  - **Dependencies:** None
  - **Validation:** Hotspot analysis identifies top 5 slow functions
  - **Deliverable:** Profiling report
  - **Notes:** Focus on eval() and trace code

- **TODO [P2]:** Enable Verilator optimizations (--O3, --inline-mult, --threads)
  - **Effort:** 1 day
  - **Priority:** P2 - Compiler optimizations
  - **Dependencies:** None
  - **Validation:** Sim speed increases by ≥20%
  - **Deliverable:** Updated Makefile with opt flags
  - **Notes:** Currently using default Verilator flags

- **TODO [P2]:** Add Verilator multi-threading (--threads 4 or auto)
  - **Effort:** 2 days
  - **Priority:** P2 - Parallelism
  - **Dependencies:** Verilator 5.x with threading support
  - **Validation:** Sim speed increases on multi-core
  - **Deliverable:** Threaded build option
  - **Notes:** May require code changes for thread safety

- **TODO [P2]:** Reduce Verilator trace overhead (selective tracing, VCD compression)
  - **Effort:** 2 days
  - **Priority:** P2 - Debug performance
  - **Dependencies:** None
  - **Validation:** Trace generation 50% faster
  - **Deliverable:** Optimized trace configuration
  - **Notes:** Only trace critical signals

- **TODO [P2]:** Add Verilator caching (--Mdir with timestamp checks)
  - **Effort:** 1 day
  - **Priority:** P2 - Build speed
  - **Dependencies:** None
  - **Validation:** Incremental builds avoid full re-verilate
  - **Deliverable:** Makefile dependency tracking
  - **Status:** Partially done - improve cache invalidation

- **TODO [P2]:** Optimize C++ sim harness (reduce overhead in eval loop)
  - **Effort:** 3 days
  - **Priority:** P2 - Sim speed
  - **Dependencies:** Profiling complete
  - **Validation:** Eval loop 10% faster
  - **Deliverable:** Optimized sim/viewer.cpp
  - **Notes:** Check for unnecessary work per cycle

- **TODO [P2]:** Add fast-forward mode (skip rendering, just run RTL for perf testing)
  - **Effort:** 2 days
  - **Priority:** P2 - Benchmarking
  - **Dependencies:** None
  - **Validation:** Can measure pure RTL perf
  - **Deliverable:** HYDRA_FAST_FORWARD env var

- **TODO [P2]:** Reduce RTL signal width where possible (smaller state, faster sim)
  - **Effort:** 3 days
  - **Priority:** P2 - Sim speed + area
  - **Dependencies:** RTL review
  - **Validation:** Sim speed increase, no functionality change
  - **Deliverable:** Signal width optimizations in RTL
  - **Notes:** Check counters, addresses for over-sizing

### RTL Cycle Optimization
- **TODO [P2]:** Profile RTL critical path to identify slow logic
  - **Effort:** 2 days
  - **Priority:** P2 - Timing optimization
  - **Dependencies:** Synthesis timing report
  - **Validation:** Critical path identified
  - **Deliverable:** Timing analysis report

- **TODO [P2]:** Add pipeline stages to ray marching loop if critical path too long
  - **Effort:** 5 days
  - **Priority:** P2 - Timing closure
  - **Dependencies:** Critical path analysis
  - **Validation:** Max freq increases by ≥20%
  - **Deliverable:** Deeper pipeline in raycaster
  - **Notes:** May increase latency, measure impact

- **TODO [P2]:** Optimize voxel memory access pattern (reduce BRAM read latency)
  - **Effort:** 4 days
  - **Priority:** P2 - Memory latency
  - **Dependencies:** None
  - **Validation:** Fewer stall cycles per ray
  - **Deliverable:** Optimized memory controller
  - **Notes:** Consider prefetch or banked BRAM

- **TODO [P2]:** Add early ray termination (exit when hit limit, not max steps)
  - **Effort:** 2 days
  - **Priority:** P2 - Ray efficiency
  - **Dependencies:** None
  - **Validation:** Average ray steps reduced
  - **Deliverable:** Early termination logic
  - **Notes:** Already exits on opaque hit, optimize further

- **TODO [P2]:** Optimize fixed-point arithmetic (reduce bit width or use DSP blocks)
  - **Effort:** 4 days
  - **Priority:** P2 - Compute efficiency
  - **Dependencies:** Synthesis report
  - **Validation:** Resource usage or speed improvement
  - **Deliverable:** Optimized arithmetic
  - **Notes:** May trade precision for speed

- **TODO [P2]:** Add compile-time parameter to reduce MAX_RAY_STEPS for faster builds
  - **Effort:** 1 day
  - **Priority:** P2 - Build speed
  - **Dependencies:** None
  - **Validation:** Reduced MAX_RAY_STEPS builds faster
  - **Deliverable:** Makefile param for MAX_RAY_STEPS
  - **Status:** Done - document in performance guide

### Memory and Bandwidth Optimization
- **TODO [P2]:** Optimize framebuffer pixel packing (RGBA32 → RGB24 if acceptable)
  - **Effort:** 2 days
  - **Priority:** P2 - Bandwidth reduction
  - **Dependencies:** None
  - **Validation:** 25% bandwidth reduction
  - **Deliverable:** Configurable pixel format

- **TODO [P2]:** Add framebuffer write coalescing (burst writes instead of single)
  - **Effort:** 3 days
  - **Priority:** P2 - Bandwidth efficiency
  - **Dependencies:** AXI master supports bursts
  - **Validation:** Fewer AXI transactions
  - **Deliverable:** Burst write logic

- **TODO [P2]:** Implement double-buffering for framebuffer (reduce host read conflicts)
  - **Effort:** 3 days
  - **Priority:** P2 - Concurrency
  - **Dependencies:** Sufficient BRAM or DRAM
  - **Validation:** Frame rate more consistent
  - **Deliverable:** Double-buffer implementation

- **TODO [P2]:** Add compression for framebuffer DMA (if bandwidth-limited)
  - **Effort:** 5 days
  - **Priority:** P2 - Bandwidth optimization
  - **Dependencies:** Compression IP or custom
  - **Validation:** DMA bandwidth reduced by ≥30%
  - **Deliverable:** Compression engine

### Build Performance
- **TODO [P2]:** Optimize Makefile dependencies to avoid unnecessary rebuilds
  - **Effort:** 2 days
  - **Priority:** P2 - Developer velocity
  - **Dependencies:** None
  - **Validation:** Incremental builds faster
  - **Deliverable:** Improved Makefiles

- **TODO [P2]:** Add ccache for C++ compilation in sim
  - **Effort:** 1 day
  - **Priority:** P2 - Build speed
  - **Dependencies:** ccache installed
  - **Validation:** Rebuilds 50% faster
  - **Deliverable:** ccache integration
  - **Status:** Done in CI - add to local builds

- **TODO [P2]:** Parallelize synthesis flow (multi-core synthesis in Vivado/Quartus)
  - **Effort:** 1 day
  - **Priority:** P2 - Synthesis speed
  - **Dependencies:** Multi-core machine
  - **Validation:** Synthesis time reduced
  - **Deliverable:** Parallel synthesis config

- **TODO [P2]:** Add incremental synthesis for FPGA builds
  - **Effort:** 3 days
  - **Priority:** P2 - Iteration speed
  - **Dependencies:** Synthesis tool support
  - **Validation:** Incremental synth 3x faster
  - **Deliverable:** Incremental build flow

### Benchmarking and Metrics
- **TODO [P2]:** Create performance benchmark suite (frame time, ray count, bandwidth)
  - **Effort:** 4 days
  - **Priority:** P2 - Measurement infrastructure
  - **Dependencies:** None
  - **Validation:** Benchmark produces consistent results
  - **Deliverable:** scripts/benchmark.sh

- **TODO [P2]:** Add performance counters in RTL (ray steps, pixel count, stalls)
  - **Effort:** 3 days
  - **Priority:** P2 - Instrumentation
  - **Dependencies:** None
  - **Validation:** Counters track expected metrics
  - **Deliverable:** Perf counters in CSR space

- **TODO [P2]:** Track performance regression in CI (benchmark on each PR)
  - **Effort:** 2 days
  - **Priority:** P2 - Regression prevention
  - **Dependencies:** Benchmark suite
  - **Validation:** CI alerts on >10% regression
  - **Deliverable:** CI perf job

### Automation & Metrics Integration

- **TODO [P2]:** Surface benchmark summaries via `scripts/ai_health_dashboard.py` so each regression run updates the dashboard’s TODO counts and alerts.
- **TODO [P2]:** Build `scripts/perf_matrix.sh` to sequentially run key benchmarks across Verilator/headless/hardware modes and emit CSV+JSON reports for automation.
- **TODO [P3]:** Add a “task size map” section that relates bugfixes, feature work, and platform expansions to performance tracker entries so contributors know where to drop notes regardless of scope.

---

## P3 - Low Priority Advanced Optimizations (Future Work)

### Advanced RTL Optimization
- **TODO [P3]:** Implement hierarchical ray marching (octree or similar)
  - **Effort:** 10 days
  - **Priority:** P3 - Algorithmic optimization
  - **Dependencies:** Significant RTL rework
  - **Validation:** Ray steps reduced by ≥50%
  - **Deliverable:** Hierarchical raycaster
  - **Notes:** Major change, evaluate cost/benefit

- **TODO [P3]:** Add adaptive ray step size (larger steps in empty space)
  - **Effort:** 5 days
  - **Priority:** P3 - Ray efficiency
  - **Dependencies:** Empty space detection
  - **Validation:** Fewer steps in empty regions
  - **Deliverable:** Adaptive stepping logic

- **TODO [P3]:** Optimize lighting calculations (LUT for normals, precomputed)
  - **Effort:** 4 days
  - **Priority:** P3 - Compute reduction
  - **Dependencies:** None
  - **Validation:** Lighting calc cycles reduced
  - **Deliverable:** LUT-based lighting

- **TODO [P3]:** Add multi-resolution voxel grid (LOD for distant voxels)
  - **Effort:** 8 days
  - **Priority:** P3 - Scalability
  - **Dependencies:** Major RTL change
  - **Validation:** Larger effective voxel volume
  - **Deliverable:** LOD voxel storage

- **TODO [P3]:** Implement parallel ray marching (multiple rays per cycle)
  - **Effort:** 10 days
  - **Priority:** P3 - Throughput
  - **Dependencies:** Resource availability
  - **Validation:** Frame rate increased by ≥2x
  - **Deliverable:** Multi-ray raycaster
  - **Notes:** Significant resource increase

### Software/Viewer Optimization
- **TODO [P3]:** Profile viewer C++ code with perf/gprof
  - **Effort:** 2 days
  - **Priority:** P3 - Viewer performance
  - **Dependencies:** None
  - **Validation:** Hotspots identified
  - **Deliverable:** Profiling report

- **TODO [P3]:** Optimize SDL pixel blitting (use GPU-accelerated path if available)
  - **Effort:** 3 days
  - **Priority:** P3 - Display performance
  - **Dependencies:** SDL2 GPU support
  - **Validation:** Blit faster on GPU
  - **Deliverable:** GPU-accelerated blit

- **TODO [P3]:** Add multi-threaded viewer (render thread + UI thread)
  - **Effort:** 5 days
  - **Priority:** P3 - Concurrency
  - **Dependencies:** Thread-safe RTL interface
  - **Validation:** UI remains responsive during render
  - **Deliverable:** Multi-threaded viewer

- **TODO [P3]:** Optimize HUD rendering (cache text rendering, update only on change)
  - **Effort:** 2 days
  - **Priority:** P3 - HUD overhead
  - **Dependencies:** None
  - **Validation:** HUD render cost reduced
  - **Deliverable:** Cached HUD rendering

### Memory Optimization
- **TODO [P3]:** Implement sparse voxel storage (compress empty regions)
  - **Effort:** 8 days
  - **Priority:** P3 - Memory scalability
  - **Dependencies:** Major storage change
  - **Validation:** 64³ → 128³ with same BRAM
  - **Deliverable:** Sparse voxel storage

- **TODO [P3]:** Add voxel data compression (RLE or custom codec)
  - **Effort:** 6 days
  - **Priority:** P3 - Memory efficiency
  - **Dependencies:** Decompression logic in RTL
  - **Validation:** Memory usage reduced by ≥40%
  - **Deliverable:** Voxel compression

- **TODO [P3]:** Optimize voxel data layout (cache-friendly access pattern)
  - **Effort:** 4 days
  - **Priority:** P3 - Cache efficiency
  - **Dependencies:** Memory access profiling
  - **Validation:** Fewer cache misses (sim or FPGA)
  - **Deliverable:** Optimized memory layout

### Synthesis and Hardware Performance
- **TODO [P3]:** Target higher clock frequency (150 MHz or 200 MHz on Kintex/Virtex)
  - **Effort:** 5 days
  - **Priority:** P3 - Performance headroom
  - **Dependencies:** Timing optimization
  - **Validation:** Timing closure at higher freq
  - **Deliverable:** High-freq build variant

- **TODO [P3]:** Reduce FPGA resource usage for area-constrained builds
  - **Effort:** 5 days
  - **Priority:** P3 - Cost reduction
  - **Dependencies:** Resource profiling
  - **Validation:** Fits in smaller/cheaper FPGA
  - **Deliverable:** Area-optimized variant

- **TODO [P3]:** Optimize power consumption (clock gating, power gating)
  - **Effort:** 5 days
  - **Priority:** P3 - Power efficiency
  - **Dependencies:** Power analysis tools
  - **Validation:** Power reduced by ≥20%
  - **Deliverable:** Power-optimized build

### DMA and PCIe Performance
- **TODO [P3]:** Optimize DMA descriptor handling (batch, prefetch)
  - **Effort:** 4 days
  - **Priority:** P3 - DMA throughput
  - **Dependencies:** DMA working
  - **Validation:** DMA latency reduced
  - **Deliverable:** Optimized DMA engine

- **TODO [P3]:** Add PCIe Read Completion Boundary optimization
  - **Effort:** 3 days
  - **Priority:** P3 - PCIe efficiency
  - **Dependencies:** LitePCIe integrated
  - **Validation:** PCIe bandwidth improved
  - **Deliverable:** RCB tuning

- **TODO [P3]:** Implement zero-copy framebuffer (host mmaps FPGA DRAM)
  - **Effort:** 5 days
  - **Priority:** P3 - Latency reduction
  - **Dependencies:** BAR1 DRAM mapping
  - **Validation:** No DMA copy needed
  - **Deliverable:** Zero-copy implementation

### Algorithmic Optimization
- **TODO [P3]:** Add frustum culling (skip rays outside view frustum)
  - **Effort:** 4 days
  - **Priority:** P3 - Ray reduction
  - **Dependencies:** Frustum definition
  - **Validation:** Fewer rays per frame
  - **Deliverable:** Frustum culling logic

- **TODO [P3]:** Implement occlusion culling (skip rays behind opaque voxels)
  - **Effort:** 6 days
  - **Priority:** P3 - Ray reduction
  - **Dependencies:** Depth buffer
  - **Validation:** Rays reduced in dense scenes
  - **Deliverable:** Occlusion culling

- **TODO [P3]:** Add adaptive sampling (fewer rays for low-detail regions)
  - **Effort:** 5 days
  - **Priority:** P3 - Quality vs. speed tradeoff
  - **Dependencies:** Quality metric
  - **Validation:** Faster with acceptable quality loss
  - **Deliverable:** Adaptive sampling logic

---

## Performance Baselines (Reference)

### Current Performance (0.0.6, as of 2025-11-25)
| Metric | Simulation | FPGA (Estimated) |
|--------|------------|------------------|
| **Frame Rate** | ~10 FPS | ~30 FPS @ 100 MHz |
| **Resolution** | 480x360 | 480x360 |
| **Ray Steps (avg)** | ~50 steps/ray | ~50 steps/ray |
| **Memory Bandwidth** | N/A (BRAM) | ~40 MB/s |
| **Build Time** | ~2 min full, ~10s incremental | ~10 min synthesis |

### Target Performance (Post-Optimization)
| Metric | Target | Notes |
|--------|--------|-------|
| **Sim Frame Rate** | 30+ FPS | 3x improvement |
| **FPGA Frame Rate** | 60 FPS @ 100 MHz | 2x improvement |
| **Resolution** | 720p capable | Scalability |
| **Ray Steps (avg)** | <30 steps/ray | Algorithmic improvement |
| **Build Time** | <1 min incremental | ccache, incremental synth |

---

## Cross-References

**Related Work:**
- See `todo_ray_engine.md` for algorithmic improvements
- See `todo_rendering.md` for visual quality vs. performance tradeoffs
- See `todo_build_tooling.md` for build performance
- See `todo_hardware_validation.md` for FPGA performance validation

**Blocking Items:**
- No performance work blocks 0.0.7 (correctness first)
- P2 items improve developer experience significantly
- P3 items are long-term optimizations

---

## Notes

- **Performance optimization is post-0.0.7 focus**
- Prioritize correctness and functionality over raw performance initially
- P2 items (simulation and build speed) improve developer velocity
- P3 items (algorithmic optimizations) are significant RTL changes
- Profile before optimizing (measure, don't guess)

**Performance Philosophy:**
1. **Make it work** (0.0.6 → 0.0.7)
2. **Make it right** (testing, validation)
3. **Make it fast** (P2/P3 optimization)

**Next Actions (post-0.0.7):**
1. Profile Verilator simulation (P2)
2. Enable Verilator optimizations (P2)
3. Create benchmark suite (P2)
4. Identify RTL critical path (P2)

---

**Document Version:** 1.0
**Created:** 2025-11-25
**Status:** Active tracker for performance optimization (post-0.0.7 focus)
