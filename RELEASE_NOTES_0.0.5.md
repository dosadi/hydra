# Hydra 0.0.5 Release Notes

## Highlights
- **DMA/IRQ path**: tightened end-to-end DMA and interrupt behavior through RTL benches and cocotb, covering DMA loopback on BAR0 and BAR1, INT_STATUS/INT_MASK semantics, and IRQ_TEST/MSI pulse observation on `msi_pulse`.
- **3D blitter stub**: exercised the 0x0100 blitter region with a new cocotb test that drives BLIT_CTRL/SRC/DST/LEN, verifies busy/done/BLIT_DONE interrupt behavior, and checks that the local `blit_pix_mem` copy path works as specified.
- **Linux/QEMU stubs**: fleshed out the Linux PCIe stub driver (`hydra_pcie_drv.c`) and QEMU PCI stub (`sim/tests/qemu_stub/hydra_pci.c`) to share vendor/device IDs, BAR0 CSR layout, and basic DMA/BLIT interrupt behavior, giving a coherent model from RTL through to a virtual PCIe device.
- **CI & tests**: confirmed that the deterministic frame regression still passes after minor scene tuning, and aligned the cocotb tests with the AXI-Lite address map and INT_STATUS behavior exercised by the SystemVerilog RTL benches.

## Known limitations
- Renderer is still orthographic; perspective DDA and more advanced lighting/shadows are deferred to a later release.
- The 3D blitter remains a bring-up stub without a full 3D command FIFO or host-visible DMA descriptor stream.
- PCIe remains sim/QEMU-only; there is no board-level PCIe endpoint or LitePCIe integration yet, and Windows/macOS drivers are still stubs.

## Build/Run summary
- Sim: `cd sim && make` (Verilator + SDL); optional backends via `make GL=1`, `WAYLAND=1`, `X11=1`, `VULKAN=1` when headers/libs are present.
- Frame regression: `make -C sim test_frame` (uses `FRAME_DUMP` + `scripts/check_frame.py` vs `sim/tests/golden_frame.ppm`).
- RTL benches: `chmod +x sim/tests/run_rtl_tests.sh && ./sim/tests/run_rtl_tests.sh` (requires iverilog/vvp) for DMA loopback, BAR1+DMA, and HDMI CRC golden.
- Cocotb: `cd sim/tests/cocotb_hydra && make SIM=icarus` to run the IRQ/DMA/BLIT smoke tests on `voxel_axil_shell`.
- Host libs/tools: `cmake --preset linux-default && cmake --build build/linux` or `./scripts/setup_sdk.sh`.
- Linux drivers: `make -C drivers/linux` to build stubs; use `hydra_pcie_drv` with the QEMU stub device for PCIe/UAPI experiments.

## Notes
- See `docs/component_status.md` for the current component maturity snapshot; PCIe/LitePCIe and perspective rendering remain explicitly out of scope for 0.0.5.
