# Top-level convenience targets (does not auto-build drivers by default)

.PHONY: all sim driver-linux clean

all: sim

sim:
	@$(MAKE) -C sim

# Optional: build the Linux PCIe driver stub (requires kernel headers)
driver-linux:
	@$(MAKE) -C drivers/linux -f Makefile

clean:
	@$(MAKE) -C sim clean || true
