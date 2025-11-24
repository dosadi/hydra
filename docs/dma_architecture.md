# DMA Architecture Clarification (Phase 4)

## Problem Statement

The current codebase has ambiguous DMA semantics:
- BAR0 registers at 0x0060-0x007F labeled "DMA" but unclear what DMA engine they control
- `axi_dma_stub.sv` exists for simulation but no real implementation for FPGA
- LitePCIe provides its own DMA engine for host↔FPGA transfers
- Unclear relationship between the two

This confusion causes:
- Driver developers unsure which registers to use
- FPGA integrators unsure which DMA blocks to instantiate
- Risk of register address conflicts

## Solution: Dual-DMA Architecture

We adopt a **two-DMA model** with clear separation of concerns:

```
┌──────────────────────────────────────────────────────────────────┐
│                          Host System                              │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  libhydra / Driver                                        │    │
│  │   ├─ Host-to-FPGA: litepcie_dma_write(src, dst, len)    │    │
│  │   └─ FPGA-internal: ioctl(HYDRA_DMA_BLIT, src, dst)     │    │
│  └──────────────────────────────────────────────────────────┘    │
└────────────────────────────┬─────────────────────────────────────┘
                             │ PCIe Gen2 x4
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                        FPGA (Nexys Video)                         │
│                                                                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  DMA1: LitePCIe DMA Engine (Host ↔ FPGA)                 │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  Purpose: High-bandwidth host memory ↔ FPGA DRAM         │   │
│  │  Control: LitePCIe CSRs (NOT BAR0 0x0060!)               │   │
│  │  Use Cases:                                                │   │
│  │    - Host uploads voxel data → FPGA DRAM                 │   │
│  │    - Host reads rendered framebuffer ← FPGA DRAM         │   │
│  │    - Bulk data transfers for scene updates               │   │
│  │  AXI Master: Connected to AXIInterconnect → LiteDRAM     │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  DMA2: LiteDMA (FPGA-Internal Moves)                     │   │
│  │  ────────────────────────────────────────────────────────  │   │
│  │  Purpose: On-FPGA memory-to-memory copies                │   │
│  │  Control: BAR0 0x0060-0x007F (hydra_spec.md)             │   │
│  │  Use Cases:                                                │   │
│  │    - Copy voxel data DRAM → BRAM (64×64×64 uploads)     │   │
│  │    - Framebuffer blits within DRAM (e.g., copy frame)    │   │
│  │    - Future: 3D blitter operations                        │   │
│  │  AXI Master: Connected to AXIInterconnect → LiteDRAM     │   │
│  │  CSR Interface: Exposed via BAR0                          │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  AXIInterconnect (Shared Crossbar)                        │   │
│  │    Masters: LitePCIe DMA, LiteDMA, HydraCore.fb_master  │   │
│  │    Slaves:  LiteDRAM (512 MiB DDR3)                      │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

## DMA1: LitePCIe DMA (Host ↔ FPGA)

### Characteristics
- **Data Path**: Host RAM ↔ PCIe ↔ FPGA DRAM
- **Bandwidth**: ~1.5 GB/s (Gen2 x4, typical)
- **Latency**: ~10-100 μs (depends on transfer size)
- **Scatter-Gather**: Yes (supports descriptor lists)
- **Interrupts**: MSI/MSI-X on completion

### Control Registers (LitePCIe CSRs, NOT BAR0!)

LitePCIe DMA is controlled via **separate PCI vendor-specific capability space**, not the Hydra BAR0 registers.

Typical register offsets (check LitePCIe docs for exact layout):
```
0x00: DMA_WRITER_BASE     (FPGA addr for writes from host)
0x08: DMA_WRITER_LEN      (bytes to write)
0x10: DMA_WRITER_ENABLE   (start write transfer)
0x14: DMA_WRITER_STATUS   (done, error flags)

0x20: DMA_READER_BASE     (FPGA addr for reads to host)
0x28: DMA_READER_LEN      (bytes to read)
0x30: DMA_READER_ENABLE   (start read transfer)
0x34: DMA_READER_STATUS   (done, error flags)
```

### Driver API

```c
// Example: Upload voxel data from host to FPGA DRAM
uint64_t host_src = (uint64_t)voxel_data;  // Host virtual addr
uint32_t fpga_dst = 0x2000_0000;           // FPGA DRAM offset (voxel region)
uint32_t len = 262144;                      // 64×64×64 × 4 bytes

