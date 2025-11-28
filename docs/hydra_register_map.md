# Hydra Register Map Reference

This document provides the definitive register map for Hydra's FPGA graphics accelerator, covering BAR0/BAR1/AXI registers, memory layout, and firmware expectations.

## Overview

Hydra exposes multiple register interfaces for configuration, control, and status monitoring:

- **BAR0 (PCIe Base Address Register 0)**: Control and status registers (4KB)
- **BAR1 (PCIe Base Address Register 1)**: Frame buffer and graphics memory (16MB)
- **AXI-Lite Interface**: Internal CSR (Control/Status Register) access
- **AXI-Stream Interfaces**: High-speed data transfer for pixel and vertex data

## BAR0 Register Map

BAR0 provides access to control registers, status monitoring, and DMA configuration. All registers are 32-bit wide and must be accessed as 32-bit words.

### Base Address and Size
- **Base Address**: Assigned by PCIe enumeration (typically 0xF0000000 or similar)
- **Size**: 4KB (0x1000 bytes)
- **Access**: Memory-mapped I/O, 32-bit aligned accesses only

### Register Layout

| Offset | Name | Access | Reset Value | Description |
|--------|------|--------|-------------|-------------|
| 0x000 | IDENT | RO | 0x48594452 | Identification register ("HYDR") |
| 0x004 | VERSION | RO | 0x00000700 | Version register (major.minor.patch) |
| 0x008 | CAPABILITIES | RO | 0x0000000F | Capability flags |
| 0x00C | STATUS | RO | 0x00000000 | Global status register |
| 0x010 | CONTROL | RW | 0x00000000 | Global control register |
| 0x014 | INTERRUPT_ENABLE | RW | 0x00000000 | Interrupt enable mask |
| 0x018 | INTERRUPT_STATUS | RW | 0x00000000 | Interrupt status register |
| 0x01C | INTERRUPT_MASK | RW | 0xFFFFFFFF | Interrupt mask register |
| 0x020 | RESET_CONTROL | RW | 0x00000000 | Reset control register |
| 0x024 | CLOCK_CONTROL | RW | 0x00000000 | Clock control register |
| 0x028 | POWER_CONTROL | RW | 0x00000000 | Power management control |
| 0x02C | TEMPERATURE | RO | 0x00000000 | Temperature sensor reading |
| 0x030-0x0FC | Reserved | - | 0x00000000 | Reserved for future use |

### Graphics Pipeline Registers (0x100-0x1FC)

