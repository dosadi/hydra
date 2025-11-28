# Testing & Debugging Overview

**Last Updated:** 2025-11-26
**Owner:** Testing Team
**Depends:** `hydra_spec.md`, `driver_integration.md`, `ip_integration.md`
**Related Trackers:** `todo/todo_testing_ci.md`, `todo/todo_dma_pcie.md`, `todo/todo_hardware_validation.md`
**Touches:** `hardware_test_plan.md`, `todo/todo_testing_ci.md`

---

This repo has several layers of tests and debug tools, from pure RTL up to driver/PCIe stubs.
This document summarizes the main entry points.

## Quick first run (new contributors)

1. Install deps: `verilator`, `libsdl2-dev`, `libsdl2-ttf-dev`, `g++`, `make`.
2. From repo root: `make -C sim test_frame` (builds and runs the frame regression).
3. Launch the viewer: `cd sim && ./sim_voxel` (mouse-look + WASD; see keybinds in README).
4. Optional: `LOG_FRAMES=1 ./sim_voxel` (per-frame stats) or `LOG_KEYS=1 ./sim_voxel` (input debug).
5. Need a keybind refresher? See `docs/sim_controls.md`.

## 1. Sim-only tests (no drivers required)

### Build and run the SDL viewer

```bash
cd sim
make           # builds sim_voxel (Verilator + SDL2)
./sim_voxel    # launches the window (480x360 logical)
```

Useful env vars:

- `LOG_FRAMES=1 ./sim_voxel` – per-frame stats (pixels written, nonzero pixels, hit count).
- `LOG_KEYS=1 ./sim_voxel` – key down/up events for input debugging.
- `FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel` – dump a single frame as PPM and exit.
- `HYDRA_BACKEND=<SDL|GL|X11|WAYLAND|VULKAN>` – request a specific backend (falls back to SDL if unavailable).

### Frame regression test

```bash
make -C sim test_frame
```

This will:
- Build the sim (if needed).
- Run a non-interactive frame dump into `sim/build/frame_test.ppm`.
- Compare against `sim/tests/golden_frame.ppm` using `scripts/check_frame.py`.
- Print per-channel statistics and fail if the image diverges beyond thresholds.

## 2. RTL benches (AXI shell, DMA, HDMI)

Location: `sim/tests/rtl/` with a helper script:

```bash
chmod +x sim/tests/run_rtl_tests.sh
sim/tests/run_rtl_tests.sh
```

Requires: `iverilog` and `vvp` on PATH.

Benches:
- `test_dma_loopback.sv` – Issues a DMA copy inside the SDRAM stub, checks source/dest and INT_STATUS/STATUS bits.
- `test_hdmi_crc_golden.sv` – HDMI CRC using the full voxel pipeline at 16x12 (TEST_FORCE_WORLD_READY=1, AUTO_START_FRAMES=1), golden CRC `0x00010600` (single-frame run; checks beat count bounds and CSR mirrors).
- `test_hdmi_crc_full.sv` – HDMI CRC at 32x24, golden CRC `0x00020500` (single-frame run; CSR + beat checks).
- `test_bar1_dma_loopback.sv` – BAR1 + DMA copy using the SDRAM stub directly (fast seeding + forced DMA start for simulation speed).
- `test_dma_stub_direct.sv` – Direct DMA-to-SDRAM validation bench (tests DMA and SDRAM stubs).

Notes:
- The SDRAM stub (`axi_sdram_stub.sv`) supports optional `READ_LATENCY`/`WRITE_LATENCY` parameters if you want to inject wait states for stress; defaults are zero for fast benches.

All tests use `voxel_sim_harness.sv` which provides a complete simulation environment with AXI stubs.

In CI, these are run best-effort via `scripts/rtl_ci_wrapper.sh` and logged to `artifacts/rtl_tests.log` when tools are present.

### Cocotb Smoke Tests

Cocotb provides cycle-accurate Python testbenches for RTL verification. The Hydra cocotb suite tests interrupt handling, DMA operations, and blitter functionality.

**Running Cocotb Tests:**
```bash
cd sim/tests/cocotb_hydra
make SIM=icarus   # Requires cocotb + iverilog
```

