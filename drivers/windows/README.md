# Hydra Windows Driver (Stub Plan)

Next steps for a KMDF PCIe stub:

- Create a KMDF driver project (EvtDeviceAdd, BAR mapping, DMA mask).
- Populate device matching with Hydra vendor/device IDs.
- Add IOCTLs to poke BARs/CSRs for bring-up; later evolve into a WDDM miniport if presenting as a GPU.
- Signatures/INF: include .inf/.cat for test signing; keep out of this repo until ready.

No code is present yet to avoid build/toolchain churn on non-Windows hosts.