| Offset | Name | Access | Reset Value | Description |
|--------|------|--------|-------------|-------------|
| 0x100 | RENDER_CONTROL | RW | 0x00000000 | Rendering pipeline control |
| 0x104 | RENDER_STATUS | RO | 0x00000000 | Rendering pipeline status |
| 0x108 | FRAMEBUFFER_BASE | RW | 0x00000000 | Frame buffer base address (BAR1 offset) |
| 0x10C | FRAMEBUFFER_SIZE | RW | 0x00800000 | Frame buffer size in bytes |
| 0x110 | DISPLAY_WIDTH | RW | 0x00000780 | Display width in pixels (default 1920) |
| 0x114 | DISPLAY_HEIGHT | RW | 0x00000438 | Display height in pixels (default 1080) |
| 0x118 | DISPLAY_FORMAT | RW | 0x00000000 | Display pixel format |
| 0x11C | VSYNC_CONTROL | RW | 0x00000000 | VSync timing control |
| 0x120 | CAMERA_POSITION_X | RW | 0x00000000 | Camera X position (32.32 fixed point) |
| 0x124 | CAMERA_POSITION_Y | RW | 0x00000000 | Camera Y position (32.32 fixed point) |
| 0x128 | CAMERA_POSITION_Z | RW | 0x00000000 | Camera Z position (32.32 fixed point) |
| 0x12C | CAMERA_ROTATION_X | RW | 0x00000000 | Camera X rotation (16.16 fixed point) |
| 0x130 | CAMERA_ROTATION_Y | RW | 0x00000000 | Camera Y rotation (16.16 fixed point) |
| 0x134 | CAMERA_ROTATION_Z | RW | 0x00000000 | Camera Z rotation (16.16 fixed point) |
| 0x138 | PROJECTION_FOV | RW | 0x40000000 | Field of view (16.16 fixed point, default 90°) |
| 0x13C | PROJECTION_NEAR | RW | 0x00010000 | Near clipping plane (16.16 fixed point) |
| 0x140 | PROJECTION_FAR | RW | 0x4E200000 | Far clipping plane (16.16 fixed point) |
| 0x144 | LIGHTING_CONTROL | RW | 0x00000001 | Lighting enable/control |
| 0x148 | LIGHT_POSITION_X | RW | 0x00000000 | Light X position (32.32 fixed point) |
| 0x14C | LIGHT_POSITION_Y | RW | 0x00000000 | Light Y position (32.32 fixed point) |
| 0x150 | LIGHT_POSITION_Z | RW | 0x00000000 | Light Z position (32.32 fixed point) |
| 0x154 | LIGHT_COLOR_R | RW | 0x0000FFFF | Light red component (16.16 fixed point) |
| 0x158 | LIGHT_COLOR_G | RW | 0x0000FFFF | Light green component (16.16 fixed point) |
| 0x15C | LIGHT_COLOR_B | RW | 0x0000FFFF | Light blue component (16.16 fixed point) |
| 0x160 | FOG_CONTROL | RW | 0x00000000 | Fog effect control |
| 0x164 | FOG_COLOR_R | RW | 0x00008000 | Fog red component (16.16 fixed point) |
| 0x168 | FOG_COLOR_G | RW | 0x00008000 | Fog green component (16.16 fixed point) |
| 0x16C | FOG_COLOR_B | RW | 0x00008000 | Fog blue component (16.16 fixed point) |
| 0x170 | FOG_DENSITY | RW | 0x00002000 | Fog density (16.16 fixed point) |
| 0x174 | TEXTURE_CONTROL | RW | 0x00000001 | Texture mapping control |
| 0x178 | MIPMAP_CONTROL | RW | 0x00000000 | Mipmap generation control |
| 0x17C | BLEND_CONTROL | RW | 0x00000000 | Alpha blending control |
| 0x180 | DEPTH_CONTROL | RW | 0x00000001 | Depth testing control |
| 0x184 | CULL_CONTROL | RW | 0x00000001 | Backface culling control |
| 0x188 | WIREFRAME_CONTROL | RW | 0x00000000 | Wireframe rendering control |
| 0x18C | DEBUG_OVERLAY | RW | 0x00000000 | Debug overlay control |
| 0x190-0x1FC | Reserved | - | 0x00000000 | Reserved for future graphics features |

### DMA Registers (0x200-0x2FC)

| Offset | Name | Access | Reset Value | Description |
|--------|------|--------|-------------|-------------|
| 0x200 | DMA_CONTROL | RW | 0x00000000 | DMA engine control |
| 0x204 | DMA_STATUS | RO | 0x00000000 | DMA engine status |
| 0x208 | DMA_DESC_BASE_LOW | RW | 0x00000000 | DMA descriptor base address (low 32 bits) |
| 0x20C | DMA_DESC_BASE_HIGH | RW | 0x00000000 | DMA descriptor base address (high 32 bits) |
| 0x210 | DMA_DESC_COUNT | RW | 0x00000000 | Number of descriptors in chain |
| 0x214 | DMA_BURST_SIZE | RW | 0x00000080 | DMA burst size in bytes (default 128) |
| 0x218 | DMA_TIMEOUT | RW | 0x000F4240 | DMA transfer timeout in cycles (default 1M) |
| 0x21C | DMA_COMPLETED_COUNT | RO | 0x00000000 | Number of completed DMA transfers |
| 0x220 | DMA_ERROR_COUNT | RO | 0x00000000 | Number of DMA errors |
| 0x224 | DMA_BYTES_TRANSFERRED_LOW | RO | 0x00000000 | Total bytes transferred (low 32 bits) |
| 0x228 | DMA_BYTES_TRANSFERRED_HIGH | RO | 0x00000000 | Total bytes transferred (high 32 bits) |
| 0x22C-0x2FC | Reserved | - | 0x00000000 | Reserved for future DMA features |

