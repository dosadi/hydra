# Hardware Test/Emulation Plan (Pre-silicon)

Short-term targets to exercise drivers without real hardware:

- **Verilated PCIe endpoint + cocotb/pyuvm**: build a cocotb testbench that toggles BAR0/INT_STATUS via DPI hooks. Goals: verify IRQ pulses (`msi_pulse`), DMA stub start/done, blitter stub FIFO/copy, and HDMI CRC updates. Artifact: VCD/trace for CI.
- **QEMU PCIe stub**: create a QEMU PCIe device with Hydra vendor/device IDs and a synthetic BAR0 that forwards to a small RAM. Use libhydra/drivers to exercise IOCTLs (RD/WR/DMA) against it; integrate into CI as an optional job.
- **Loopback DMA test in sim**: extend the RTL testbench to issue a DMA copy inside the SDRAM stub and compare source/dest regions; check INT_STATUS and STATUS bits.
- **DRM smoke on render node**: once DRM IOCTLs solidify, run a tiny userspace tool to create a dumb buffer and query DRM-Hydra info (using the new ioctl); for CI, build-only until a QEMU device is present.

Longer-term:
- **FPGA prototyping (LitePCIe/LiteX)**: map voxel shell/AXI wrapper onto a dev board with LitePCIe to run the Linux drivers. Not yet planned for CI.
- **HDMI path check**: in sim, compute frame CRC (`hdmi_crc_last`) and compare against a golden reference for a fixed camera/config; make this a unit test when the frame content is stable.