int ret = litepcie_dma_writer(
    pcie_fd,
    fpga_dst,
    (void*)host_src,
    len,
    /*timeout_ms=*/1000
);

// Example: Read framebuffer from FPGA DRAM to host
uint32_t fpga_src = 0x0000_0000;           // FPGA framebuffer base
uint64_t host_dst = (uint64_t)frame_buf;   // Host virtual addr
uint32_t len = 720 * 480 * 8;              // RGBA32 + reemissure32

int ret = litepcie_dma_reader(
    pcie_fd,
    fpga_src,
    (void*)host_dst,
    len,
    /*timeout_ms=*/1000
);
```

### Use Cases
1. **Scene Upload**: Host prepares 64×64×64 voxel grid, DMAs to FPGA DRAM @ 0x2000_0000
2. **Frame Readback**: Host reads rendered frame from FPGA DRAM @ 0x0000_0000
3. **Texture Streaming**: Host uploads large texture atlas to DRAM for blitter
4. **Debug Dumps**: Host reads FPGA memory regions for debugging

## DMA2: LiteDMA (FPGA-Internal)

### Characteristics
- **Data Path**: FPGA DRAM ↔ FPGA DRAM or FPGA DRAM ↔ BRAM
- **Bandwidth**: ~6.4 GB/s (DDR3-1600, theoretical; ~4 GB/s practical)
- **Latency**: ~1-10 μs (on-chip)
- **Scatter-Gather**: Optional (can be added)
- **Interrupts**: Raises `INT_STATUS.dma_done` on completion

### Control Registers (BAR0 0x0060-0x007F)

These are the registers documented in `docs/hydra_spec.md`:

```
Offset  | Name         | R/W | Description
--------|--------------|-----|------------------------------------------
0x0060  | DMA_SRC      | R/W | Source address (FPGA DRAM byte address)
0x0064  | DMA_DST      | R/W | Destination address (FPGA DRAM byte addr)
0x0068  | DMA_LEN      | R/W | Transfer length in bytes
0x006C  | DMA_CMD      | W   | Command: [2:0] = opcode
        |              |     |   0 = NOP
        |              |     |   1 = MEM2MEM (copy SRC→DST, LEN bytes)
        |              |     |   2 = VOXEL_UPLOAD (DRAM→BRAM, special)
        |              |     |   3 = Reserved (future 3D blitter)
0x0070  | DMA_STATUS   | R   | Status: [0] = busy, [1] = done, [7:2] = err
0x0074  | Reserved     |     |
0x0078  | Reserved     |     |
0x007C  | Reserved     |     |
```

### Driver API

```c
// Example: Copy framebuffer region A → region B (double-buffer swap prep)
ioctl(fd, HYDRA_DMA_SRC, 0x0000_0000);  // Frame A base
ioctl(fd, HYDRA_DMA_DST, 0x1000_0000);  // Frame B base
ioctl(fd, HYDRA_DMA_LEN, 720*480*8);    // RGBA32+reemissure32
ioctl(fd, HYDRA_DMA_CMD, 1);            // MEM2MEM

// Wait for completion (poll or IRQ)
while (ioctl(fd, HYDRA_DMA_STATUS_GET) & 0x1);  // busy bit