### Performance Monitoring (0x300-0x3FC)

| Offset | Name | Access | Reset Value | Description |
|--------|------|--------|-------------|-------------|
| 0x300 | PERF_FRAME_COUNT | RO | 0x00000000 | Total frames rendered |
| 0x304 | PERF_FRAME_TIME | RO | 0x00000000 | Last frame render time in cycles |
| 0x308 | PERF_FRAME_TIME_MIN | RO | 0x00000000 | Minimum frame render time |
| 0x309 | PERF_FRAME_TIME_MAX | RO | 0x00000000 | Maximum frame render time |
| 0x30C | PERF_FRAME_TIME_AVG | RO | 0x00000000 | Average frame render time |
| 0x310 | PERF_VOXEL_COUNT | RO | 0x00000000 | Voxels processed last frame |
| 0x314 | PERF_TRIANGLE_COUNT | RO | 0x00000000 | Triangles processed last frame |
| 0x318 | PERF_PIXEL_COUNT | RO | 0x00000000 | Pixels rendered last frame |
| 0x31C | PERF_TEXTURE_FETCHES | RO | 0x00000000 | Texture fetches last frame |
| 0x320 | PERF_CACHE_HITS | RO | 0x00000000 | Cache hits last frame |
| 0x324 | PERF_CACHE_MISSES | RO | 0x00000000 | Cache misses last frame |
| 0x328 | PERF_CLOCK_CYCLES | RO | 0x00000000 | Total clock cycles since reset |
| 0x32C | PERF_BUSY_CYCLES | RO | 0x00000000 | Busy clock cycles |
| 0x330-0x3FC | Reserved | - | 0x00000000 | Reserved for additional metrics |

### Debug and Test Registers (0x400-0x4FC)

| Offset | Name | Access | Reset Value | Description |
|--------|------|--------|-------------|-------------|
| 0x400 | DEBUG_CONTROL | RW | 0x00000000 | Debug feature enable |
| 0x404 | DEBUG_BREAKPOINT | RW | 0x00000000 | Debug breakpoint control |
| 0x408 | DEBUG_WATCHPOINT | RW | 0x00000000 | Debug watchpoint control |
| 0x40C | DEBUG_TRACE_CONTROL | RW | 0x00000000 | Trace buffer control |
| 0x410 | DEBUG_TRACE_STATUS | RO | 0x00000000 | Trace buffer status |
| 0x414 | DEBUG_TRACE_READ | RO | 0x00000000 | Trace buffer read port |
| 0x418 | TEST_PATTERN_CONTROL | RW | 0x00000000 | Test pattern generation |
| 0x41C | TEST_PATTERN_STATUS | RO | 0x00000000 | Test pattern status |
| 0x420-0x4FC | Reserved | - | 0x00000000 | Reserved for debug features |

## BAR1 Memory Map

BAR1 provides direct access to graphics memory regions including frame buffers, textures, and vertex data.

### Base Address and Size
- **Base Address**: Assigned by PCIe enumeration (typically 0xF1000000 or similar)
- **Size**: 16MB (0x01000000 bytes)
- **Access**: Memory-mapped I/O, supports various access sizes

### Memory Layout

| Address Range | Size | Description | Access Pattern |
|---------------|------|-------------|----------------|
| 0x00000000-0x007FFFFF | 8MB | Frame Buffer | 32-bit RGBA pixels |
| 0x00800000-0x017FFFFF | 16MB | Texture Memory | 32-bit RGBA texels |
| 0x01800000-0x01BFFFFF | 4MB | Vertex Buffer | 32-bit float vectors |
| 0x01C00000-0x01FFFFFF | 4MB | Command Buffer | 128-bit command packets |

### Frame Buffer Organization

The frame buffer uses 32-bit RGBA pixels in row-major order:

