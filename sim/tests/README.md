# Simulation Test Scaffolding (pre-silicon)

These tests are **not** wired into CI; they are placeholders to exercise the RTL/driver interface once dependencies are installed.

- `cocotb_hydra/`: scaffold for a cocotb testbench that pokes BAR0 registers, observes `irq_out/msi_pulse`, and checks HDMI CRC output.
- `qemu_stub/`: notes for a QEMU PCIe device that mirrors BAR0 into host RAM for driver/libhydra exercise.

To run cocotb locally (example):
```bash
cd sim/tests/cocotb_hydra
make SIM=icarus   # or adjust for your cocotb setup
```
(You’ll need cocotb + a supported simulator installed; this repo does not vendor them.)
