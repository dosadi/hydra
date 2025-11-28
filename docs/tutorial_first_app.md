# Your First Hydra App Tutorial

This tutorial walks you through creating your first application that controls a Hydra device using the libhydra library. We'll build a simple camera control program that demonstrates the core concepts of device interaction, camera positioning, and render flag configuration.

## Prerequisites

Before starting, ensure you have:

1. **Built SDK**: Run `make sdk-setup` to build libhydra and tools
2. **Hardware/Device**: Either physical Hydra hardware or the simulation environment
3. **Basic C knowledge**: Familiarity with C programming and compilation

## Step 1: Project Setup

Create a new directory for your project and set up the basic files:

```bash
mkdir hydra_camera_app
cd hydra_camera_app
```

Create the following files:

**Makefile**
```makefile
CC = gcc
CFLAGS = -Wall -Wextra -O2 -I../drivers/libhydra -I../drivers/linux/uapi
LDFLAGS = -L../drivers/libhydra -lhydra

camera_app: camera_app.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f camera_app
```

**camera_app.c**
```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include "../drivers/libhydra/hydra.h"

int main(int argc, char** argv) {
    const char* dev_path = (argc > 1) ? argv[1] : "/dev/hydra_pcie";

    // Initialize handle
    struct hydra_handle h = HYDRA_HANDLE_INIT;

    // Try to open device
    int ret = hydra_open(&h, dev_path);
    if (ret != 0) {
        fprintf(stderr, "Failed to open %s: %s\n", dev_path, strerror(-ret));
        fprintf(stderr, "Make sure the device exists and you have permissions\n");
        return 1;
    }

    printf("Successfully opened Hydra device!\n");
    printf("libhydra version: %s\n", hydra_version_string());

    // Clean up
    hydra_close(&h);
    return 0;
}
```

Build and test the basic connection:

```bash
make
./camera_app
```

You should see output like:
```
Successfully opened Hydra device!
libhydra version: 0.0.5
```

## Step 2: Reading Device Information

Let's extend the app to read basic device information:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include "../drivers/libhydra/hydra.h"

