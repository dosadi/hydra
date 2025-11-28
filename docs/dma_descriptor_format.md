# DMA Architecture and Descriptor Format

This document specifies the Direct Memory Access (DMA) architecture, descriptor format, and alignment requirements for Hydra's PCIe-based FPGA graphics accelerator.

## Overview

Hydra uses DMA for high-performance data transfer between system memory and FPGA graphics memory. The DMA system supports scatter-gather operations with configurable descriptor chains for efficient memory management.

## DMA Architecture

### System Architecture

```
System Memory (Host)          PCIe Bus           FPGA Memory (Device)
┌─────────────────┐          ┌──────┐          ┌─────────────────┐
│ User Application│          │      │          │ Frame Buffer    │
│                 │          │ PCIe │          │ Texture Memory  │
│ DMA Descriptors │◄────────►│ Root │◄────────►│ Vertex Data     │
│                 │          │Complex│          │ Command Queues │
│ Scatter-Gather  │          │      │          │                 │
│ Lists           │          │      │          │                 │
└─────────────────┘          └──────┘          └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         └───── LitePCIe DMA Engine ─────────────────────┘
```

### DMA Engine Features

- **Scatter-Gather Support**: Multi-descriptor transfers for non-contiguous memory
- **64-bit Addressing**: Full 64-bit address space support
- **Configurable Burst Sizes**: Optimized for different memory types
- **Interrupt Generation**: Completion and error interrupt support
- **Error Detection**: Comprehensive error reporting and recovery

## Descriptor Format

### Basic Descriptor Structure

Each DMA descriptor is a 128-bit (16-byte) structure with the following format:

```c
typedef struct {
    uint64_t address;      // 64-bit source/destination address
    uint32_t length;       // Transfer length in bytes (24 bits used)
    uint32_t control;      // Control flags and status (8 bits used)
} dma_descriptor_t;
```

**Memory Layout:**
```
Bits:   127          64 63          32 31          8 7           0
        ┌─────────────┬─────────────┬─────────────┬─────────────┐
        │   Address   │   Address   │   Length    │  Control    │
        │   [63:32]   │   [31:0]    │   [23:0]    │   [7:0]     │
        └─────────────┴─────────────┴─────────────┴─────────────┘
```

### Field Definitions

#### Address Field (64 bits)
- **Bits [63:0]**: Memory address for transfer
- **Alignment**: Must be aligned according to transfer size
- **Address Space**: Can reference system memory or FPGA memory regions

#### Length Field (24 bits)
- **Bits [23:0]**: Transfer length in bytes
- **Range**: 1 to 16,777,215 bytes (16MB - 1)
- **Alignment**: Must be multiple of transfer granularity
- **Zero Length**: Reserved (not allowed)

#### Control Field (8 bits)
```
Bit 7: Interrupt Enable (IE)
Bit 6: End of Chain (EOC)
Bit 5: Direction (DIR) - 0=Host→Device, 1=Device→Host
Bit 4: Reserved
Bit 3: Reserved
Bit 2: Reserved
Bit 1: Reserved
Bit 0: Valid (V) - Must be set for descriptor to be processed
```

**Control Field Values:**
- **IE (Interrupt Enable)**: Generate interrupt when this descriptor completes
- **EOC (End of Chain)**: Last descriptor in scatter-gather chain
- **DIR (Direction)**: Transfer direction (0 = Host→Device, 1 = Device→Host)
- **V (Valid)**: Descriptor is valid and ready for processing

## Descriptor Chain Operation

### Scatter-Gather Lists

DMA operations use linked lists of descriptors for complex transfers:

```c
typedef struct {
    dma_descriptor_t descriptors[MAX_DESCRIPTORS];
    uint32_t count;                    // Number of valid descriptors
    uint32_t next_index;              // Next descriptor to process
} dma_descriptor_chain_t;
```

### Chain Processing Rules

1. **Sequential Processing**: Descriptors processed in array order (index 0 to N-1)
2. **EOC Termination**: Chain ends when EOC bit is set in control field
3. **Interrupt Generation**: Interrupt generated for descriptors with IE bit set
4. **Error Handling**: Chain stops on first error, error status reported

### Example Descriptor Chain

