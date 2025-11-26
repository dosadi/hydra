# Hydra Package & Dependency Requirements

**Version:** 1.0
**Generated:** 2025-11-25
**Purpose:** Comprehensive tracking of external package/install requirements across all platforms and build targets.

---

## Overview

This document tracks all external dependencies required to build, test, and deploy Hydra components across supported platforms. Dependencies are organized by:

1. **Platform** (Linux, FreeBSD, macOS, Windows)
2. **Component** (simulation, drivers, SDK, testing, FPGA synthesis)
3. **Sector mapping** (links to `docs/todo/todo_sector_map.json`)

**Quick Reference:**
- Linux quickstart: [Debian/Ubuntu Installation](#debianubuntu-linux)
- macOS quickstart: [macOS Installation](#macos)
- Windows quickstart: [Windows Installation](#windows-msys2mingw)
- FreeBSD quickstart: [FreeBSD Installation](#freebsd)

---

## Summary by Component

| Component | Required Packages | Optional Packages | Sector |
|-----------|------------------|-------------------|--------|
| **RTL Simulation (Verilator)** | verilator (5.x), libsdl2-dev, libsdl2-ttf-dev, build-essential/gcc, make | GL libs, Vulkan SDK, X11/Wayland dev libs | SECTOR-06 (SIM_TEST) |
| **RTL Benches (iverilog)** | iverilog, vvp | - | SECTOR-06 (SIM_TEST) |
| **Cocotb Tests** | python3, pip, cocotb, pytest | - | SECTOR-06 (SIM_TEST) |
| **Linux PCIe Driver** | linux-headers-$(uname -r), build-essential/gcc, make | libdrm-dev (for DRM tools) | SECTOR-07 (DRIVERS_SDK) |
| **FreeBSD Driver** | freebsd-src (kernel headers/sources), gmake, llvm15, git | - | SECTOR-07 (DRIVERS_SDK) |
| **SDK/libhydra** | gcc, make, pkg-config | libdrm-dev (optional DRM tool) | SECTOR-07 (DRIVERS_SDK) |
| **CMake Build (host libs)** | cmake (3.20+), ninja-build, gcc/clang | - | SECTOR-10 (BUILD_CI) |
| **Pre-commit Hooks** | python3, pip, pre-commit, codespell | - | SECTOR-10 (BUILD_CI) |
| **FPGA Synthesis (LiteX)** | python3, pip, litex, migen, yosys, nextpnr (or Vivado/Quartus) | - | SECTOR-05 (FPGA_BOARD), SECTOR-04 (IP_INTEGRATION) |
| **Third-Party IP (submodules)** | git | - | SECTOR-04 (IP_INTEGRATION) |
| **Documentation Linting** | python3 | - | SECTOR-11 (DOCS_EXAMPLES) |

---

## Debian/Ubuntu Linux

### Minimal Installation (Simulation Only)

```bash
sudo apt-get update
sudo apt-get install -y \
  verilator \
  libsdl2-dev \
  libsdl2-ttf-dev \
  build-essential \
  cmake \
  ninja-build \
  python3 \
  python3-pip \
  pkg-config
```

**What this enables:**
- `make -C sim` (Verilator + SDL2 viewer)
- `make -C sim test_frame` (frame regression)
- `./scripts/setup_sdk.sh` (libhydra + tools)
- CMake build for host libs

### Full Development Installation

```bash
# Add optional backends
sudo apt-get install -y \
  libgl-dev \
  libvulkan-dev \
  libx11-dev \
  libwayland-dev

# Add RTL testing tools
sudo apt-get install -y \
  iverilog \
  gtkwave

# Add Python test tools
python3 -m pip install --user --upgrade pip
python3 -m pip install --user cocotb pytest

# Add pre-commit hooks
python3 -m pip install --user pre-commit
pre-commit install

# Add documentation linting
python3 -m pip install --user markdown-link-check  # if available
```

### Linux Kernel Driver Build

```bash
# Install kernel headers for running kernel
sudo apt-get install -y linux-headers-$(uname -r)

# Optional: libdrm for DRM tools
sudo apt-get install -y libdrm-dev

# Build driver
make -C /lib/modules/$(uname -r)/build M=$(pwd)/drivers/linux modules
```

### FPGA Synthesis (Vivado/LiteX)

```bash
# LiteX toolchain (open source)
python3 -m pip install --user litex migen

# Yosys/nextpnr (for open FPGA flows)
sudo apt-get install -y yosys nextpnr-xilinx

# Xilinx Vivado (proprietary - manual install)
# Download from Xilinx website, requires license for some boards
```

**Sector Mapping:**
- Simulation: SECTOR-06 (SIM_TEST)
- Drivers: SECTOR-07 (DRIVERS_SDK)
- FPGA: SECTOR-05 (FPGA_BOARD), SECTOR-04 (IP_INTEGRATION)

---

## macOS

### Homebrew Installation

```bash
# Install Homebrew if not present
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Run automated setup script
./scripts/setup_macos_env.sh
```

**What the script installs:**
- SDL2, SDL2_ttf
- Python 3.12+
- pkg-config
- cocotb, pytest (via pip)

### Manual Installation

```bash
brew update
brew install sdl2 sdl2_ttf python@3.12 pkg-config verilator cmake ninja

# Python test tools
python3 -m pip install --upgrade pip cocotb pytest

# Pre-commit hooks
python3 -m pip install pre-commit
pre-commit install
```

### CMake Build (macOS preset)

```bash
cmake --preset macos
cmake --build build/macos
```

**Notes:**
- Verilator may require building from source if Homebrew version is outdated
- macOS kernel driver is **not supported** (documented only)
- FPGA synthesis requires Vivado/Quartus (macOS support varies by version)

**Sector Mapping:**
- Simulation: SECTOR-06 (SIM_TEST)
- Build: SECTOR-10 (BUILD_CI)
- Cross-platform: SECTOR-14 (MULTIPLATFORM)

---

## Windows (MSYS2/MinGW)

### MSYS2 Installation

```bash
# Install MSYS2 from https://www.msys2.org/ first

# Inside MSYS2 UCRT64 shell:
pacman -Syu
pacman -S \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-SDL2 \
  mingw-w64-ucrt-x86_64-SDL2_ttf \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-ninja \
  mingw-w64-ucrt-x86_64-python \
  make
```

### MSVC Build (Visual Studio)

**Prerequisites:**
- Visual Studio 2019+ with C++ workload
- CMake 3.20+
- vcpkg (for SDL2 if using vcpkg)

```powershell
# From repo root in Developer Command Prompt:
cmake --preset windows-msvc
cmake --build build/windows
```

**What this builds:**
- libhydra (static library)
- Host-side tools (POSIX tools are skipped on Windows)

### Verilator Simulation (Experimental on Windows)

```bash
# Install Verilator (build from source or use prebuilt if available)
# Set SDL_CFLAGS/SDL_LIBS manually if sdl2-config is missing:
export SDL_CFLAGS="-I/mingw64/include/SDL2 -D_REENTRANT"
export SDL_LIBS="-L/mingw64/lib -lSDL2 -lSDL2_ttf"

cd sim
make VERILATOR=verilator CXX=g++ SDL_CFLAGS="$SDL_CFLAGS" SDL_LIBS="$SDL_LIBS"
```

**Notes:**
- Verilator on Windows is **community-supported** (expect warnings)
- **Recommended:** Use WSL2 for simulation (see Linux instructions)
- Windows kernel driver is **not supported** (documented only)

**Sector Mapping:**
- Build: SECTOR-10 (BUILD_CI)
- Cross-platform: SECTOR-14 (MULTIPLATFORM)

---

## FreeBSD

### Package Installation

```bash
# Install packages via pkg
sudo pkg install git llvm15 gmake sdl2 sdl2_ttf cmake ninja python3

# Install kernel sources (for driver builds)
sudo pkg install freebsd-src

# Python test tools
python3 -m pip install --upgrade pip cocotb pytest
```

### FreeBSD Kernel Driver Build

```bash
cd drivers/bsd
gmake -f Makefile.kmod

# Load module
sudo kldload ./hydra.ko

# Check status
kldstat | grep hydra
sysctl dev.hydra

# Unload module
sudo kldunload hydra
```

### QEMU Testing Environment

See `docs/freebsd_qemu.md` for detailed QEMU setup instructions for FreeBSD driver testing.

**Sector Mapping:**
- Drivers: SECTOR-07 (DRIVERS_SDK)
- Multi-platform: SECTOR-14 (MULTIPLATFORM)

---

## Python Dependencies

### Core Python Packages

| Package | Version | Purpose | Installation |
|---------|---------|---------|-------------|
| **cocotb** | Latest | RTL cocotb benches | `pip install cocotb` |
| **pytest** | Latest | Python unit tests | `pip install pytest` |
| **pre-commit** | Latest | Pre-commit hooks | `pip install pre-commit` |
| **codespell** | v2.2.6+ | Spell checking | `pip install codespell` (via pre-commit) |
| **litex** | Latest | FPGA synthesis (LiteX SoC) | `pip install litex` |
| **migen** | Latest | FPGA HDL (LiteX dependency) | `pip install migen` |

### Installation

```bash
# All-in-one Python setup
python3 -m pip install --user --upgrade pip
python3 -m pip install --user cocotb pytest pre-commit litex migen

# Install pre-commit hooks
pre-commit install
```

**Sector Mapping:**
- Testing: SECTOR-06 (SIM_TEST)
- Build/CI: SECTOR-10 (BUILD_CI)
- FPGA: SECTOR-04 (IP_INTEGRATION)

---

## Third-Party IP (Git Submodules)

### Submodule Dependencies

```bash
# Initialize all submodules (idempotent, safe to re-run)
./scripts/fetch_ip.sh

# Manual check
git submodule status third_party/*
```

### IP Packages Required

| IP | Repository | License | Purpose | Sector |
|----|-----------|---------|---------|--------|
| **LitePCIe** | https://github.com/enjoy-digital/litepcie | BSD | PCIe endpoint + DMA | SECTOR-04 (IP_INTEGRATION) |
| **LiteDRAM** | https://github.com/enjoy-digital/litedram | BSD | DDR3/DDR4 controller | SECTOR-04 (IP_INTEGRATION) |
| **LiteICLink** | https://github.com/enjoy-digital/liteiclink | BSD | HDMI/DVI encoder | SECTOR-03 (VIDEO_HDMI) |
| **LiteX** | https://github.com/enjoy-digital/litex | BSD | SoC framework | SECTOR-04 (IP_INTEGRATION) |

**Dependencies:** None (vendored as submodules)
**See:** `third_party/README.md` for pinned commit hashes

**Sector Mapping:**
- SECTOR-04 (IP_INTEGRATION)
- SECTOR-03 (VIDEO_HDMI)

---

## FPGA Toolchain Requirements

### Open Source Toolchain

```bash
# Yosys synthesis
sudo apt-get install yosys

# nextpnr place-and-route (for Xilinx/Lattice/etc.)
sudo apt-get install nextpnr-xilinx nextpnr-ecp5

# LiteX (Python-based)
python3 -m pip install litex migen
```

### Proprietary Toolchains

| Vendor | Toolchain | Required For | Download |
|--------|----------|--------------|----------|
| **Xilinx** | Vivado/ISE | Artix-7, Kintex-7 (Nexys Video, KC705) | https://www.xilinx.com/support/download.html |
| **Intel** | Quartus Prime | Cyclone, Arria, Stratix | https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/ |
| **Lattice** | Diamond/Radiant | ECP5, iCE40 | https://www.latticesemi.com/lattice-diamond |

**Target Boards:**
- **Primary:** Digilent Nexys Video (Artix-7, requires Vivado)
- **Alternate:** Xilinx KC705 (Kintex-7, requires Vivado)

**Sector Mapping:**
- SECTOR-05 (FPGA_BOARD)
- SECTOR-08 (HW_VALIDATION)

---

## Optional Backend Libraries

### Graphics Backends (opt-in at build time)

```bash
# OpenGL backend
sudo apt-get install libgl-dev
make -C sim GL=1

# Vulkan backend
sudo apt-get install libvulkan-dev vulkan-tools
make -C sim VULKAN=1

# X11 backend
sudo apt-get install libx11-dev
make -C sim X11=1

# Wayland backend
sudo apt-get install libwayland-dev
make -C sim WAYLAND=1
```

**Runtime selection:**
```bash
HYDRA_BACKEND=GL ./sim_voxel
HYDRA_BACKEND=VULKAN ./sim_voxel
HYDRA_BACKEND=X11 ./sim_voxel
HYDRA_BACKEND=WAYLAND ./sim_voxel
HYDRA_BACKEND=HEADLESS ./sim_voxel  # No display server
```

**Sector Mapping:**
- SECTOR-13 (VIEWER_PLATFORM)
- SECTOR-14 (MULTIPLATFORM)

---

## CI/CD Package Requirements

### GitHub Actions / CI Runner

```yaml
# Minimal CI packages (from .github/workflows/*.yml)
packages:
  - verilator
  - libsdl2-dev
  - libsdl2-ttf-dev
  - build-essential
  - cmake
  - ninja-build
  - python3
  - python3-pip

optional:
  - iverilog  # RTL benches (best-effort)
  - gtkwave   # Waveform viewing
  - qemu-system-x86  # QEMU PCI stub testing
```

### Pre-commit Hook Requirements

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks (defined in .pre-commit-config.yaml)
pre-commit install

# Dependencies checked by hooks:
# - verilator (version check, manual stage)
# - python3 (for docs_lint.py, check_todo_unique.py)
# - codespell (via pre-commit repo)
```

**Sector Mapping:**
- SECTOR-10 (BUILD_CI)

---

## Dependency Verification Scripts

### Automated Dependency Checks

```bash
# Check for missing packages (best-effort)
./scripts/check_dependencies.sh  # TODO: create this script

# Verify Verilator version
./scripts/verilator_check.sh

# Verify backend availability
./scripts/check_backends.sh

# Verify kernel headers (Linux)
ls /lib/modules/$(uname -r)/build >/dev/null && echo "Kernel headers present"
```

### Manual Verification

```bash
# Check core tools
command -v verilator && verilator --version
command -v sdl2-config && sdl2-config --version
command -v cmake && cmake --version

# Check Python packages
python3 -c "import cocotb; print(cocotb.__version__)"
python3 -c "import pytest; print(pytest.__version__)"

# Check optional backends
pkg-config --exists gl && echo "OpenGL: available"
pkg-config --exists vulkan && echo "Vulkan: available"
pkg-config --exists wayland-client && echo "Wayland: available"
pkg-config --exists x11 && echo "X11: available"

# Check git submodules
git submodule status | grep -q '^-' && echo "WARNING: Some submodules not initialized" || echo "Submodules OK"
```

---

## Sector Mapping Reference

This section maps dependencies to the sector system defined in `docs/todo/todo_sector_map.json`.

| Sector ID | Sector Name | Key Dependencies |
|-----------|-------------|------------------|
| **SECTOR-01** | RTL Core & Ray Engine | verilator, iverilog (testing) |
| **SECTOR-02** | AXI/PCIe/DMA Infrastructure | linux-headers, verilator |
| **SECTOR-03** | Video Output & Display | LiteICLink (submodule) |
| **SECTOR-04** | IP Integration | LitePCIe, LiteDRAM, LiteX (submodules), git |
| **SECTOR-05** | FPGA Synthesis & Board | Vivado/Quartus/yosys, litex, python3 |
| **SECTOR-06** | Simulation & Testing | verilator, iverilog, cocotb, pytest |
| **SECTOR-07** | Drivers & Userspace SDK | linux-headers, build-essential, libdrm-dev (opt) |
| **SECTOR-08** | Hardware Validation | FPGA toolchain, test equipment |
| **SECTOR-09** | Security & Robustness | Standard build tools |
| **SECTOR-10** | Build System & CI/CD | cmake, ninja, pre-commit, python3 |
| **SECTOR-11** | Docs & Examples | python3, markdown tools |
| **SECTOR-12** | Rendering & Visual Quality | SDL2, SDL2_ttf, optional GL/Vulkan |
| **SECTOR-13** | Interactive Viewer | SDL2, SDL2_ttf, GL/Vulkan/X11/Wayland (opt) |
| **SECTOR-14** | Multi-Platform Support | Platform-specific toolchains |
| **SECTOR-15** | Performance & Optimization | Profiling tools (perf, valgrind) |

---

## Missing Dependency Handling

### Common Errors and Fixes

**Error: `verilator: command not found`**
```bash
# Debian/Ubuntu
sudo apt-get install verilator

# macOS
brew install verilator

# Windows/MSYS2
# Build from source: https://verilator.org/guide/latest/install.html
```

**Error: `fatal error: SDL2/SDL.h: No such file or directory`**
```bash
# Debian/Ubuntu
sudo apt-get install libsdl2-dev libsdl2-ttf-dev

# macOS
brew install sdl2 sdl2_ttf

# Windows/MSYS2
pacman -S mingw-w64-ucrt-x86_64-SDL2 mingw-w64-ucrt-x86_64-SDL2_ttf
```

**Error: `No rule to make target '/lib/modules/.../build'`**
```bash
# Install kernel headers matching your running kernel
sudo apt-get install linux-headers-$(uname -r)
```

**Error: `ModuleNotFoundError: No module named 'cocotb'`**
```bash
python3 -m pip install --user cocotb
```

**Error: `git submodule status` shows `-` prefix (not initialized)**
```bash
./scripts/fetch_ip.sh
```

---

## Future Improvements

### Planned Dependency Tracking Enhancements

- [ ] Create `scripts/check_dependencies.sh` - automated dependency verification
  *Tracker:* `docs/todo/todo_build_devtools.md` (P2)

- [ ] Add platform-specific dependency manifests (JSON/YAML)
  *Tracker:* `docs/todo/todo_multiplatform_builds.md` (P2)

- [ ] Create Docker/Podman images with pre-installed dependencies
  *Tracker:* `docs/todo/todo_build_ci.md` (P2)

- [ ] Add package version pinning/lock files
  *Tracker:* `docs/todo/todo_build_tooling.md` (P3)

- [ ] Create Nix flake for reproducible builds
  *Tracker:* `docs/todo/todo_build_tooling.md` (P3)

- [ ] Add dependency dashboard to CI artifacts
  *Tracker:* `docs/todo/todo_build_ci.md` (P3)

---

## Related Documentation

- **Build System:** `CLAUDE.md` (Quick Commands section)
- **Driver Integration:** `docs/driver_integration.md`
- **Testing Overview:** `docs/testing_overview.md`
- **IP Integration:** `docs/ip_integration.md`, `third_party/README.md`
- **Multi-Platform Builds:** `docs/macos_windows_build.md`, `docs/windows_sim.md`, `docs/freebsd_qemu.md`
- **Sector System:** `docs/todo/todo_sector_overview.md`, `docs/todo/todo_sector_map.json`
- **TODO Trackers:** `docs/TODO_MASTER_INDEX.md`

---

## Maintenance

**Document Owner:** Build & CI Team (SECTOR-10)
**Update Frequency:** On package additions/changes, before major releases
**Last Updated:** 2025-11-25
**Next Review:** 0.0.7 release (Q1 2026)

**Automated Checks:**
- `scripts/automation_watchdog.sh` - verifies submodule status
- `.pre-commit-config.yaml` - enforces verilator version (manual stage)
- CI workflows - check dependency availability on matrix platforms

**Change Process:**
1. Update this document when adding/removing dependencies
2. Update relevant sector tracker (e.g., `todo_build_tooling.md`)
3. Update platform-specific docs (`windows_sim.md`, `macos_windows_build.md`, etc.)
4. Test on affected platforms
5. Update CI workflows if needed
