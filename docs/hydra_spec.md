# Hydra Device Sketch (Draft)

**Last Updated:** 2025-11-26
**Owner:** RTL/Driver Team
**Touches:** `driver_integration.md`, `hardware_test_plan.md`, `ip_integration.md`, `testing_overview.md`, `todo/todo_dma_pcie.md`, `todo/todo_testing_ci.md`

---

This is a working outline for the Hydra PCIe device: blocks, formats, and a straw‑man BAR0 register map to guide driver/hardware bring‑up.

**Release Version:** 0.0.7 (latest)

## Functional blocks (initial)
- PCIe endpoint (BAR0 CSR space, optional BAR1 aperture for frame/voxel data).
- Voxel core: 64×64×64 volume, fixed‑point raycaster with diagnostic slice mode.
- Surface extraction (stubbed in RTL today), 3D blitter (bring-up stub present, not a full 3D pipeline).
- Framebuffer: RGBA32 plus “reemissure32” sidecar (per‑pixel emission/extra field; unused in current shell).
- HDMI/DVI output pipeline (LiteICLink/LiteVideo planned), AXI-Stream sink stub in sim.
- DMA engine (host↔SDRAM/BRAM) for voxel/frame uploads (LitePCIe/LiteDMA planned; AXI stubs exist in RTL).

## Device IDs (current for 0.0.7)
- Vendor ID: `0x1BAD`
- Device ID: `0x2024`
(Update when assigned; keep in sync with Linux driver and UAPI headers.)

## BARs (proposed)
- BAR0: CSR space (64 KiB window) – control, status, DMA, camera, selection, interrupts.
- BAR1 (optional): Framebuffer/voxel aperture into SDRAM for bulk moves (map via DMA or host).

## BAR0 register sketch (byte offsets, little-endian)
- `0x0000` `ID`          (RO): [31:16] vendor, [15:0] device.
- `0x0004` `REV`         (RO): [7:0] rev, [15:8] build, [31:16] reserved.  
  Current: rev `0x07`, build `0x01` for release 0.0.7; bump on any register map change.
- `0x0010` `CTRL`        (RW): [0]=soft_reset, [1]=start_frame, [2]=diag_slice_en, [3]=extra_light_en.
- `0x0014` `STATUS`      (RO): [0]=busy, [1]=frame_done, [2]=dma_busy, [3]=dma_done, [4]=blit_busy, [5]=blit_done, [31:6]=resvd.
- `0x0020..0x003C` Camera (RW): cam_x/y/z, cam_dir_x/y/z, cam_plane_x/y (signed 16-bit each, packed 32-bit).
- `0x0040` `FLAGS`       (RW): [0]=smooth, [1]=curvature, [2]=extra_light, [3]=diag_slice.
- `0x0044..0x0050` Selection (RW): sel_active, sel_x, sel_y, sel_z (6-bit fields in 32-bit words).
- `0x0054` `FB_BASE`     (RW): framebuffer base address (BAR1/SDRAM).
- `0x0058` `FB_STRIDE`   (RW): bytes per line.
- `0x0060..0x0070` DMA regs (RW): SRC, DST, LEN (bytes), CMD [0]=start, STATUS [0]=done, [1]=busy, [2]=err.
- `0x0080` `INT_STATUS`  (RW1C): [0]=frame_done, [1]=dma_done, [2]=dma_err, [3]=irq_test, [4]=blit_done.
- `0x0084` `INT_MASK`    (RW): same bits as STATUS.
- `0x0088` `IRQ_TEST`    (WO): [0]=pulse INT_STATUS[3] (sim MSI test).
- `0x00A0..0x00A8` Debug voxel write: ADDR (18-bit), DATA_LO (32), DATA_HI (32), CTRL [0]=write_pulse.
- `0x00B0` `HDMI_CRC`    (RO, sim): last frame CRC from AXI sink.
- `0x00B4` `HDMI_FRAMES` (RO, sim): frame counter from AXI sink.
- `0x00B8` `HDMI_LINE`   (RO, sim): last line count observed.
- `0x00BC` `HDMI_PIX`    (RO, sim): last pixel-in-line counter.
- `0x0100..` 3D blitter stub: CTRL/STATUS/SRC/DST/LEN/STRIDE, SURF_BASE/SURF_LEN/SURF_STATS for the surface extractor stub, pixel read/write, object attribute table, FIFO data port.
- `0x0150..` Region-0 automatic extractor (experimental): REGION0_CFG/MIN/MAX/STATUS/SURF_STATS implement a fixed-function per-volume extraction pass that currently only synthesizes stats.
- Reserved: 0x0170..0xFFFF for future (perf counters, extended extractor controls).

