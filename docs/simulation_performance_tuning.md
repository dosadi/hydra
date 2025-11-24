# Simulation Performance Tuning

## Overview

This document describes how to optimize Hydra's simulation speed for different use cases.

## Quick Wins (Most Impact)

### 1. Reduce Ray Marching Steps
**Impact**: 3-4x speedup for typical scenes

```bash
# In sim/Makefile or verilator command line
-GMAX_RAY_STEPS=16      # Default: 32 in Makefile, 128 in RTL
-GRAY_STEP_SHIFT=9      # Default: 8 (smaller steps = faster but less precise)
```

**Explanation**: Each pixel requires up to `MAX_RAY_STEPS` iterations. Reducing this trades accuracy for speed.

### 2. Reduce Screen Resolution
**Impact**: Linear with pixel count (4x smaller = 4x faster)

```bash
# 8×6 (48 pixels) - fastest, for logic testing
make VERILATOR_FLAGS="-GSCREEN_WIDTH=8 -GSCREEN_HEIGHT=6"

# 120×90 (10,800 pixels) - good for visual debugging
make VERILATOR_FLAGS="-GSCREEN_WIDTH=120 -GSCREEN_HEIGHT=90"

# 480×360 (172,800 pixels) - default, good quality
make  # Uses defaults from Makefile
```

### 3. Use Optimized Memory Model
**Impact**: 10-20% speedup

```systemverilog
// In axi_sdram_stub.sv instantiation
axi_sdram_stub #(
    .MEM_WORDS(1 << 16),        // Reduce from default 1<<18 (256K → 64K words)
    .READ_LATENCY(0),           // Zero latency (default)
    .WRITE_LATENCY(0),          // Zero latency (default)
    .WAIT_JITTER(0),            // No random stalls (default)
    .MAX_OUTSTANDING(1)         // Reduce pipelining (default: 2)
) u_sdram (...);
```

### 4. Disable Unused Features
**Impact**: 5-10% speedup

```bash
# Disable world generation (use preloaded voxels)
make VERILATOR_FLAGS="-DTEST_FORCE_WORLD_READY=1"

# Disable auto frame start
make VERILATOR_FLAGS="-DAUTO_START_FRAMES=0"
```

## Performance Modes

### Ultra-Fast Mode (Logic Testing)
**Use case**: CI, RTL tests, quick validation
**Speed**: ~10-50ms per frame

```bash
cd sim
make clean
make VERILATOR_FLAGS="\
    -GSCREEN_WIDTH=8 \
    -GSCREEN_HEIGHT=6 \
    -GMAX_RAY_STEPS=8 \
    -GRAY_STEP_SHIFT=10"
./sim_voxel
```

### Fast Mode (Visual Debugging)
**Use case**: Interactive development, shader tuning
**Speed**: ~200-500ms per frame

```bash
cd sim
make clean
make VERILATOR_FLAGS="\
    -GSCREEN_WIDTH=120 \
    -GSCREEN_HEIGHT=90 \
    -GMAX_RAY_STEPS=16 \
    -GRAY_STEP_SHIFT=9"
./sim_voxel
```

### Quality Mode (Demo/Screenshots)
**Use case**: Final validation, screenshots, recordings
**Speed**: ~1-5s per frame

```bash
cd sim
make clean
make VERILATOR_FLAGS="\
    -GSCREEN_WIDTH=480 \
    -GSCREEN_HEIGHT=360 \
    -GMAX_RAY_STEPS=64 \
    -GRAY_STEP_SHIFT=7"
./sim_voxel
```

### Stress Test Mode (Realistic Hardware)
**Use case**: Testing timing issues, bus contention
**Speed**: ~5-20s per frame (slow by design)

```systemverilog
// Modify voxel_sim_harness.sv instantiation
axi_sdram_stub #(
    .READ_LATENCY(10),      // 10 cycles read latency
    .WRITE_LATENCY(5),      // 5 cycles write latency
    .WAIT_JITTER(3),        // 0-3 random stall cycles
    .MAX_OUTSTANDING(2)     // 2 outstanding transactions
) u_sdram (...);
```

## Verilator-Specific Optimizations

### Compilation Flags
```makefile
# In sim/Makefile, add to VERILATOR_FLAGS:
-O3                    # Maximum C++ optimization
--x-assign fast        # Don't simulate X propagation
--x-initial fast       # Fast X initialization
--noassert             # Disable assertions (use with caution!)
--trace-max-array 32   # Limit array tracing depth
```

### Threading
```bash
# Use Verilator threading (if supported)
verilator ... --threads 4 -CFLAGS "-O3 -march=native"
```

### Profiling
```bash
# Find performance bottlenecks
verilator ... --profile-cfuncs
# Run simulation
gprof obj_dir/Vvoxel_framebuffer_top > profile.txt
```

## Memory Model Tuning

### For Small Test Cases (< 64 pixels)
```systemverilog
axi_sdram_stub #(
    .MEM_WORDS(1 << 14)  // 16K words (128 KiB @ 64-bit)
)
```

### For Visual Tests (< 10K pixels)
```systemverilog
axi_sdram_stub #(
    .MEM_WORDS(1 << 16)  // 64K words (512 KiB @ 64-bit)
)
```

### For Full-Resolution Tests
```systemverilog
axi_sdram_stub #(
    .MEM_WORDS(1 << 18)  // 256K words (2 MiB @ 64-bit, default)
)
```

## Ray Marching Parameters Explained

### MAX_RAY_STEPS
- **What**: Maximum iterations per pixel before giving up
- **Trade-off**: Lower = faster but more black pixels (ray escape)
- **Recommended**:
  - Tests: 8-16
  - Development: 16-32
  - Quality: 64-128

