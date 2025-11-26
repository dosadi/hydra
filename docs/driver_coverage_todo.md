# Driver Coverage TODOs

Focus on increasing confidence in HAL/PCIe/driver interactions (tests, tools, docs).

- TODO [P0]: Add a kselftest case that exercises `HYDRA_IOCTL_DMA` (good/bad offsets) and assert interrupt counts/return codes; capture regression log sample.
- TODO [P0]: Create a small driver-mode cocotb bench (via `drivers/linux/tests` or sim stub) that flushes DTO interrupts and compares `int_status` with CSR reads.
- DONE [P1]: Add `scripts/driver_coverage.sh` to run `hydra_cam_reset`, `hydra_irq_test`, `hydra_bar1_hexdump` sequentially on a live device and log outputs for CI (`out/driver-coverage`).
- DONE [P1]: Document driver coverage tools in `docs/driver_integration.md`, link to the new coverage script/log artifacts, and publish `docs/driver_coverage_guide.md` with usage/help notes.
- TODO [P2]: Add a FreeBSD userspace coverage script (matching `scripts/hydra_bsd_info.c`) to sample BAR reads and print IRQ count.
