#!/usr/bin/env bash
set -euo pipefail

# Build and run the hydra sim in Docker.
# Usage:
#   ./run_container.sh build            # build the image
#   ./run_container.sh run [--gui]      # run the container; --gui enables X11 forwarding
#   ./run_container.sh run --headless   # run headless (no DISPLAY mapping)

IMAGE_NAME="hydra-sim:local"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function build_image() {
    echo "[run_container] Building image $IMAGE_NAME (this may take several minutes)"
    docker build -t "$IMAGE_NAME" "$HERE"
}

function run_container() {
    local gui=false
    if [ "${1-}" = "--gui" ]; then
        gui=true
    fi

    # Common mounts
    mounts=( -v "$HERE":/workspace )

    envs=( -e HYDRA_FONT -e HYDRA_FOG -e HYDRA_FOG_COLOR -e HYDRA_FOG_DENSITY -e HYDRA_RENDER_INSTRUMENT )

    if $gui; then
        if [ -z "${DISPLAY:-}" ]; then
            echo "[run_container] DISPLAY not set — cannot enable GUI"
            exit 1
        fi
        echo "[run_container] Running with X11 GUI support (DISPLAY=$DISPLAY)"
        mounts+=( -v /tmp/.X11-unix:/tmp/.X11-unix )
        # If you use Xauthority, bind it in; otherwise xhost +local:root may be needed
        if [ -n "${XAUTHORITY:-}" ] && [ -f "$XAUTHORITY" ]; then
            mounts+=( -v "$XAUTHORITY":/root/.Xauthority:ro )
            envs+=( -e XAUTHORITY=/root/.Xauthority )
        fi
        # Allow GPU/KMS passthrough if present (optional)
        if [ -d /dev/dri ]; then
            mounts+=( --device /dev/dri )
        fi
        docker run --rm -it "${mounts[@]}" "${envs[@]}" -e DISPLAY="$DISPLAY" --name hydra_sim "$IMAGE_NAME" /workspace/sim/sim_voxel
    else
        echo "[run_container] Running headless (logs in container stdout)."
        docker run --rm -it "${mounts[@]}" "${envs[@]}" --name hydra_sim "$IMAGE_NAME" /workspace/sim/sim_voxel
    fi
}

case "${1-}" in
    build)
        build_image
        ;;
    run)
        run_container "${2-}"
        ;;
    *)
        echo "Usage: $0 {build|run [--gui|--headless]}"
        exit 2
        ;;
esac