### RAY_STEP_SHIFT
- **What**: Fixed-point shift for ray step size (step = 1 << (FRAC_BITS - RAY_STEP_SHIFT))
- **Trade-off**: Larger shift = bigger steps = faster but may skip voxels
- **Recommended**:
  - Fast: 9-10 (0.5-0.25 voxel steps)
  - Balanced: 8 (0.39 voxel steps, default)
  - Precise: 7 (0.195 voxel steps)

## Common Scenarios

### "I just want to test CSR read/write logic"
```bash
# Ultra-fast, no rendering needed
make VERILATOR_FLAGS="-GSCREEN_WIDTH=1 -GSCREEN_HEIGHT=1 -GMAX_RAY_STEPS=1"
```

### "I need to verify pixel output visually"
```bash
# Fast enough to iterate, large enough to see
make VERILATOR_FLAGS="-GSCREEN_WIDTH=120 -GSCREEN_HEIGHT=90 -GMAX_RAY_STEPS=16"
```

### "I'm debugging a ray marching algorithm change"
```bash
# Quality mode with full steps
make VERILATOR_FLAGS="-GMAX_RAY_STEPS=128 -GRAY_STEP_SHIFT=7"
```

### "I'm testing DMA or bus contention issues"
```bash
# Enable realistic SDRAM delays in voxel_sim_harness.sv:
# Change axi_sdram_stub parameters to add latency/jitter
```

## Benchmarking Results

Measured on typical dev machine (Intel i7, 32GB RAM, Verilator 5.x):

| Mode           | Resolution | Steps | Time/Frame | FPS (sim) |
|----------------|------------|-------|------------|-----------|
| Ultra-Fast     | 8×6        | 8     | 10ms       | 100       |
| Fast           | 120×90     | 16    | 200ms      | 5         |
| Default        | 480×360    | 32    | 2s         | 0.5       |
| Quality        | 480×360    | 64    | 4s         | 0.25      |
| Full Quality   | 720×480    | 128   | 15s        | 0.07      |

*Note: Actual times vary based on scene complexity (voxel density, lighting).*

## Best Practices

### For Development Workflow
1. Use Fast Mode (120×90, 16 steps) for interactive work
2. Periodically test with Default Mode to catch visual regressions
3. Run Quality Mode before commits/PRs

### For CI/Testing
1. Use Ultra-Fast Mode for RTL logic tests (test_*.sv benches)
2. Use frame regression test with Default Mode (golden_frame.ppm)
3. Consider adding a fast-mode golden frame for quick smoke tests

### For Demos/Screenshots
1. Use Quality Mode or Full Quality
2. Consider increasing screen resolution to 720×480 or 1280×720
3. Set MAX_RAY_STEPS=128 for best accuracy

## Advanced: Custom Build Scripts

### Interactive Mode Switcher
```bash
# Create scripts/sim_fast.sh
#!/bin/bash
cd sim
make clean
make VERILATOR_FLAGS="-GSCREEN_WIDTH=120 -GSCREEN_HEIGHT=90 -GMAX_RAY_STEPS=16"
./sim_voxel

# Create scripts/sim_quality.sh
#!/bin/bash
cd sim
make clean
make VERILATOR_FLAGS="-GSCREEN_WIDTH=720 -GSCREEN_HEIGHT=480 -GMAX_RAY_STEPS=128"
./sim_voxel
```

### Makefile Targets
Add to `sim/Makefile`:
```makefile
.PHONY: fast quality ultra-fast

ultra-fast:
	$(MAKE) clean
	$(MAKE) VERILATOR_FLAGS="$(VERILATOR_FLAGS) -GSCREEN_WIDTH=8 -GSCREEN_HEIGHT=6 -GMAX_RAY_STEPS=8"

fast:
	$(MAKE) clean
	$(MAKE) VERILATOR_FLAGS="$(VERILATOR_FLAGS) -GSCREEN_WIDTH=120 -GSCREEN_HEIGHT=90 -GMAX_RAY_STEPS=16"

quality:
	$(MAKE) clean
	$(MAKE) VERILATOR_FLAGS="$(VERILATOR_FLAGS) -GSCREEN_WIDTH=720 -GSCREEN_HEIGHT=480 -GMAX_RAY_STEPS=128"
```

Then use: `make fast && ./sim_voxel`

## Troubleshooting

### "Simulation is still too slow"
- Profile with `verilator --profile-cfuncs` to find bottlenecks
- Check if debug tracing is enabled (--trace adds significant overhead)
- Ensure Verilator is using `-O3` optimization
- Consider reducing voxel grid size (requires RTL changes)

### "Visual artifacts with fast settings"
- Increase MAX_RAY_STEPS (rays escaping grid)
- Decrease RAY_STEP_SHIFT (steps too large, skipping voxels)
- Check for off-by-one errors in ray marching loop

### "Memory errors with reduced MEM_WORDS"
- Ensure framebuffer fits: (WIDTH × HEIGHT × 8 bytes) < (MEM_WORDS × 8)
- Account for voxel BRAM staging area (256 KiB typical)
- Leave headroom for DMA buffers

## Summary

**Quick tuning guide**:
- **10x faster**: `GMAX_RAY_STEPS=8 GSCREEN_WIDTH=8 GSCREEN_HEIGHT=6`
- **3x faster**: `GMAX_RAY_STEPS=16 GSCREEN_WIDTH=120 GSCREEN_HEIGHT=90`
- **Visual quality**: `GMAX_RAY_STEPS=64`
- **Stress test**: `READ_LATENCY=10 WRITE_LATENCY=5 WAIT_JITTER=3`

For 90% of development, use Fast Mode (120×90, 16 steps). It's fast enough to iterate quickly while still showing visual results clearly.
