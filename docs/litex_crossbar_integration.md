# LiteX Crossbar Integration (Phase 3)

## Overview

This document describes how to integrate `HydraCore` with LiteX's AXI interconnect fabric, replacing the manual crossbar muxing that existed in the old `voxel_axil_shell`.

## Problem: Manual Crossbar is Fragile

The old `voxel_axil_shell.sv` implemented a hardcoded 2-to-1 crossbar:
- **Master 0**: External host (via BAR1)
- **Master 1**: Internal DMA engine
- **Slave 0**: SDRAM stub

This approach had issues:
- Fixed priority (DMA always wins when active)
- No support for adding more masters (e.g., HDMI scanout DMA)
- Address decoding mixed with arbitration logic
- Not reusable across boards

## Solution: LiteX AXIInterconnect

LiteX provides `AXIInterconnect` which handles:
- Automatic arbitration (round-robin or priority)
- Address-based routing (multiple slaves)
- Burst support and backpressure
- Debug infrastructure (bus timeout detection, performance counters)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     LiteX SoC (Nexys Video)                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  LitePCIe                                                     │
│   ├─ BAR0 (AXI-Lite) ──────────────────────> HydraCore      │
│   │                                           .csr_bus       │
│   └─ DMA Engine (AXI4 master)                                │
│        │                                                      │
│        ├──> AXIInterconnect ◄──── HydraCore.fb_master       │
│        │         │                 (framebuffer writes)      │
│        │         │                                            │
│        │         ├──> LiteDRAM Port0 (512 MiB DDR3)          │
│        │         │                                            │
│        │     (Optional)                                       │
│        └──> LiteDMA ◄────────────────────────────────────┐   │
│             (FPGA-internal moves)                         │   │
│                  │                                         │   │
│                  └──> AXIInterconnect                     │   │
│                           │                               │   │
│                           └──> LiteDRAM Port1             │   │
│                                                             │   │
│  LiteVideo HDMI ◄────────────────── HydraCore.video      │   │
│   (or read from DRAM via DMA in future)                   │   │
│                                                             │   │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Step 1: Create Board-Specific SoC

Create `scripts/hydra_litex_nexysvideo.py`:

```python
#!/usr/bin/env python3
from litex.soc.integration.soc import SoCRegion
from litex.soc.integration.soc_core import SoCCore
from litex.soc.interconnect.axi import AXIInterface, AXIInterconnect
from litex.soc.cores.dma import LiteDMA
from litex_boards.platforms import digilent_nexysvideo
from scripts.hydra_litex_shell import HydraCore

class HydraNexysVideoSoC(SoCCore):
    def __init__(self):
        platform = digilent_nexysvideo.Platform()

        # Basic SoC (no CPU, just clocks/reset/UART for debug)
        SoCCore.__init__(
            self,
            platform,
            sys_clk_freq=100e6,
            cpu_type=None,  # No soft CPU
            integrated_rom_size=0,
            integrated_sram_size=0,
            uart_name="crossover",  # For debugging via PCIe
        )

        # PCIe endpoint (Gen2 x4)
        self.add_pcie(phy="xilinx", gen=2, lanes=4)

        # DDR3 (512 MiB)
        self.add_sdram("ddr3", phy_settings="1:2", module="MT41J256M16")

        # Hydra voxel core
        self.hydra = HydraCore(screen_width=720, screen_height=480)
        self.submodules.hydra = self.hydra

        # Connect HydraCore.csr_bus to PCIe BAR0
        self.pcie.bar0.add_slave("hydra_csr", self.hydra.csr_bus, base=0x0000)

        # AXI interconnect for DRAM
        self.axi_xbar = AXIInterconnect()
        self.submodules.axi_xbar = self.axi_xbar

        # Add masters
        self.axi_xbar.add_master(name="pcie_dma", master=self.pcie.dma.master)
        self.axi_xbar.add_master(name="hydra_fb", master=self.hydra.fb_master)

        # Add slave (DDR3 via LiteDRAM)
        self.axi_xbar.add_slave(
            name="dram",
            slave=self.sdram.crossbar.get_port(),
            region=SoCRegion(origin=0x0, size=512*1024*1024),
        )

        # HDMI output (TODO: replace direct stream with DMA-based scanout)
        self.add_hdmi_out(source=self.hydra.video)

if __name__ == "__main__":
    soc = HydraNexysVideoSoC()
    soc.build()
```

### Step 2: Update `HydraCore` for LiteX Conventions

(Already done in Phase 1, but verify):
- ✅ `self.csr_bus` is an AXI-Lite slave
- ✅ `self.fb_master` is an AXI4 master
- ✅ `self.video` is an AXI-Stream master
- ✅ No hardcoded address decoding in RTL

### Step 3: Wire Up DMA Engines

#### LitePCIe DMA (Host ↔ FPGA)
- Already included in `self.add_pcie()`
- Exposes `self.pcie.dma.master` as AXI4 master
- Add to crossbar as shown above

#### LiteDMA (Optional, FPGA Internal)
```python
# Add LiteDMA for FPGA-internal mem2mem moves
self.litedma = LiteDMA(
    data_width=64,
    max_burst_length=256,
)
self.submodules.litedma = self.litedma

# Connect to crossbar
self.axi_xbar.add_master(name="litedma", master=self.litedma.master)

# Expose LiteDMA CSRs via BAR0
self.pcie.bar0.add_slave("litedma_csr", self.litedma.csr_bus, base=0x1000)
```

**Note**: The DMA CSRs at BAR0 0x0060 will now control LiteDMA, not the stubbed `axi_dma_stub`.

### Step 4: Add HDMI Scanout DMA (Future)

