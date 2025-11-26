#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# ============================================================================
# batch_render.sh
# - Batch render N frames using headless backend
# - Useful for CI, benchmarking, and regression testing
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SIM_BIN="${SIM_BIN:-$PROJECT_ROOT/sim/sim_voxel}"

# Defaults
NUM_FRAMES=10
OUTPUT_DIR="./batch_output"
OUTPUT_PREFIX="frame"
BACKEND="headless"
WORLD_SEED=""
CAMERA_POS=""
CAMERA_ANG=""
VERBOSE=0
BENCHMARK=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Batch render multiple frames in headless mode.

Options:
  -n, --frames NUM       Number of frames to render (default: 10)
  -o, --output DIR       Output directory (default: ./batch_output)
  -p, --prefix PREFIX    Output file prefix (default: frame)
  -b, --backend BACKEND  Backend to use (default: headless)
  -s, --seed SEED        World seed for deterministic output
  -c, --camera X,Y,Z     Camera position
  -a, --angle YAW,PITCH  Camera angle (yaw,pitch in degrees)
  --benchmark            Benchmark mode (measure render time)
  -v, --verbose          Verbose output
  -h, --help             Show this help

Examples:
  # Render 10 frames to ./batch_output/
  $0

  # Render 100 frames for benchmarking
  $0 -n 100 --benchmark

  # Deterministic render with fixed seed
  $0 -n 5 -s 42 -o regression_frames

  # Custom camera position
  $0 -n 10 -c 32,32,32 -a 45,30
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--frames)
            NUM_FRAMES="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--prefix)
            OUTPUT_PREFIX="$2"
            shift 2
            ;;
        -b|--backend)
            BACKEND="$2"
            shift 2
            ;;
        -s|--seed)
            WORLD_SEED="$2"
            shift 2
            ;;
        -c|--camera)
            CAMERA_POS="$2"
            shift 2
            ;;
        -a|--angle)
            CAMERA_ANG="$2"
            shift 2
            ;;
        --benchmark)
            BENCHMARK=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate inputs
if [ ! -f "$SIM_BIN" ]; then
    echo -e "${RED}ERROR:${NC} Simulator binary not found: $SIM_BIN"
    echo "Build it first: make -C sim"
    exit 1
fi

if [ "$NUM_FRAMES" -lt 1 ]; then
    echo -e "${RED}ERROR:${NC} Number of frames must be >= 1"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${CYAN}=== Hydra Batch Render ===${NC}"
echo -e "Frames:  ${YELLOW}$NUM_FRAMES${NC}"
echo -e "Output:  ${YELLOW}$OUTPUT_DIR/${OUTPUT_PREFIX}_*.ppm${NC}"
echo -e "Backend: ${YELLOW}$BACKEND${NC}"
[ -n "$WORLD_SEED" ] && echo -e "Seed:    ${YELLOW}$WORLD_SEED${NC}"
[ -n "$CAMERA_POS" ] && echo -e "Camera:  ${YELLOW}$CAMERA_POS${NC}"
[ -n "$CAMERA_ANG" ] && echo -e "Angle:   ${YELLOW}$CAMERA_ANG${NC}"
echo ""

# Build environment
export HYDRA_BACKEND="$BACKEND"
[ -n "$WORLD_SEED" ] && export HYDRA_WORLD_SEED="$WORLD_SEED"
[ -n "$CAMERA_POS" ] && export HYDRA_CAM_POS="$CAMERA_POS"
[ -n "$CAMERA_ANG" ] && export HYDRA_CAM_ANG="$CAMERA_ANG"

# Benchmark setup
if [ $BENCHMARK -eq 1 ]; then
    BENCH_START=$(date +%s%N)
    FRAME_TIMES=()
fi

# Render frames
for i in $(seq 0 $((NUM_FRAMES - 1))); do
    FRAME_PATH="$OUTPUT_DIR/${OUTPUT_PREFIX}_$(printf '%04d' $i).ppm"

    if [ $BENCHMARK -eq 1 ]; then
        FRAME_START=$(date +%s%N)
    fi

    if [ $VERBOSE -eq 1 ]; then
        echo -e "${BLUE}[Frame $((i+1))/$NUM_FRAMES]${NC} Rendering to $FRAME_PATH..."
        FRAME_DUMP="$FRAME_PATH" AUTO_EXIT=1 "$SIM_BIN"
    else
        # Use quiet mode to suppress backend messages
        HYDRA_QUIET=1 FRAME_DUMP="$FRAME_PATH" AUTO_EXIT=1 "$SIM_BIN" >/dev/null 2>&1
    fi

    if [ ! -f "$FRAME_PATH" ]; then
        echo -e "${RED}ERROR:${NC} Frame $i failed to render"
        exit 1
    fi

    if [ $BENCHMARK -eq 1 ]; then
        FRAME_END=$(date +%s%N)
        FRAME_TIME=$(( (FRAME_END - FRAME_START) / 1000000 ))  # Convert to ms
        FRAME_TIMES+=($FRAME_TIME)

        if [ $VERBOSE -eq 1 ]; then
            echo -e "  ${GREEN}✓${NC} Rendered in ${FRAME_TIME}ms"
        else
            printf "${GREEN}█${NC}"
        fi
    else
        if [ $VERBOSE -eq 0 ]; then
            printf "${GREEN}█${NC}"
        fi
    fi
done

[ $VERBOSE -eq 0 ] && echo ""  # Newline after progress bar

# Report results
echo ""
echo -e "${GREEN}✓${NC} Successfully rendered $NUM_FRAMES frames"

# Compute statistics
TOTAL_SIZE=0
for f in "$OUTPUT_DIR/${OUTPUT_PREFIX}"_*.ppm; do
    if [ -f "$f" ]; then
        SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    fi
done

TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024" | bc)
echo -e "Total size: ${YELLOW}${TOTAL_SIZE_MB} MB${NC}"

# Benchmark results
if [ $BENCHMARK -eq 1 ]; then
    BENCH_END=$(date +%s%N)
    TOTAL_TIME=$(( (BENCH_END - BENCH_START) / 1000000 ))  # ms
    AVG_TIME=0
    MIN_TIME=${FRAME_TIMES[0]}
    MAX_TIME=${FRAME_TIMES[0]}

    for t in "${FRAME_TIMES[@]}"; do
        AVG_TIME=$((AVG_TIME + t))
        [ $t -lt $MIN_TIME ] && MIN_TIME=$t
        [ $t -gt $MAX_TIME ] && MAX_TIME=$t
    done
    AVG_TIME=$((AVG_TIME / NUM_FRAMES))

    echo ""
    echo -e "${CYAN}=== Benchmark Results ===${NC}"
    echo -e "Total time:   ${YELLOW}${TOTAL_TIME}ms${NC} ($(echo "scale=2; $TOTAL_TIME / 1000" | bc)s)"
    echo -e "Average/frame: ${YELLOW}${AVG_TIME}ms${NC}"
    echo -e "Min/frame:    ${GREEN}${MIN_TIME}ms${NC}"
    echo -e "Max/frame:    ${RED}${MAX_TIME}ms${NC}"
    echo -e "Throughput:   ${YELLOW}$(echo "scale=2; $NUM_FRAMES * 1000 / $TOTAL_TIME" | bc) FPS${NC}"
fi

echo ""
echo -e "${CYAN}Frames written to:${NC} $OUTPUT_DIR/"
