# Integrating Hydra RTL into SoC Designs

## Overview

This guide provides comprehensive instructions for SoC designers who want to integrate the Hydra 3D graphics accelerator RTL into their system-on-chip designs. The Hydra core provides real-time ray-marched voxel rendering with AXI interfaces suitable for FPGA and ASIC implementations.

## Architecture Overview

### Core Components

The Hydra RTL consists of several key modules:

1. **voxel_framebuffer_top** - Top-level integration module
2. **voxel_raycaster_core_pipelined** - Main rendering pipeline
3. **voxel_memory_64** - Geometry storage (64³ voxel grid)
4. **voxel_world_gen** - Procedural world generation
5. **voxel_axil_csr** - AXI-Lite control/status registers
6. **voxel_axil_shell** - PCIe BAR0 interface wrapper

### Interface Summary

| Interface | Protocol | Purpose | Bandwidth |
|-----------|----------|---------|-----------|
| AXI-Lite | Control | Register access, configuration | Low (register reads/writes) |
| AXI-Stream | Pixel Output | Rendered frame data | High (up to 480×360×4 bytes/frame) |
| Native | Geometry Memory | Internal voxel storage | Medium (64-bit voxel data) |
| Interrupt | Wire | Event signaling | Low (status pulses) |

## Integration Checklist

### Pre-Integration Requirements

- [ ] **Clock Domain**: Identify system clock (typically 100-200MHz for FPGA)
- [ ] **Reset Strategy**: Synchronous reset preferred, active-low
- [ ] **Memory Requirements**: 256KB for voxel storage + framebuffer
- [ ] **Interrupt Controller**: Available interrupt input for Hydra events
- [ ] **AXI Interconnect**: Master ports for DMA, slave ports for control

### RTL Integration Steps

1. **Instantiate Core Modules**
2. **Connect Clock and Reset**
3. **Configure AXI Interfaces**
4. **Set Up Memory Interfaces**
5. **Connect Control Signals**
6. **Implement Interrupt Handling**
7. **Add Power Management (Optional)**

## Detailed Integration Guide

### Step 1: Module Instantiation

#### Basic Core Instantiation

```systemverilog
// Hydra Core Instance
voxel_framebuffer_top #(
    .SCREEN_WIDTH(1920),           // Your display width
    .SCREEN_HEIGHT(1080),          // Your display height
    .VOXEL_GRID_SIZE(64),          // Fixed at 64³
    .COORD_WIDTH(16),              // Fixed-point precision
    .FRAC_BITS(8),                 // Fractional bits
    .MAX_RAY_STEPS(256),           // Ray marching steps
    .RAY_STEP_SHIFT(7),            // Step size control
    .AUTO_START_FRAMES(0),         // Manual frame control
    .WORLD_SEED_DEFAULT(32'h12345678) // World seed
) hydra_core (
    .clk(sys_clk),
    .rst_n(sys_rst_n),

    // Pixel output interface
    .pixel_write_en(pixel_valid),
    .pixel_addr(pixel_address),
    .pixel_word0(pixel_data_rgb),
    .pixel_word1(pixel_data_material),
    .pixel_word2(pixel_data_lighting),
    .pixel_reemissure(pixel_sidecar),

    // Frame control
    .frame_done(frame_complete),
    .core_busy(rendering_active),
    .world_ready(world_initialized),

    // Camera control (from your control logic)
    .cam_load(camera_update),
    .cam_x_in(camera_pos_x),
    .cam_y_in(camera_pos_y),
    .cam_z_in(camera_pos_z),
    // ... other camera parameters

    // Configuration flags
    .flags_load(config_update),
    .flag_smooth_in(enable_antialiasing),
    .flag_curvature_in(enable_curvature),
    // ... other flags

    // Voxel selection
    .sel_load(selection_update),
    .sel_active_in(voxel_select_enable),
    .sel_voxel_x_in(selected_x),
    .sel_voxel_y_in(selected_y),
    .sel_voxel_z_in(selected_z),

    // Debug interface (optional)
    .dbg_ext_write_en(debug_write),
    .dbg_ext_write_addr(debug_addr),
    .dbg_ext_write_data(debug_data),

    // Frame control
    .start_frame_ext(start_rendering),
    .soft_reset_ext(system_reset),
    .benchmark_mode(benchmark_enable)
);
```

#### AXI-Lite Control Interface

