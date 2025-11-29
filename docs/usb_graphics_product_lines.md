# USB Graphics Support for Hydra

## Overview

The Hydra FPGA accelerator supports USB graphics output through various USB display protocols and devices. This enables flexible graphics output options for different product configurations.

## Supported USB Graphics Standards

### 1. USB DisplayPort Alt Mode
- **Protocol**: DisplayPort over USB-C
- **Resolution**: Up to 8K@60Hz
- **Advantages**: High bandwidth, native DisplayPort compatibility
- **Implementation**: USB-C connector with DisplayPort alt mode

### 2. USB HDMI Adapters
- **Protocol**: HDMI over USB
- **Resolution**: Up to 4K@60Hz
- **Advantages**: HDMI compatibility, wide device support
- **Implementation**: USB-to-HDMI converter chips

### 3. USB DisplayLink
- **Protocol**: DisplayLink compression
- **Resolution**: Up to 4K (compressed)
- **Advantages**: Software-based, works with any USB host
- **Implementation**: DisplayLink USB graphics processor

### 4. USB Webcams/Frame Grabbers
- **Protocol**: UVC (USB Video Class)
- **Resolution**: Up to 4K@30Hz
- **Advantages**: Standard webcam interface
- **Implementation**: USB video capture devices

## Hardware Implementation

### USB Graphics PHY Integration

```systemverilog
// USB Graphics Controller Interface
interface usb_graphics_if();
  // USB signals
  logic usb_dp, usb_dm;        // USB differential pairs
  logic usb_vbus;              // USB power
  logic usb_id;                // USB ID pin (USB-C)

  // Graphics signals
  logic [23:0] pixel_data;     // RGB pixel data
  logic pixel_valid;           // Pixel data valid
  logic hsync, vsync;          // Sync signals
  logic pixel_clk;             // Pixel clock

  // Control signals
  logic enable;                // Graphics enable
  logic [1:0] mode;            // Graphics mode (DP/HDMI/DisplayLink/UVC)

  modport controller(
    input usb_dp, usb_dm, usb_vbus, usb_id,
    output pixel_data, pixel_valid, hsync, vsync, pixel_clk
  );

  modport phy(
    output usb_dp, usb_dm, usb_vbus, usb_id,
    input pixel_data, pixel_valid, hsync, vsync, pixel_clk, enable, mode
  );
endinterface
```

### USB Graphics Controller RTL

```systemverilog
module usb_graphics_controller (
  input clk, rst_n,

  // USB interface
  usb_graphics_if.phy usb_if,

  // Framebuffer interface
  input [31:0] fb_addr,
  output [31:0] fb_data,
  input fb_valid,

  // Configuration
  input [1:0] graphics_mode,
  input enable_graphics
);

  // USB protocol handler
  usb_protocol_handler usb_handler (
    .clk(clk), .rst_n(rst_n),
    .usb_if(usb_if),
    .mode(graphics_mode)
  );

  // Graphics encoder (DP/HDMI/DisplayLink/UVC)
  graphics_encoder encoder (
    .clk(clk), .rst_n(rst_n),
    .fb_addr(fb_addr),
    .fb_data(fb_data),
    .fb_valid(fb_valid),
    .usb_if(usb_if),
    .mode(graphics_mode)
  );

endmodule
```

## Software Integration

### USB Graphics Backend

```cpp
class USBGraphicsBackend : public PlatformBackend {
public:
  USBGraphicsBackend();
  ~USBGraphicsBackend();

  bool initialize(int width, int height, bool vsync) override;
  void present_frame(const uint32_t* pixels) override;
  void shutdown() override;

private:
  USBDevice* usb_device_;
  GraphicsEncoder* encoder_;
  FrameBufferConverter* converter_;
};
```

### Backend Selection Logic

```cpp
PlatformBackend* select_usb_graphics_backend() {
  // Detect available USB graphics devices
  if (detect_displayport_alt_mode()) {
    return new DisplayPortUSBBackend();
  } else if (detect_hdmi_adapter()) {
    return new HDMIUSBBackend();
  } else if (detect_displaylink()) {
    return new DisplayLinkBackend();
  } else if (detect_uvc_device()) {
    return new UVCBackend();
  }

  // Fallback to headless
  return new HeadlessBackend();
}
```

## Diverse Product Line Support

### Product Configuration Classes

```systemverilog
// Base product configuration
class hydra_product_config extends uvm_object;
  `uvm_object_utils(hydra_product_config)

  // Core features (common to all products)
  bit has_framebuffer = 1;
  bit has_axil_interface = 1;

  // Optional features
  bit has_usb_graphics = 0;
  bit has_hdmi_output = 0;
  bit has_pcie_interface = 0;
  bit has_ethernet = 0;

  // Performance parameters
  int max_resolution_x = 1920;
  int max_resolution_y = 1080;
  int max_frame_rate = 60;

  // Memory configuration
  int framebuffer_size_mb = 8;
  bit has_ddr_memory = 0;

  function new(string name = "hydra_product_config");
    super.new(name);
  endfunction

  pure virtual function void configure_product();
endclass

