#!/bin/bash
# scripts/render_benchmark.sh
# Run a brief render benchmark to measure ray steps, hits, and timing

set -euo pipefail

echo "=== Hydra Render Benchmark ==="

# Build if needed
if [ ! -f sim/sim_voxel ]; then
    echo "Building sim_voxel..."
    cd sim
    make clean
    make
    cd ..
fi

# Create output directory
mkdir -p out

# Run a short benchmark: render 10 frames with logging
echo "Running benchmark render (10 frames)..."
cd sim

# Set environment for fast benchmark mode
export LOG_FRAMES=1
export RENDER_BENCHMARK=1

# Run sim_voxel with timeout to prevent hanging
timeout 30s ./sim_voxel --benchmark 10 2>&1 | tee ../out/render_benchmark.log

cd ..

# Extract stats from log
echo "=== Benchmark Results ==="
if [ -f out/render_pipeline_baseline.csv ]; then
    echo "Timing data (last 5 frames):"
    tail -5 out/render_pipeline_baseline.csv | column -s, -t
fi

# Extract ray stats from log (assuming they are printed)
echo ""
echo "Ray statistics from log:"
grep -E "(ray_steps|hit_count|miss_count)" out/render_benchmark.log || echo "No ray stats found in log"

echo ""
echo "Benchmark complete. Full log in out/render_benchmark.log"