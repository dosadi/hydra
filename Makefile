# Top-level convenience targets (does not auto-build drivers by default)

.PHONY: all sim driver-linux blit-smoketest libhydra clean

all: sim

sim:
	@$(MAKE) -C sim

# Optional: build the Linux PCIe driver stub (requires kernel headers)
driver-linux:
	@$(MAKE) -C drivers/linux -f Makefile

blit-smoketest:
	@echo "Building user blit smoke test"
	@gcc -I drivers/linux/uapi -O2 -o scripts/hydra_blit_smoketest scripts/hydra_blit_smoketest.c

libhydra:
	@$(MAKE) -C drivers/libhydra

clean:
	@$(MAKE) -C sim clean || true