### Reset defaults (expected values after power-on or soft reset)
**Release 0.0.7 CSR Defaults:**
- `CTRL` = 0x0000_0000 (soft_reset/start_frame deasserted; flags cleared)
- `FLAGS` = smooth=1, curvature=1, extra_light=0, diag_slice=0, ray_jitter=0
- `SEL_ACTIVE` = 0, `SEL_X/Y/Z` = 0
- `FB_BASE` = 0x0000_0000, `FB_STRIDE` = 0x0000_0000
- `DMA_STATUS` = 0 (busy/done cleared); `INT_STATUS` = 0; `INT_MASK` = 0
- Blitter stub registers: CTRL/STATUS/SRC/DST/LEN/STRIDE/SURF_* = 0
- Debug write addr/data = 0

Driver probe validation (recommended for 0.0.7):
- Read `ID`/`REV` and compare against driver expectations; fail if unknown.
- Read `FLAGS`, `CTRL`, `INT_STATUS`, `INT_MASK`, `FB_BASE/STRIDE`, `SEL_*`, and `DMA_STATUS` to confirm reset defaults match the above table; if any differ, log and fail probe to catch RTL drift.
- For BAR1-capable systems, confirm `HYDRA_IOCTL_INFO` reports non-zero BAR1 length before mapping.

## Frame formats (current / planned)
- RGBA32: 8 bits per channel, premultiplied alpha optional (current sim output path).
- Reemissure32 (sidecar): reserved for future emission/extra data; current RTL leaves this field zeroed in the shell.

### Diagnostic slice mode (render_config[1])

Setting `render_config[1]` (the same bit exposed as `FLAGS.diag_slice` via AXI/CTRL) enables an orthographic “diagnostic slice” render path that samples a fixed set of X slices at every pixel instead of marching a single ray to completion.
- `NUM_SLICES` (currently 7) determines how many equidistant planes are sampled; each pass chooses `cur_x = SLICE_X_START - slice_idx * SLICE_STEP` (currently 56 down by 8) while keeping Y/Z mapped from the screen coordinates.
- Each sampled voxel update latches occupancy/emissive data; the rasterizer remembers the most-emissive hit across slices and only commits one pixel once all slices are probed.
- If no slice reports a hit, the HUD emits the sky gradient color (no solid geometry).

This mode is primarily used to inspect the volume along the X axis and verify slice coverage; driver tests can toggle the diag slice flag to make sure the per-slice sampling pattern is observable in logged pixels.

### Ray jitter (render_config[2])

Setting `render_config[2]` / `FLAGS[4]` enables a tiny deterministic sub-voxel jitter on the Y/Z ray positions (derived from the screen coordinate). It smooths banding/artifacts by offsetting the ray start slightly for each pixel; toggle it via the `J` key or `HYDRA_RAY_JITTER=1` in the sim or driver.

## AXI-Stream Backpressure Protocol (IP Integration)

Hydra's AXI-Stream video output (for HDMI/DRAM/PCIe integration) follows standard AXI-Stream handshake and backpressure signaling:

- **tvalid**: Indicates valid data on the bus.
- **tready**: Indicates receiver is ready to accept data.
- **tuser**: Start-of-frame marker (asserted on first pixel of each frame).
- **tlast**: End-of-line or end-of-frame marker (asserted on last pixel of each line or frame).

### Backpressure Handling
- The RTL must only assert `tvalid` when `tready` is high.
- If `tready` deasserts, the pixel pipeline stalls and holds the current value until `tready` returns high.
- Frame and line counters must not advance unless a pixel is successfully transferred (`tvalid && tready`).
- HDMI/DRAM/PCIe sinks must assert `tready` according to their buffer state; if full, deassert to apply backpressure.
- The AXI-Stream stub in simulation always asserts `tready` (no backpressure), but hardware IP may apply backpressure dynamically.

### Protocol Compliance
- All AXI-Stream signals are synchronous to the pixel clock.
- The RTL should include SVAs (SystemVerilog Assertions) to check:
  - `tvalid` only advances when `tready` is high.
  - `tuser` and `tlast` are asserted at correct frame/line boundaries.
  - No dropped or repeated pixels under backpressure.
