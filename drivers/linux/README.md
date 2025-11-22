# Hydra PCIe Driver (Linux Stub)

This is a minimal out-of-tree PCI driver stub. It binds to a placeholder vendor/device ID, enables the device, and does not yet map BARs or expose IOCTLs.

Build (manual, optional):

```bash
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
```

Notes:

- Replace `HYDRA_VENDOR_ID`/`HYDRA_DEVICE_ID` in `hydra_pcie_drv.c` when assigned.
- BAR0 is mapped and logged; extend with DMA mask setup, MSI/MSI-X, and a user-visible interface (`debugfs`, `ioctl`, or a DRM/VFIO path) as needed.
- This stub is not built in CI; it requires kernel headers/toolchain.
