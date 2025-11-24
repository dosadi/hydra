# IP Integration Plan (PCIe-Centric)

Goal: standardize around a PCIe control/data fabric (no Wishbone exposure upstream), with DMA into external DRAM and HDMI output. Use open-source, FPGA-proven IP and keep ASIC hooks clean.

## Targets
- **Primary board**: Digilent Nexys Video (Artix-7, PCIe Gen2 x4 edge, HDMI in/out, 512 MiB DDR3).  
  Alternate: Xilinx KC705 (Kintex-7, PCIe Gen2 x4, DDR3; HDMI via FMC or TMDS mezz).
- **Flow**: LiteX-family IP (BSD) for PCIe, DRAM, DMA, HDMI. Keep BAR-exposed AXI-Lite for CSRs and AXI-Stream for DMA paths; use `scripts/hydra_litex_shell.py` + `scripts/hydra_litex_nexysvideo.py` for the FPGA shell.

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
- Stubs now in-tree (for CI or early integration):
  - `rtl/axil_csr_stub.sv` – AXI4-Lite CSR register file (use for BAR0 placeholder).
  - `rtl/axi_sdram_stub.sv` – AXI memory model acting as fake SDRAM/DDR.
  - `rtl/axi_stream_sink_stub.sv` – AXI-Stream sink for HDMI/TMDS-style video.
  - (Add PCIe-DMA loopback stub when we wire BAR/DMA control paths.)
- CI jobs: Verilator lint + targeted sims (DMA loopback, CSR reads/writes, BRAM-backed HDMI stub), plus `yosys -p "read_verilog ...; synth -top ..."`.

## Requirements / Fetching IP

Before building the PCIe/DRAM/HDMI shell, make sure three layers are in place: git submodules (RTL IP), Python packages (LiteX tooling), and an FPGA toolchain + board.

### 1. Git submodules (third_party IP)
- IP is vendored as git submodules under `third_party/` and initialized via `scripts/fetch_ip.sh`.
- To check submodule status and see whether anything is missing or out-of-date:
  ```bash
  cd /path/to/hydra
  git submodule status third_party/*
  ```
  - Lines starting with `-` or `+` indicate submodules that are not initialized or not at the expected commit.
- To (re)sync all IP to pinned commits recorded in `third_party/README.md` (idempotent, safe to re-run):
  ```bash
  cd /path/to/hydra
  ./scripts/fetch_ip.sh
  ```
- This fetches and pins:
  - LitePCIe  – `third_party/litepcie` (PCIe endpoint + DMA; BAR0 AXI-Lite + DMA streams).
  - LiteDRAM  – `third_party/litedram` (DDR controller/PHY; Nexys Video preset).
  - LiteICLink/LiteVideo – `third_party/liteiclink` (HDMI/DVI TMDS + timing helpers).
  - LiteX core – `third_party/litex` (AXI/AXI-Lite/stream fabrics, LiteDMA helpers).
- Typical failure modes and fixes:
  - "fatal: repository ... not found" – check your network/proxy and that GitHub is reachable.
  - "permission denied (publickey)" – ensure your SSH keys are configured or use HTTPS remotes.
  - If you cloned with `--recursive`, you can still run `./scripts/fetch_ip.sh` to resync to the pinned SHAs.

### 2. Python packages (host build tooling)
For FPGA builds and LiteX-based shells you also need the Python side of LiteX and the board files.

- Recommended: Python 3.8+ and a virtualenv (optional but keeps LiteX deps isolated):
  ```bash
  cd /path/to/hydra
  python3 -m venv .venv        # optional
  source .venv/bin/activate    # optional
  ```
- Install the core packages:
  ```bash
  python3 -m pip install --upgrade pip
  python3 -m pip install --user litex litex-boards migen
  # Optional but recommended when using vendor toolchains from LiteX:
  python3 -m pip install --user pyserial pyusb
  ```
- To verify they are present and importable:
  ```bash
  python3 -c "import litex, litex_boards, migen; print('LiteX OK')"
  ```
