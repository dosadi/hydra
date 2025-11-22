# QEMU PCIe Stub (concept)

Idea: create a tiny QEMU PCI device with Hydra vendor/device IDs and a BAR0 RAM window. Use it to exercise Linux drivers/libhydra IOCTLs without real hardware.

Steps (not implemented here):
- Write a QEMU device model that exposes BAR0 (64 KiB) backed by RAM, returns a synthetic STATUS/INT map, and supports MSI toggle.
- Launch QEMU with the device and a Linux guest; load the Hydra drivers against it.
- Run `hydra_blit_smoketest` and `libhydra` tools to validate IOCTL paths.

This directory is a placeholder for that device model when authored.
