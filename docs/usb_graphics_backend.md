# USB Graphics Backend Implementation

## Overview

The USB Graphics Backend provides graphics output through USB interfaces, supporting various USB display protocols for flexible graphics connectivity.

## Backend Architecture

```cpp
class USBGraphicsBackend : public PlatformBackend {
public:
  USBGraphicsBackend();
  ~USBGraphicsBackend() override;

  // PlatformBackend interface
  bool initialize(int width, int height, bool vsync) override;
  void present_frame(const uint32_t* pixels) override;
  void shutdown() override;

  // USB-specific methods
  bool detect_usb_display();
  bool configure_usb_mode(USBGraphicsMode mode);

private:
  // USB device management
  USBDevice* usb_device_;
  USBGraphicsController* controller_;

  // Frame management
  FrameBufferConverter* converter_;
  USBFrameEncoder* encoder_;

  // Configuration
  USBGraphicsMode current_mode_;
  int frame_width_;
  int frame_height_;
  bool vsync_enabled_;
};
```

## USB Graphics Modes

### 1. DisplayPort Alt Mode
```cpp
class DisplayPortUSBBackend : public USBGraphicsBackend {
public:
  bool initialize(int width, int height, bool vsync) override {
    // Detect DisplayPort alt mode capability
    if (!detect_displayport_alt_mode()) {
      return false;
    }

    // Configure for DisplayPort over USB-C
    configure_displayport_mode(width, height, vsync);

    // Initialize USB DisplayPort controller
    return initialize_displayport_controller();
  }

private:
  bool detect_displayport_alt_mode() {
    // Check USB-C connector for DisplayPort pins
    // Verify DisplayPort alt mode capability
    return usb_device_->supports_displayport_alt_mode();
  }

  void configure_displayport_mode(int width, int height, bool vsync) {
    // Set DisplayPort timing parameters
    displayport_config_.width = width;
    displayport_config_.height = height;
    displayport_config_.vsync = vsync;
    displayport_config_.color_depth = 24;  // RGB888
  }
};
```

### 2. HDMI over USB
```cpp
class HDMIUSBBackend : public USBGraphicsBackend {
public:
  bool initialize(int width, int height, bool vsync) override {
    // Find HDMI-over-USB adapter
    if (!find_hdmi_adapter()) {
      return false;
    }

    // Configure HDMI timing
    configure_hdmi_timing(width, height, vsync);

    // Initialize HDMI encoder
    return initialize_hdmi_encoder();
  }

private:
  bool find_hdmi_adapter() {
    // Scan for HDMI USB adapters
    // Check device descriptors for HDMI capability
    return usb_device_->is_hdmi_adapter();
  }

  void configure_hdmi_timing(int width, int height, bool vsync) {
    hdmi_config_.resolution = calculate_hdmi_resolution(width, height);
    hdmi_config_.vsync = vsync;
    hdmi_config_.color_space = HDMI_RGB;
    hdmi_config_.pixel_encoding = HDMI_RGB888;
  }
};
```

### 3. DisplayLink USB Graphics
```cpp
class DisplayLinkBackend : public USBGraphicsBackend {
public:
  bool initialize(int width, int height, bool vsync) override {
    // Detect DisplayLink device
    if (!detect_displaylink_device()) {
      return false;
    }

    // Configure compression settings
    configure_compression(width, height);

    // Initialize DisplayLink encoder
    return initialize_displaylink_encoder();
  }

private:
  bool detect_displaylink_device() {
    // Check for DisplayLink vendor/device IDs
    return usb_device_->get_vendor_id() == DISPLAYLINK_VENDOR_ID;
  }

  void configure_compression(int width, int height) {
    // DisplayLink uses lossy compression
    compression_config_.quality = DISPLAYLINK_DEFAULT_QUALITY;
    compression_config_.frame_rate = 30;  // Limited by USB bandwidth
    compression_config_.color_depth = 24;
  }
};
```

### 4. UVC (USB Video Class) Backend
```cpp
class UVCBackend : public USBGraphicsBackend {
public:
  bool initialize(int width, int height, bool vsync) override {
    // Find UVC-compliant device
    if (!find_uvc_device()) {
      return false;
    }

    // Configure UVC parameters
    configure_uvc_stream(width, height);

    // Start UVC stream
    return start_uvc_streaming();
  }

private:
  bool find_uvc_device() {
    // Look for UVC interface class
    return usb_device_->has_uvc_interface();
  }

  void configure_uvc_stream(int width, int height) {
    uvc_config_.format = UVC_FORMAT_RGB888;
    uvc_config_.width = width;
    uvc_config_.height = height;
    uvc_config_.frame_interval = calculate_frame_interval(30);  // 30 FPS
  }
};
```

## USB Device Management