int main(int argc, char** argv) {
    const char* dev_path = (argc > 1) ? argv[1] : "/dev/hydra_pcie";
    struct hydra_handle h = HYDRA_HANDLE_INIT;

    int ret = hydra_open(&h, dev_path);
    if (ret != 0) {
        fprintf(stderr, "Failed to open %s: %s\n", dev_path, strerror(-ret));
        return 1;
    }

    printf("Successfully opened Hydra device!\n");
    printf("libhydra version: %s\n", hydra_version_string());

    // Read device information
    struct hydra_info info;
    ret = hydra_info_query(&h, &info);
    if (ret == 0) {
        printf("\nDevice Information:\n");
        printf("  Vendor ID: 0x%04x\n", info.vendor_id);
        printf("  Device ID: 0x%04x\n", info.device_id);
        printf("  Revision: 0x%02x\n", info.revision);
        printf("  BAR0 size: %u bytes\n", info.bar0_size);
        printf("  BAR1 size: %u bytes\n", info.bar1_size);
    } else {
        fprintf(stderr, "Failed to query device info: %s\n", strerror(-ret));
    }

    // Read some basic registers
    uint32_t id_reg, rev_reg, status_reg;
    if (hydra_rd32(&h, 0x00, &id_reg) == 0) {
        printf("  ID register: 0x%08x\n", id_reg);
    }
    if (hydra_rd32(&h, 0x04, &rev_reg) == 0) {
        printf("  Revision register: 0x%08x\n", rev_reg);
    }
    if (hydra_rd32(&h, 0x08, &status_reg) == 0) {
        printf("  Status register: 0x%08x\n", status_reg);
    }

    hydra_close(&h);
    return 0;
}
```

Build and run:

```bash
make clean && make
./camera_app
```

## Step 3: Camera Control

Now let's add camera positioning functionality:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include "../drivers/libhydra/hydra.h"

void print_usage(const char* prog_name) {
    printf("Usage: %s [device_path] [command]\n", prog_name);
    printf("Commands:\n");
    printf("  info          - Show device information\n");
    printf("  camera x y z  - Set camera position\n");
    printf("  look dx dy dz - Set camera direction\n");
    printf("  flags smooth curvature light slice jitter - Set render flags\n");
    printf("  select x y z  - Set voxel selection\n");
    printf("  reset         - Soft reset device\n");
}

int main(int argc, char** argv) {
    const char* dev_path = "/dev/hydra_pcie";
    struct hydra_handle h = HYDRA_HANDLE_INIT;

    // Parse arguments
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "/dev/hydra_pcie") == 0 || strncmp(argv[1], "/dev/", 5) == 0) {
        dev_path = argv[1];
        argv++;
        argc--;
    }

    int ret = hydra_open(&h, dev_path);
    if (ret != 0) {
        fprintf(stderr, "Failed to open %s: %s\n", dev_path, strerror(-ret));
        return 1;
    }

    const char* command = argv[1];

    if (strcmp(command, "info") == 0) {
        // Device info (from previous step)
        struct hydra_info info;
        ret = hydra_info_query(&h, &info);
        if (ret == 0) {
            printf("Device: %04x:%04x rev %02x\n", info.vendor_id, info.device_id, info.revision);
            printf("BAR0: %u bytes, BAR1: %u bytes\n", info.bar0_size, info.bar1_size);
        }

    } else if (strcmp(command, "camera") == 0 && argc >= 5) {
        // Set camera position
        int32_t x = atoi(argv[2]);
        int32_t y = atoi(argv[3]);
        int32_t z = atoi(argv[4]);

        ret = hydra_set_camera_raw(&h, x, y, z, 0, 0, 0, 0, 0); // Position only
        if (ret == 0) {
            printf("Set camera position to (%d, %d, %d)\n", x, y, z);
        } else {
            fprintf(stderr, "Failed to set camera position\n");
        }

    } else if (strcmp(command, "look") == 0 && argc >= 5) {
        // Set camera direction
        int32_t dx = atoi(argv[2]);
        int32_t dy = atoi(argv[3]);
        int32_t dz = atoi(argv[4]);

        ret = hydra_set_camera_raw(&h, 0, 0, 0, dx, dy, dz, 0, 0); // Direction only
        if (ret == 0) {
            printf("Set camera direction to (%d, %d, %d)\n", dx, dy, dz);
        } else {
            fprintf(stderr, "Failed to set camera direction\n");
        }

    } else if (strcmp(command, "flags") == 0 && argc >= 7) {
        // Set render flags
        bool smooth = atoi(argv[2]);
        bool curvature = atoi(argv[3]);
        bool light = atoi(argv[4]);
        bool slice = atoi(argv[5]);
        bool jitter = atoi(argv[6]);

        ret = hydra_set_flags(&h, smooth, curvature, light, slice, jitter);
        if (ret == 0) {
            printf("Set render flags: smooth=%d curvature=%d light=%d slice=%d jitter=%d\n",
                   smooth, curvature, light, slice, jitter);
        } else {
            fprintf(stderr, "Failed to set render flags\n");
        }

    } else if (strcmp(command, "select") == 0 && argc >= 5) {
        // Set voxel selection
        uint8_t x = atoi(argv[2]);
        uint8_t y = atoi(argv[3]);
        uint8_t z = atoi(argv[4]);

        ret = hydra_set_selection(&h, true, x, y, z);
        if (ret == 0) {
            printf("Selected voxel at (%u, %u, %u)\n", x, y, z);
        } else {
            fprintf(stderr, "Failed to set selection\n");
        }

    } else if (strcmp(command, "reset") == 0) {
        // Soft reset
        ret = hydra_soft_reset(&h);
        if (ret == 0) {
            printf("Device reset complete\n");
        } else {
            fprintf(stderr, "Failed to reset device\n");
        }

    } else {
        print_usage(argv[0]);
        ret = 1;
    }

    hydra_close(&h);
    return ret ? 1 : 0;
}
```

## Step 4: Using State Structures

For more complex applications, use the state structures for batch updates:

```c
// Add this after the command handling
} else if (strcmp(command, "state") == 0) {
    // Demonstrate using state structures
    struct hydra_camera_state cam = {
        .cam_x = -512, .cam_y = -512, .cam_z = -512,
        .dir_x = -32768, .dir_y = 0, .dir_z = 0,
        .plane_x = 0, .plane_y = 64
    };

    struct hydra_flags_state flags = {
        .smooth = true,
        .curvature = false,
        .extra_light = true,
        .diag_slice = false,
        .ray_jitter = false
    };

    struct hydra_selection_state sel = {
        .active = true,
        .x = 5, .y = 10, .z = 15
    };

    ret = hydra_apply_state(&h, &cam, &flags, &sel);
    if (ret == 0) {
        printf("Applied complete state configuration\n");
    } else {
        fprintf(stderr, "Failed to apply state\n");
    }
```

