`ifndef HYDRA_PRODUCT_CONFIG_SV
`define HYDRA_PRODUCT_CONFIG_SV

// Hydra Product Configuration Classes
// Support for diverse product lines with different feature sets

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

  function string get_product_name();
    return get_name();
  endfunction
endclass

// USB Graphics Product Configuration
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

// HDMI Product Configuration
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

// Enterprise Product Configuration
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

// Product Configuration Factory
class hydra_product_factory;
  static function hydra_product_config create_product(string product_name);
    case (product_name)
      "hydra_usb_product": return hydra_usb_product::type_id::create("usb_product");
      "hydra_hdmi_product": return hydra_hdmi_product::type_id::create("hdmi_product");
      "hydra_enterprise_product": return hydra_enterprise_product::type_id::create("enterprise_product");
      default: begin
        `uvm_fatal("FACTORY", $sformatf("Unknown product configuration: %s", product_name))
        return null;
      end
    endcase
  endfunction
endclass

`endif
