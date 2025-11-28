# Hydra Interrupt Status and Mask Register Documentation

## Overview

The Hydra graphics accelerator uses a 32-bit interrupt system with status and mask registers to manage hardware events. Interrupts are generated when rendering frames complete, DMA operations finish, errors occur, or other hardware events trigger.

## Interrupt Registers

### Interrupt Status Register (BAR0 + 0x0080)

The interrupt status register contains individual bits for each interrupt source. Reading this register returns the current interrupt state. Writing a 1 to any bit clears that interrupt (W1C - Write 1 to Clear).

| Bit | Name | Description | Trigger Condition |
|-----|------|-------------|-------------------|
| 0 | `HYDRA_INT_FRAME_DONE` | Frame rendering completed | Set when `frame_done_pulse` occurs (end of rendering cycle) |
| 1 | `HYDRA_INT_DMA_DONE` | DMA operation completed | Set when DMA transfer finishes successfully or encounters error |
| 2 | `HYDRA_INT_DMA_ERR` | DMA operation error | Set when DMA alignment error occurs or DMA busy during start |
| 3 | `HYDRA_INT_TEST` | Test interrupt | Set by writing bit 0 to IRQ_TEST register (0x0088) |
| 4 | `HYDRA_INT_BLIT_DONE` | Blitter operation completed | Set when 3D blitter finishes any operation |
| 5 | `HYDRA_INT_REGION0_DONE` | Region-0 extractor completed | Set when automatic region-0 surface extractor finishes |
| 6-31 | Reserved | Reserved for future use | - |

### Interrupt Mask Register (BAR0 + 0x0084)

The interrupt mask register controls which interrupts are enabled. Writing to this register sets the mask value directly. Only interrupts with both their status bit set AND their mask bit set will trigger the hardware interrupt output.

| Bit | Name | Description |
|-----|------|-------------|
| 0 | `HYDRA_INT_MASK_FRAME_DONE` | Enable frame done interrupts |
| 1 | `HYDRA_INT_MASK_DMA_DONE` | Enable DMA completion interrupts |
| 2 | `HYDRA_INT_MASK_DMA_ERR` | Enable DMA error interrupts |
| 3 | `HYDRA_INT_MASK_TEST` | Enable test interrupts |
| 4 | `HYDRA_INT_MASK_BLIT_DONE` | Enable blitter completion interrupts |
| 5 | `HYDRA_INT_MASK_REGION0_DONE` | Enable region-0 extractor completion interrupts |
| 6-31 | Reserved | Reserved for future use |

## Hardware Interrupt Output

The hardware interrupt signal (`irq_out`) is asserted when:
```
irq_out = |(int_status & int_mask)
```

This means the interrupt pin is active high whenever any enabled interrupt condition is active.

## Interrupt Handling Sequence

### Typical Driver Interrupt Handler

1. **Read Interrupt Status**: Read the interrupt status register to determine which events occurred
2. **Handle Events**: Process each pending interrupt based on priority/status
3. **Clear Interrupts**: Write 1s to the status register bits to clear handled interrupts
4. **Check for More**: Re-read status register in case new interrupts occurred during handling

### Example C Code

```c
#define HYDRA_INT_STATUS     0x0080
#define HYDRA_INT_MASK       0x0084

#define HYDRA_INT_FRAME_DONE (1 << 0)
#define HYDRA_INT_DMA_DONE   (1 << 1)
#define HYDRA_INT_DMA_ERR    (1 << 2)
#define HYDRA_INT_BLIT_DONE  (1 << 4)
#define HYDRA_INT_REGION0_DONE (1 << 5)

void hydra_interrupt_handler(void) {
    uint32_t status = readl(hydra_base + HYDRA_INT_STATUS);

    // Handle frame completion
    if (status & HYDRA_INT_FRAME_DONE) {
        handle_frame_done();
        writel(HYDRA_INT_FRAME_DONE, hydra_base + HYDRA_INT_STATUS);
    }

    // Handle DMA completion
    if (status & HYDRA_INT_DMA_DONE) {
        handle_dma_done();
        writel(HYDRA_INT_DMA_DONE, hydra_base + HYDRA_INT_STATUS);
    }

    // Handle DMA errors (highest priority)
    if (status & HYDRA_INT_DMA_ERR) {
        handle_dma_error();
        writel(HYDRA_INT_DMA_ERR, hydra_base + HYDRA_INT_STATUS);
    }

    // Handle blitter completion
    if (status & HYDRA_INT_BLIT_DONE) {
        handle_blit_done();
        writel(HYDRA_INT_BLIT_DONE, hydra_base + HYDRA_INT_STATUS);
    }

    // Handle region-0 completion
    if (status & HYDRA_INT_REGION0_DONE) {
        handle_region0_done();
        writel(HYDRA_INT_REGION0_DONE, hydra_base + HYDRA_INT_STATUS);
    }
}
```

## Interrupt Priorities and Behavior

### Priority Order (Software Handling)

1. **DMA Error** (Bit 2) - Highest priority, indicates transfer failure
2. **DMA Done** (Bit 1) - Normal DMA completion
3. **Frame Done** (Bit 0) - Rendering cycle completion
4. **Blitter Done** (Bit 4) - 3D acceleration completion
5. **Region-0 Done** (Bit 5) - Surface extraction completion
6. **Test Interrupt** (Bit 3) - Diagnostic only

### Special Behaviors

- **DMA Error vs DMA Done**: When a DMA error occurs, both bit 1 (DMA done) and bit 2 (DMA error) are set simultaneously
- **Frame Done Latching**: The frame done interrupt is automatically cleared when the STATUS register is read
- **Soft Reset**: All interrupt status bits are cleared during soft reset
- **W1C Operation**: Writing 0 to a status bit has no effect; only writing 1 clears the bit

## Error Conditions

### DMA Alignment Errors

DMA transfers must be 8-byte aligned (addresses and lengths). If misaligned values are programmed:

- `HYDRA_INT_DMA_ERR` (bit 2) is set
- `HYDRA_INT_DMA_DONE` (bit 1) is also set to indicate completion
- The transfer does not actually execute
- DMA status register bit 2 is set

### DMA Busy During Start

Attempting to start a DMA transfer while another is in progress:

- `HYDRA_INT_DMA_ERR` (bit 2) is set
- DMA status register bit 2 is set
- No new transfer begins

## Testing and Debugging

### Test Interrupt

Writing `0x1` to the IRQ_TEST register (BAR0 + 0x0088) sets the test interrupt bit. This allows:

- Testing interrupt handler setup
- Verifying interrupt routing in hardware
- Debugging interrupt mask configurations

### Debug Sequence

1. Enable desired interrupts by writing to INT_MASK
2. Trigger operations (frame render, DMA, blitter)
3. Monitor interrupt status register
4. Verify interrupt pin assertion
5. Clear interrupts and verify de-assertion

## Performance Considerations

- **Interrupt Coalescing**: Multiple events may occur between interrupt handler calls
- **Read-Modify-Write**: Always read status before clearing to avoid losing events
- **Mask Management**: Consider temporarily masking interrupts during critical sections
- **Latency**: Hardware interrupt latency depends on PCIe interrupt routing

## Future Extensions

Bits 6-31 are reserved for future interrupt sources such as:
- HDMI sync events
- Additional DMA channels
- Hardware error conditions
- Performance monitoring thresholds</content>
<parameter name="filePath">/workspaces/hydra/docs/hydra_interrupt_reference.md