**Test Suite:**
- `smoke_irq_and_crc` - Basic interrupts and HDMI CRC validation
- `bar1_dma_loopback` - BAR1 memory access + DMA data movement
- `blitter_basic_copy` - Blitter engine pixel operations
- `region0_auto_extractor_stub` - Region extraction functionality

**CI Integration:** Runs as best-effort `cocotb` job in GitHub Actions using Icarus Verilog.

**Expected Results:** All tests pass with proper interrupt generation and data integrity. Failures indicate RTL logic bugs or AXI protocol issues.

### Headless / batch frame dumps

- Single frame: `FRAME_DUMP=frame.ppm AUTO_EXIT=1 ./sim_voxel` (480x360 PPM ≈ 520 KiB).
- Multiple frames: `HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=10 FRAME_DUMP=ignored AUTO_EXIT=1 HYDRA_BACKEND=HEADLESS ./sim_voxel`
- Headless backend: set `HYDRA_BACKEND=HEADLESS` to force SDL's dummy driver (no display server needed). Pairs well with `AUTO_EXIT=1` for CI.
- Numbered dumps: set `HYDRA_FRAME_BASE=frame` and `HYDRA_MAX_FRAME_DUMPS=N` to emit `frame_0.ppm...frame_(N-1).ppm`.
- Other useful envs: `HYDRA_CLEAR_COLOR=r,g,b` to init the framebuffer; `HYDRA_CAM_POS=x,y,z` / `HYDRA_CAM_ANG=yaw,pitch` for initial pose; `HYDRA_MOVE_SPEED`, `HYDRA_MOVE_SPEED_FAST`, `HYDRA_TURN_SPEED_KEYS`, `HYDRA_MOUSE_SENS`, `HYDRA_INVERT_Y`, `HYDRA_MOUSE_CAPTURE` for movement feel; `HYDRA_FONT` / `HYDRA_FONT_SCALE` for HUD font; `HYDRA_VSYNC` to toggle vsync; `HYDRA_FPS_TARGET` to pace frames (if implemented in your build).

## 3. SDK + Linux driver loop

### Build SDK tools

From the repo root:

```bash
./scripts/setup_sdk.sh
```

This builds:
- `drivers/libhydra/libhydra.a` – userspace helper library for IOCTLs.
- `scripts/hydra_blit_smoketest` – raw BAR0/INT/blitter FIFO smoketest.
- `scripts/hydra_dma_blit_demo` – libhydra-based DMA + blitter demo.
- `scripts/hydra_irq_test` – triggers IRQ_TEST, dumps INT_STATUS/INT_MASK.

### Linux driver bring-up (requires Linux kernel headers and a hydra_pcie device)

High-level steps (see `docs/driver_integration.md` for details):

1. Build and load the Linux PCIe/DRM stubs in `drivers/linux/`.
2. Ensure `/dev/hydra_pcie` is present.
3. Run:
   ```bash
   sudo ./scripts/hydra_blit_smoketest /dev/hydra_pcie
   sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie
   ```

These exercise BAR0 CSRs, INT_MASK/INT_STATUS, DMA stubs, and the 3D blitter stub.

## 4. QEMU PCIe stub (optional)

Location: `sim/tests/qemu_stub/`.

- `hydra_pci.c` – reference QEMU device model implementing a `hydra-pci` device with BAR0 compatible with `hydra_regs.h`.
- `qemu_hydra_smoke.sh` – host-side harness that:
  - Checks for QEMU + a guest image (`HYDRA_QEMU_GUEST_IMG`).
  - Boots a Linux guest with `-device hydra-pci`.
  - Captures the guest console to `artifacts/qemu_console.log`.

The guest image is expected to auto-load the Hydra drivers and run the SDK smoketests, then power off.
In CI, the `qemu-smoke` job will run this script when a guest image URL/env is configured.

## 5. One-command loop

For day-to-day development, use:

```bash
./scripts/hydra_dev_loop.sh
```

This script:
- Builds the sim and runs the frame regression.
- Builds SDK tools.
- Optionally runs RTL benches.
- Optionally runs the QEMU PCI stub smoke (if configured).

Artifacts from CI runs (frame images, frame diff, SDK build log, RTL logs, QEMU console) are collected under `artifacts/` and uploaded when CI fails, to help debug regressions.

