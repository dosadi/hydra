# Cross-compiling Hydra

This guide covers cross-compiling Hydra components for different architectures including ARM64 (aarch64), RISC-V 64-bit (riscv64), and other targets.

## Supported Architectures

- **aarch64**: ARM 64-bit (Raspberry Pi 4/5, Jetson, etc.)
- **riscv64**: RISC-V 64-bit (HiFive, VisionFive, etc.)
- **armhf**: ARM 32-bit hard float (Raspberry Pi 1-3)
- **x86_64**: AMD64 (standard Linux, for reference)

## Prerequisites

### Ubuntu/Debian Host Setup

```bash
# ARM64 cross-compilation
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
    crossbuild-essential-arm64

# RISC-V 64 cross-compilation
sudo apt install -y gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    crossbuild-essential-riscv64

# ARM 32-bit cross-compilation
sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
    crossbuild-essential-armhf

# CMake for cross-compilation
sudo apt install -y cmake
```

### Fedora/CentOS Host Setup

```bash
# ARM64
sudo dnf install -y gcc-aarch64-linux-gnu gcc-c++-aarch64-linux-gnu

# RISC-V 64
sudo dnf install -y gcc-riscv64-linux-gnu gcc-c++-riscv64-linux-gnu

# ARM 32-bit
sudo dnf install -y gcc-arm-linux-gnu gcc-c++-arm-linux-gnu
```

## Cross-compiling the Linux Driver (kmod)

### ARM64 (aarch64)

```bash
# Set cross-compilation environment
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Build the driver
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# Verify the output
file hydra_pcie_drv.ko
# Should show: ELF 64-bit LSB relocatable, ARM aarch64, version 1 (SYSV)
```

### RISC-V 64 (riscv64)

```bash
# Set cross-compilation environment
export ARCH=riscv
export CROSS_COMPILE=riscv64-linux-gnu-

# Build the driver
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# Verify the output
file hydra_pcie_drv.ko
# Should show: ELF 64-bit LSB relocatable, UCB RISC-V, version 1 (SYSV)
```

### ARM 32-bit (armhf)

```bash
# Set cross-compilation environment
export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

# Build the driver
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules

# Verify the output
file hydra_pcie_drv.ko
# Should show: ELF 32-bit LSB relocatable, ARM, EABI5 version 1
```

### Common Issues

**Kernel Headers Mismatch:**
```bash
# Error: "Cannot generate ORC metadata for CONFIG_UNWINDER_ORC=y"
# Solution: Use target kernel headers, not host headers
make -C /path/to/target/kernel/source M=$(pwd) modules
```

**Missing Kernel Config:**
```bash
# Error: "CONFIG_PCI not enabled"
# Solution: Ensure target kernel has required options
zcat /proc/config.gz | grep CONFIG_PCI
```

## Cross-compiling libhydra (userspace library)

### Using CMake (Recommended)

**ARM64:**
```bash
# Configure for cross-compilation
cmake -S . -B build/aarch64 \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
    -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
    -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
    -DCMAKE_INSTALL_PREFIX=/usr/aarch64-linux-gnu \
    -DCMAKE_FIND_ROOT_PATH=/usr/aarch64-linux-gnu \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY

# Build
cmake --build build/aarch64 --target libhydra -- -j$(nproc)

# Install to sysroot
cmake --install build/aarch64
```

**RISC-V 64:**
```bash
# Configure for cross-compilation
cmake -S . -B build/riscv64 \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
    -DCMAKE_C_COMPILER=riscv64-linux-gnu-gcc \
    -DCMAKE_CXX_COMPILER=riscv64-linux-gnu-g++ \
    -DCMAKE_INSTALL_PREFIX=/usr/riscv64-linux-gnu \
    -DCMAKE_FIND_ROOT_PATH=/usr/riscv64-linux-gnu \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY

# Build
cmake --build build/riscv64 --target libhydra -- -j$(nproc)
```

### Using Make (Alternative)

**ARM64:**
```bash
# Set cross-compilers
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

# Build libhydra
make -C drivers/libhydra libhydra.a

# Verify
file drivers/libhydra/libhydra.a
# Should show: current ar archive
aarch64-linux-gnu-objdump -a drivers/libhydra/libhydra.a | head -5
```

## Cross-compiling SDK Tools

### ARM64 Example

```bash
# Set cross-compilation environment
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

# Build all SDK tools
./scripts/setup_sdk.sh

# Verify binaries
file scripts/hydra_blit_smoketest
# Should show: ELF 64-bit LSB executable, ARM aarch64, version 1

file scripts/hydra_dma_blit_demo
# Should show: ELF 64-bit LSB executable, ARM aarch64, version 1
```

## Cross-compiling the Simulator (Verilator)

### Prerequisites

```bash
# Install cross-compilers for Verilator
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Verilator itself needs to be built for the target architecture
# This is complex and usually not recommended
```

### ARM64 (Limited Support)

