# RTL Signal Reference

This document provides a comprehensive reference for the signal naming conventions and prefixes used throughout the Hydra RTL codebase. Understanding these conventions is essential for RTL contributors and maintainers.

## Signal Prefix Conventions

Hydra uses consistent signal prefixes to categorize related functionality and improve code readability. All prefixes are lowercase and followed by an underscore.

### Core Signal Categories

#### Camera Signals (`cam_`)
Camera-related parameters and position vectors used for ray casting.

**Examples:**
- `cam_x`, `cam_y`, `cam_z` - Camera position coordinates (signed 16-bit)
- `cam_dir_x`, `cam_dir_y`, `cam_dir_z` - Camera viewing direction vector
- `cam_plane_x`, `cam_plane_y` - Camera projection plane vectors
- `cam_load_pulse` - Pulse to load new camera parameters into ray caster

**Usage:**
```systemverilog
output reg signed [15:0] cam_x, cam_y, cam_z;
output reg signed [15:0] cam_dir_x, cam_dir_y, cam_dir_z;
output reg signed [15:0] cam_plane_x, cam_plane_y;
output reg              cam_load_pulse;
```

#### Selection Signals (`sel_`)
Voxel selection coordinates for editing and inspection.

**Examples:**
- `sel_active` - Whether voxel selection is enabled
- `sel_x`, `sel_y`, `sel_z` - Selected voxel coordinates (6-bit, 0-63 range)
- `sel_load_pulse` - Pulse to load new selection coordinates

**Usage:**
```systemverilog
output reg         sel_active;
output reg [5:0]   sel_x, sel_y, sel_z;
output reg         sel_load_pulse;
```

#### Debug Signals (`dbg_`)
Debug interface for direct voxel memory access and inspection.

**Examples:**
- `dbg_we_pulse` - Write enable pulse for debug writes
- `dbg_addr` - Debug access address (18-bit for 256K voxel memory)
- `dbg_wdata` - Debug write data (64-bit for voxel + metadata)
- `dbg_data_lo`, `dbg_data_hi` - Split 32-bit debug data registers

**Usage:**
```systemverilog
output reg         dbg_we_pulse;
output reg [17:0]  dbg_addr;
output reg [63:0]  dbg_wdata;
reg [31:0]         dbg_data_lo, dbg_data_hi;
```

#### Configuration Flags (`flag_`)
Rendering configuration flags that control visual quality and features.

**Examples:**
- `flag_smooth` - Enable smooth surface rendering (anti-aliasing)
- `flag_curvature` - Enable curvature-based lighting
- `flag_extra_light` - Enable additional lighting effects
- `flag_diag_slice` - Enable diagonal slice rendering mode
- `flag_ray_jitter` - Enable ray jittering for anti-aliasing

**Usage:**
```systemverilog
output reg flag_smooth, flag_curvature, flag_extra_light;
output reg flag_diag_slice, flag_ray_jitter;
```

#### DMA Signals (`dma_`)
DMA (Direct Memory Access) control and status signals.

**Examples:**
- `dma_start_pulse` - Pulse to initiate DMA transfer
- `dma_busy_in` - DMA engine busy status input
- `dma_done_in` - DMA completion status input
- `dma_err_in` - DMA error status input
- `dma_src`, `dma_dst`, `dma_len` - Transfer parameters
- `dma_status` - Combined status register (bit0=busy, bit1=done, bit2=err)

**Usage:**
```systemverilog
output reg         dma_start_pulse;
input  wire        dma_busy_in, dma_done_in, dma_err_in;
output reg [31:0]  dma_src, dma_dst, dma_len, dma_status;
```

#### Blitter Signals (`blit_`)
2D blitter operations for texture and surface processing.

**Examples:**
- `blit_ctrl` - Blitter control register (operation type, flags)
- `blit_busy`, `blit_done` - Operation status
- `blit_src`, `blit_dst`, `blit_len` - Transfer parameters
- `blit_stride` - Memory stride for 2D operations
- `blit_pix_addr`, `blit_pix_data` - Pixel memory access
- `blit_obj_idx`, `blit_obj_attr` - Object attribute access
- `blit_fifo_*` - Command FIFO for batched operations

**Usage:**
```systemverilog
reg [31:0] blit_ctrl, blit_status, blit_src, blit_dst, blit_len;
reg [31:0] blit_stride, blit_pix_data;
reg [15:0] blit_pix_addr;
reg [5:0]  blit_obj_idx;
reg [31:0] blit_obj_attr;
```

#### Region Signals (`region0_`)
Automatic region extraction for surface analysis.

**Examples:**
- `region0_cfg` - Configuration register (enable, kick bit)
- `region0_min`, `region0_max` - Bounding box coordinates
- `region0_status` - Operation status (busy, valid, done)
- `region0_surf_stats` - Extracted surface statistics

**Usage:**
```systemverilog
reg [31:0] region0_cfg, region0_min, region0_max;
reg [31:0] region0_status, region0_surf_stats;
```

#### HDMI Signals (`hdmi_`)
HDMI output status and monitoring.

**Examples:**
- `hdmi_crc_in` - HDMI frame CRC for validation
- `hdmi_frames_in` - Frame counter
- `hdmi_line_in` - Current scanline number
- `hdmi_pix_in` - Current pixel position

