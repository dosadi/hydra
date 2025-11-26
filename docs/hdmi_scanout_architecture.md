# HDMI Scanout Architecture (Phase 5)

## Problem Statement

The current architecture streams pixels directly from the voxel raycaster to the HDMI encoder:

```
voxel_raycaster → pixel_write_en/pixel_data → AXI-Stream → HDMI
```

**This approach has critical flaws**:

1. **Timing Mismatch**: Ray marching is **variable-time** (1-128 steps per pixel), but HDMI is **constant-rate** (74.25 MHz for 720p60)
2. **No Buffering**: If raycaster stalls, HDMI encoder gets garbage or black pixels
3. **Can't Sustain Frame Rate**: Raycaster averages ~500 cycles/pixel @ 100 MHz = 5 ms/frame minimum (200 fps max), but real scenes take 10-50 ms (20-100 fps)
4. **No Display Persistence**: Can't show last rendered frame while next frame renders
5. **Works in Sim Only**: Verilator doesn't enforce real-time constraints; FPGA will produce corrupted output

## Solution: DRAM-Based Scanout with Double-Buffering

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Render Path (Variable Rate)                  │
├─────────────────────────────────────────────────────────────────┤
│  Voxel Raycaster                                                 │
│   └─> pixel_write_en + pixel_data                               │
│         └─> AXI4 Burst Writer ────────┐                          │
│                                        │                          │
│              ┌─────────────────────────┼──────────────────────┐  │
│              │  Framebuffer Region A  (16 MiB)                │  │
│              │   @ DRAM 0x0000_0000                           │  │
│              │  [RGBA32 + reemissure32] × 720 × 480           │  │
│              └─────────────────────────┼──────────────────────┘  │
│                                        │                          │
│              ┌─────────────────────────┼──────────────────────┐  │
│              │  Framebuffer Region B  (16 MiB)                │  │
│              │   @ DRAM 0x1000_0000                           │  │
│              │  [RGBA32 + reemissure32] × 720 × 480           │  │
│              └─────────────────────────┘                         │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Display Path (Constant Rate)                  │
├─────────────────────────────────────────────────────────────────┤
│  HDMI DMA Reader (LiteVideo)                                     │
│   ├─> Reads from DRAM @ display_base (Region A or B)            │
│   ├─> Rate: 74.25 MHz (720p60 pixel clock)                      │
│   ├─> Burst size: 16 pixels (line buffer)                       │
│   └─> AXI4 reads ──> Line Buffer ──> HDMI Encoder ──> Monitor   │
│                                                                   │
│  Swap Logic (triggered by frame_done IRQ):                       │
│   1. Raycaster writes to render_buf (e.g., Region A)            │
│   2. HDMI reads from display_buf (e.g., Region B, last frame)   │
│   3. On frame_done: swap(render_buf, display_buf)               │
│   4. Display shows newly rendered frame immediately             │
└───────────────────────────────────────────────────────────────────┘
```

### Key Benefits
1. **Decoupled Timing**: Render and display run independently
2. **Display Persistence**: HDMI always shows last complete frame
3. **Double-Buffering**: No tearing or partial frames
4. **Variable Frame Rate**: Render can take 5-100 ms; display stays 60 Hz
5. **Works on Real Hardware**: HDMI timing guaranteed by DMA reader

## Implementation Plan

### Step 1: Implement AXI4 Burst Writer in RTL

Currently `voxel_axi_core.sv` lines 100-150 stub out the AXI4 master. Replace with:

```systemverilog
// rtl/voxel_fb_writer.sv (new module)

