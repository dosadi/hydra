# Hydra Data Flow Architecture

This diagram shows the complete data flow from RTL simulation through the driver to the viewer application.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             HYDRA DATA FLOW ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                          RTL LAYER (FPGA/Verilator)                        │ │
│  ├─────────────────────────────────────────────────────────────────────────────┤ │
│  │                                                                             │ │
│  │  ┌─────────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │  │ voxel_framebuf │    │ voxel_axil_ │    │ axi_dma_   │    │ axi_sdram_  │ │ │
│  │  │ fer_top.sv     │    │ csr.sv      │    │ stub.sv    │    │ stub.sv     │ │ │
│  │  │ (Raycaster)    │    │ (CSRs)      │    │ (DMA)      │    │ (SDRAM)     │ │ │
│  │  └─────────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  │           │                   │                   │                   │         │ │
│  │           │                   │                   │                   │         │ │
│  │           └───────────────────┼───────────────────┼───────────────────┘         │ │
│  │                               │                   │                             │ │
│  │                               ▼                   ▼                             │ │
│  │                      ┌─────────────────┐    ┌─────────────┐                     │ │
│  │                      │ axi_stream_sink │    │   BAR1      │                     │ │
│  │                      │ stub.sv (HDMI)  │    │ AXI4 Window │                     │ │
│  │                      └─────────────────┘    └─────────────┘                     │ │
│  │                               │                   ▲                             │ │
│  │                               │                   │                             │ │
│  │                               ▼                   │                             │ │
│  │                      ┌─────────────────┐          │                             │ │
│  │                      │   PIXEL DATA    │◄─────────┘                             │ │
│  │                      │  (RGB Stream)   │                                         │ │
│  │                      └─────────────────┘                                         │ │
│  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│                                                                                   │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │                          PCIe INTERFACE LAYER                              │   │ │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │ │
│  │                                                                             │   │ │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐                   │ │
│  │  │    BAR0     │    │    BAR1     │    │  LitePCIe Core  │                   │ │
│  │  │ AXI-Lite    │    │ AXI4 Memory │    │ (Endpoint+DMA)  │                   │ │
│  │  │ Window      │    │ Window      │    │                 │                   │ │
│  │  └─────────────┘    └─────────────┘    └─────────────────┘                   │ │
│  │           ▲                   ▲                   ▲                           │ │
│  │           │                   │                   │                           │ │
│  │           │                   │                   │                           │ │
│  │    ┌──────┴──────┐    ┌───────┴───────┐    ┌──────┴──────┐                   │ │
│  │    │ CSR CONTROL │    │   DMA DATA   │    │ DMA CONTROL │                   │ │
│  │    │ (AXI-Lite)  │    │   (AXI4)     │    │   (AXI4)    │                   │ │
│  │    └─────────────┘    └───────────────┘    └─────────────┘                   │ │
│  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│                                                                                   │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │                          DRIVER LAYER (libhydra)                           │   │ │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │ │
│  │                                                                             │   │ │
│  │  ┌─────────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │ │
│  │  │   libhydra.so   │    │ IOCTL: CSR  │    │ IOCTL: DMA  │    │ MMAP: FB    │ │ │
│  │  │    (C API)      │    │   Access     │    │   Control   │    │   (Pixels)  │ │ │
│  │  └─────────────────┘    └─────────────┘    └─────────────┘    └─────────────┘ │ │
│  │           │                   │                   │                   │         │ │
│  │           │                   │                   │                   │         │ │
│  │           └───────────────────┼───────────────────┼───────────────────┘         │ │
│  │                               │                   │                             │ │
│  │                               ▼                   ▼                             │ │
│  │                      ┌─────────────────┐    ┌─────────────┐                     │ │
│  │                      │   hydra_csr_*() │    │ hydra_dma_*()│                     │ │
│  │                      │                 │    │              │                     │ │
│  │                      └─────────────────┘    └─────────────┘                     │ │
│  │                               │                   │                             │ │
│  │                               ▼                   ▼                             │ │
│  │                      ┌─────────────────┐    ┌─────────────┐                     │ │
│  │                      │  CAMERA/FLAGS   │    │ FRAME CAPTURE│                     │ │
│  │                      │    CONTROL      │    │   CONTROL    │                     │ │
│  │                      └─────────────────┘    └─────────────┘                     │ │
│  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│                                                                                   │ │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │ │
│  │                          VIEWER LAYER (sim_voxel)                           │   │ │
│  ├─────────────────────────────────────────────────────────────────────────────┤   │ │
│  │                                                                             │   │ │
│  │  ┌─────────────────┐    ┌─────────────┐    ┌─────────────────┐               │ │
│  │  │ SDL Event Loop  │    │  Renderer   │    │ CPU Framebuffer │               │ │
│  │  │ (Input/Camera)  │    │ (Textures)  │    │  (ARGB8888)     │               │ │
│  │  └─────────────────┘    └─────────────┘    └─────────────────┘               │ │
│  │           │                   │                   ▲                           │ │
│  │           │                   │                   │                           │ │
│  │           ▼                   ▼                   │                           │ │
│  │  ┌─────────────────┐    ┌─────────────┐          │                           │ │
│  │  │   WASD + Mouse  │    │   SDL Window │◄─────────┘                           │ │
│  │  │   Camera Ctrl   │    │   Display    │                                     │ │
│  │  └─────────────────┘    └─────────────────┘                                   │ │
│  │           ▲                   ▲                                               │ │
│  │           │                   │                                               │ │
│  │           └───────────────────┘                                               │ │
│  │               HOTKEYS + HUD OVERLAY                                           │ │
│  └─────────────────────────────────────────────────────────────────────────────┘   │ │
│                                                                                   │ │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  KEY DATA FLOWS:                                                                │
│  • RED: Pixel Data (RTL → HDMI Sink → BAR1 → MMAP → Framebuffer → Display)     │
│  • BLUE: Control Flow (CSR Registers → BAR0 → IOCTL → Camera/Flags Control)    │
│  • GREEN: DMA Flow (DMA Engine → BAR1 → IOCTL → Frame Capture)                 │
│                                                                                 │
│  PRIMARY INTERFACES:                                                            │
│  • AXI-Lite: Control registers (camera position, render flags, voxel selection)│
│  • AXI4: High-bandwidth data (SDRAM access, DMA transfers)                     │
│  • AXI-Stream: Pixel output (RGB data to HDMI/display)                         │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Summary

