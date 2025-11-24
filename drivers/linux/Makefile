# Minimal out-of-tree build stub for the Hydra drivers.
# Usage:
#   make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

obj-m += hydra_pcie_drv.o
# hydra_drm_stub.o depends on legacy DRM PCI helpers; omit from default build on modern kernels.
# obj-m += hydra_drm_stub.o
