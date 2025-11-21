# IP Integration Plan (PCIe-Centric)

Goal: standardize around a PCIe control/data fabric (no Wishbone exposure upstream), with DMA into external DRAM and HDMI output. Use open-source, FPGA-proven IP and keep ASIC hooks clean.

## Targets
- **Primary board**: Digilent Nexys Video (Artix-7, PCIe Gen2 x4 edge, HDMI in/out, 512 MiB DDR3).  
  Alternate: Xilinx KC705 (Kintex-7, PCIe Gen2 x4, DDR3; HDMI via FMC or TMDS mezz).
- **Flow**: LiteX-family IP (BSD) for PCIe, DRAM, DMA, HDMI. Keep BAR-exposed AXI-Lite for CSRs and AXI-Stream for DMA paths.

## IP Blocks (open source)
- **PCIe**: LitePCIe (BSD) – exposes BARs (AXI-Lite or Wishbone bridge) and host↔FPGA DMA endpoints. Use BAR0 for CSRs (camera/flags/DMA ctrl) and BAR1 for framebuffer scatter/gather if needed.
- **DRAM**: LiteDRAM (BSD) – DDR3 controller/PHY for Nexys Video; expose AXI or Wishbone port. For ASIC, swap to foundry SRAM/DDR PHY; keep a clean memory interface record.
- **DMA**: LitePCIe’s DMA (host↔mem) plus LiteX stream2mem/mem2stream blocks for on-FPGA moves between voxel BRAM and DRAM/HDMI buffers.
- **HDMI/DVI**: LiteICLink/LiteVideo TMDS encoder (BSD) – 720p/1080p timing gen + stream sink; source from DRAM framebuffer or test pattern.

## Fabric & CSRs
- Upstream fabric: PCIe BAR0 mapped as AXI-Lite. Define a CSR window for:
  - Voxel core control: camera regs, flags, selection, world writer.
  - DMA engine: src/dst/len/ctrl for mem2mem, plus IRQ status.
  - HDMI timing/enable and framebuffer base.
- Data paths:
  - Host↔DDR: PCIe DMA (LitePCIe) using AXI-Stream into LiteDRAM port.
  - DDR↔HDMI: LiteVideo fetch from DRAM (line buffer) or test pattern.
  - DDR↔voxel BRAM: small LiteDMA stream2mem/mem2stream for bulk voxel uploads (or PCIe DMA directly if BRAM is mapped into BAR space).

## Simulation/CI Stubs
- Provide `ifdef SIM` stubs:
  - PCIe: simple AXI-Lite master model plus loopback DMA FIFO.
  - DRAM: BRAM-backed “SDRAM” model with same width interface.
  - HDMI: timing counter that logs frame/line events instead of TMDS.
- CI jobs: Verilator lint + targeted sims (DMA loopback, CSR reads/writes, BRAM-backed HDMI stub), plus `yosys -p "read_verilog ...; synth -top ..."`.

## Fetching IP (when network is allowed)
- LitePCIe: https://github.com/enjoy-digital/litepcie
- LiteDRAM: https://github.com/enjoy-digital/litedram
- LiteVideo/LiteICLink: https://github.com/enjoy-digital/liteiclink (HDMI/DVI); timing helpers in LiteX.
- WB2AXIP (for bridges if needed): https://github.com/ZipCPU/wb2axip
Pinned commit hashes should be recorded in `third_party/README.md`.

## Open Tasks (suggested order)
1) Add `third_party/` fetch script with pinned commits (LitePCIe, LiteDRAM, LiteICLink, LiteDMA helpers).
2) Define AXI-Lite CSR map for BAR0 (camera/flags/world/DMA/HDMI) and add a thin AXI-Lite slave that drives existing voxel regs.
3) Add `ifdef SIM` stubs for PCIe, DRAM, and HDMI so CI can run without the real cores.
4) Wire BRAM-backed “SDRAM” into the voxel core path for sim; keep LiteDRAM port wiring in place for real FPGA builds.
5) Create a Nexys Video synthesis target (constraints + LiteDRAM PHY params + LitePCIe x4 config); keep a KC705 variant as fallback.
6) Add a minimal DMA CSR block (mem2mem) and a smoke test that copies a pattern through the stub DRAM and verifies contents.

## ASIC Notes
- Replace LiteDRAM with SRAM/DDR PHY wrappers; keep AXI-Lite/AXI-Stream boundaries identical.
- Swap PCIe for vendor/ASIC IP but retain BAR0 CSR map; isolate clock/reset domains with CDC FIFOs at the AXI boundaries.
- Ensure RAM macros have byte-enable support; add scan/DFT hooks later.