module voxel_fb_writer #(
    parameter SCREEN_WIDTH = 720,
    parameter SCREEN_HEIGHT = 480
)(
    input  wire         clk,
    input  wire         rst_n,

    // Pixel stream from raycaster
    input  wire         pixel_valid,
    input  wire [31:0]  pixel_addr,      // Linear pixel index
    input  wire [31:0]  pixel_rgb,       // RGBA32
    input  wire [31:0]  pixel_reemissure,// Reemissure sidecar

    // Framebuffer config (from CSRs)
    input  wire [27:0]  fb_base_addr,    // DRAM base (0x0 or 0x1000_0000)
    input  wire [15:0]  fb_stride,       // Bytes per row (usually 720*8)

    // AXI4 master for writes
    output reg  [3:0]   m_axi_awid,
    output reg  [27:0]  m_axi_awaddr,
    output reg  [7:0]   m_axi_awlen,     // Burst length-1
    output reg  [2:0]   m_axi_awsize,    // 3 = 8 bytes
    output reg  [1:0]   m_axi_awburst,   // 1 = INCR
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    output reg  [63:0]  m_axi_wdata,
    output reg  [7:0]   m_axi_wstrb,
    output reg          m_axi_wlast,
    output reg          m_axi_wvalid,
    input  wire         m_axi_wready,
    input  wire [3:0]   m_axi_bid,
    input  wire [1:0]   m_axi_bresp,
    input  wire         m_axi_bvalid,
    output reg          m_axi_bready
);

    // FIFO for pixel buffering (8 entries, 16 beats per burst)
    reg [63:0] pixel_fifo [0:15];
    reg [3:0]  fifo_wptr;
    reg [3:0]  fifo_rptr;
    wire       fifo_full  = (fifo_wptr + 1 == fifo_rptr);
    wire       fifo_empty = (fifo_wptr == fifo_rptr);

    // State machine: IDLE, AW, W, B
    // On pixel_valid: pack RGB+reemissure → 64-bit word, push to FIFO
    // When FIFO has 16 entries: issue AXI burst (awlen=15, 16 beats)
    // Pipeline write data channel while address channel pends

    // Pixel address translation
    wire [27:0] pixel_byte_addr = fb_base_addr + (pixel_addr << 3); // ×8 bytes/pixel

    // TODO: Implement burst FSM (see LiteDRAM examples for burst patterns)

endmodule
```

**Integration**: Instantiate `voxel_fb_writer` in `voxel_axi_core` and connect to `m_axi_*` ports.

### Step 2: Add Framebuffer CSRs to BAR0

Update `voxel_axil_csr.sv` to add framebuffer config registers:

```
Offset  | Name          | R/W | Description
--------|---------------|-----|--------------------------------------------
0x0054  | FB_BASE       | R/W | Framebuffer base address (DRAM byte addr)
        |               |     |   Default: 0x0000_0000 (Region A)
        |               |     |   For double-buffer: alternate 0x0/0x1000_0000
0x0058  | FB_STRIDE     | R/W | Bytes per row (default: 720 × 8 = 5760)
0x005C  | FB_CTRL       | R/W | [0] = swap_on_done (auto-swap buffers)
        |               |     | [1] = clear_on_start (zero FB before render)
```

**Swap Logic**:
```systemverilog
// In voxel_axil_csr.sv or voxel_axi_core.sv
reg fb_region_sel;  // 0 = Region A, 1 = Region B

always @(posedge clk) begin
    if (frame_done && fb_swap_on_done) begin
        fb_region_sel <= ~fb_region_sel;  // Toggle buffer
    end
end

assign fb_base_addr = fb_region_sel ? 28'h1000_000 : 28'h0000_000;
```

### Step 3: Remove Direct AXI-Stream from Raycaster

In `voxel_axi_core.sv`:
- **Remove** `m_axis_tdata/tvalid/tlast/tuser` ports (or make them optional via parameter)
- **Replace** with AXI4 master for framebuffer writes
- **Keep** `m_axis_*` in `voxel_sim_harness` for fast testing (stub captures pixels directly)

### Step 4: Add LiteVideo HDMI with DMA Reader

In `hydra_litex_nexysvideo.py`:

```python
from litevideo.output import VideoOut

# HDMI timing parameters (720p60)
self.video_timings = {
    "pix_clk": 74.25e6,
    "h_active": 1280,
    "h_blanking": 370,
    "h_sync_offset": 220,
    "h_sync_width": 40,
    "v_active": 720,
    "v_blanking": 30,
    "v_sync_offset": 5,
    "v_sync_width": 5,
}

# Video output with DMA reader
self.video_out = VideoOut(
    device=platform.request("hdmi_out"),
    timings=self.video_timings,
    clock_domain="hdmi",  # Separate 74.25 MHz clock
)
self.submodules.video_out = self.video_out

# Connect DMA reader to DRAM via crossbar
self.axi_xbar.add_master(
    name="hdmi_dma",
    master=self.video_out.dma.master,
)

# Framebuffer base address (controlled by Hydra CSRs)
# LiteVideo will read from this address in DRAM
# Connect CSR for dynamic base address update:
self.comb += self.video_out.dma.base.eq(self.hydra.fb_display_base)
```

### Step 5: Implement Double-Buffer Swap

Two approaches for swap logic:

**Approach A: Hardware Auto-Swap** (Recommended)
- On `frame_done` pulse, RTL toggles `fb_region_sel`
- `render_base` = Region A or B (whichever is not being displayed)
- `display_base` = opposite of `render_base`
- Driver reads `FB_BASE` to know where to read pixels (if needed)

**Approach B: Software-Controlled Swap**
- Driver writes `FB_BASE` after receiving `frame_done` IRQ
- More flexible but adds IRQ latency (~100 μs)

**Implementation (Approach A in RTL)**:
```systemverilog
// In voxel_axi_core.sv
reg display_sel;  // 0 = display Region A, 1 = display Region B