```systemverilog
// AXI-Lite CSR Interface for PCIe BAR0
voxel_axil_shell #(
    .ADDR_WIDTH(8)  // 256-byte register space
) hydra_axil (
    .clk(sys_clk),
    .rst_n(sys_rst_n),

    // AXI-Lite slave interface (connect to PCIe BAR0)
    .s_axil_awvalid(bar0_awvalid),
    .s_axil_awready(bar0_awready),
    .s_axil_awaddr(bar0_awaddr[7:0]),
    .s_axil_awprot(bar0_awprot),
    .s_axil_wvalid(bar0_wvalid),
    .s_axil_wready(bar0_wready),
    .s_axil_wdata(bar0_wdata),
    .s_axil_wstrb(bar0_wstrb),
    .s_axil_bvalid(bar0_bvalid),
    .s_axil_bready(bar0_bready),
    .s_axil_bresp(bar0_bresp),
    .s_axil_arvalid(bar0_arvalid),
    .s_axil_arready(bar0_arready),
    .s_axil_araddr(bar0_araddr[7:0]),
    .s_axil_arprot(bar0_arprot),
    .s_axil_rvalid(bar0_rvalid),
    .s_axil_rready(bar0_rready),
    .s_axil_rdata(bar0_rdata),
    .s_axil_rresp(bar0_rresp),

    // Connect to Hydra core control inputs
    .cam_load(hydra_core.cam_load),
    .cam_x(hydra_core.cam_x_in),
    // ... connect all control signals

    // Status inputs from Hydra core
    .core_busy(hydra_core.core_busy),
    .frame_done(hydra_core.frame_done),
    // ... connect all status signals

    // Interrupt output
    .irq_out(hydra_interrupt)
);
```

### Step 2: Clock and Reset Strategy

#### Clock Requirements

```systemverilog
// Clock constraints (example for FPGA)
create_clock -name sys_clk -period 5.0 [get_ports sys_clk]  // 200MHz
create_clock -name hydra_clk -period 10.0 [get_ports hydra_clk]  // 100MHz

// If using separate Hydra clock domain
voxel_framebuffer_top hydra_core (
    .clk(hydra_clk),  // Dedicated Hydra clock
    .rst_n(hydra_rst_n),
    // ... other connections
);
```

#### Reset Synchronization

```systemverilog
// Reset synchronizer for clean deassertion
reset_sync hydra_rst_sync (
    .clk(hydra_clk),
    .rst_in(system_reset),
    .rst_out(hydra_rst_n)
);
```

### Step 3: Memory Interface Integration

#### Framebuffer Memory

The Hydra core outputs pixels sequentially. Connect to your display controller:

```systemverilog
// Framebuffer write interface
always @(posedge hydra_clk) begin
    if (hydra_core.pixel_write_en) begin
        framebuffer[hydra_core.pixel_addr] <= {
            hydra_core.pixel_word2,  // Lighting data
            hydra_core.pixel_word1,  // Material data
            hydra_core.pixel_word0   // RGB data
        };
    end
end
```

#### Geometry Memory (Internal)

The voxel memory is internal to Hydra. For external access, use the debug interface:

```systemverilog
// Optional: External geometry memory access
assign hydra_core.dbg_ext_write_en = external_voxel_write;
assign hydra_core.dbg_ext_write_addr = external_voxel_addr;
assign hydra_core.dbg_ext_write_data = external_voxel_data;
```

### Step 4: Interrupt Integration

#### Interrupt Controller Connection

```systemverilog
// Connect to system interrupt controller
interrupt_controller int_ctrl (
    .irq_inputs({hydra_interrupt, other_interrupts}),
    .irq_outputs(processed_interrupts)
);

// Hydra interrupt handler
always @(posedge sys_clk) begin
    if (hydra_interrupt) begin
        // Read interrupt status register
        // Handle frame complete, DMA done, errors, etc.
        // Clear interrupts by writing to INT_STATUS
    end
end
```

### Step 5: DMA Integration (Optional)

If your system includes DMA capabilities, connect external DMA for data transfer:

```systemverilog
// External DMA controller connection
dma_controller system_dma (
    .start(hydra_axil.dma_start),
    .busy(hydra_axil.dma_busy),
    .done(hydra_axil.dma_done),
    .error(hydra_axil.dma_err),
    .src_addr(hydra_axil.dma_src),
    .dst_addr(hydra_axil.dma_dst),
    .length(hydra_axil.dma_len),
    // AXI master interface to system memory
    .m_axi_awaddr(dma_awaddr),
    .m_axi_awvalid(dma_awvalid),
    // ... other AXI signals
);
```

## Configuration and Tuning

### Performance Parameters

| Parameter | Recommended | Description |
|-----------|-------------|-------------|
| `MAX_RAY_STEPS` | 128-256 | Quality vs performance tradeoff |
| `RAY_STEP_SHIFT` | FRAC_BITS-1 | Ray step size precision |
| Clock Frequency | 100-200MHz | Depends on target technology |

### Memory Layout Considerations