## How to Reproduce a Frame

For bug reports, testing, or sharing specific scenes, you need to capture both the visual frame and the exact state that produced it. This guide shows how to create reproducible frame captures.

### Basic Frame Capture

Capture a single frame as PPM image:

```bash
# Capture current frame and exit
FRAME_DUMP=bug_frame.ppm AUTO_EXIT=1 ./sim_voxel
```

### Deterministic Frame Reproduction

To reproduce the exact same frame, you need to control all sources of non-determinism:

1. **Camera Position & Orientation**
   ```bash
   HYDRA_CAM_POS=32.0,32.0,48.0 \
   HYDRA_CAM_ANG=0.785,0.2 \
   FRAME_DUMP=repro_frame.ppm \
   AUTO_EXIT=1 \
   ./sim_voxel
   ```

2. **Render Flags State**
   - Use the HUD (press H) to see current flag values
   - Or run with `LOG_FRAMES=1` to see flag state in logs
   - Flags are controlled via CSRs and can be set with IOCTLs

3. **World Seed (if applicable)**
   - If the voxel world uses procedural generation, ensure the seed is fixed
   - Check for `HYDRA_WORLD_SEED` or similar environment variables

4. **Timing & Pacing**
   ```bash
   # Ensure deterministic timing
   HYDRA_FPS_TARGET=60 \
   HYDRA_VSYNC=0 \
   HYDRA_CAM_POS=32.0,32.0,48.0 \
   FRAME_DUMP=deterministic.ppm \
   AUTO_EXIT=1 \
   ./sim_voxel
   ```

### Complete Reproduction Command

For a fully reproducible bug report, include all state:

```bash
# Capture state for reproduction
LOG_FRAMES=1 \
HYDRA_CAM_POS=32.0,32.0,48.0 \
HYDRA_CAM_ANG=0.785,0.2 \
HYDRA_FPS_TARGET=60 \
HYDRA_VSYNC=0 \
FRAME_DUMP=bug_reproduction.ppm \
AUTO_EXIT=1 \
./sim_voxel 2>&1 | tee frame_log.txt
```

The `frame_log.txt` will contain:
- Frame statistics including render flags
- Camera position/angle confirmation
- Performance metrics
- Any error messages

### Multi-Frame Sequences

For animations or multi-frame bugs:

```bash
# Capture 10 frames with deterministic camera path
HYDRA_FRAME_BASE=sequence \
HYDRA_MAX_FRAME_DUMPS=10 \
HYDRA_CAM_POS=32.0,32.0,48.0 \
HYDRA_FPS_TARGET=30 \
AUTO_EXIT=1 \
./sim_voxel
```

This creates `sequence_0.ppm`, `sequence_1.ppm`, etc.

### Headless Reproduction

For CI or remote reproduction:

```bash
# Fully headless, no display server needed
HYDRA_BACKEND=headless \
HYDRA_CAM_POS=32.0,32.0,48.0 \
HYDRA_CAM_ANG=0.785,0.2 \
FRAME_DUMP=headless_repro.ppm \
AUTO_EXIT=1 \
./sim_voxel
```

### Verifying Reproduction

To verify your reproduction command works:

1. Run the command twice
2. Compare the PPM files: `diff frame1.ppm frame2.ppm`
3. If identical, the reproduction is deterministic
4. If different, identify the source of non-determinism (timing, uninitialized state, etc.)

### Common Issues

- **Frame varies between runs**: Check for uninitialized camera state or timing dependencies
- **Colors look wrong**: Ensure `HYDRA_CLEAR_EACH_FRAME` and `HYDRA_CLEAR_COLOR` are set consistently
- **Performance differs**: Use `HYDRA_FPS_TARGET` to normalize timing
- **Headless fails**: Verify `HYDRA_BACKEND=headless` works on your system

### Including in Bug Reports

When filing bugs, provide:

1. The exact command used
2. The captured PPM file
3. `LOG_FRAMES=1` output showing render state
4. Your environment: OS, GPU, SDL version (`make env-probe`)
5. Expected vs actual behavior

## Troubleshooting sim build/runs (quick checks)

### Build Dependencies