```c
// Transfer vertex data (Host→Device)
dma_descriptor_t vertex_data = {
    .address = 0x00000000ABCDEF00ULL,  // Host memory address
    .length = 65536,                   // 64KB transfer
    .control = DMA_IE | DMA_DIR_HOST_TO_DEVICE  // Interrupt + direction
};

// Transfer texture data (Host→Device)
dma_descriptor_t texture_data = {
    .address = 0x00000000FEDCBA00ULL,  // Host memory address
    .length = 1048576,                 // 1MB transfer
    .control = DMA_IE | DMA_DIR_HOST_TO_DEVICE | DMA_EOC  // Interrupt + direction + end
};
```

## Memory Alignment Requirements

### Address Alignment

| Transfer Size | Minimum Alignment | Performance Alignment |
|---------------|-------------------|----------------------|
| 1 byte       | 1 byte           | 4 bytes             |
| 2 bytes      | 2 bytes          | 4 bytes             |
| 4 bytes      | 4 bytes          | 16 bytes            |
| 8 bytes      | 8 bytes          | 32 bytes            |
| 16 bytes     | 16 bytes         | 64 bytes            |
| 32 bytes     | 32 bytes         | 128 bytes           |

### Descriptor Alignment

- **Descriptor Array**: Must be aligned to 16-byte boundary
- **Individual Descriptors**: Must be 16-byte aligned in memory
- **Chain Base Address**: Must be aligned to cache line boundary (64 bytes recommended)

### FPGA Memory Regions

| Region | Base Address | Size | Alignment Requirements |
|--------|-------------|------|----------------------|
| Frame Buffer | 0x0000_0000 | 8MB | 4KB page alignment |
| Texture Memory | 0x0080_0000 | 16MB | 4KB page alignment |
| Vertex Buffer | 0x0180_0000 | 4MB | 64-byte cache alignment |
| Command Queue | 0x01C0_0000 | 1MB | 16-byte descriptor alignment |

## Transfer Protocols

### Basic Transfer Sequence

1. **Setup Phase**
   - Prepare descriptor chain in host memory
   - Ensure proper alignment and validation
   - Configure DMA engine registers

2. **Initiation Phase**
   - Write descriptor chain base address to DMA engine
   - Set transfer parameters (burst size, etc.)
   - Start DMA operation

3. **Execution Phase**
   - DMA engine processes descriptors sequentially
   - Hardware handles PCIe transactions
   - Progress tracked via status registers

4. **Completion Phase**
   - Interrupt generated (if enabled)
   - Status updated in descriptor control fields
   - Error conditions reported

### Burst Size Optimization

| Memory Type | Optimal Burst Size | Maximum Burst Size |
|-------------|-------------------|-------------------|
| System DRAM | 64 bytes | 4096 bytes |
| FPGA Block RAM | 16 bytes | 256 bytes |
| PCIe Transfers | 128 bytes | 4096 bytes |

## Register Interface

### DMA Control Registers (BAR0)

| Offset | Name | Description |
|--------|------|-------------|
| 0x100 | DMA_DESC_BASE | Descriptor chain base address (64-bit) |
| 0x108 | DMA_DESC_COUNT | Number of descriptors in chain |
| 0x110 | DMA_CONTROL | Control register (start/stop/reset) |
| 0x118 | DMA_STATUS | Status register (busy/done/error) |
| 0x120 | DMA_BURST_SIZE | Transfer burst size configuration |
| 0x128 | DMA_TIMEOUT | Transfer timeout configuration |

### Control Register Bits

```
Bit 31: Reset (write 1 to reset DMA engine)
Bit 30: Enable (1 = DMA enabled, 0 = disabled)
Bit 29: Start Transfer (write 1 to start, auto-clears)
Bit 28: Abort Transfer (write 1 to abort current transfer)
Bits 27-0: Reserved
```

### Status Register Bits

```
Bit 31: Transfer Complete (1 = last transfer finished)
Bit 30: Transfer Active (1 = DMA engine busy)
Bit 29: Transfer Error (1 = error occurred)
Bit 28: Descriptor Error (1 = invalid descriptor)
Bit 27: Timeout Error (1 = transfer timeout)
Bit 26: PCIe Error (1 = PCIe bus error)
Bits 25-16: Completed Descriptors (count)
Bits 15-0: Current Descriptor Index
```

## Error Handling

### Error Conditions

| Error Code | Description | Recovery Action |
|------------|-------------|-----------------|
| 0x01 | Invalid Descriptor | Check descriptor format and alignment |
| 0x02 | Address Error | Verify address is in valid range |
| 0x03 | Length Error | Check transfer length is valid |
| 0x04 | PCIe Error | Check PCIe link status |
| 0x05 | Timeout Error | Increase timeout or check system performance |
| 0x06 | Alignment Error | Ensure proper address/length alignment |