**Usage:**
```systemverilog
input  wire [31:0] hdmi_crc_in, hdmi_frames_in;
input  wire [15:0] hdmi_line_in, hdmi_pix_in;
```

#### Interrupt Signals (`int_`)
Interrupt control and status.

**Examples:**
- `int_status` - Interrupt status register (32-bit, write-1-to-clear)
- `int_mask` - Interrupt mask register (enables specific interrupts)
- `irq_out` - Combined interrupt output (wired OR of masked status bits)

**Usage:**
```systemverilog
reg [31:0] int_status, int_mask;
wire       irq_out = |(int_status & int_mask);
```

#### Framebuffer Signals (`fb_`)
Framebuffer configuration parameters.

**Examples:**
- `fb_base` - Framebuffer base address in system memory
- `fb_stride` - Bytes per scanline (for proper memory layout)

**Usage:**
```systemverilog
reg [31:0] fb_base, fb_stride;
```

## Signal Naming Patterns

### Pulse Signals
Control signals that trigger actions use `_pulse` suffix:
```systemverilog
cam_load_pulse     // Load camera parameters
sel_load_pulse     // Load selection coordinates
dbg_we_pulse       // Debug write enable
dma_start_pulse    // Start DMA transfer
start_frame_pulse  // Begin frame rendering
soft_reset_pulse   // Trigger soft reset
```

### Status Signals
Status indicators use `_in` suffix for inputs, bare names for outputs:
```systemverilog
dma_busy_in        // DMA busy status input
dma_done_in        // DMA completion input
dma_err_in         // DMA error input
core_busy          // Ray caster busy output
frame_done_pulse   // Frame completion output
```

### Memory Access Signals
Memory interface signals follow standard naming:
```systemverilog
blit_mem_we        // Write enable
blit_mem_re        // Read enable
blit_mem_addr      // Address
blit_mem_wdata     // Write data
blit_mem_rdata     // Read data (input)
```

### AXI-Lite Signals
AXI-Lite interface follows standard ARM naming conventions:
```systemverilog
s_axil_awaddr      // Write address
s_axil_awvalid     // Write address valid
s_axil_awready     // Write address ready
s_axil_wdata       // Write data
s_axil_wstrb       // Write strobe
s_axil_wvalid      // Write data valid
s_axil_wready      // Write data ready
s_axil_bresp       // Write response
s_axil_bvalid      // Write response valid
s_axil_bready      // Write response ready
// ... (similar for read channel)
```

## Module-Specific Conventions

### CSR Module (`voxel_axil_csr.sv`)
- Uses `W_` prefix for register word offsets (e.g., `W_CAM_X`, `W_STATUS`)
- Control pulses derived from `CTRL` register bits
- Status word combines multiple status sources
- Interrupt status bits are write-1-to-clear (W1C)

### Ray Caster Core (`voxel_raycaster_core_pipelined.sv`)
- Uses `render_config` vector for flag inputs
- Jitter calculations use `jitter_sel_` for pixel-based selection
- Ray marching uses accumulator width `ACC_WIDTH` parameter

### CDC Synchronizer (`cdc_synchronizer.sv`)
- Uses `src_` and `dst_` prefixes for clock domain signals
- Pulse extenders use `_ext` suffix
- Synchronizers use `_sync` suffix

## Best Practices

### When Adding New Signals
1. **Choose appropriate prefix** from existing categories
2. **Use consistent suffixes** (`_pulse`, `_in`, `_out`, etc.)
3. **Follow bit width conventions** (16-bit for camera, 6-bit for voxel coords)
4. **Document new prefixes** in this reference if introducing new categories

### Signal Declaration Order
```systemverilog
// Inputs first (by prefix group)
input  wire signed [15:0] cam_dir_x, cam_dir_y, cam_dir_z;
input  wire [5:0]         sel_voxel_x, sel_voxel_y, sel_voxel_z;
input  wire               dma_busy_in, dma_done_in;

// Outputs second (by prefix group)
output reg  signed [15:0] cam_x, cam_y, cam_z;
output reg                sel_active;
output reg                dma_start_pulse;

// Internal signals (wires and regs)
wire                      cam_load_active;
reg  [31:0]               dma_status;
```

### Avoiding Name Conflicts
- Use full prefix + descriptive name (e.g., `cam_pos_x` not just `x`)
- Reserve generic names for local use only
- Check existing usage before adding new signals

## Common Mistakes to Avoid

1. **Missing prefixes**: `x_pos` instead of `cam_x`
2. **Inconsistent suffixes**: `load` instead of `load_pulse`
3. **Wrong bit widths**: Using 32-bit for voxel coordinates (should be 6-bit)
4. **AXI naming errors**: `awvalid` instead of `s_axil_awvalid`

## Cross-References

- **CSR Register Map**: See `docs/hydra_spec.md` for register definitions
- **Interrupt Handling**: See `docs/hydra_spec.md` section on INT_STATUS/INT_MASK
- **DMA Protocol**: See `docs/dma_architecture.md` for DMA operation details
- **AXI-Lite Protocol**: See `docs/hydra_spec.md` for AXI-Lite interface specification

---

**Document Version:** 1.0
**Last Updated:** 2025-11-26
**Related Files:** `rtl/*.sv`, `docs/hydra_spec.md`