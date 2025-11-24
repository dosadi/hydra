# Hydra RTL Coding Standards

This document defines the coding standards for SystemVerilog RTL in the Hydra project. These standards promote consistency, readability, and maintainability across the codebase.

## File Organization

### Header Comments

Every RTL file should start with a header block:

```systemverilog
// ============================================================================
// module_name.sv
// - Brief description of module purpose and functionality
// - Key features or architectural notes
// ============================================================================

`timescale 1ns/1ps
```

## Module Declarations

### Parameter Declarations

**Use `parameter integer` for all integer parameters** to be explicit about types:

```systemverilog
// Good
module example #(
    parameter integer SCREEN_WIDTH    = 480,
    parameter integer SCREEN_HEIGHT   = 360,
    parameter integer VOXEL_GRID_SIZE = 64,
    parameter integer COORD_WIDTH     = 16,
    parameter integer FRAC_BITS       = 8
)(
    // ...
);

// Bad
module example #(
    parameter SCREEN_WIDTH    = 480,  // Avoid - type not explicit
    parameter SCREEN_HEIGHT   = 360
)(
    // ...
);
```

**Exception**: Use plain `parameter` for string or non-integer parameters:

```systemverilog
parameter INIT_FILE = ""  // String parameter - no 'integer'
```

### Parameter Naming

- Use `UPPER_SNAKE_CASE` for all parameters
- Descriptive names that indicate purpose
- Common parameters across modules:
  - `SCREEN_WIDTH`, `SCREEN_HEIGHT` - Display dimensions
  - `VOXEL_GRID_SIZE` - Voxel volume dimension
  - `COORD_WIDTH`, `FRAC_BITS` - Fixed-point representation
  - `ADDR_WIDTH`, `DATA_WIDTH` - Bus interface widths

## Signal Naming

### Naming Convention

**Use `snake_case` with logical prefixes** to group related signals:

| Prefix | Purpose | Examples |
|--------|---------|----------|
| `cam_` | Camera parameters | `cam_x`, `cam_y`, `cam_z`, `cam_dir_x` |
| `cfg_` | Configuration settings | `cfg_smooth_surfaces`, `cfg_lighting` |
| `sel_` | Selection/cursor state | `sel_active`, `sel_voxel_x`, `sel_y` |
| `dbg_` | Debug/diagnostic signals | `dbg_we_pulse`, `dbg_addr`, `dbg_wdata` |
| `flag_` | Boolean control flags | `flag_smooth`, `flag_extra_light` |
| `dma_` | DMA-related signals | `dma_start_pulse`, `dma_busy`, `dma_src` |
| `blit_` | Blitter/3D engine signals | `blit_ctrl`, `blit_status`, `blit_src` |

### Port Naming

Input and output ports should use descriptive suffixes when needed:

```systemverilog
input  wire        start,           // Action trigger (no suffix needed)
input  wire        enable,          // Boolean enable (no suffix needed)
output reg         busy,            // Status signal (no suffix needed)
output reg         done,            // Completion signal (no suffix needed)

// Suffixes for disambiguation:
input  wire        cam_load,        // Load trigger
input  wire [15:0] cam_x_in,        // Input value (when internal reg exists)
output reg  [15:0] cam_x,           // Output value (from internal reg)

input  wire        dma_busy_in,     // Input status from another module
output reg         dma_start_pulse, // Output control pulse
```

### Wire vs Reg Declarations

```systemverilog
// Inputs/outputs: Declare type explicitly
input  wire        clk,
input  wire [15:0] data_in,
output reg  [31:0] result,

// Internal signals:
wire [7:0]  intermediate_result;    // Combinational
reg  [7:0]  state_register;         // Sequential or combinational from always block
```

## Code Structure

### Always Blocks

**Separate combinational and sequential logic:**

```systemverilog
// Sequential block (registered outputs)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
        counter <= 0;
    end else begin
        state <= next_state;
        counter <= counter + 1;
    end
end

// Combinational block (immediate outputs)
always @(*) begin
    next_state = state;
    case (state)
        S_IDLE: if (start) next_state = S_ACTIVE;
        S_ACTIVE: if (done) next_state = S_IDLE;
    endcase