// Example: Upload voxels from DRAM to BRAM (after host uploaded via DMA1)
ioctl(fd, HYDRA_DMA_SRC, 0x2000_0000);  // Voxel data in DRAM
ioctl(fd, HYDRA_DMA_DST, 0x0000_0000);  // Ignored (BRAM is implicit)
ioctl(fd, HYDRA_DMA_LEN, 262144);       // 64^3 × 4 bytes
ioctl(fd, HYDRA_DMA_CMD, 2);            // VOXEL_UPLOAD opcode
```

### Use Cases
1. **Voxel Streaming**: After DMA1 uploads voxel data to DRAM, DMA2 copies DRAM→BRAM
2. **Framebuffer Ping-Pong**: Copy rendered frame to secondary buffer for display
3. **Debug Blits**: Copy small memory regions for inspection
4. **Future 3D Blitter**: Fast voxel manipulation (fill, copy, transform)

## Register Semantics Clarification

### BAR0 0x0060 DMA_SRC
- **For DMA2 only** (LiteDMA)
- Physical FPGA DRAM byte address (not host address!)
- Valid range: 0x0000_0000 - 0x1FFF_FFFF (512 MiB)
- Must be 64-byte aligned for best performance

### BAR0 0x006C DMA_CMD Opcodes

#### Opcode 1: MEM2MEM
- Standard memory-to-memory copy
- Reads from `DMA_SRC`, writes to `DMA_DST`, `DMA_LEN` bytes
- No transformations, just byte-for-byte copy

#### Opcode 2: VOXEL_UPLOAD
- Special mode for DRAM → voxel BRAM transfer
- `DMA_SRC`: Source address in DRAM (voxel data, 8 bytes per voxel)
- `DMA_DST`: Ignored (destination is always the 64×64×64 BRAM)
- `DMA_LEN`: Must be exactly 262144 bytes (64³ × 4 bytes per voxel)
- Format: Each voxel is `[material:8, flags:8, R:8, G:8, B:8, emissive:8, ...]`

#### Opcode 3: Reserved (Future 3D Blitter)
- Planned for voxel fill, copy, transform operations
- Will support rect/cube regions, stride, masking

## Implementation Plan

### Step 1: Keep Sim Stub for DMA2
- `voxel_sim_harness` continues to use `axi_dma_stub.sv` for testing
- Validates DMA CSR protocol without needing LiteDMA

### Step 2: Add LiteDMA to FPGA SoC
In `hydra_litex_nexysvideo.py`:

```python
# Add LiteDMA for FPGA-internal moves
from litex.soc.cores.dma import LiteDMA

self.litedma = LiteDMA(
    data_width=64,           # 64-bit AXI bus
    max_burst_length=256,    # 256-beat bursts (2 KiB)
)
self.submodules.litedma = self.litedma

# Connect to AXI crossbar
self.axi_xbar.add_master(name="litedma", master=self.litedma.master)

