`ifndef HYDRA_AXIL_SEQUENCER_SV
`define HYDRA_AXIL_SEQUENCER_SV

class hydra_axil_sequencer extends uvm_sequencer#(hydra_axil_item);
  `uvm_component_utils(hydra_axil_sequencer)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

endclass : hydra_axil_sequencer

`endif
