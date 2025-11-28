# Performance Tuning Guide

This guide covers performance expectations, benchmarking, and optimization techniques for the Hydra simulation.

## Baseline Performance Expectations

### Frame Rates
- **Typical FPS**: 10-30 FPS on modern hardware (depends on scene complexity)
- **Target FPS**: Configurable via `HYDRA_FPS_TARGET` environment variable
- **VSync**: Enabled by default, can be disabled with `HYDRA_VSYNC=0`

### Memory Usage
- **Simulation memory**: ~50-100MB for basic scenes
- **Framebuffer**: 480×360×4 = ~691KB per frame
- **Verilator overhead**: Additional 200-500MB depending on optimization level

### CPU Usage
- **Single-threaded**: Ray tracing runs on single CPU core
- **SDL overhead**: Minimal additional CPU usage
- **Memory bandwidth**: Critical for performance

## Performance Monitoring

### Built-in Metrics
The viewer displays real-time performance metrics in the HUD:

```
FPS 24.3 | Pos 10.0 10.0 10.0
Mem: rd 45.2% wr 12.8%
Hits 1247 | ray avg 2.3 max 15 miss 89
```

- **FPS**: Frames per second (higher is better)
- **Mem utilization**: Memory read/write percentages (lower is better)
- **Ray statistics**: Hit count, average/max ray steps, miss count

### Environment Variables for Monitoring
```bash
LOG_FRAMES=1     # Log frame completion details
HYDRA_RENDER_INSTRUMENT=1  # Detailed timing breakdown
```

## Optimization Techniques

### Hardware Acceleration
```bash
# Use GPU acceleration (if available)
HYDRA_BACKEND=gl     # OpenGL backend
HYDRA_BACKEND=vulkan # Vulkan backend (if compiled in)

# Check available backends
./sim_voxel --caps
```

### Rendering Flags
```bash
# Disable expensive features for better performance
# (All enabled by default for quality)
HYDRA_RAY_JITTER=0     # Disable anti-aliasing
# Keep smooth_surfaces=1, curvature=1 for acceptable quality
```

### Simulation Parameters
```bash
# Reduce simulation chunk size (may affect stability)
# Edit sim/viewer.cpp: const int cycles_per_chunk = 2000;

# Use faster movement speeds to reduce frame time variance
HYDRA_MOVE_SPEED=0.5
HYDRA_MOVE_SPEED_FAST=1.0
```

### Build Optimizations
```bash
# Build with optimizations
make sim CFLAGS="-O3 -march=native"

# Use faster compiler
make sim CXX=clang++
```

## Benchmarking

### Quick Benchmark
```bash
# Run benchmark with logging
LOG_FRAMES=1 AUTO_EXIT=1 ./sim_voxel

# Or use the bench target
make bench
```

### Performance Regression Testing
```bash
# Compare before/after changes
HYDRA_RENDER_INSTRUMENT=1 ./sim_voxel > before.csv
# Make changes...
HYDRA_RENDER_INSTRUMENT=1 ./sim_voxel > after.csv
```

### Profiling
```bash
# Use perf for CPU profiling
perf record ./sim_voxel
perf report

# Use heaptrack for memory profiling
heaptrack ./sim_voxel
```

## Common Performance Issues

### Low FPS (< 10)
**Symptoms**: Choppy animation, high input lag
**Causes**:
- Complex scenes with many ray bounces
- Memory bandwidth saturation
- CPU frequency scaling
- VSync enabled on slow displays

**Solutions**:
```bash
HYDRA_VSYNC=0                    # Disable VSync
HYDRA_FPS_TARGET=30             # Cap FPS to reduce CPU load
# Simplify scene or reduce render distance
```

### High Memory Usage
**Symptoms**: System slowdown, out-of-memory errors
**Causes**:
- Large framebuffers
- Verilator unoptimized build
- Memory leaks in simulation

**Solutions**:
```bash
# Build Verilator with optimizations
make sim VERILATOR_OPT="--O3"

# Reduce framebuffer size (edit SCREEN_WIDTH/SCREEN_HEIGHT)
# Monitor with htop or free -h
```

### Stuttering
**Symptoms**: Inconsistent frame times
**Causes**:
- Variable simulation load per frame
- Memory allocation during frame
- Background processes

**Solutions**:
```bash
# Use real-time scheduling
chrt --rr 50 ./sim_voxel

# Pin to specific CPU cores
taskset -c 0-3 ./sim_voxel
```

## Platform-Specific Tuning

### Linux
```bash
# Use performance governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable address space randomization
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
```

### macOS
```bash
# Use Metal backend if available
HYDRA_BACKEND=metal  # (if implemented)
```

### Windows (WSL)
```bash
# Use Windows graphics drivers
HYDRA_BACKEND=gl
# Consider native Windows build for better performance
```

## Advanced Optimization

### Verilator Optimizations
```bash
# In Makefile, add to VERILATOR_FLAGS
VERILATOR_FLAGS += --O3 --x-assign fast --noassert
```

### Compiler Optimizations
```bash
# Aggressive optimizations (may affect debugging)
CXXFLAGS += -O3 -march=native -flto -funroll-loops
```

### Memory Layout
- Framebuffer is accessed linearly for good cache performance
- Voxel data is stored in BRAM for fast access
- Consider NUMA placement for multi-socket systems

## Troubleshooting

### Performance Debugging
```bash
# Enable verbose logging
HYDRA_VERBOSE=1 ./sim_voxel

# Check system resources
top -p $(pidof sim_voxel)
iostat -x 1
```

### Common Issues
1. **"Slow on first frame"**: Normal - Verilator initialization overhead
2. **"FPS drops over time"**: Check for memory leaks or thermal throttling
3. **"Inconsistent performance"**: Disable CPU frequency scaling

### Getting Help
- Check HUD metrics for bottlenecks
- Use `LOG_FRAMES=1` for detailed per-frame analysis
- Compare against known good configurations
- File issues with `LOG_FRAMES=1` output and system specs

## Expected Performance by Hardware

### High-End Desktop (Intel i7-13700K, RTX 4070)
- **FPS**: 30-60
- **Memory**: 200-400MB
- **CPU usage**: 50-80% single core

### Mid-Range Laptop (Intel i5-1240P)
- **FPS**: 15-30
- **Memory**: 150-300MB
- **CPU usage**: 70-90% single core

### Low-End Systems (Intel i3/Raspberry Pi 4)
- **FPS**: 5-15
- **Memory**: 100-200MB
- **CPU usage**: 90-100% single core

*Note: Performance heavily depends on scene complexity and rendering flags. Simple scenes may achieve higher FPS.*</content>
<parameter name="filePath">/workspaces/hydra/docs/performance_tuning.md