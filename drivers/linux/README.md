# Hydra PCIe Driver (Linux Stub)

This is a minimal out-of-tree PCI driver stub. It binds to a placeholder vendor/device ID, enables the device, and does not yet map BARs or expose IOCTLs.

Build (manual, optional):

```bash
cd drivers/linux
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules
sudo insmod hydra_pcie_drv.ko
sudo dmesg | tail
lsmod | grep hydra
sudo rmmod hydra_pcie_drv
```

Notes:

- Replace `HYDRA_VENDOR_ID`/`HYDRA_DEVICE_ID` in `hydra_pcie_drv.c` when assigned.
- BAR0 is mapped and logged; DMA masks set; MSI/MSI-X (or legacy) requested; `debugfs/hydra_pcie/status` shows BAR/IRQ info.
- Basic IOCTLs are available via a misc device (`/dev/hydra_pcie`): `HYDRA_IOCTL_RD32`/`WR32` to read/write BAR0 (see `drivers/linux/uapi/hydra_ioctl.h`).
- This stub is not built in CI; it requires kernel headers/toolchain.