- `litex`/`migen` provide the SoC generator and HDL glue used by `scripts/hydra_litex_shell.py`.
- `litex-boards` provides the Nexys Video platform/clock/DDR/PCIe/HDMI targets used by `scripts/hydra_litex_nexysvideo.py`.

### 3. FPGA / toolchain requirements (Nexys Video path)
To actually build and load a Nexys Video bitstream with the Hydra shell you need:
- Xilinx Vivado (or another LiteX-supported Artix-7 toolchain) on PATH.
- A Digilent Nexys Video board (Artix-7, PCIe Gen2 x4 edge, HDMI in/out, DDR3).
- USB/JTAG cable drivers installed so `openocd`/Vivado can talk to the board.

Sanity checks:
- Confirm Vivado (or your chosen toolchain) is on PATH and licensed:
  ```bash
  command -v vivado >/dev/null && vivado -version
  ```
- Confirm the Nexys Video enumerates on USB when plugged in (host-specific, e.g. `lsusb` or `dmesg | grep -i xilinx`).

Minimal build flow (once toolchains + Python deps are in place):
```bash
cd /path/to/hydra
./scripts/fetch_ip.sh
python3 scripts/hydra_litex_nexysvideo.py --build        # generate bitstream
python3 scripts/hydra_litex_nexysvideo.py --load         # program board (JTAG)
```

This keeps the requirements/flow explicit: git submodules for RTL IP, Python packages for LiteX/LitePCIe integration, and a vendor toolchain + Nexys Video for end-to-end FPGA testing.

## Open Tasks (suggested order)
1) Add `third_party/` fetch script with pinned commits (LitePCIe, LiteDRAM, LiteICLink, LiteDMA helpers).
   - Status: script and pin table exist (`scripts/fetch_ip.sh`, `third_party/README.md`); keep SHAs in sync.
2) Define AXI-Lite CSR map for BAR0 (camera/flags/world/DMA/HDMI) and add a thin AXI-Lite slave that drives existing voxel regs.
   - Status: BAR0 map is defined in `docs/hydra_spec.md` and implemented in the AXI-Lite CSR shell; keep UAPI/RTL/spec aligned.
3) Add `ifdef SIM` stubs for PCIe, DRAM, and HDMI so CI can run without the real cores.
   - Status: AXI SDRAM and HDMI sink stubs (`axi_sdram_stub`, `axi_stream_sink_stub`) are in-tree and used by `voxel_axil_shell`.
4) Wire BRAM-backed “SDRAM” into the voxel core path for sim; keep LiteDRAM port wiring in place for real FPGA builds (use `axi_sdram_stub`).
   - Status: BRAM/AXI stubs are hooked to the voxel core in the shell; LiteDRAM wiring remains to be validated on FPGA.
5) Create a Nexys Video synthesis target (constraints + LiteDRAM PHY params + LitePCIe x4 config) using `scripts/hydra_litex_shell.py` as the voxel-shell↔LiteX glue; keep a KC705 variant as fallback.
   - Priority for 0.0.5: this is the main path to running the Linux driver + DMA on real hardware.
6) Add a minimal DMA CSR block (mem2mem) and a smoke test that copies a pattern through the stub DRAM and verifies contents.
   - Status/Priority: an RTL DMA loopback test exists (`sim/tests/rtl/test_dma_loopback.sv`, run via `sim/tests/run_rtl_tests.sh`); extend this to exercise the LitePCIe/LiteDMA path on FPGA as a 0.0.5 bring-up gate.

## ASIC Notes
- Replace LiteDRAM with SRAM/DDR PHY wrappers; keep AXI-Lite/AXI-Stream boundaries identical.
- Swap PCIe for vendor/ASIC IP but retain BAR0 CSR map; isolate clock/reset domains with CDC FIFOs at the AXI boundaries.
- Ensure RAM macros have byte-enable support; add scan/DFT hooks later.