## Step 5: Error Handling and Best Practices

Add proper error handling and resource management:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include "../drivers/libhydra/hydra.h"

// Helper function for error messages
void print_error(const char* operation, int error_code) {
    fprintf(stderr, "%s failed: %s (code: %d)\n", operation, strerror(-error_code), error_code);
}

int main(int argc, char** argv) {
    // ... argument parsing ...

    struct hydra_handle h = HYDRA_HANDLE_INIT;
    int ret;

    // Check if device exists before opening
    if (!hydra_device_present(dev_path)) {
        fprintf(stderr, "Device %s not found or not accessible\n", dev_path);
        fprintf(stderr, "Check that:\n");
        fprintf(stderr, "  - Hardware is connected and powered\n");
        fprintf(stderr, "  - Driver is loaded (lsmod | grep hydra)\n");
        fprintf(stderr, "  - Device node exists (ls -l %s)\n", dev_path);
        fprintf(stderr, "  - You have read/write permissions\n");
        return 1;
    }

    ret = hydra_open(&h, dev_path);
    if (ret != 0) {
        print_error("hydra_open", ret);
        return 1;
    }

    // Ensure handle is always closed
    int exit_code = 0;

    // ... command handling with error checking ...

    if (ret != 0) {
        print_error(command, ret);
        exit_code = 1;
    }

    hydra_close(&h);
    return exit_code;
}
```

## Step 6: Building and Testing

Build the complete application:

```bash
make clean && make
```

Test the different commands:

```bash
# Show device info
./camera_app info

# Set camera position
./camera_app camera -512 -512 -512

# Set camera direction (looking along negative X axis)
./camera_app look -32768 0 0

# Enable smooth rendering and extra lighting
./camera_app flags 1 0 1 0 0

# Select a voxel
./camera_app select 5 10 15

# Apply complete state
./camera_app state

# Reset device
./camera_app reset
```

## Step 7: Advanced Features (Optional)

For more advanced applications, you can add:

### Frame Synchronization
```c
// Start a frame render
ret = hydra_start_frame(&h);
if (ret == 0) {
    printf("Frame rendering started\n");
}

// Wait for completion (polling interrupts)
uint32_t int_status;
do {
    ret = hydra_get_int_status(&h, &int_status);
    if (ret != 0) break;
    usleep(1000); // 1ms delay
} while ((int_status & INT_STATUS_FRAME_DONE) == 0);

if (ret == 0) {
    printf("Frame completed\n");
    // Clear the interrupt
    hydra_clear_int_status(&h, INT_STATUS_FRAME_DONE);
}
```

### DMA Operations
```c
// Copy data using DMA (stub implementation)
uint64_t src_addr = 0x100000;  // Source in BAR1
uint64_t dst_addr = 0x200000;  // Destination in BAR1
uint32_t length = 4096;

ret = hydra_dma_copy(&h, src_addr, dst_addr, length);
if (ret == 0) {
    printf("DMA transfer initiated\n");
}
```

## Troubleshooting

### Common Issues

1. **"No such file or directory"**
   - Device node doesn't exist
   - Check `ls -l /dev/hydra_pcie`
   - Ensure driver is loaded: `lsmod | grep hydra`

2. **"Permission denied"**
   - Need read/write access to device
   - Try running as root or adjust udev rules

3. **"Device or resource busy"**
   - Another application has the device open
   - Close other Hydra applications first

4. **Invalid register values**
   - Check BAR sizes with `info` command
   - Ensure offsets are within valid ranges

### Debug Tips

- Use `hydra_rd32()` to read registers and verify writes
- Check interrupt status with `hydra_get_int_status()`
- Enable verbose logging in your application
- Test with simulation first before hardware

## Next Steps

Now that you have a working Hydra application, you can:

1. **Add interactive controls** - Use curses or SDL for real-time camera control
2. **Implement presets** - Save/load camera positions and settings
3. **Add frame capture** - Use DMA to read rendered frames
4. **Create animations** - Smoothly interpolate between camera positions
5. **Build a GUI** - Use GTK or Qt for a complete control interface

## Complete Source Code

The complete `camera_app.c` with all features is available in the Hydra repository under `scripts/` as reference examples. Check `hydra_cam_flags_demo.c` for a simpler version or `hydra_blit_smoketest.c` for DMA operations.

For more advanced usage, see the [libhydra API documentation](api.md) and [driver integration guide](driver_integration.md).</content>
<parameter name="filePath">/workspaces/hydra/docs/tutorial_first_app.md