**Missing SDL2 development libraries:**
```bash
# Ubuntu/Debian
sudo apt install libsdl2-dev libsdl2-ttf-dev

# Fedora/CentOS
sudo dnf install SDL2-devel SDL2_ttf-devel

# macOS (with Homebrew)
brew install sdl2 sdl2_ttf

# Check installation
sdl2-config --version
```

**Verilator version issues:**
- Target version: Verilator 5.x
- Check version: `verilator --version`
- If wrong version, run `make purge-obj-dir` to clear stale generated files
- CI uses specific versions; check `scripts/rtl_ci_wrapper.sh` for version requirements

**Missing build tools:**
```bash
# Ubuntu/Debian
sudo apt install build-essential g++ make

# Check tools are available
which g++ && which make && g++ --version
```

### Runtime Issues

**SDL initialization failures:**
- Try different backends: `HYDRA_BACKEND=headless ./sim_voxel`
- Force SDL driver: `SDL_VIDEODRIVER=x11 ./sim_voxel` (X11) or `SDL_VIDEODRIVER=wayland ./sim_voxel`
- Check display server: `echo $DISPLAY` (X11) or `echo $WAYLAND_DISPLAY`

**Font rendering issues:**
- HUD text missing? Install `libsdl2-ttf-dev`
- Custom font: `HYDRA_FONT=/path/to/font.ttf ./sim_voxel`
- Font scaling: `HYDRA_FONT_SCALE=2.0 ./sim_voxel` for high-DPI displays

**Input handling problems:**
- Mouse capture stuck: Press `M` to toggle
- Disable capture: `HYDRA_MOUSE_CAPTURE=0 ./sim_voxel`
- Keyboard issues: `LOG_KEYS=1 ./sim_voxel` to debug input events

### Performance & Rendering

**Slow frame rates:**
- Enable vsync: `HYDRA_VSYNC=1 ./sim_voxel`
- Cap FPS: `HYDRA_FPS_TARGET=60 ./sim_voxel`
- Check backend: `HYDRA_BACKEND=gl ./sim_voxel` (GPU acceleration)

**Rendering artifacts:**
- Clear each frame: `HYDRA_CLEAR_EACH_FRAME=1 ./sim_voxel`
- Set background: `HYDRA_CLEAR_COLOR=0,0,0 ./sim_voxel`
- Force software rendering: `LIBGL_ALWAYS_SOFTWARE=1 ./sim_voxel`

### Headless/CI Issues

**No display server:**
```bash
HYDRA_BACKEND=headless \
FRAME_DUMP=test.ppm \
AUTO_EXIT=1 \
./sim_voxel
```

**Frame dump problems:**
- Large files: 480x360 PPM ≈ 520KB; use compression for storage
- Multiple frames: `HYDRA_FRAME_BASE=frame HYDRA_MAX_FRAME_DUMPS=10`
- Deterministic output: Set `HYDRA_FPS_TARGET=60` and camera position

### Verilator-Specific Issues

**Stale build artifacts:**
```bash
# Clear generated Verilog
make purge-obj-dir
# Or manually
rm -rf sim/obj_dir/
```

**Version compatibility:**
- Verilator 4.x may work but 5.x recommended
- Check `make env-probe` output for detected versions
- CI failures often indicate version mismatches

### Platform-Specific Issues

**Wayland permissions:**
```bash
# Check Wayland socket
ls $XDG_RUNTIME_DIR/wayland-*
# Or force X11
SDL_VIDEODRIVER=x11 ./sim_voxel
```

**macOS GPU issues:**
```bash
# Force OpenGL
HYDRA_BACKEND=gl ./sim_voxel
# Or software fallback
LIBGL_ALWAYS_SOFTWARE=1 ./sim_voxel
```

**Windows MSYS2:**
- Ensure SDL2 packages are installed: `pacman -S mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_ttf`
- Use `SDL_VIDEODRIVER=windows` if issues occur

### Debugging Commands

**Environment probe:**
```bash
make env-probe
```

**Verbose logging:**
```bash
HYDRA_VERBOSE=1 ./sim_voxel
LOG_FRAMES=1 ./sim_voxel
LOG_KEYS=1 ./sim_voxel
```

