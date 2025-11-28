# Clock Domain Crossing (CDC) Audit

## Overview

This document tracks Clock Domain Crossing analysis and mitigation for the Hydra design.

## Current Clock Domains

- **Main System Clock (`clk`)**: All RTL logic operates in this domain
  - AXI-Lite CSR interface
  - Voxel core and raycaster
  - DMA stub
  - HDMI output pipeline

## CDC Analysis

### Asynchronous Inputs
- `rst_n`: Asynchronous reset (active low)
  - **Mitigation**: Async assert, sync deassert pattern used throughout
  - **SVA**: Reset recovery time checking added
  - **Waiver**: Glitch-free reset input assumed from board design

### Synchronous Interfaces
- All AXI interfaces are synchronous to `clk`
- PCIe interface (future) will require CDC synchronizers
- External interrupts (future) will require pulse synchronizers

## Mitigation Strategies

### 1. Reset Synchronization
- All flops use `always @(posedge clk or negedge rst_n)`
- Reset recovery SVAs ensure stable deassertion
- No reset domain crossings currently

### 2. Data Synchronization
- Use `cdc_synchronizer.sv` for multi-bit data crossing
- Use `cdc_pulse_sync.sv` for pulse signals crossing domains

### 3. Future PCIe Interface
When PCIe is added:
- PCIe clock domain → System clock domain crossing
- MSI interrupts require pulse synchronization
- DMA descriptors require data synchronization

## SVA Coverage

Added SVAs for:
- Reset recovery time
- Reset glitch detection
- IRQ pulse timing (single-clock for now)

## Waiver List

- **Reset glitches**: Assumed handled by board-level reset circuitry
- **Single clock domain**: Current design is single-clock, no crossings needed
- **Debug signals**: No timing requirements, false paths in SDC

## Future Work

- Add PCIe CDC synchronizers when PCIe interface is implemented
- Add formal CDC verification
- Create CDC waiver database for synthesis tools