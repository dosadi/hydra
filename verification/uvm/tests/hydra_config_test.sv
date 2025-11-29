`ifndef HYDRA_CONFIG_TEST_SV
`define HYDRA_CONFIG_TEST_SV

// Configuration-Driven Test for Diverse Product Lines
class hydra_config_test extends hydra_base_test;
  `uvm_component_utils(hydra_config_test)

  hydra_product_config product_cfg;

  function new(string name = "hydra_config_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    string product_config_name;

    super.build_phase(phase);

    // Get product configuration from command line
    if (!$value$plusargs("PRODUCT_CONFIG=%s", product_config_name)) begin
      product_config_name = "hydra_usb_product";  // Default to USB product
    end

    // Create product configuration using factory
    product_cfg = hydra_product_factory::create_product(product_config_name);

    // Configure environment based on product
    configure_environment_for_product(product_cfg);

    `uvm_info("CONFIG_TEST", $sformatf("Running test for product: %s",
              product_config_name), UVM_LOW)
  endfunction

  function void configure_environment_for_product(hydra_product_config cfg);
    // Configure AXI-Lite agent based on product features
    if (!cfg.has_axil_interface) begin
      env.axil_agent.is_active = UVM_PASSIVE;
      `uvm_info("CONFIG", "AXI-Lite interface disabled for this product", UVM_MEDIUM)
    end

    // Configure resolution limits for coverage
    uvm_config_db#(int)::set(this, "env.coverage", "max_res_x", cfg.max_resolution_x);
    uvm_config_db#(int)::set(this, "env.coverage", "max_res_y", cfg.max_resolution_y);

    // Configure framebuffer size constraints
    uvm_config_db#(int)::set(this, "env", "fb_size_mb", cfg.framebuffer_size_mb);

    // Configure feature availability
    uvm_config_db#(bit)::set(this, "*", "has_usb_graphics", cfg.has_usb_graphics);
    uvm_config_db#(bit)::set(this, "*", "has_hdmi_output", cfg.has_hdmi_output);
    uvm_config_db#(bit)::set(this, "*", "has_pcie_interface", cfg.has_pcie_interface);

    `uvm_info("CONFIG", $sformatf("Environment configured for: %s",
              cfg.get_product_name()), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  USB Graphics: %0d", cfg.has_usb_graphics), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  HDMI Output: %0d", cfg.has_hdmi_output), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  PCIe Interface: %0d", cfg.has_pcie_interface), UVM_LOW)
    `uvm_info("CONFIG", $sformatf("  Max Resolution: %0dx%0d",
              cfg.max_resolution_x, cfg.max_resolution_y), UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    hydra_csr_sequence csr_seq;
    hydra_dma_sequence dma_seq;
    hydra_blit_sequence blit_seq;
    hydra_frame_sequence frame_seq;

    super.run_phase(phase);

    phase.raise_objection(this);

    // Run product-specific test sequence
    if (product_cfg.has_axil_interface) begin
      `uvm_info("CONFIG_TEST", "Running CSR tests", UVM_MEDIUM)
      csr_seq = hydra_csr_sequence::type_id::create("csr_seq");
      csr_seq.start(env.axil_agent.sequencer);
    end

    if (product_cfg.has_usb_graphics || product_cfg.has_hdmi_output) begin
      `uvm_info("CONFIG_TEST", "Running graphics tests", UVM_MEDIUM)
      frame_seq = hydra_frame_sequence::type_id::create("frame_seq");
      frame_seq.start(env.axil_agent.sequencer);
    end

    // Run common tests
    `uvm_info("CONFIG_TEST", "Running DMA tests", UVM_MEDIUM)
    dma_seq = hydra_dma_sequence::type_id::create("dma_seq");
    dma_seq.start(env.axil_agent.sequencer);

    `uvm_info("CONFIG_TEST", "Running blitter tests", UVM_MEDIUM)
    blit_seq = hydra_blit_sequence::type_id::create("blit_seq");
    blit_seq.start(env.axil_agent.sequencer);

    phase.drop_objection(this);

    `uvm_info("CONFIG_TEST", $sformatf("Configuration test complete for: %s",
              product_cfg.get_product_name()), UVM_LOW)
  endtask

endclass : hydra_config_test

`endif