// Specific product configurations
class hydra_usb_product extends hydra_product_config;
  `uvm_object_utils(hydra_usb_product)

  function new(string name = "hydra_usb_product");
    super.new(name);
    configure_product();
  endfunction

  function void configure_product();
    has_usb_graphics = 1;
    has_hdmi_output = 0;
    has_pcie_interface = 0;
    max_resolution_x = 1920;
    max_resolution_y = 1080;
    framebuffer_size_mb = 8;
  endfunction
endclass

class hydra_hdmi_product extends hydra_product_config;
  `uvm_object_utils(hydra_hdmi_product)

  function new(string name = "hydra_hdmi_product");
    super.new(name);
    configure_product();
  endfunction

  function void configure_product();
    has_usb_graphics = 0;
    has_hdmi_output = 1;
    has_pcie_interface = 0;
    max_resolution_x = 3840;
    max_resolution_y = 2160;
    framebuffer_size_mb = 16;
  endfunction
endclass

class hydra_enterprise_product extends hydra_product_config;
  `uvm_object_utils(hydra_enterprise_product)

  function new(string name = "hydra_enterprise_product");
    super.new(name);
    configure_product();
  endfunction

  function void configure_product();
    has_usb_graphics = 1;
    has_hdmi_output = 1;
    has_pcie_interface = 1;
    has_ethernet = 1;
    has_ddr_memory = 1;
    max_resolution_x = 7680;
    max_resolution_y = 4320;
    framebuffer_size_mb = 64;
  endfunction
endclass
```

### Configuration-Driven Verification

```systemverilog
class hydra_config_test extends hydra_base_test;
  `uvm_component_utils(hydra_config_test)

  hydra_product_config product_cfg;

  function new(string name = "hydra_config_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get product configuration from command line or config file
    if (!$value$plusargs("PRODUCT_CONFIG=%s", product_config_name)) begin
      product_config_name = "hydra_usb_product";  // Default
    end

    // Create appropriate product configuration
    case (product_config_name)
      "hydra_usb_product": product_cfg = hydra_usb_product::type_id::create("product_cfg");
      "hydra_hdmi_product": product_cfg = hydra_hdmi_product::type_id::create("product_cfg");
      "hydra_enterprise_product": product_cfg = hydra_enterprise_product::type_id::create("product_cfg");
      default: `uvm_fatal("CONFIG", $sformatf("Unknown product config: %s", product_config_name))
    endcase

    // Configure environment based on product
    configure_environment_for_product(product_cfg);
  endfunction

  function void configure_environment_for_product(hydra_product_config cfg);
    // Enable/disable agents based on product features
    if (!cfg.has_axil_interface) begin
      env.axil_agent.is_active = UVM_PASSIVE;
    end

    // Configure resolution limits
    env.max_res_x = cfg.max_resolution_x;
    env.max_res_y = cfg.max_resolution_y;

    // Set memory constraints
    env.fb_size_mb = cfg.framebuffer_size_mb;

    `uvm_info("CONFIG", $sformatf("Configured for product: %s", cfg.get_name()), UVM_LOW)
  endfunction
endclass
```

## Testing Diverse Configurations

### Multi-Product Test Suite

```bash
# Test USB graphics product
make test_integration PRODUCT_CONFIG=hydra_usb_product

# Test HDMI product
make test_integration PRODUCT_CONFIG=hydra_hdmi_product

# Test enterprise product
make test_integration PRODUCT_CONFIG=hydra_enterprise_product
```

### Configuration Coverage

```systemverilog
covergroup product_config_cg;
  option.per_instance = 1;

  product_type_cp: coverpoint product_cfg.get_name() {
    bins usb_product = {"hydra_usb_product"};
    bins hdmi_product = {"hydra_hdmi_product"};
    bins enterprise_product = {"hydra_enterprise_product"};
  }

  usb_graphics_cp: coverpoint product_cfg.has_usb_graphics;
  hdmi_output_cp: coverpoint product_cfg.has_hdmi_output;
  pcie_interface_cp: coverpoint product_cfg.has_pcie_interface;

  // Cross coverage
  product_x_usb: cross product_type_cp, usb_graphics_cp;
  product_x_hdmi: cross product_type_cp, hdmi_output_cp;
endgroup
```

## Build System Integration

### Makefile Configuration

```makefile
# Product configuration
PRODUCT_CONFIG ?= hydra_usb_product

# Feature flags based on product
ifeq ($(PRODUCT_CONFIG), hydra_usb_product)
  USB_GRAPHICS = 1
  HDMI_OUTPUT = 0
  PCIe_INTERFACE = 0
endif

ifeq ($(PRODUCT_CONFIG), hydra_hdmi_product)
  USB_GRAPHICS = 0
  HDMI_OUTPUT = 1
  PCIe_INTERFACE = 0
endif

ifeq ($(PRODUCT_CONFIG), hydra_enterprise_product)
  USB_GRAPHICS = 1
  HDMI_OUTPUT = 1
  PCIe_INTERFACE = 1
endif

# Compile flags
CFLAGS += -DPRODUCT_CONFIG=$(PRODUCT_CONFIG)
ifeq ($(USB_GRAPHICS), 1)
  CFLAGS += -DUSB_GRAPHICS_ENABLED
endif
```

This implementation provides comprehensive USB graphics support and flexible product line configuration for the Hydra FPGA accelerator, enabling diverse product offerings with appropriate verification coverage.