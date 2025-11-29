`ifndef HYDRA_AXIL_AGENT_SV
`define HYDRA_AXIL_AGENT_SV

class hydra_axil_agent extends uvm_agent;
  `uvm_component_utils(hydra_axil_agent)

  // Agent components
  hydra_axil_driver    driver;
  hydra_axil_monitor   monitor;
  hydra_axil_sequencer sequencer;

  // Configuration
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  // Virtual interface
  virtual hydra_axil_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Get virtual interface
    if (!uvm_config_db#(virtual hydra_axil_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "AXI-Lite virtual interface not found")

    // Set interface for components
    uvm_config_db#(virtual hydra_axil_if)::set(this, "*", "vif", vif);

    // Create monitor (always present)
    monitor = hydra_axil_monitor::type_id::create("monitor", this);

    // Create active components only if agent is active
    if (is_active == UVM_ACTIVE) begin
      driver = hydra_axil_driver::type_id::create("driver", this);
      sequencer = hydra_axil_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect driver to sequencer if active
    if (is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : hydra_axil_agent

`endif