always @(posedge clk) begin
    if (frame_done && fb_auto_swap) begin
        display_sel <= ~display_sel;
    end
end

assign render_base  = display_sel ? 28'h0000_000 : 28'h1000_000;
assign display_base = display_sel ? 28'h1000_000 : 28'h0000_000;

// Connect to framebuffer writer
assign fb_writer_base = render_base;

// Expose display_base for LiteVideo DMA (via LiteX interconnect)
// This requires wiring through HydraCore Python wrapper
```

### Step 6: Update `HydraCore` Wrapper

In `hydra_litex_shell.py`, expose framebuffer control signals:

```python
class HydraCore(LiteXModule):
    def __init__(self, ...):
        # ... existing code ...

        # Framebuffer control signals
        self.fb_render_base = Signal(28)   # Where raycaster writes
        self.fb_display_base = Signal(28)  # Where HDMI reads

        self.specials += Instance(
            "voxel_axi_core",
            # ... existing ports ...
            o_fb_render_base=self.fb_render_base,
            o_fb_display_base=self.fb_display_base,
        )
```

Then in board SoC:
```python
# Connect HDMI DMA to display buffer
self.comb += self.video_out.dma.base.eq(self.hydra.fb_display_base)
```

## Memory Layout

### DRAM Regions (512 MiB Total)
```
0x0000_0000 - 0x00FF_FFFF : Framebuffer A (16 MiB)
                             ├─ RGBA32 plane (720×480×4 = 1.32 MiB)
                             └─ Reemissure plane (720×480×4 = 1.32 MiB)
                             (Rest reserved for larger resolutions)

0x1000_0000 - 0x1FFF_FFFF : Framebuffer B (16 MiB)
                             (Same layout as A)

0x2000_0000 - 0x2FFF_FFFF : Voxel data (16 MiB)
                             ├─ Voxel BRAM staging (64³×8 = 2 MiB)
                             └─ Extra voxel LODs / mipmaps

0x3000_0000 - 0x1FFF_FFFF : Host scratch space (464 MiB)
```

### Pixel Format in DRAM
Each pixel is **8 bytes** (64 bits):
```
Bits [63:32]: reemissure32
  [31:24]: R
  [23:16]: G
  [15:8]:  B
  [7:0]:   material/flags
