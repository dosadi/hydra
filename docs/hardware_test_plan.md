# Hardware Test/Emulation Plan (Pre-silicon)

Short-term targets to exercise drivers without real hardware:

- **Verilated PCIe endpoint + cocotb/pyuvm**: build a cocotb testbench that toggles BAR0/INT_STATUS via DPI hooks. Goals: verify IRQ pulses (`msi_pulse`), DMA stub start/done, blitter stub FIFO/copy, and HDMI CRC updates. Artifact: VCD/trace for CI. (Scaffold lives in `sim/tests/cocotb_hydra`; an optional `cocotb` GitHub Actions job runs a basic Icarus-based smoke test.)
- **QEMU PCIe stub**: use `sim/tests/qemu_stub/hydra_pci.c` as a QEMU PCIe device with Hydra vendor/device IDs and a synthetic BAR0 backed by RAM. In a Linux guest, use libhydra/drivers to exercise IOCTLs (RD/WR/DMA/blit) against it; optional CI job `qemu-smoke` runs `sim/tests/qemu_stub/qemu_hydra_smoke.sh` when `HYDRA_QEMU_GUEST_URL` (GitHub secret) or `HYDRA_QEMU_GUEST_IMG` is configured.
- **Loopback DMA test in sim**: implemented as `sim/tests/rtl/test_dma_loopback.sv` and runnable via `sim/tests/run_rtl_tests.sh`.
- **HDMI path check**: implemented as `sim/tests/rtl/test_hdmi_crc_golden.sv` (checks `hdmi_crc_last` against a golden for a fixed camera/config) and runnable via `sim/tests/run_rtl_tests.sh`.
- **DRM smoke on render node**: once DRM IOCTLs solidify, run a tiny userspace tool to create a dumb buffer and query DRM-Hydra info (using the new ioctl); for CI, build-only until a QEMU device is present.

Longer-term:
- **FPGA prototyping (LitePCIe/LiteX)**: map voxel shell/AXI wrapper onto a dev board with LitePCIe to run the Linux drivers. Not yet planned for CI.
- **HDMI path check**: in sim, compute frame CRC (`hdmi_crc_last`) and compare against a golden reference for a fixed camera/config; make this a unit test when the frame content is stable.