**Backend debugging:**
```bash
# List available backends
./sim_voxel --caps
# Test specific backend
HYDRA_BACKEND=gl ./sim_voxel
```

### Common Error Messages

**"SDL initialization failed":**
- No display server in headless environment
- Solution: `HYDRA_BACKEND=headless`

**"Font loading failed":**
- Missing SDL_ttf or font file not found
- Solution: Install `libsdl2-ttf-dev` or set `HYDRA_FONT`

**"Verilator version too old":**
- Verilator < 5.0 detected
- Solution: Upgrade Verilator or use CI-recommended version

**"Backend not available":**
- Requested backend not supported on platform
- Solution: Check `./sim_voxel --caps` for available backends

## Negative/Edge Case Testing

Negative tests verify that the system properly handles invalid inputs, error conditions, and edge cases. These tests ensure robustness and help catch regressions in error handling.

### IOCTL Error Handling

**Invalid DMA parameters:**
```bash
# Test DMA with invalid source address (should fail gracefully)
sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie --src-addr 0xFFFFFFFFFFFFFFFF
# Expected: EINVAL error, no crash

# Test DMA with zero length (edge case)
sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie --length 0
# Expected: EINVAL or graceful handling

# Test DMA with misaligned addresses
sudo ./scripts/hydra_dma_blit_demo /dev/hydra_pcie --src-addr 1 --dst-addr 1
# Expected: EINVAL for alignment violations
```

**CSR bounds checking:**
```bash
# Test reading invalid CSR address
sudo ./scripts/hydra_drm_info /dev/hydra_pcie --read-csr 0xFFFF
# Expected: EINVAL error

# Test writing read-only CSR
sudo ./scripts/hydra_drm_info /dev/hydra_pcie --write-csr 0x00 0xDEADBEEF
# Expected: EPERM or EINVAL if register is read-only
```

**Interrupt testing:**
```bash
# Test interrupt masking/unmasking
sudo ./scripts/hydra_irq_test /dev/hydra_pcie
# Should show interrupts properly masked/unmasked
# Expected: irq_count increments only when unmasked
```

### Memory Access Edge Cases

**BAR access bounds:**
```bash
# Test reading beyond BAR0 size
sudo dd if=/dev/hydra_pcie of=/dev/null bs=1 count=1 skip=$((0x100000))
# Expected: EOF or error, no crash

# Test writing to invalid BAR regions
sudo dd if=/dev/zero of=/dev/hydra_pcie bs=1 count=1 seek=$((0x100000))
# Expected: Error, no system crash
```

**MMAP edge cases:**
```bash
# Test mapping invalid offsets
# (This would require custom test code)
# Expected: EINVAL for invalid offsets
```

### Viewer/Simulator Crashes

**Invalid environment variables:**
```bash
# Test with malformed camera position
HYDRA_CAM_POS=invalid,values ./sim_voxel
# Expected: Graceful fallback to defaults, warning message

# Test with out-of-bounds camera coordinates
HYDRA_CAM_POS=999999,999999,999999 ./sim_voxel
# Expected: Clamping or graceful handling

# Test with invalid backend
HYDRA_BACKEND=nonexistent ./sim_voxel
# Expected: Fallback to available backend with warning
```

**Resource exhaustion:**
```bash
# Test with very large frame dumps
HYDRA_MAX_FRAME_DUMPS=10000 FRAME_DUMP=test.ppm ./sim_voxel
# Expected: Reasonable limits or graceful failure

# Test rapid key presses (if input logging enabled)
LOG_KEYS=1 ./sim_voxel
# Spam keys rapidly
# Expected: No buffer overflows, reasonable rate limiting
```

### SDL/Graphics Edge Cases

**Display server disconnection:**
```bash
# Start viewer, then kill display server
HYDRA_BACKEND=sdl ./sim_voxel &
killall Xorg  # or appropriate display server
# Expected: Graceful exit or error handling
```

**Invalid window operations:**
```bash
# Test with invalid window dimensions (if configurable)
# Expected: Fallback to safe defaults
```

### Verilator/RTL Edge Cases

**Invalid CSR writes:**
```bash
# Test writing invalid values to CSRs (via driver)
# Expected: RTL handles gracefully, no undefined behavior
```

