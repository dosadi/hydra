# UCIe Chiplet Integration (Phase 6)

## Overview

This document describes the integration of Universal Chiplet Interconnect Express (UCIe) for multi-chiplet Hydra implementations, enabling modular, scalable FPGA architectures with standardized die-to-die communication.

## Problem Statement

Current Hydra implementation assumes monolithic FPGA integration:
- Single die with all components (voxel core, DRAM controller, PCIe endpoint)
- Fixed resource allocation and power envelope
- Limited scalability for larger designs
- No support for heterogeneous chiplet integration

UCIe enables:
- **Modular Design**: Separate chiplets for different functions
- **Scalability**: Mix and match chiplets based on requirements
- **Heterogeneous Integration**: Combine different process nodes/technologies
- **Cost Optimization**: Use smaller dies for specific functions

## UCIe Architecture Overview

UCIe provides standardized die-to-die interconnect with:
- **Up to 32 GT/s per lane** (16 lanes maximum)
- **PHY layer**: 236 pins per UCIe link
- **Protocol layer**: FLIT-based packetized communication
- **Voltage levels**: Standard I/O voltages (0.8V, 1.0V, 1.2V, 1.8V)

### UCIe Link Configuration
```
┌─────────────────────────────────────────────────────────────┐
│                    UCIe Link (16 lanes max)                 │
├─────────────────────────────────────────────────────────────┤
│  TX Lanes 0-15 ──────────────────────────────────────────► │
│  RX Lanes 0-15 ◄─────────────────────────────────────────── │
│                                                             │
│  Sideband Signals:                                          │
│  ├─ clk_req/clk_ack (clock request)                       │
│  ├─ valid_flit (data valid)                               │
│  ├─ flit_type (protocol type)                             │
│  ├─ crc_error (error detection)                           │
│  ├─ link_error (link status)                              │
│  ├─ reset (link reset)                                    │
│  └─ voltage_level (I/O voltage)                           │
└─────────────────────────────────────────────────────────────┘
```

## Chiplet Partitioning Strategy

### Base Chiplet (Compute Core)
```
┌─────────────────────────────────────────────────────────────┐
│                Hydra Compute Chiplet                        │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Voxel Core                            │    │
│  │  ├─ Ray marching pipeline                         │    │
│  │  ├─ Framebuffer generation                        │    │
│  │  └─ CSR control interface                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  UCIe Links:                                                │
│  ├─ Link 0: To Memory Chiplet (framebuffer access)       │
│  ├─ Link 1: To I/O Chiplet (PCIe, HDMI)                  │
│  └─ Link 2: To Network Chiplet (optional)                │
└─────────────────────────────────────────────────────────────┘
```

### Memory Chiplet (DRAM Interface)
```
┌─────────────────────────────────────────────────────────────┐
│                Hydra Memory Chiplet                         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │              LiteDRAM Controller                     │    │
│  │  ├─ DDR4/DDR5 PHY                                   │    │
│  │  ├─ Memory controller                                │    │
│  │  ├─ ECC support                                      │    │
│  │  └─ Power management                                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Framebuffer Cache                       │    │
│  │  ├─ L1 cache (per chiplet)                          │    │
│  │  ├─ L2 cache (shared)                               │    │
│  │  └─ Cache coherence                                  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  UCIe Links:                                                │
│  ├─ Link 0: To Compute Chiplet                           │
│  ├─ Link 1: To I/O Chiplet                               │
│  └─ Link 2: Inter-memory communication                   │
└─────────────────────────────────────────────────────────────┘
```