1. **RTL Generation**: `voxel_framebuffer_top.sv` raytraces voxels and generates pixel data
2. **Control Path**: CSR registers control camera position, render flags, and frame start
3. **Pixel Stream**: RGB pixels flow via AXI-Stream to HDMI sink stub
4. **PCIe Transport**: BAR0 (AXI-Lite) and BAR1 (AXI4) expose RTL to host
5. **Driver API**: `libhydra` provides C API for CSR access, DMA control, and memory mapping
6. **Viewer Integration**: `sim_voxel` uses libhydra to control rendering and display pixels

## Key Components

- **RTL**: SystemVerilog modules running in Verilator or FPGA
- **PCIe**: LitePCIe core providing host↔FPGA communication
- **Driver**: `libhydra` with IOCTL for control and MMAP for data access
- **Viewer**: SDL-based application with camera controls and rendering

## Usage

This diagram helps developers understand:
- How pixel data flows from RTL raytracer to display
- Control interfaces for camera and rendering parameters
- DMA paths for high-bandwidth data transfers
- Layer separation between hardware, driver, and application

*Note: SVG version available at `docs/hydra_data_flow.svg` (requires GraphViz: `dot -Tsvg hydra_data_flow.dot -o hydra_data_flow.svg`)*</content>
<parameter name="filePath">/workspaces/hydra/docs/hydra_data_flow_diagram.md