**Timing violations:**
```bash
# Test rapid CSR accesses
# Expected: No race conditions or corruption
```

### Network/File System Issues

**Missing font files:**
```bash
HYDRA_FONT=/nonexistent/font.ttf ./sim_voxel
# Expected: Fallback to default font with warning
```

**Read-only output directories:**
```bash
mkdir -p /tmp/readonly_test
chmod 444 /tmp/readonly_test
FRAME_DUMP=/tmp/readonly_test/frame.ppm ./sim_voxel
# Expected: Clear error message, graceful failure
```

### Platform-Specific Edge Cases

**FreeBSD vs Linux differences:**
```bash
# Test same operations on both platforms
# Expected: Consistent error codes and behavior where possible
```

**Cross-platform file paths:**
```bash
# Test with Windows-style paths on Unix
FRAME_DUMP=C:\invalid\path.ppm ./sim_voxel
# Expected: Appropriate error handling
```

### Stress Testing

**Rapid start/stop cycles:**
```bash
for i in {1..100}; do
    timeout 1 ./sim_voxel --backend=headless --auto-exit
done
# Expected: No resource leaks, clean exits
```

**Memory pressure:**
```bash
# Run under memory limits
ulimit -v 100000  # 100MB limit
./sim_voxel
# Expected: Graceful failure if memory exhausted
```

### Security Testing

**Input validation:**
```bash
# Test with extremely large environment variables
HYDRA_CAM_POS=$(python3 -c 'print("1," * 10000)') ./sim_voxel
# Expected: Reasonable limits, no buffer overflows
```

**Path traversal attempts:**
```bash
FRAME_DUMP=../../../etc/passwd ./sim_voxel
# Expected: Sanitized paths or appropriate restrictions
```

### Automated Negative Test Script

Create a script to run common negative tests:

```bash
#!/bin/bash
# negative_tests.sh

echo "Running negative test suite..."

# Test invalid DMA parameters
echo "Testing invalid DMA..."
./scripts/hydra_dma_blit_demo /dev/hydra_pcie --src-addr 0xFFFFFFFFFFFFFFFF 2>&1 || echo "Expected failure"

# Test invalid CSR access
echo "Testing invalid CSR..."
./scripts/hydra_drm_info /dev/hydra_pcie --read-csr 0xFFFF 2>&1 || echo "Expected failure"

# Test viewer with invalid inputs
echo "Testing viewer edge cases..."
HYDRA_CAM_POS=invalid ./sim_voxel --backend=headless --auto-exit 2>&1 || echo "Expected failure"

echo "Negative test suite complete."
```

### Interpreting Negative Test Results

**Expected behaviors:**
- **EINVAL (-22)**: Invalid argument/parameters
- **EPERM (-1)**: Operation not permitted (read-only registers)
- **EFAULT (-14)**: Bad address/memory access
- **ENOTTY (-25)**: Inappropriate ioctl for device
- **EIO (-5)**: I/O error (hardware issues)

**Unexpected behaviors (bugs):**
- Segmentation faults or crashes
- System hangs or unkillable processes
- Resource leaks (memory, file descriptors)
- Inconsistent error codes between platforms
- Silent failures (no error reporting)

**Documentation:**
- Log all test results with error codes
- Note platform differences (Linux vs FreeBSD)
- Track regressions in error handling

## FAQ (common setup/running fixes)
- **HUD missing text?** Ensure `libsdl2-ttf-dev` installed and `HYDRA_FONT` points to a real TTF; check stderr for font load warnings.
- **Viewer hangs on start?** Try `SDL_VIDEODRIVER=dummy` or `HYDRA_BACKEND=HEADLESS` to rule out windowing issues; verify `SDL2` and GPU drivers.
- **Verilator build errors after upgrade?** Run `make purge-obj-dir` then rebuild to clear stale generated files.
- **Mouse not captured?** Press `M`; HUD shows mouse capture status. In logs, `HYDRA_MOUSE_CAPTURE=0` disables capture for headless.
- **ABI mismatch tool errors?** Update both kernel driver and userspace headers; `scripts/hydra_drm_info` now checks `HYDRA_IOCTL_VERSION` when supported and will fail on size/version mismatch.