### I/O Chiplet (External Interfaces)
```
┌─────────────────────────────────────────────────────────────┐
│                 Hydra I/O Chiplet                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │              PCIe Endpoint                           │    │
│  │  ├─ Gen4/Gen5 support                               │    │
│  │  ├─ SR-IOV support                                  │    │
│  │  └─ Multiple BAR regions                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              HDMI/DisplayPort                        │    │
│  │  ├─ Video timing generation                         │    │
│  │  ├─ DMA-based scanout                               │    │
│  │  └─ Multi-monitor support                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Network Interfaces                      │    │
│  │  ├─ Ethernet (1G/10G/25G)                           │    │
│  │  ├─ RDMA support                                    │    │
│  │  └─ Quality of Service                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  UCIe Links:                                                │
│  ├─ Link 0: To Compute Chiplet                           │
│  ├─ Link 1: To Memory Chiplet                            │
│  └─ Link 2: To Network Chiplet                           │
└─────────────────────────────────────────────────────────────┘
```

## UCIe Protocol Integration

### FLIT-Based Communication

UCIe uses Flow Control Units (FLITs) for data transfer:
- **FLIT Size**: 256 bits (32 bytes)
- **Types**: Data, Protocol, Idle, Training
- **Flow Control**: Credit-based, prevents buffer overflow

### Protocol Stack
```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
├─────────────────────────────────────────────────────────────┤
│  ├─ AXI4/AXI-Lite (memory mapped)                         │
│  ├─ AXI-Stream (streaming data)                           │
│  └─ Custom protocols (chiplet-specific)                   │
├─────────────────────────────────────────────────────────────┤
│                    Transport Layer                           │
├─────────────────────────────────────────────────────────────┤
│  ├─ FLIT assembly/disassembly                             │
│  ├─ Error detection/correction                            │
│  └─ Flow control management                               │
├─────────────────────────────────────────────────────────────┤
│                    Link Layer                                │
├─────────────────────────────────────────────────────────────┤
│  ├─ Lane management                                       │
│  ├─ Training sequences                                    │
│  └─ Link state machine                                     │
├─────────────────────────────────────────────────────────────┤
│                    Physical Layer                            │
├─────────────────────────────────────────────────────────────┤
│  ├─ SerDes transceivers                                   │
│  ├─ Clock/data recovery                                   │
│  └─ Signal conditioning                                   │
└─────────────────────────────────────────────────────────────┘
```

## RTL Implementation

### UCIe Wrapper Module
```systemverilog
module hydra_ucie_wrapper (
    // UCIe physical interface
    input  logic [15:0] ucie_tx_data,
    output logic [15:0] ucie_rx_data,
    input  logic        ucie_tx_valid,
    output logic        ucie_rx_valid,
    input  logic [1:0]  ucie_flit_type,
    output logic [1:0]  ucie_flit_type_out,
    input  logic        ucie_crc_error,
    output logic        ucie_link_error,

    // Internal AXI interfaces
    // ... AXI4 master/slave ports

    // Control interface
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] csr_addr,
    input  logic [31:0] csr_wdata,
    output logic [31:0] csr_rdata,
    input  logic        csr_valid,
    output logic        csr_ready
);

    // UCIe protocol controller
    ucie_controller u_controller (
        .ucie_tx_data(ucie_tx_data),
        .ucie_rx_data(ucie_rx_data),
        // ... other UCIe signals
    );

    // AXI bridge
    ucie_axi_bridge u_bridge (
        .clk(clk),
        .rst_n(rst_n),
        // ... AXI ports
    );

    // Error handling and status
    ucie_error_handler u_error (
        .crc_error(ucie_crc_error),
        .link_error(ucie_link_error),
        // ... status registers
    );

endmodule
```

### Chiplet-Specific Adapters

#### Compute Chiplet Adapter
```systemverilog
module compute_chiplet_adapter (
    // UCIe interface to memory chiplet
    ucie_if.mem_port mem_ucie,

    // UCIe interface to I/O chiplet
    ucie_if.io_port io_ucie,

    // Internal voxel core interface
    axi4_if.master fb_master,  // Framebuffer writes
    axi_lite_if.slave csr_slave,  // Control registers
    axis_if.master video_master  // Video output
);

    // Route framebuffer writes to memory chiplet
    always_comb begin
        mem_ucie.axi_awaddr = fb_master.awaddr;
        mem_ucie.axi_awvalid = fb_master.awvalid;
        fb_master.awready = mem_ucie.axi_awready;
        // ... other AXI signals
    end

    // Route video data to I/O chiplet
    always_comb begin
        io_ucie.axis_tdata = video_master.tdata;
        io_ucie.axis_tvalid = video_master.tvalid;
        video_master.tready = io_ucie.axis_tready;
        // ... other AXIS signals
    end

endmodule
```

