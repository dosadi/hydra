# Hydra Device Sketch (Draft)

This is a working outline for the Hydra PCIe device: blocks, formats, and a straw‑man BAR0 register map to guide driver/hardware bring‑up.

## Functional blocks (initial)
- PCIe endpoint (BAR0 CSR space, optional BAR1 aperture for frame/voxel data).
- Voxel core: 64×64×64 volume, fixed‑point raycaster, diagnostic slice mode.
- Surface extraction (stubbed in RTL today), 3D blitter (planned).
- Framebuffer: RGBA32 plus “reemissure32” sidecar (per‑pixel emission/extra field).
- HDMI/DVI output pipeline (LiteICLink/LiteVideo planned), AXI-Stream sink stub in sim.
- DMA engine (host↔SDRAM/BRAM) for voxel/frame uploads (LitePCIe/LiteDMA planned).

## Device IDs (placeholder)
- Vendor ID: `0x1BAD`
- Device ID: `0x2024`
(Update when assigned; keep in sync with Linux driver.)

## BARs (proposed)
- BAR0: CSR space (64 KiB window) – control, status, DMA, camera, selection, interrupts.
- BAR1 (optional): Framebuffer/voxel aperture into SDRAM for bulk moves (map via DMA or host).

## BAR0 register sketch (byte offsets, little-endian)
- `0x0000` `ID`          (RO): [31:16] vendor, [15:0] device.
- `0x0004` `REV`         (RO): [7:0] rev, [15:8] build, [31:16] reserved.
- `0x0010` `CTRL`        (RW): [0]=soft_reset, [1]=start_frame, [2]=diag_slice_en, [3]=extra_light_en.
- `0x0014` `STATUS`      (RO): [0]=busy, [1]=frame_done, [2]=dma_busy, [3]=dma_done, [31:4]=resvd.
- `0x0020..0x003C` Camera (RW): cam_x/y/z, cam_dir_x/y/z, cam_plane_x/y (signed 16-bit each, packed 32-bit).
- `0x0040` `FLAGS`       (RW): [0]=smooth, [1]=curvature, [2]=extra_light, [3]=diag_slice.
- `0x0044..0x004C` Selection (RW): sel_active, sel_x, sel_y, sel_z (6-bit fields in 32-bit words).
- `0x0050` `FB_BASE`     (RW): framebuffer base address (BAR1/SDRAM).
- `0x0054` `FB_STRIDE`   (RW): bytes per line.
- `0x0060..0x0070` DMA regs (RW): SRC, DST, LEN (bytes), CMD [0]=start, STATUS [0]=done, [1]=busy, [2]=err.
- `0x0080` `INT_STATUS`  (RW1C): [0]=frame_done, [1]=dma_done, [2]=dma_err, [3]=irq_test.
- `0x0084` `INT_MASK`    (RW): same bits as STATUS.
- `0x00A0..0x00A8` Debug voxel write: ADDR (18-bit), DATA_LO (32), DATA_HI (32), CTRL [0]=write_pulse.
- Reserved: 0x0100..0xFFFF for future (surface extractor, blitter, perf counters).

## Frame formats (planned)
- RGBA32: 8 bits per channel, premultiplied alpha optional.
- Reemissure32 (sidecar): 32-bit field for emission/extra data per pixel (definition TBD).
- AXI-Stream video: 24-bit RGB, tuser=start-of-frame, tlast=end-of-frame per line/frame depending on encoder.

## Interrupts (proposed)
- Frame done (raycaster completed a frame).
- DMA done/error.
- Optional: hotplug/test IRQ.

## Linux driver alignment
- BAR0 mapped, DMA masks set, MSI/MSI-X requested, misc device `/dev/hydra_pcie` with IOCTLs:
  - `HYDRA_IOCTL_INFO`: vendor/device, BAR0 info, IRQ number/count.
  - `HYDRA_IOCTL_RD32`/`WR32`: aligned BAR0 accesses for early bring‑up.
- Debugfs: `hydra_pcie/status` dumps BAR0/IRQ info.

## Open items
- Finalize vendor/device IDs.
- Lock BAR0 map and bitfields; align RTL CSRs to this map.
- Define reemissure32 semantics and the blitter/surface extractor control space.
- Add MSI/INT wiring in RTL once the interrupt controller is specified.