- For integration, see `docs/ip_integration.md` and `docs/hardware_test_plan.md` for test scenarios and compliance checks.

**Note:** Proper backpressure handling is critical for reliable HDMI/DRAM/PCIe output and must be validated in both simulation and hardware.

## Interrupts (proposed)
- Bits: [0]=frame_done, [1]=dma_done, [2]=dma_err (stub: not driven, reads 0), [3]=irq_test pulse, [4]=blit_done.
- `INT_STATUS` is RW1C; `irq_out` is level-sensitive on `INT_STATUS & INT_MASK`. `STATUS.frame_done` latches until read or the next CTRL start/reset. `blit_done` asserts `INT_STATUS[4]` in the stub; `IRQ_TEST` pulses `INT_STATUS[3]`.
- Masking: writing `INT_MASK` gates `irq_out`/`msi_pulse` but leaves `INT_STATUS` unchanged; userspace should clear `INT_STATUS` bits after handling.
- Clear: write `INT_STATUS` with the bit(s) set to 1 to clear (RW1C). Reads return current latched bits regardless of mask.

## 3D blitter stub (bring-up shell)
- Registers at 0x0100: `BLIT_CTRL` [0]=start, [1]=dir(readback flag), [2]=use_fifo; `BLIT_STATUS` [0]=busy, [1]=done, [2]=fifo_empty, [3]=fifo_full.
- Address/dimension: `BLIT_SRC`, `BLIT_DST`, `BLIT_LEN` (bytes), `BLIT_STRIDE` (bytes/line). Stub counts down len/4 beats.
- Pixel access: `BLIT_PIX_ADDR` (index), `BLIT_PIX_DATA` (RGBA32), `BLIT_PIX_CMD` [0]=write, [1]=read; stores to an internal RAM.
- Object/attribute table: `BLIT_OBJ_IDX`, `BLIT_OBJ_ATTR` to set/get a small attribute array.
- FIFO hook: `BLIT_FIFO_DATA` pushes/pops a small FIFO; `BLIT_FIFO_STATUS` exposes depth/full/empty. `BLIT_CTRL.use_fifo` doesn’t change behavior yet but is plumbed.
- Completion: stub deasserts busy after the countdown, sets done, and raises `INT_STATUS[4]=BLIT_DONE` and `STATUS.blitter_done`.

## Linux driver alignment
- BAR0 mapped, DMA masks set, MSI/MSI-X requested, misc device `/dev/hydra_pcie` with IOCTLs:
  - `HYDRA_IOCTL_INFO`: vendor/device, BAR0 info, IRQ number/count.
  - `HYDRA_IOCTL_RD32`/`WR32`: aligned BAR0 accesses for early bring‑up.
- Debugfs: `hydra_pcie/status` dumps BAR0/IRQ info.

## Open items
- Update vendor/device IDs if silicon IDs are reassigned (keep RTL/UAPI/spec in sync).
- Extend reemissure32 definition and surface extractor control space post-0.0.4.
- Add full MSI/INT wiring in the real PCIe endpoint when integrated.

## Implementation status (0.0.4+)
- Voxel core, camera, flags, selection, and debug voxel write path are implemented in RTL and exercised in the Verilator+SDL sim.
- BAR0 register map is reflected in the Linux UAPI headers (`drivers/linux/uapi/hydra_regs.h`) and the AXI-Lite CSR shell; BAR1/SDRAM aperture is modeled by simple AXI memory stubs in sim.
- PCIe/DRAM/HDMI integration is captured in `docs/ip_integration.md` and `docs/hardware_test_plan.md`; FPGA shells use LiteX IP, while the sim uses AXI/AXI-Stream stubs.
- The 3D blitter is a functional bring-up stub wired to BAR0 but not yet connected to a full 3D pipeline or DMA command stream.

## Simulation and regression hooks
- The Verilator+SDL sim exposes the core via `sim_voxel`; environment variables `FRAME_DUMP` and `AUTO_EXIT` drive a deterministic single-frame dump for regression.
- `make -C sim test_frame` builds the sim, dumps a frame through a dummy backend, and compares against `sim/tests/golden_frame.ppm` using `scripts/check_frame.py`.
- Diagnostic slice and extra-light flags (`CTRL.diag_slice_en`, `CTRL.extra_light_en` / `FLAGS.diag_slice`, `FLAGS.extra_light`) are exercised in the sim HUD and must remain stable across hardware revisions.
