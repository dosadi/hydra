# Driver Coverage Guide

This guide explains how to exercise the small helper tools that touch BAR0/DMA/IRQ paths and collect logs for regression tracking.

## Requirements
- Linux users: load the Hydra kernel module or stub, ensure `/dev/hydra_pcie` exists (`drivers/linux/hydra_pcie_drv.c`).
- macOS/Windows: run `scripts/setup_macos_env.sh` or `scripts/windows-env.ps1` beforehand so any cocotb/tooling dependencies are present.

## Running the coverage loop

```bash
./scripts/driver_coverage.sh
```

The script runs, in order:

1. `scripts/hydra_cam_reset` to zero camera/flag/selection state.
2. `scripts/hydra_irq_test` to pulse `IRQ_TEST` and poll `INT_STATUS`/`irq_out`.
3. `scripts/hydra_bar1_hexdump` to read a few words via BAR1 and log them.

Each tool log is written to `out/driver-coverage/<tool>.log`, which also captures stderr for diagnostics. If any tool fails (non-zero exit), the script aborts so CI can catch regressions.

## Interpreting logs
- `hydra_cam_reset.log` should show the camera/flag writes and a successful `/dev...` ioctl.
- `hydra_irq_test.log` dumps `INT_STATUS` before/after and confirms `irq_out` toggles.
- `hydra_bar1_hexdump.log` prints the hexdump output; use it to verify BAR1 data is readable and matches expectations.

Keep these logs as CI artifacts when driver coverage is part of the pipeline. If you add new helper scripts, append them to `scripts/driver_coverage.sh` and note them here.
