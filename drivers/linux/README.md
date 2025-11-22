# Hydra PCIe Driver (Linux Stub)

This directory contains Linux-side bring-up shims for Hydra: a misc-device PCIe stub and an optional DRM skeleton.

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
- Basic IOCTLs via `/dev/hydra_pcie` (see `drivers/linux/uapi/hydra_ioctl.h`):
  - `HYDRA_IOCTL_INFO` – returns vendor/device, BAR0 info, IRQ/IRQ count.
  - `HYDRA_IOCTL_RD32`/`WR32` – read/write BAR0 offsets (aligned 32-bit).
- This stub is not built in CI; it requires kernel headers/toolchain.
- `hydra_drm_stub.c` is a DRM/KMS placeholder that binds to the PCI ID, maps BAR0, and registers a DRM device without planes or GEM yet. Enable it manually when you’re ready to bring up modesetting; not built by default.