```bash
# Verilator simulation requires native compilation
# Cross-compiling Verilator output is not straightforward
# Recommendation: Build Verilator natively on target system

# For development, build on x86_64 host and deploy binaries
make -C sim
file sim/sim_voxel
# Keep on x86_64 for development
```

## Target System Deployment

### Copying Files to Target

**ARM64 Example:**
```bash
# Copy driver
scp drivers/linux/hydra_pcie_drv.ko user@arm64-target:/tmp/

# Copy userspace libraries
scp build/aarch64/lib/libhydra.a user@arm64-target:/usr/local/lib/
scp drivers/libhydra/hydra.h user@arm64-target:/usr/local/include/

# Copy tools
scp scripts/hydra_blit_smoketest user@arm64-target:/usr/local/bin/
scp scripts/hydra_dma_blit_demo user@arm64-target:/usr/local/bin/
```

### Target System Installation

**On ARM64 Target:**
```bash
# Install driver
sudo insmod /tmp/hydra_pcie_drv.ko

# Install libraries
sudo cp /tmp/libhydra.a /usr/local/lib/
sudo cp /tmp/hydra.h /usr/local/include/

# Install tools
sudo cp /tmp/hydra_blit_smoketest /usr/local/bin/
sudo cp /tmp/hydra_dma_blit_demo /usr/local/bin/

# Verify
ls /dev/hydra_pcie
lsmod | grep hydra
```

## Testing Cross-compiled Binaries

### Basic Functionality Test

```bash
# On target system
sudo ./hydra_blit_smoketest /dev/hydra_pcie
# Should complete without errors

sudo ./hydra_drm_info /dev/hydra_pcie
# Should show device information
```

### Architecture Verification

```bash
# Check if binary is correct architecture
file /usr/local/bin/hydra_blit_smoketest
# Should show target architecture, not host

# Run ldd to check library dependencies
ldd /usr/local/bin/hydra_blit_smoketest
# Should show target system libraries
```

## Common Cross-compilation Issues

### Library Path Issues

**Problem:** "cannot find -lSDL2"
**Solution:**
```bash
# Install target libraries or use static linking
apt install libsdl2-dev:arm64
# Or
export CMAKE_EXE_LINKER_FLAGS="-static"
```

### Header File Mismatches

**Problem:** "stddef.h: No such file"
**Solution:**
```bash
# Set correct sysroot
export SYSROOT=/usr/aarch64-linux-gnu
export CFLAGS="--sysroot=$SYSROOT"
export CXXFLAGS="--sysroot=$SYSROOT"
```

### Endianness Issues

**Problem:** Data corruption on big-endian targets
**Solution:**
```bash
# Ensure little-endian target
# Most ARM64/RISC-V are little-endian by default
lscpu | grep "Byte Order"
```

### Floating Point ABI

**Problem:** "hard float" vs "soft float" mismatch
**Solution:**
```bash
# For ARM, ensure hard float
export CROSS_COMPILE=arm-linux-gnueabihf-  # Not arm-linux-gnueabi-
```

## CI/CD Cross-compilation

### GitHub Actions Example

```yaml
name: Cross-compile
on: [push, pull_request]

jobs:
  cross-compile:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch: [aarch64, riscv64, armhf]
    steps:
    - uses: actions/checkout@v3
    - name: Install cross-compilers
      run: |
        sudo apt update
        sudo apt install -y gcc-${{ matrix.arch }}-linux-gnu g++-${{ matrix.arch }}-linux-gnu
    - name: Cross-compile libhydra
      run: |
        export CC=${{ matrix.arch }}-linux-gnu-gcc
        export CXX=${{ matrix.arch }}-linux-gnu-g++
        make -C drivers/libhydra libhydra.a
    - name: Test compilation
      run: |
        file drivers/libhydra/libhydra.a
```

## Performance Considerations

### Architecture-specific Optimizations

**ARM64:**
- Use NEON SIMD when available
- Enable CRC32 extensions
- Consider 64-bit operations for better performance

**RISC-V:**
- Use RV64GC (General purpose + Compressed + Floating point)
- Consider vector extensions (RVV) for future optimization
- Atomic operations for synchronization

### Benchmarking Cross-compiled Code

```bash
# Compare performance between architectures
time ./hydra_blit_smoketest /dev/hydra_pcie
# Note execution time and compare across targets
```

## Troubleshooting

### Build Fails with "unrecognized command line option"

**Cause:** Compiler version mismatch
**Fix:** Update cross-compiler toolchain
```bash
sudo apt install --only-upgrade gcc-aarch64-linux-gnu
```

### Runtime Fails with "Exec format error"

**Cause:** Wrong architecture binary
**Fix:** Verify with `file` command and rebuild

### Library Not Found

**Cause:** Missing target system libraries
**Fix:** Install on target or statically link
```bash
# Static linking example
export LDFLAGS="-static"
```

## References

- [CMake Cross-compiling](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html)
- [Linux Kernel Cross-compilation](https://www.kernel.org/doc/html/latest/kbuild/index.html)
- [Debian Cross-compilation](https://wiki.debian.org/CrossCompiling)
