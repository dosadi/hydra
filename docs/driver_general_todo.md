# General Driver TODOs

Capture a broad backlog for Linux/FreeBSD/Windows/macOS driver work that sits above the coverage-specific items.

- TODO [P0]: Finish the Linux PCIe driver stub by wiring BAR1 DMA windows, validating MSI counts, and documenting the new IOCTLs in `drivers/linux/uapi/hydra_regs.h`.
- TODO [P0]: Add a kselftest suite that loads the Linux driver, issues `HYDRA_IOCTL_DMA` (good/bad offsets), and verifies `INT_STATUS`/`irq_out` behavior; store logs under `out/kselftest`.
- DONE [P1]: Expand the FreeBSD stub to expose BAR1 via mmap, add sysctl entries for DMA/IRQ stats, and ship a userspace sample (mirroring `scripts/hydra_bsd_info.c`) that reads the stats.
- TODO [P1]: Provide Windows userspace tools that wrap libhydra and exercise INT_MASK and DMA (reusing `hydra_irq_test`/`hydra_cam_reset` patterns) and note them in `docs/driver_integration.md`.
- TODO [P2]: Add a minimal driver-mode cocotb bench that drives CSR writes through the simulated PCIe path and asserts the driver’s exported IRQ counts match `int_status`.
- DONE [P2]: Create a "driver readiness" dashboard section in the README linking to kernel/test scripts and summarizing which platforms already have stub coverage.
