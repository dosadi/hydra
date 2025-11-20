FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential git pkg-config \
    verilator \
    libsdl2-dev libsdl2-ttf-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# You’ll clone your repo into /workspace in your own workflow, e.g.:
# docker run -it --rm -v $(pwd):/workspace voxel-accel-dev /bin/bash