```
Pixel Address = base + (y * width + x) * 4

Pixel Format (32-bit):
Bits 31-24: Alpha (A)
Bits 23-16: Red (R)
Bits 15-8:  Green (G)
Bits 7-0:   Blue (B)
```

### Texture Memory Organization

Textures are stored as 32-bit RGBA texels with configurable dimensions:

```
Texel Address = texture_base + (level * level_size) + (y * width + x) * 4

Mipmap Level Size = width * height * 4 bytes
```

### Vertex Buffer Organization

Vertex data uses 32-bit floating point coordinates:

```
Vertex Structure (96 bits = 3 floats):
Float X: X coordinate (-1.0 to 1.0)
Float Y: Y coordinate (-1.0 to 1.0)
Float Z: Z coordinate (-1.0 to 1.0)

Vertex Address = vertex_base + vertex_index * 12
```

## AXI-Lite CSR Interface

The internal AXI-Lite interface provides access to the same registers as BAR0, optimized for FPGA-internal access.

### Interface Specifications
- **Data Width**: 32 bits
- **Address Width**: 12 bits (4KB address space)
- **Clock Domain**: Core clock (typically 100MHz)
- **Latency**: 1-2 cycles for register access

### Address Mapping
AXI-Lite addresses directly correspond to BAR0 offsets:
- AXI Address = BAR0 Offset
- All registers accessible with 32-bit read/write operations

## AXI-Stream Interfaces

Hydra uses AXI-Stream interfaces for high-speed data transfer.

### Pixel Stream (Output)
- **Direction**: FPGA → Host
- **Data Width**: 32 bits (RGBA pixel)
- **TID Width**: 4 bits (frame buffer ID)
- **TDEST Width**: 4 bits (display output)
- **Clock**: Pixel clock (148.5MHz for 1080p60)

### Vertex Stream (Input)
- **Direction**: Host → FPGA
- **Data Width**: 96 bits (X,Y,Z coordinates)
- **TID Width**: 4 bits (vertex buffer ID)
- **TDEST Width**: 4 bits (processing unit)
- **Clock**: Core clock (100MHz)

### Command Stream (Input)
- **Direction**: Host → FPGA
- **Data Width**: 128 bits (command packet)
- **TID Width**: 4 bits (command type)
- **TDEST Width**: 4 bits (target unit)
- **Clock**: Core clock (100MHz)

## Register Bit Field Definitions

### IDENT Register (0x000)
```
Bits 31-0: ASCII "HYDR" (0x48594452)
```

### VERSION Register (0x004)
```
Bits 31-24: Major version
Bits 23-16: Minor version
Bits 15-8:  Patch version
Bits 7-0:   Reserved
```

### CAPABILITIES Register (0x008)
```
Bit 0: DMA support
Bit 1: Texture mapping
Bit 2: Lighting
Bit 3: Fog effects
Bits 31-4: Reserved
```

### STATUS Register (0x00C)
```
Bit 0: Ready (1 = device ready)
Bit 1: Busy (1 = rendering in progress)
Bit 2: Error (1 = error condition)
Bit 3: Frame complete (1 = frame finished)
Bits 31-4: Reserved
```

### CONTROL Register (0x010)
```
Bit 0: Enable rendering (1 = start, 0 = stop)
Bit 1: Reset pipeline (1 = reset, auto-clear)
Bit 2: Clear frame buffer (1 = clear, auto-clear)
Bit 3: VSync enable
Bits 31-4: Reserved
```

### INTERRUPT_ENABLE Register (0x014)
```
Bit 0: Frame complete interrupt enable
Bit 1: DMA complete interrupt enable
Bit 2: Error interrupt enable
Bit 3: VSync interrupt enable
Bits 31-4: Reserved
```

### INTERRUPT_STATUS Register (0x018)
```
Bit 0: Frame complete interrupt (write 1 to clear)
Bit 1: DMA complete interrupt (write 1 to clear)
Bit 2: Error interrupt (write 1 to clear)
Bit 3: VSync interrupt (write 1 to clear)
Bits 31-4: Reserved
```