end
```

### State Machine Style

Use enumerated localparams for state encoding:

```systemverilog
localparam S_IDLE        = 4'd0;
localparam S_RENDER_PIXEL= 4'd1;
localparam S_STEP        = 4'd2;
localparam S_FETCH       = 4'd3;
localparam S_SHADE       = 4'd4;
localparam S_WRITE       = 4'd5;
localparam S_NEXT_PIXEL  = 4'd6;

reg [3:0] state, next_state;
```

### Comments

- Use `//` for single-line comments
- Comment **why**, not **what** (code should be self-explanatory)
- Add comments for:
  - Subtle timing behavior
  - Hardware-specific optimizations
  - Workarounds for tool limitations
  - Complex arithmetic or bit manipulations

```systemverilog
// Good - explains why
// Write-first behavior: if read and write to same address, return new data
if (write_en && read_en && write_addr == read_addr)
    read_data <= write_data;

// Bad - states the obvious
// Increment counter by 1
counter <= counter + 1;
```

## Module Organization

### Standard Module Structure

```systemverilog
module example #(
    // Parameters first
    parameter integer WIDTH = 32
)(
    // Clock and reset first
    input  wire clk,
    input  wire rst_n,

    // Group related ports together with blank lines
    // Control inputs
    input  wire start,
    input  wire enable,

    // Data inputs
    input  wire [WIDTH-1:0] data_in,

    // Status outputs
    output reg  busy,
    output reg  done,

    // Data outputs
    output reg  [WIDTH-1:0] data_out
);

    // Localparams
    localparam STATE_IDLE = 2'd0;

    // Internal signals
    reg [1:0] state;
    wire      condition;

    // Always blocks
    always @(posedge clk or negedge rst_n) begin
        // Sequential logic
    end

    // Continuous assignments
    assign condition = (state == STATE_IDLE) && enable;

endmodule
```

## Interface Standards

### AXI-Lite Naming

Follow standard AXI-Lite signal naming:

```systemverilog
// AXI-Lite slave interface
input  wire [ADDR_WIDTH-1:0]    s_axil_awaddr,
input  wire                     s_axil_awvalid,
output reg                      s_axil_awready,
input  wire [DATA_WIDTH-1:0]    s_axil_wdata,
input  wire [(DATA_WIDTH/8)-1:0]s_axil_wstrb,
input  wire                     s_axil_wvalid,
output reg                      s_axil_wready,
output reg  [1:0]               s_axil_bresp,
output reg                      s_axil_bvalid,
input  wire                     s_axil_bready,
input  wire [ADDR_WIDTH-1:0]    s_axil_araddr,
input  wire                     s_axil_arvalid,
output reg                      s_axil_arready,
output reg [DATA_WIDTH-1:0]     s_axil_rdata,
output reg [1:0]                s_axil_rresp,
output reg                      s_axil_rvalid,
input  wire                     s_axil_rready
```

### AXI4 Naming

For AXI4 master/slave interfaces, follow standard naming:

```systemverilog
// AXI4 master interface (framebuffer writes)
output wire [3:0]  m_axi_awid,
output wire [27:0] m_axi_awaddr,
output wire [7:0]  m_axi_awlen,
output wire [2:0]  m_axi_awsize,
output wire [1:0]  m_axi_awburst,
output wire        m_axi_awvalid,
input  wire        m_axi_awready,
// ... (full AXI4 write and read channels)
```

### AXI-Stream Naming

For streaming video/pixel data:

```systemverilog
// AXI-Stream master (video output)
output wire [23:0] m_axis_tdata,
output wire        m_axis_tvalid,
output wire        m_axis_tlast,
output wire        m_axis_tuser,
input  wire        m_axis_tready
```

## Simulation vs. Synthesis

### Synthesis Safety Checks

For simulation-only modules, add safety checks:

```systemverilog
`ifndef SIM
    `ifdef SYNTHESIS
        `error "module_name is for simulation only! Use production_module for FPGA."
    `endif
`endif
```

### Simulation Parameters

Provide simulation-friendly parameter overrides:

```systemverilog
parameter integer MAX_RAY_STEPS   = 128,        // Default for FPGA
parameter integer RAY_STEP_SHIFT  = FRAC_BITS-1,
parameter integer TEST_FORCE_WORLD_READY = 0,   // Sim-only shortcut
parameter integer AUTO_START_FRAMES = 1         // Sim convenience
```

## Common Patterns

### Pulse Generation from Register Write

```systemverilog
reg        ctrl_start_frame;     // Written by CSR
reg        ctrl_start_frame_d;   // Delayed by 1 cycle
wire       start_frame_pulse;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ctrl_start_frame_d <= 1'b0;
    else
        ctrl_start_frame_d <= ctrl_start_frame;
end

assign start_frame_pulse = ctrl_start_frame & ~ctrl_start_frame_d;
```

### Sticky Status Bits

```systemverilog
reg frame_done_sticky;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        frame_done_sticky <= 1'b0;
    else if (csr_clear_status)  // Software clear
        frame_done_sticky <= 1'b0;
    else if (frame_done_pulse)
        frame_done_sticky <= 1'b1;  // Latched until cleared
end
```

## Deprecated Code

When deprecating a module:

1. Add prominent deprecation notice at top of file
2. Document replacement module(s)
3. Move to `rtl/deprecated/` directory
4. Update `rtl/deprecated/README.md` with deprecation reason

```systemverilog
// ** DEPRECATION NOTICE **
// This module is DEPRECATED and will be removed in a future release.
// Reason: [Brief explanation]
//
// Please use instead:
//   - rtl/replacement_module.sv : [Purpose]
```

## File Naming

- Use `snake_case.sv` for all SystemVerilog files
- Prefix with subsystem when part of larger component:
  - `voxel_*.sv` - Voxel rendering subsystem
  - `axi_*.sv` - AXI interface modules
- Suffix `_stub.sv` for simulation stubs (models, not production)
- Suffix `_top.sv` for integration/top-level modules

## Indentation and Formatting

- **4 spaces** per indentation level (no tabs)
- Align port declarations and assignments for readability:

```systemverilog
// Good - aligned
output reg [31:0]  pixel_word0,
output reg [31:0]  pixel_word1,
output reg [31:0]  pixel_word2,

// Less readable - not aligned
output reg [31:0] pixel_word0,
output reg [31:0] pixel_word1,
output reg [31:0] pixel_word2,
```

## Fixed-Point Arithmetic

Document fixed-point representation clearly:

```systemverilog
// All coordinates are signed 16-bit fixed-point: {8 integer, 8 fractional}
// Range: -128.0 to +127.996 with 1/256 precision
parameter integer COORD_WIDTH = 16;
parameter integer FRAC_BITS   = 8;

// Example: cam_x = 16'h0A80 represents 10.5
//   Integer part: 0x0A = 10
//   Fractional part: 0x80 = 128/256 = 0.5
```

## Verilator Lint Pragmas

Use Verilator lint pragmas sparingly and document why:

```systemverilog
/* verilator lint_off WIDTHEXPAND */
// Width expansion intentional here for saturation arithmetic
tmp = r + (curvature >> 4);
result = (tmp > 9'd255) ? 8'd255 : tmp[7:0];
/* verilator lint_on WIDTHEXPAND */
```

## References

- **AXI Specifications**: ARM IHI 0022E (AXI3), IHI 0051A (AXI4)
- **Verilator Manual**: https://verilator.org/guide/latest/
- **SystemVerilog LRM**: IEEE 1800-2017

## Rationale

These standards were established through analysis of existing Hydra RTL modules and reflect best practices for:
- Hardware synthesis (FPGA/ASIC compatibility)
- Simulation performance (Verilator/iverilog)
- Team collaboration and code review
- Long-term maintainability

## Exceptions

When standards conflict with:
- Tool limitations (document with comment)
- Performance requirements (profile and justify)
- External IP integration (document interface contract)

...exception is acceptable with clear documentation.

---

*Last updated: 2025-11-24*
*See also: `docs/ip_integration_cleanup.md`, `docs/architecture_cleanup_summary.md`*