# Expose LiteDMA CSRs via BAR0 0x0060 region
# (Map LiteDMA's native CSRs to Hydra's DMA_SRC/DST/LEN/CMD layout)
```

### Step 3: Adapt LiteDMA CSRs to Hydra Register Layout

LiteDMA has its own CSR layout, which may not match BAR0 0x0060. Options:

**Option A: Thin RTL Adapter**
- Create `hydra_dma_csr_adapter.sv`:
  - Translates BAR0 0x0060 writes → LiteDMA CSR writes
  - Maps `DMA_CMD` opcodes to LiteDMA control bits
  - Reflects LiteDMA status back to BAR0 0x0070

**Option B: Use LiteDMA Directly, Update UAPI**
- Change `hydra_regs.h` to match LiteDMA's native layout
- Simpler but breaks backwards compatibility

**Recommendation**: Use Option A for first integration, consider Option B for v0.1.0 release.

### Step 4: Add VOXEL_UPLOAD Special Path

Since VOXEL_UPLOAD needs to target BRAM (not DRAM), we need custom logic:

```systemverilog
// In voxel_axi_core.sv or adapter module
wire voxel_upload_active = (dma_cmd_opcode == 3'd2);

// Route DMA reads to BRAM write port instead of DRAM
assign voxel_bram_we = voxel_upload_active && dma_read_valid;
assign voxel_bram_addr = dma_read_addr[17:3];  // 64^3 address space
assign voxel_bram_wdata = dma_read_data;
```

## Driver Integration

### Linux IOCTL Interface

```c
// drivers/linux/uapi/hydra_regs.h

#define HYDRA_IOCTL_DMA_BLIT _IOW('H', 0x10, struct hydra_dma_req)

struct hydra_dma_req {
    uint32_t src;        // FPGA DRAM addr
    uint32_t dst;        // FPGA DRAM addr
    uint32_t len;        // bytes
    uint8_t  opcode;     // 1=MEM2MEM, 2=VOXEL_UPLOAD
    uint8_t  flags;      // reserved
    uint16_t timeout_ms; // 0 = blocking
};

// Example usage:
struct hydra_dma_req req = {
    .src = 0x2000_0000,
    .dst = 0x0000_0000,
    .len = 262144,
    .opcode = 2,  // VOXEL_UPLOAD
    .timeout_ms = 1000,
};
ioctl(fd, HYDRA_IOCTL_DMA_BLIT, &req);
```

### Userspace Helper (libhydra)

```c
// drivers/libhydra/hydra_dma.c

int hydra_dma_blit(struct hydra_device *dev,
                   uint32_t src, uint32_t dst, uint32_t len) {
    struct hydra_dma_req req = {
        .src = src,
        .dst = dst,
        .len = len,
        .opcode = 1,  // MEM2MEM
        .timeout_ms = 5000,
    };
    return ioctl(dev->fd, HYDRA_IOCTL_DMA_BLIT, &req);
}

int hydra_voxel_upload(struct hydra_device *dev, uint32_t dram_addr) {
    struct hydra_dma_req req = {
        .src = dram_addr,
        .dst = 0,  // ignored
        .len = 262144,
        .opcode = 2,  // VOXEL_UPLOAD
        .timeout_ms = 1000,
    };
    return ioctl(dev->fd, HYDRA_IOCTL_DMA_BLIT, &req);
}
```

## Typical Workflow

### Scene Update Example
```
1. Host prepares voxel data in RAM (64³ voxels, 262144 bytes)
2. Host calls litepcie_dma_writer() → uploads to FPGA DRAM @ 0x2000_0000
   [DMA1: Host → FPGA DRAM, ~200 μs @ 1 GB/s]
3. Host calls hydra_voxel_upload(0x2000_0000) → triggers DMA2
   [DMA2: FPGA DRAM → voxel BRAM, ~50 μs @ 5 GB/s]
4. Host writes START_FRAME to BAR0 0x0010 → begins rendering
5. Voxel core renders frame to FPGA DRAM @ 0x0000_0000
6. Host waits for INT_STATUS.frame_done IRQ
7. Host calls litepcie_dma_reader() → reads framebuffer to host RAM
   [DMA1: FPGA DRAM → Host, ~2 ms for 720p frame @ 1 GB/s]
```

Total latency: ~2.5 ms (400 fps theoretical, limited by render time)

## Performance Considerations

### DMA1 (LitePCIe) Bottlenecks
- PCIe Gen2 x4 = 2 GB/s theoretical, ~1.5 GB/s practical
- Latency dominated by PCIe TLP overhead (~10 μs minimum)
- Use large transfers (>4 KiB) to amortize overhead

### DMA2 (LiteDMA) Bottlenecks
- DDR3-1600 = 12.8 GB/s theoretical, ~6-8 GB/s practical (single port)
- AXI crossbar arbitration can add latency if multiple masters active
- Keep burst sizes aligned to DDR3 page boundaries (2 KiB)

### Optimization Tips
1. **Batch voxel uploads**: Update entire 64³ grid in one DMA2 transfer
2. **Double-buffer frames**: Use DMA2 to copy frame while rendering next
3. **Avoid ping-pong**: If host only reads occasionally, no need to copy frames
4. **Profile with counters**: Use AXI crossbar performance counters to identify bottlenecks

## Testing Plan

### 1. DMA1 Test (Host ↔ FPGA)
```bash
# Load LitePCIe driver (separate from Hydra driver)
sudo modprobe litepcie
# Run loopback test: write pattern to DRAM, read back, verify
sudo litepcie_util dma_test
```

### 2. DMA2 Test (FPGA Internal)
```bash
# Load Hydra driver
sudo insmod hydra.ko
# Write test pattern to DRAM via BAR1 mmap
# Trigger DMA2 copy to different region
# Read back via BAR1, verify
sudo ./drivers/linux/tools/hydra_dma_loopback_test
```

### 3. Combined Workflow Test
```bash
# Full scene upload → voxel BRAM → render → readback
sudo ./drivers/linux/tools/hydra_render_pipeline_test
```

## Summary

**Two DMA engines, two purposes**:
- **DMA1 (LitePCIe)**: Host ↔ FPGA, controlled via LitePCIe CSRs
- **DMA2 (LiteDMA)**: FPGA-internal, controlled via BAR0 0x0060-0x007F

**Key takeaways**:
- BAR0 0x0060 registers control DMA2 only
- Host data transfers always use DMA1
- Typical workflow: DMA1 upload → DMA2 BRAM load → render → DMA1 readback

**Next steps**:
- Add LiteDMA to `hydra_litex_nexysvideo.py`
- Create CSR adapter for BAR0 0x0060 compatibility
- Implement VOXEL_UPLOAD special path
- Update driver IOCTL interface
- Write comprehensive DMA tests