## Implementation Plan

### Phase 6A: UCIe IP Integration
1. **Acquire UCIe IP**: Obtain UCIe controller IP from vendor (Xilinx, Intel, etc.)
2. **PHY Integration**: Integrate UCIe PHY with FPGA transceivers
3. **Protocol Stack**: Implement UCIe protocol layers
4. **Testing**: Basic link training and data transfer tests

### Phase 6B: Chiplet Architecture
1. **Partition Analysis**: Determine optimal chiplet boundaries
2. **Interface Definition**: Define UCIe protocols for each chiplet type
3. **RTL Updates**: Modify existing modules for chiplet communication
4. **Power Management**: Implement per-chiplet power domains

### Phase 6C: Multi-Chiplet System
1. **System Assembly**: Create multi-chiplet package design
2. **Thermal Management**: Address heat dissipation across chiplets
3. **Signal Integrity**: Ensure UCIe link reliability
4. **Validation**: Full system testing with all chiplets

## Benefits

### Performance Scaling
- **Bandwidth**: Up to 512 GB/s per UCIe link (16 lanes × 32 GT/s)
- **Latency**: Sub-nanosecond die-to-die communication
- **Throughput**: Aggregate bandwidth scales with chiplet count

### Design Flexibility
- **Modular Design**: Mix compute, memory, I/O chiplets as needed
- **Technology Diversity**: Combine different process nodes (7nm compute + 10nm memory)
- **Cost Optimization**: Use minimal die sizes for specific functions
- **Upgrade Path**: Replace individual chiplets without redesigning everything

### Power Efficiency
- **Fine-Grained Power**: Power down unused chiplets
- **Optimized Process**: Match process technology to function requirements
- **Reduced Leakage**: Smaller dies have lower leakage current

## Challenges and Solutions

### Signal Integrity
**Challenge**: High-speed signaling across die boundaries
**Solution**:
- Careful impedance matching
- Ground plane optimization
- Signal conditioning circuits

### Thermal Management
**Challenge**: Heat dissipation in multi-chiplet packages
**Solution**:
- Advanced packaging technologies (2.5D/3D)
- Microchannel cooling
- Thermal interface materials

### Testing and Debug
**Challenge**: Debugging across chiplet boundaries
**Solution**:
- Built-in self-test (BIST) circuits
- JTAG daisy-chaining across chiplets
- Protocol analyzers for UCIe links

## Migration Path

### From Monolithic to Chiplet
1. **Phase 1-5**: Complete monolithic FPGA implementation
2. **Phase 6A**: Add UCIe interfaces to existing design
3. **Phase 6B**: Create chiplet-specific wrappers
4. **Phase 6C**: Physical chiplet partitioning and packaging

### Backward Compatibility
- Maintain monolithic FPGA support
- Chiplet mode as optional configuration
- Same software interface regardless of implementation

## References

- UCIe 1.0 Specification: https://www.uciexpress.org/
- IEEE 2803-2022 (UCIe standard)
- Chiplet design patterns and best practices
- Vendor UCIe IP documentation (Xilinx, Intel, TSMC)

## Next Steps

1. **Evaluate UCIe IP availability** for target FPGA families
2. **Create chiplet partitioning analysis** based on Hydra requirements
3. **Design UCIe protocol layers** for AXI/AXIS bridging
4. **Prototype single UCIe link** communication
5. **Plan multi-chiplet package** design and assembly</content>
<parameter name="filePath">/workspaces/hydra/docs/ucie_chiplet_integration.md