### INTERRUPT_MASK Register (0x01C)
```
Bit 0: Frame complete interrupt mask (1 = masked)
Bit 1: DMA complete interrupt mask (1 = masked)
Bit 2: Error interrupt mask (1 = masked)
Bit 3: VSync interrupt mask (1 = masked)
Bits 31-4: Reserved
```

### RENDER_CONTROL Register (0x100)
```
Bit 0: Enable rendering pipeline
Bit 1: Enable texture mapping
Bit 2: Enable lighting
Bit 3: Enable fog
Bit 4: Enable depth testing
Bit 5: Enable backface culling
Bit 6: Wireframe mode
Bit 7: Debug overlay
Bits 31-8: Reserved
```

### DISPLAY_FORMAT Register (0x118)
```
Bits 3-0: Pixel format
  0 = RGBA8888
  1 = RGB565
  2 = RGBA4444
  3 = RGB888
Bits 31-4: Reserved
```

### DMA_CONTROL Register (0x200)
```
Bit 0: DMA enable
Bit 1: Start transfer (auto-clear)
Bit 2: Abort transfer (auto-clear)
Bit 3: Reset DMA engine (auto-clear)
Bits 31-4: Reserved
```

### DMA_STATUS Register (0x204)
```
Bit 0: DMA ready
Bit 1: Transfer in progress
Bit 2: Transfer complete
Bit 3: Transfer error
Bits 15-4: Current descriptor index
Bits 31-16: Reserved
```

## Firmware Expectations

### Initialization Sequence

1. **Power-on Reset**: All registers return to reset values
2. **Identification**: Read IDENT register to verify device presence
3. **Version Check**: Read VERSION register for compatibility
4. **Capability Query**: Read CAPABILITIES register for feature support
5. **Configuration**: Set up display parameters, camera, lighting
6. **Memory Setup**: Configure frame buffer and texture memory regions
7. **Enable Operation**: Set CONTROL register to enable rendering

### Runtime Operation

1. **Frame Rendering**: Monitor STATUS register for frame completion
2. **Interrupt Handling**: Service interrupts based on INTERRUPT_STATUS
3. **Error Recovery**: Check for errors and perform recovery as needed
4. **Performance Monitoring**: Read performance counters for optimization
5. **DMA Operations**: Use DMA registers for bulk data transfer

### Shutdown Sequence

1. **Stop Rendering**: Clear CONTROL register enable bit
2. **Flush Operations**: Wait for all pending operations to complete
3. **Disable Interrupts**: Mask all interrupts
4. **Power Down**: Set POWER_CONTROL register appropriately

## AI Automation Integration

This register map is designed to integrate with AI automation systems for:

### Automated Documentation Updates
- Register definitions automatically extracted from RTL source
- Documentation updated when registers are added/modified
- Cross-references maintained between spec and implementation

### TODO Generation
- Missing register documentation flagged as TODO items
- Implementation gaps identified automatically
- Test coverage gaps highlighted

### Validation Scripts
- Register access validation against this specification
- Reset value verification
- Bit field consistency checking

## Migration Notes

### From Previous Versions

#### Version 0.0.6 to 0.0.7
- Added performance monitoring registers (0x300-0x3FC)
- Extended graphics pipeline controls
- Enhanced DMA status reporting
- Improved interrupt handling

#### Breaking Changes
- Some register offsets may have changed
- New required initialization steps
- Modified reset values for certain registers

### Compatibility Matrix

| Feature | 0.0.6 | 0.0.7 |
|---------|-------|-------|
| Basic rendering | ✅ | ✅ |
| Texture mapping | ✅ | ✅ |
| DMA transfers | ✅ | ✅ |
| Interrupt handling | ⚠️ | ✅ |
| Performance monitoring | ❌ | ✅ |
| Debug features | ❌ | ✅ |

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**RTL Source:** `rtl/voxel_axil_csr.sv`
**Validation:** Cross-referenced with driver implementation
**Next Update:** When new registers are added to RTL