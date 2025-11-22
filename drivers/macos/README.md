# Hydra macOS Driver (Stub Plan)

Next steps for a DriverKit/SystemExtension PCIe stub:

- Define PCI matching for Hydra vendor/device IDs.
- Map BARs and expose an IOUserClient-style interface for userspace tools.
- Consider Metal/MoltenVK compatibility only after low-level bring-up is stable.

No code is present yet to avoid Xcode/DriverKit dependencies in this repo.
