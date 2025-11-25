# Hydra user tools (stubs / smoke tests)

Small helper binaries built from `scripts/` and `drivers/libhydra`. These are primarily for bring-up on the Linux PCIe stub; they exit non-zero on errors.

- `hydra_blit_smoketest` (C, ioctl-based): Opens `/dev/hydra_pcie` (or argv[1]), runs `HYDRA_IOCTL_INFO`, enables INT_MASK bits, seeds a 4-word FIFO, kicks a 16-byte blit, polls STATUS/INT_STATUS, and dumps a few pixel words. Exit `0` on success; non-zero if any ioctl or poll fails.
- `hydra_dma_blit_demo` (C/libhydra): Uses libhydra to open `/dev/hydra_pcie` (argv[1] overrides), prints info, clears/enables interrupts, issues a tiny DMA copy (device-local addresses), pushes 4 FIFO words, kicks a blit, waits for BLIT_DONE, and reads back pixels. Exit `0` when DMA_DONE/BLIT_DONE observed, `1` otherwise.
- `hydra_drm_info` (C/DRM): Opens render node `/dev/dri/renderD128` by default, issues `DRM_IOCTL_HYDRA_INFO` and `DRM_IOCTL_HYDRA_CSROUT` for STATUS/INT_STATUS. Exit `0` on success; non-zero if ioctls fail.
- `hydra_irq_test` (C/ioctl): Opens `/dev/hydra_pcie` (argv override), programs INT_MASK (argv `mask=`), clears INT_STATUS, triggers IRQ_TEST, prints INT_STATUS before/after, clears it, exits `0` on success or `1` on failure.
- `hydra_cam_reset` (C/libhydra): Resets camera, flags, and selection to defaults on `/dev/hydra_pcie` (argv override). Exits `0` on success, `77` if device missing, or `1` on error.
- `hydra_mmap_smoke` (C/ioctl+mmap): Checks ABI/version/struct sizes via `HYDRA_IOCTL_VERSION`, maps BAR0, reads ID/REV/STATUS registers, prints them. Exits `0` on success, `77` if device missing, non-zero on ABI mismatch.
- `hydra_cam_flags_demo` (C/libhydra): Sample that sets camera/flags/selection and reads INT_STATUS; exits `0` on success, `77` if device missing.

Build targets:
- `make blit-smoketest` → `scripts/hydra_blit_smoketest`
- `make sdk-setup` → builds libhydra + `hydra_dma_blit_demo`, `hydra_drm_info`, `hydra_irq_test`
- `make cam-reset` → builds and runs `scripts/hydra_cam_reset` (requires driver node present)
- `make mmap-smoke` → builds and runs `scripts/hydra_mmap_smoke`
- `make cam-flags-demo` → builds and runs `scripts/hydra_cam_flags_demo`

Dependencies: Linux PCIe stub driver (`/dev/hydra_pcie`), libhydra for the lib-based tools, DRM headers/libs for `hydra_drm_info`.