```systemverilog
// Framebuffer stride calculation
localparam FB_STRIDE = SCREEN_WIDTH * 4;  // RGBA pixels

// Configure framebuffer base and stride
always @(posedge sys_clk) begin
    hydra_axil.fb_base <= FRAMEBUFFER_BASE_ADDR;
    hydra_axil.fb_stride <= FB_STRIDE;
end
```

## Testing and Validation

### Basic Functionality Test

1. **Reset Test**: Verify clean reset behavior
2. **World Generation**: Check `world_ready` signal
3. **Frame Rendering**: Monitor `frame_done` pulses
4. **Pixel Output**: Validate framebuffer writes
5. **Interrupt Handling**: Test all interrupt conditions

### Integration Test Sequence

```systemverilog
// Test sequence for Hydra integration
initial begin
    // Reset
    system_reset = 1;
    #100 system_reset = 0;

    // Wait for world generation
    wait(hydra_core.world_ready);

    // Configure camera
    hydra_axil.cam_load = 1;
    hydra_axil.cam_x = 16'h2000;  // 32.0 in fixed-point
    // ... set other camera parameters
    @(posedge sys_clk) hydra_axil.cam_load = 0;

    // Start frame rendering
    hydra_axil.start_frame_ext = 1;
    @(posedge sys_clk) hydra_axil.start_frame_ext = 0;

    // Wait for completion
    wait(hydra_core.frame_done);

    // Verify pixel output
    // ... check framebuffer contents
end
```

## FPGA Implementation Notes

### Resource Utilization (Approximate)

| Resource | Utilization | Notes |
|----------|-------------|-------|
| LUTs | 50K-100K | Depends on screen resolution |
| BRAM | 32 blocks | For voxel memory + FIFOs |
| DSP | 20-50 | For fixed-point math |
| Frequency | 100-150MHz | Typical FPGA speeds |

### Timing Constraints

```tcl
# Critical path constraints for Hydra
create_clock -name hydra_clk -period 10.0 [get_ports hydra_clk]
set_clock_uncertainty 0.5 [get_clocks hydra_clk]

# Multi-cycle paths for pixel processing
set_multicycle_path -from [get_cells hydra_core/raycaster/*] \
                    -to [get_cells hydra_core/pixel_output/*] \
                    -setup 2 -hold 1
```

## ASIC Implementation Considerations

### Power Management

```systemverilog
// Optional power gating
power_gate hydra_power (
    .enable(hydra_active),
    .power_ok(hydra_power_ready)
);

// Clock gating for inactive periods
clock_gate hydra_clk_gate (
    .enable(hydra_core.core_busy || hydra_axil.active_access),
    .clk_in(sys_clk),
    .clk_out(hydra_gated_clk)
);
```

### DFT Integration

```systemverilog
// Scan chain insertion
scan_chain hydra_scan (
    .scan_in(system_scan_in),
    .scan_out(hydra_scan_out),
    .scan_enable(scan_enable),
    .scan_mode(scan_mode)
);
```

## Troubleshooting Common Issues

### Timing Violations
- **Solution**: Reduce `MAX_RAY_STEPS` or increase pipeline stages
- **Alternative**: Use higher-speed FPGA grade

### Memory Bandwidth Issues
- **Solution**: Add buffering between Hydra and display controller
- **Alternative**: Reduce screen resolution

### Interrupt Storm
- **Solution**: Implement proper interrupt masking
- **Check**: Clear interrupts immediately after handling

### World Generation Timeout
- **Solution**: Increase timeout or check clock frequency
- **Debug**: Monitor `world_busy` and `world_done` signals

## Reference Designs

### FPGA Development Board
- **Target**: Xilinx Zynq-7000 or Intel Stratix V
- **Interfaces**: PCIe for control, HDMI for display
- **Memory**: DDR3/DDR4 for framebuffer

### ASIC Integration
- **Process**: 28nm or 16nm FinFET
- **Voltage**: 0.8V core, 1.8V IO
- **Power**: <500mW at 100MHz

## Support and Resources

### Documentation References
- `docs/hydra_spec.md` - Hardware specification
- `docs/hydra_register_map.md` - Register definitions
- `docs/rtl_signal_reference.md` - Signal interfaces
- `docs/dma_descriptor_format.md` - DMA protocols

### Getting Help
- Check interrupt status registers for error conditions
- Use debug interface to inspect voxel memory
- Monitor `core_busy` and `frame_done` for timing issues

---

**Document Version:** 1.0
**Last Updated:** 2025-11-26
**Target Audience:** SoC designers, FPGA engineers, ASIC integrators</content>
<parameter name="filePath">/workspaces/hydra/docs/rtl_integration_guide.md