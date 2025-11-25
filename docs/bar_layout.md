# Hydra BAR Layout (Bring-up Reference)

- BAR0: CSR window (AXI-lite). Size: `HYDRA_BAR0_SIZE` (typically 4 KiB). Holds ID/REV/STATUS, INT_STATUS/MASK, DMA/BLIT CSRs, framebuffer base/stride, selection/flag registers.
- BAR1: Framebuffer / scratch window. Size depends on platform; expect at least one full framebuffer (480x360x4 bytes ≈ 675 KiB). Driver maps BAR1 when present; userspace can mmap for inspection.

Notes:
- When BAR1 is absent or too small, driver falls back to BAR0-only; DMA/ioctls still work on stub addresses.
- IOCTLs: `HYDRA_IOCTL_INFO` reports BAR sizes; user tools should honor `bar1_len` and skip BAR1 tests when zero.
- Align DMA src/dst/len to 4 bytes; driver rejects wrap/overflow against BAR0 size.
- For MSI-challenged platforms, load driver with `msi=0` to use legacy INTx.
