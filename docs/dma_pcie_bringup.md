# Hydra DMA / PCIe Bring-Up Checklist

Quick steps to validate BARs, DMA, and interrupts on new platforms.

1) Confirm BAR layout and sizes
- `lspci -vv -s <bus>` → note BAR0/BAR1 size/type; expect BAR0 (CSRs) + BAR1 (framebuffer).
- If BAR1 missing/too small, load driver with `bar1_disable=1` and stick to BAR0 tests.

2) Load driver with sane params
- Module params: `vendor_id=0x1D13 device_id=0x0001 msi=1 bar1_disable=0` (tweak for FPGA IDs/MSI issues).
- Check dmesg for probe logs (BAR sizes, MSI vs. INTx selection).

3) Basic IOCTL/mmap sanity (userspace)
- Run `hydra_irq_test` to confirm INT_STATUS clears and IRQ_TEST pulses.
- Run `hydra_mmap_smoke` to map BAR0/BAR1 and read ID/version registers.
- Run `hydra_dma_negative` to verify misaligned/wrap DMA is rejected.

4) DMA functional smoke
- Use `hydra_dma_blit_demo` (or upcoming kselftest) with small transfers; expect DMA_DONE and no DMA_ERR.
- Watch dmesg for DMA_ERR or bounds violations; verify INT_STATUS.DMA_DONE RW1C works.

5) Interrupt sanity
- Toggle `msi=0` to force INTx if MSI is flaky; confirm interrupts fire in both modes.
- Check `/proc/interrupts` counts during `hydra_irq_test` or DMA runs.

6) Optional stress
- Run a short loop of DMA tests with varying lengths/offsets; monitor for DMA_ERR and driver logs.
- If IOMMU is enabled, confirm mappings succeed or add `intel_iommu=on`/`amd_iommu=on` plus driver dma_map hooks.

Artifacts to capture on failure: `lspci -vv`, dmesg excerpt from probe to failure, INT_STATUS dump, and tool output.
