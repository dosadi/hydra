FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    make \
    pkg-config \
    ca-certificates \
    wget \
    git \
    verilator \
    libsdl2-dev \
    libsdl2-ttf-dev \
    libpng-dev \
    libgl1-mesa-dev \
    python3 \
    python3-pip \
    xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Copy the repository into the image. Docker cache will help during iterative builds.
COPY . /workspace

# Build the sim target. This may take a while (verilator + C++ build).
WORKDIR /workspace/sim
RUN make -j"$(nproc)" || true

# Default command prints help; use the run script (`run_container.sh`) to run with correct mounts.
WORKDIR /workspace
CMD ["bash"]
