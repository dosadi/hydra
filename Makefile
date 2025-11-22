# Top-level convenience targets (does not auto-build drivers by default)

.PHONY: all sim driver-linux driver-freebsd drivers backends blit-smoketest libhydra drm-info clean sdk-setup

all: sim

sim:
	@$(MAKE) -C sim

# Optional: build the Linux PCIe driver stub (requires kernel headers)
driver-linux:
	@$(MAKE) -C drivers/linux -f Makefile

# Optional: FreeBSD PCI driver stub (placeholder)
driver-freebsd:
	@$(MAKE) -C drivers/bsd -f Makefile

# Build all host-side bits we have in-tree (stubs included)
drivers: libhydra driver-linux driver-freebsd

# Platform backend stubs (no-op today; keeps build knobs centralized)
backends:
	@echo "Platform backends are stubbed; nothing to build yet."

blit-smoketest:
	@echo "Building user blit smoke test"
	@gcc -I drivers/linux/uapi -O2 -o scripts/hydra_blit_smoketest scripts/hydra_blit_smoketest.c

libhydra:
	@$(MAKE) -C drivers/libhydra

drm-info:
	@echo "Building Hydra DRM info tool"
	@gcc -I drivers/linux/uapi -o scripts/hydra_drm_info scripts/hydra_drm_info.c -ldrm

sdk-setup:
	@echo "Setting up Hydra SDK (libhydra + tools)"
	@./scripts/setup_sdk.sh

clean:
	@$(MAKE) -C sim clean || true