### Device Detection and Enumeration
```cpp
class USBGraphicsDetector {
public:
  static std::vector<USBGraphicsDevice> detect_graphics_devices() {
    std::vector<USBGraphicsDevice> devices;

    // Enumerate all USB devices
    auto usb_devices = usb_context_.enumerate_devices();

    for (const auto& device : usb_devices) {
      if (is_graphics_device(device)) {
        USBGraphicsDevice graphics_device;
        graphics_device.usb_device = device;
        graphics_device.capabilities = detect_capabilities(device);
        graphics_device.supported_modes = enumerate_modes(device);
        devices.push_back(graphics_device);
      }
    }

    return devices;
  }

private:
  static bool is_graphics_device(const USBDevice& device) {
    // Check for graphics-related interface classes
    return device.has_display_interface() ||
           device.has_video_interface() ||
           device.supports_displayport_alt_mode();
  }

  static USBGraphicsCapabilities detect_capabilities(const USBDevice& device) {
    USBGraphicsCapabilities caps;

    // Check supported resolutions and refresh rates
    caps.max_resolution = get_max_resolution(device);
    caps.supported_formats = get_supported_formats(device);
    caps.bandwidth_limit = calculate_bandwidth_limit(device);

    return caps;
  }
};
```

### Backend Selection Logic
```cpp
PlatformBackend* select_usb_graphics_backend() {
  auto graphics_devices = USBGraphicsDetector::detect_graphics_devices();

  if (graphics_devices.empty()) {
    // No USB graphics devices found
    return new HeadlessBackend();
  }

  // Select best available backend
  for (const auto& device : graphics_devices) {
    if (device.capabilities.supports_displayport) {
      return new DisplayPortUSBBackend(device);
    }
  }

  for (const auto& device : graphics_devices) {
    if (device.capabilities.supports_hdmi) {
      return new HDMIUSBBackend(device);
    }
  }

  for (const auto& device : graphics_devices) {
    if (device.capabilities.supports_displaylink) {
      return new DisplayLinkBackend(device);
    }
  }

  // Fallback to UVC if available
  for (const auto& device : graphics_devices) {
    if (device.capabilities.supports_uvc) {
      return new UVCBackend(device);
    }
  }

  // No suitable backend found
  return new HeadlessBackend();
}
```

## Performance Considerations

### Bandwidth Management
```cpp
class USBGraphicsBandwidthManager {
public:
  bool can_support_resolution(int width, int height, int fps, USBGraphicsMode mode) {
    double required_bandwidth = calculate_required_bandwidth(width, height, fps, mode);
    double available_bandwidth = get_usb_bandwidth(mode);

    return required_bandwidth <= available_bandwidth;
  }

private:
  double calculate_required_bandwidth(int width, int height, int fps, USBGraphicsMode mode) {
    double pixels_per_second = width * height * fps;
    double bytes_per_pixel = get_bytes_per_pixel(mode);
    double compression_ratio = get_compression_ratio(mode);

    return (pixels_per_second * bytes_per_pixel) / compression_ratio;
  }

  double get_usb_bandwidth(USBGraphicsMode mode) {
    switch (mode) {
      case USB_MODE_DISPLAYPORT: return 32.4 * 1000 * 1000 * 1000;  // 32.4 Gbps
      case USB_MODE_HDMI:        return 18.0 * 1000 * 1000 * 1000;  // 18 Gbps
      case USB_MODE_DISPLAYLINK: return 5.0 * 1000 * 1000;          // 5 Gbps
      case USB_MODE_UVC:         return 5.0 * 1000 * 1000;          // 5 Gbps
      default:                   return 0.0;
    }
  }
};
```

## Integration with Build System

### Makefile Configuration
```makefile
# USB Graphics Backend Support
USB_GRAPHICS_ENABLED ?= 1

ifeq ($(USB_GRAPHICS_ENABLED), 1)
  CXXFLAGS += -DUSB_GRAPHICS_ENABLED
  LDFLAGS += -lusb-1.0

  # Backend source files
  SOURCES += sim/platform/usb_graphics_backend.cpp
  SOURCES += sim/platform/displayport_usb_backend.cpp
  SOURCES += sim/platform/hdmi_usb_backend.cpp
  SOURCES += sim/platform/displaylink_backend.cpp
  SOURCES += sim/platform/uvc_backend.cpp
endif
```

### CMake Configuration
```cmake
option(USB_GRAPHICS_ENABLED "Enable USB graphics backend" ON)

if(USB_GRAPHICS_ENABLED)
  find_package(USB1 REQUIRED)

  add_definitions(-DUSB_GRAPHICS_ENABLED)

  target_sources(hydra PRIVATE
    platform/usb_graphics_backend.cpp
    platform/displayport_usb_backend.cpp
    platform/hdmi_usb_backend.cpp
    platform/displaylink_backend.cpp
    platform/uvc_backend.cpp
  )

  target_link_libraries(hydra PRIVATE ${USB1_LIBRARIES})
endif()
```

This implementation provides comprehensive USB graphics support for the Hydra system, enabling flexible graphics output options across different USB display protocols and devices.