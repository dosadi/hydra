# Hydra FreeBSD Driver (Stub)

This directory holds a placeholder for a future FreeBSD PCI driver that mirrors the Linux UAPI (`drivers/linux/uapi/`).

Current state:
- `hydra_pci_stub.c`: minimal PCI probe/attach/detach; does not map BARs or expose UAPI yet.
- `Makefile` is a no-op to avoid breaking top-level builds; update when real kmod sources land.

Planned steps:
1) Expand the kernel module (see `Makefile.kmod`) to map BAR0/1 and align offsets with `docs/hydra_spec.md`.
2) Add IOCTL/sysctl hooks mirroring the Linux UAPI in `drivers/linux/uapi/`.
3) Document build deps (`src tree`/kernel headers) and tested FreeBSD versions; wire `make -f Makefile.kmod` in the top-level target once sources are present.

Building the stub (example, on FreeBSD host with kernel sources/headers installed):
```bash
cd drivers/bsd
make -f Makefile.kmod   # builds hydra.ko
sudo kldload ./hydra.ko # load (no real functionality yet)
sudo kldunload hydra
```

Until then, the `driver-freebsd` top-level target will simply acknowledge the stub.