### Error Recovery Procedures

1. **Descriptor Errors**: Validate descriptor format and fix alignment
2. **Address Errors**: Check memory region permissions and validity
3. **PCIe Errors**: Reset PCIe link, check hardware connections
4. **Timeout Errors**: Increase timeout values, check system load
5. **Alignment Errors**: Realign buffers to required boundaries

## Performance Considerations

### Optimization Guidelines

1. **Descriptor Coalescing**: Combine small transfers into larger ones
2. **Alignment Optimization**: Use optimal alignments for target memory
3. **Burst Size Tuning**: Match burst sizes to memory characteristics
4. **Interrupt Reduction**: Use interrupts sparingly for high-frequency transfers

### Performance Metrics

| Metric | Target Value | Measurement Method |
|--------|-------------|-------------------|
| Transfer Rate | >500 MB/s | PCIe bus analyzer |
| Latency | <10μs | Hardware timestamping |
| CPU Overhead | <5% | System profiling |
| Error Rate | <0.01% | Error counter monitoring |

## Software Interface

### Linux Driver API

```c
// DMA transfer request structure
typedef struct {
    uint64_t src_addr;          // Source address
    uint64_t dst_addr;          // Destination address
    uint32_t length;            // Transfer length
    uint32_t flags;             // Transfer flags
    dma_callback_t callback;    // Completion callback
    void *user_data;            // User context
} dma_transfer_request_t;

// DMA operations
int hydra_dma_transfer(dma_transfer_request_t *req);
int hydra_dma_wait_completion(uint32_t timeout_ms);
int hydra_dma_get_status(dma_status_t *status);
```

### Usage Examples

#### Simple Single Transfer
```c
// Host to device transfer
dma_transfer_request_t req = {
    .src_addr = host_buffer_addr,
    .dst_addr = FPGA_FRAMEBUFFER_BASE,
    .length = 1920 * 1080 * 4,  // 1920x1080 RGBA frame
    .flags = DMA_DIR_HOST_TO_DEVICE | DMA_IRQ_COMPLETION,
    .callback = frame_complete_callback,
    .user_data = frame_context
};

hydra_dma_transfer(&req);
```

#### Scatter-Gather Transfer
```c
// Multiple buffers to device
dma_descriptor_t descriptors[3];

// Vertex data
descriptors[0] = (dma_descriptor_t){
    .address = vertex_buffer_addr,
    .length = 65536,
    .control = DMA_VALID | DMA_DIR_HOST_TO_DEVICE
};

// Index data
descriptors[1] = (dma_descriptor_t){
    .address = index_buffer_addr,
    .length = 16384,
    .control = DMA_VALID | DMA_DIR_HOST_TO_DEVICE
};

// Texture data (last in chain)
descriptors[2] = (dma_descriptor_t){
    .address = texture_buffer_addr,
    .length = 1048576,
    .control = DMA_VALID | DMA_DIR_HOST_TO_DEVICE | DMA_EOC | DMA_IRQ
};

hydra_dma_transfer_sg(descriptors, 3);
```

## Testing and Validation

### DMA Test Patterns

1. **Basic Functionality**: Single descriptor transfers of various sizes
2. **Scatter-Gather**: Multi-descriptor chains with different patterns
3. **Error Conditions**: Invalid descriptors, alignment errors, timeouts
4. **Performance**: Throughput and latency measurements
5. **Stress Testing**: Continuous transfers under load

### Validation Checklist

- [ ] Descriptor format validation
- [ ] Address range checking
- [ ] Alignment verification
- [ ] Transfer completion confirmation
- [ ] Error condition handling
- [ ] Performance benchmarking
- [ ] Multi-threaded access testing

## Future Enhancements

### Planned Features

- **Advanced Scatter-Gather**: Linked list descriptors for dynamic chains
- **Priority Queues**: Multiple priority levels for different transfer types
- **Compression Support**: Hardware-accelerated compression/decompression
- **Virtual Memory**: IOMMU support for virtual address translation
- **Quality of Service**: Bandwidth allocation and traffic shaping

### Extended Capabilities

- **Multi-Channel DMA**: Parallel transfer channels for higher throughput
- **Hardware Acceleration**: FPGA-based compression and encryption
- **Error Correction**: Forward error correction for unreliable links
- **Telemetry**: Detailed transfer statistics and performance monitoring

---

**Document Version:** 1.0
**Last Updated:** 2025-11-28
**Status:** DMA descriptor format and alignment requirements documented
**Next Steps:** Implement driver API and validation tests