# Hydra Device Sketch (Draft)

This is a working outline for the Hydra PCIe device: blocks, formats, and a straw‑man BAR0 register map to guide driver/hardware bring‑up.

## Functional blocks (initial)
- PCIe endpoint (BAR0 CSR space, optional BAR1 aperture for frame/voxel data).
- Voxel core: 64×64×64 volume, fixed‑point raycaster, diagnostic slice mode.
- Surface extraction (stubbed in RTL today), 3D blitter (planned).
- Framebuffer: RGBA32 plus “reemissure32” sidecar (per‑pixel emission/extra field).
- HDMI/DVI output pipeline (LiteICLink/LiteVideo planned), AXI-Stream sink stub in sim.
- DMA engine (host↔SDRAM/BRAM) for voxel/frame uploads (LitePCIe/LiteDMA planned).

## Device IDs (current for 0.0.3)
- Vendor ID: `0x1BAD`
- Device ID: `0x2024`
(Update when assigned; keep in sync with Linux driver and UAPI headers.)

## BARs (proposed)
- BAR0: CSR space (64 KiB window) – control, status, DMA, camera, selection, interrupts.
- BAR1 (optional): Framebuffer/voxel aperture into SDRAM for bulk moves (map via DMA or host).

## BAR0 register sketch (byte offsets, little-endian)
- `0x0000` `ID`          (RO): [31:16] vendor, [15:0] device.
- `0x0004` `REV`         (RO): [7:0] rev, [15:8] build, [31:16] reserved.  
  Current: rev `0x02`, build `0x01` for release 0.0.3; bump on any register map change.
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
- `0x0100..` 3D blitter stub: CTRL/STATUS/SRC/DST/LEN/STRIDE, pixel read/write, object attribute table, FIFO data port.
- Reserved: 0x0150..0xFFFF for future (surface extractor, perf counters).

## Frame formats (planned)
- RGBA32: 8 bits per channel, premultiplied alpha optional.
- Reemissure32 (sidecar): reserved for future emission/extra data; 0.0.3 leaves this field zeroed in the stub.
- AXI-Stream video: 24-bit RGB, tuser=start-of-frame, tlast=end-of-frame per line/frame depending on encoder.

## Interrupts (proposed)
- Bits: [0]=frame_done, [1]=dma_done, [2]=dma_err (stub: not driven, reads 0), [3]=irq_test pulse, [4]=blit_done.
- `INT_STATUS` is RW1C; `irq_out` is level-sensitive on `INT_STATUS & INT_MASK`. `STATUS.frame_done` latches until read or the next CTRL start/reset. `blit_done` asserts `INT_STATUS[4]` in the stub; `IRQ_TEST` pulses `INT_STATUS[3]`.

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
- Extend reemissure32 definition and surface extractor control space post-0.0.3.
- Add full MSI/INT wiring in the real PCIe endpoint when integrated.
