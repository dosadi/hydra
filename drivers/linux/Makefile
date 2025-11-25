# Minimal out-of-tree build stub for the Hydra drivers.
# Usage:
#   make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

.PHONY: help

help:
	@echo "Hydra Linux driver build targets:"
	@echo "  make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules   # build module(s)"
	@echo "  make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean     # clean build outputs"
	@echo "Requires: kernel headers for the running kernel (linux-headers-$(shell uname -r))"

obj-m += hydra_pcie_drv.o
# hydra_drm_stub.o depends on legacy DRM PCI helpers; omit from default build on modern kernels.
# obj-m += hydra_drm_stub.o
