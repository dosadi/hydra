# Simulation Test Scaffolding (pre-silicon)

These tests are a mix of CI-wired unit benches and optional scaffolds to exercise the RTL/driver interface once dependencies are installed.

- `rtl/`: self-contained SystemVerilog benches for the AXI shell (DMA loopback and HDMI CRC golden); runnable via `sim/tests/run_rtl_tests.sh`.
- `cocotb_hydra/`: cocotb testbench that pokes BAR0 registers, observes `irq_out/msi_pulse`, and checks HDMI CRC output; can be run locally via `make SIM=icarus` and is wired into CI as the `cocotb` job.
- `qemu_stub/`: QEMU PCIe stub (`hydra_pci.c`) and a smoke harness (`qemu_hydra_smoke.sh`) that boots a prepared guest with a `hydra-pci` device for driver/libhydra exercise; CI job `qemu-smoke` runs this when a guest image/QEMU build are configured.

To run cocotb locally (example):
```bash
cd sim/tests/cocotb_hydra
make SIM=icarus   # or adjust for your cocotb setup
```
(You’ll need cocotb + a supported simulator installed; this repo does not vendor them.)
