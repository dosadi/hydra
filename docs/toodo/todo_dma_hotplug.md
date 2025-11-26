# DMA Hotplug & Resource Cleanup TODOs

Captures driver behavior around PCIe hotplug, DI devices, and how DMA/IRQ/BSR resources are reclaimed and reinitialized.

- **TODO [P1]:** Document early detection steps (PCIe _link_ loss, `pci_device_is_present`) and describe expected resource cleanup (msi vectors, BAR mappings).
  - Effort: 1 day
  - Deliverable: Section in this tracker with actionable steps

- **TODO [P2]:** Add driver test (kselftest or script) that simulates device removal/reprobe and validates DMA resources are reallocated without leaking.
  - Effort: 2 days
  - Deliverable: Script + logs showing clean reprobe

- **TODO [P2]:** Expand driver debug logs to record hotplug events with DMA window/base addresses so stale transfers can be traced.
  - Effort: 1 day
  - Deliverable: Driver patch + example log

- **TODO [P3]:** Add doc that describes how to drive PCIe hotplug from Linux (echo 1 > /sys/bus/pci/devices/0000:xx/remove; rescan) and tie it back to no-DMA-after-hang scenarios.
  - Effort: 1 day
  - Deliverable: doc snippet referencing this tracker
- **TODO [P3]:** Demonstrate a hotplug recovery script that rebinds Hydra driver and prints cleaned DMA stats (publish in docs for QA).
- **TODO [P3]:** Capture hotplug traces (dmesg + DMA logs) into `out/driver-coverage/` when hotplug tests run so regressions can be diffed.
- **TODO [P1]:** Write a troubleshooting checklist that ties hotplug steps to DMA cleanup (`unbind/bind`, mmaps, interrupts) and cite the checklist from `docs/driver_coverage_todo.md`.
  - Effort: 1 day
  - Deliverable: Checklist doc section + links to driver scripts
- **TODO [P2]:** Create `scripts/dma_hotplug_cycle.sh` that removes/readds the PCI device and captures DMA stats before/after (RQ depth, pending bytes) so hardware tests verify clean state transitions.
  - Effort: 1.5 days
  - Deliverable: Script + sample log comparison
