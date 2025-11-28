# Hydra libhydra API Documentation

This directory contains automatically generated API documentation for the Hydra libhydra userspace library.

## Generating Documentation

To generate the API documentation:

```bash
# Install Doxygen (if not already installed)
sudo apt install doxygen

# Generate documentation
make doxygen
```

This will create HTML documentation in `docs/api/html/`.

## Viewing Documentation

After generation, open `docs/api/html/index.html` in your web browser to view the complete API reference.

## What's Included

The documentation covers:

- **Data Structures**: All public structs like `hydra_handle`, `hydra_camera_state`, etc.
- **Functions**: Complete reference for all libhydra functions with parameters and return values
- **Constants**: Version macros and other defines
- **Usage Examples**: Code snippets showing how to use each function

## Key Functions

### Device Management
- `hydra_open()` / `hydra_close()` - Open/close device connections
- `hydra_info_query()` - Get device information
- `hydra_device_present()` - Check if device exists

### Register Access
- `hydra_rd32()` / `hydra_wr32()` - Direct register read/write
- `hydra_get_int_status()` / `hydra_get_int_mask()` - Interrupt handling

### High-Level Control
- `hydra_set_camera_raw()` - Set camera position/orientation
- `hydra_set_flags()` - Control rendering features
- `hydra_set_selection()` - Select voxels for editing
- `hydra_apply_state()` - Update all state at once

### Advanced Operations
- `hydra_blit_*()` functions - Blitter operations for data transfer
- `hydra_surface_extract_stub()` - Surface data extraction
- `hydra_dma_copy()` - DMA operations

## Data Structures

### hydra_handle
Represents an open connection to a Hydra device. Initialize with `HYDRA_HANDLE_INIT`.

### hydra_camera_state
Contains camera parameters in fixed-point format (scale factor FX = 256).

### hydra_flags_state
Boolean flags controlling rendering features like smoothing, curvature, lighting effects.

### hydra_selection_state
Represents the currently selected voxel for editing operations.

## Error Handling

All functions return 0 on success or a negative errno value on failure. Common errors include:
- `-ENODEV`: Device not found
- `-EBUSY`: Device busy
- `-EINVAL`: Invalid parameters
- `-EIO`: I/O error

## Thread Safety

The libhydra library is not thread-safe. Do not call libhydra functions from multiple threads simultaneously on the same device handle.

## Version Information

The library version can be retrieved with `hydra_version_string()` or through the version macros:
- `HYDRA_LIBHYDRA_VERSION_MAJOR`
- `HYDRA_LIBHYDRA_VERSION_MINOR`
- `HYDRA_LIBHYDRA_VERSION_PATCH`