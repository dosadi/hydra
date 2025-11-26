# Driver Kselftest Plan

Objective: define a small kselftest suite that can execute and verify the Linux driver’s core IOCTL paths (DMA, IRQ, BAR access) and report pass/fail via the kselftest framework.

## Proposed cases

1. **HYDRA_IOCTL_DMA success/failure**
   - Build a simple C test (under `drivers/linux/tests`) that opens `/dev/hydra_pcie`, issues `HYDRA_IOCTL_DMA` with a valid src/dst/len (within BAR0 bounds), waits for completion, and asserts `INT_STATUS` has `DMA_DONE`.
   - Repeat the test with an out-of-range length to confirm the driver returns `-EINVAL` (or sets `DMA_ERR`) and does not flip `DMA_DONE`.
2. **IRQ_TEST propagation**
   - Extend the test to call `HYDRA_IOCTL_IRQ_TEST` (or `hydra_irq_test` tool) and compare the kernel’s `irq_count` sysctl/debugfs value before/after to ensure the IRQ path fires and acknowledges `INT_STATUS`.
3. **BAR1 read coverage**
   - Map BAR1 via `mmap` within the test and read/write a few words, comparing to a known pattern/from `scripts/hydra_bar1_hexdump`. Ensure driver enforces bounds and returns expected data for valid offsets.
4. **Cleanup**
   - Each case should log its actions to stdout/stderr (kselftest logs) and exit non-zero on mismatch. Combine cases into a small kselftest subdirectory so `make kselftest`/`scripts/driver_coverage.sh` can invoke it.

## Next steps

- Implement the C test harness (use `libhydra` helpers if helpful) and add `Makefile` entries so `drivers/linux/tests/Makefile` builds the binary.
- Create a `scripts/run_driver_kselftest.sh` wrapper that builds the test and invokes it, capturing logs to `out/kselftest`.
- Update `docs/driver_integration.md` to mention the kselftest suite and how to run it in lab/CI.