When Phase 5 is implemented:
```python
# LiteVideo HDMI with DMA reader
self.hdmi_dma = LiteDMA(data_width=32, max_burst_length=16)
self.submodules.hdmi_dma = self.hdmi_dma

# Connect to crossbar
self.axi_xbar.add_master(name="hdmi_dma", master=self.hdmi_dma.master)

# HDMI timing generator + encoder
self.hdmi = LiteVideoHDMI(
    phy=platform.request("hdmi_out"),
    pix_clk_freq=74.25e6,  # 720p60
    dma=self.hdmi_dma,
)
self.submodules.hdmi = self.hdmi
```

## Address Map

### PCIe BAR0 (AXI-Lite, 64 KiB)
```
0x0000 - 0x0FFF : HydraCore CSRs (camera, flags, sel, status, IRQ)
0x1000 - 0x1FFF : LiteDMA CSRs (src, dst, len, cmd)
0x2000 - 0x2FFF : HDMI CSRs (base addr, stride, enable)
0x3000 - 0x3FFF : Reserved (future blitter)
```

### PCIe BAR1 (AXI4 Memory Window, 512 MiB)
- Maps directly to DDR3 via LitePCIe's memory window
- No need for RTL address translation (LitePCIe handles it)

### DRAM (Physical, 512 MiB)
```
0x0000_0000 - 0x0FFF_FFFF : Framebuffer region A (16 MiB)
0x1000_0000 - 0x1FFF_FFFF : Framebuffer region B (16 MiB, ping-pong)
0x2000_0000 - 0x2FFF_FFFF : Voxel data (16 MiB)
0x3000_0000 - 0x1FFF_FFFF : Host scratch space (464 MiB)
```

## Crossbar Configuration Options

### Arbitration Policy
```python
# Round-robin (default)
self.axi_xbar = AXIInterconnect(arbitration="rr")

# Priority-based (PCIe DMA has priority)
self.axi_xbar = AXIInterconnect(arbitration="priority")
self.axi_xbar.set_priority("pcie_dma", 0)  # highest
self.axi_xbar.set_priority("hydra_fb", 1)
self.axi_xbar.set_priority("hdmi_dma", 2)  # lowest
```

### Timeout Detection
```python
# Enable bus timeout detection (10ms timeout)
self.axi_xbar.add_timeout(cycles=1_000_000)  # @ 100 MHz = 10ms
```

### Performance Counters
```python
# Add AXI transaction counters
self.axi_xbar.add_counter("pcie_dma", "transactions")
self.axi_xbar.add_counter("hydra_fb", "bytes_written")
```

## Testing Strategy

### 1. Synthesis Verification
```bash
cd /path/to/hydra
./scripts/fetch_ip.sh  # Ensure LitePCIe/LiteDRAM are fetched
python3 scripts/hydra_litex_nexysvideo.py --build
# Check build log for resource usage (expect < 50% LUTs, < 30% BRAM)
```

### 2. PCIe Enumeration Test
```bash
# Load bitstream
python3 scripts/hydra_litex_nexysvideo.py --load

# Check PCIe enumeration (Linux host)
lspci -d 1bad:2024 -vv
# Should show BAR0 (64 KiB), BAR1 (512 MiB)

# Load driver
cd drivers/linux
make && sudo insmod hydra.ko

# Read ID register
sudo ./tools/hydra_reg_read 0x0000
# Should return 0x1BAD2024
```

### 3. DMA Loopback Test
```bash
# Test PCIe DMA (host ↔ DRAM)
sudo ./drivers/linux/tools/hydra_dma_test

# Test LiteDMA (DRAM ↔ DRAM)
# TODO: Add userspace tool after LiteDMA integration
```

### 4. Framebuffer Write Test
```bash
# Render single frame, read back via PCIe
sudo ./drivers/linux/tools/hydra_render_test --dump-frame test.ppm
# Verify CRC matches sim golden frame
```

## Known Issues and Workarounds

### Issue: AXI Burst Alignment
**Problem**: Unaligned AXI bursts can cause LiteDRAM to stall
**Workaround**: Ensure framebuffer base address is 4 KiB-aligned
**Fix**: Add alignment check in `voxel_axi_core` burst writer (Phase 5)

### Issue: HDMI Direct Streaming Unreliable
**Problem**: Voxel core can't sustain 60fps pixel rate (ray marching too slow)
**Workaround**: Reduce resolution (480x360) or use lower refresh rate
**Fix**: Implement DMA-based scanout (Phase 5)

### Issue: No IRQ on Frame Done
**Problem**: `msi_pulse` signal not yet wired to LitePCIe MSI controller
**Workaround**: Poll `STATUS` register for `frame_done` bit
**Fix**: Wire `hydra.msi_pulse` to `pcie.msi.add_source()` in SoC builder

## Next Steps

After crossbar integration is complete:
1. **Phase 4**: Replace `axi_dma_stub` with LiteDMA, clarify CSR semantics
2. **Phase 5**: Implement AXI4 burst writer in `voxel_axi_core`, add HDMI DMA scanout
3. **Driver updates**: Add DMA IOCTLs, framebuffer mmap support
4. **Performance tuning**: Measure DDR3 bandwidth, optimize burst sizes

## References

- LiteX AXI interconnect docs: `third_party/litex/litex/soc/interconnect/axi.py`
- LitePCIe BAR mapping: `third_party/litepcie/litepcie/core.py`
- LiteDRAM crossbar: `third_party/litedram/litedram/core/controller.py`
- Example board SoC: `third_party/litex-boards/litex_boards/targets/digilent_nexysvideo.py`