```

**Note**: HDMI only needs RGB24. The DMA reader extracts `[31:8]` for display.

## Performance Analysis

### Bandwidth Requirements

**Raycaster Write (Variable Rate)**:
- 720 × 480 pixels × 8 bytes/pixel = 2.66 MiB/frame
- At 100 fps: 266 MB/s (peak, but bursty)
- Actual: 5-50 fps → 13-133 MB/s average

**HDMI Read (Constant Rate)**:
- 720 × 480 pixels × 8 bytes/pixel × 60 fps = 160 MB/s
- Actually only need RGB24 → could optimize to 4 bytes/pixel → 80 MB/s

**Total DRAM Bandwidth Used**:
- Write: ~50 MB/s (average case, 20 fps render)
- Read: 160 MB/s (HDMI scanout)
- **Total: ~210 MB/s** out of 6.4 GB/s available → **3.3% utilization**

**Conclusion**: Bandwidth is not a bottleneck. DRAM has plenty of headroom for DMA1, DMA2, and other masters.

### Latency Considerations

**Frame Display Latency** (time from frame_done to visible on monitor):
- Buffer swap: 0 cycles (auto-swap on frame_done)
- HDMI DMA reaction: < 1 scanline (< 20 μs)
- Monitor input lag: 1-3 frames (16-50 ms, depends on display)

**Total: ~16-50 ms latency** (dominated by monitor, not FPGA)

For interactive applications, this is acceptable. For VR/gaming, consider:
- Reducing monitor lag (gaming displays: ~5 ms)
- Using VSync/FreeSync for tear-free updates

## Testing Strategy

### 1. Framebuffer Write Test (No HDMI)
```bash
# Render single frame, read back via BAR1 mmap
sudo ./tools/hydra_fb_write_test
# Verify pixel data in DRAM matches expected
```

### 2. HDMI Static Pattern Test
```bash
# Write test pattern to Region A via BAR1
# Set display_base = Region A
# Verify monitor shows pattern (no raycaster involved)
sudo ./tools/hdmi_pattern_test
```

### 3. Double-Buffer Swap Test
```bash
# Write pattern A to Region A, pattern B to Region B
# Toggle FB_BASE every second
# Verify monitor alternates between patterns
sudo ./tools/hdmi_swap_test
```

### 4. Full Render + Display Test
```bash
# Render frame to Region A
# HDMI displays Region B (previous frame)
# On frame_done, swap
# Verify smooth animation
sudo ./tools/hydra_interactive_test
```

### 5. Frame Rate Measurement
```bash
# Render continuously, measure frame_done IRQ rate
# Verify HDMI shows all frames without tearing
sudo ./tools/hydra_fps_benchmark
```

## Migration Notes

### Simulation (No Changes Needed)
- `voxel_sim_harness` keeps direct `axi_stream_sink_stub` for fast testing
- Verilator tests still use `pixel_write_en` capture (no DRAM involved)
- Golden frame test (`test_frame`) unchanged

### FPGA (New Build Required)
- Must implement `voxel_fb_writer.sv`
- Must add `FB_BASE`/`FB_STRIDE` CSRs
- Must wire LiteVideo HDMI with DMA reader
- Build time increase: ~5-10% (due to AXI burst writer logic)

### Driver (Minor Updates)
- Add mmap support for BAR1 (if not already present)
- Optionally expose `FB_BASE` as read-only sysfs attribute
- No IOCTL changes needed (auto-swap handles everything)

## Pixel Packing and CRC (simulation path)

- Pixel format: 24-bit RGB888 packed into `m_axis_tdata[23:0]` as `{R[23:16], G[15:8], B[7:0]}`. No alpha is sent on the HDMI stream.
- SOF/EOF: `m_axis_tuser` is asserted on the first pixel of a frame (addr 0), and `m_axis_tlast` on the final pixel (`TOTAL_PIXELS-1`).
- CRC: The current sink accumulates a simple XOR of `m_axis_tdata` across a frame, reset on SOF. The HDMI_CRC CSR mirrors this accumulator for regression checks; hardware should replace this with encoder-side CRC/test patterns.
- Counters: `HDMI_FR`, `HDMI_LINE`, and `HDMI_PIX` advance only on `axis_fire` (valid && ready) and reset on SOF. They are exposed via CSRs for cocotb/RTL benches.

## Known Limitations and Future Work

### Limitation 1: Single Display Output
Current design supports one HDMI output. For multi-display:
- Add second LiteVideo instance
- Either: duplicate frames (read same DRAM region)
- Or: render to separate regions (A1/B1 for display 1, A2/B2 for display 2)

### Limitation 2: No Overlay Support
All pixels written by raycaster. For UI overlays:
- Reserve Region C for overlay buffer
- Use DMA2 blitter to composite A+C → B before display
- Or: use LiteVideo's built-in overlay mixer (if available)

### Limitation 3: Fixed Resolution
720×480 hardcoded in RTL. For dynamic resolution:
- Make `SCREEN_WIDTH`/`HEIGHT` CSRs instead of parameters
- Reconfigure LiteVideo timings at runtime (requires clock domain handling)

### Future: Triple-Buffering
For even smoother frame pacing:
- Add Region C (third buffer)
- Raycaster writes to C while HDMI reads from B (A is idle)
- On frame_done: A ← B ← C, start rendering to A

## Summary

**Phase 5 transforms HDMI output from broken to production-ready**:

✅ **Before**: Direct pixel streaming (works in sim, fails on FPGA)
✅ **After**: DRAM-based scanout with double-buffering

**Key changes**:
1. Implement AXI4 burst writer for framebuffer writes
2. Add FB_BASE/FB_STRIDE CSRs for buffer control
3. Remove direct AXI-Stream from voxel core
4. Add LiteVideo HDMI with DMA reader
5. Implement auto-swap logic for seamless frame updates

**Benefits**:
- Guaranteed HDMI timing (no glitches/tearing)
- Variable render rate (5-100 fps) with fixed display (60 Hz)
- Display persistence (always shows last complete frame)
- Low DRAM bandwidth usage (~3%)

**Next steps**:
- Implement `voxel_fb_writer.sv` burst FSM
- Add framebuffer CSRs to `voxel_axil_csr.sv`
- Wire up LiteVideo in `hydra_litex_nexysvideo.py`
- Test on real hardware with monitor
