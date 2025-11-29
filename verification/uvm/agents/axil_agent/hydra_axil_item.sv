`ifndef HYDRA_AXIL_ITEM_SV
`define HYDRA_AXIL_ITEM_SV

class hydra_axil_item extends uvm_sequence_item;
  `uvm_object_utils(hydra_axil_item)

  // AXI-Lite signals
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        write;
  rand int        delay;

  // Constraints
  constraint addr_align_c {
    addr[1:0] == 2'b00; // 32-bit aligned
  }

  constraint delay_c {
    delay inside {[0:10]};
  }

  function new(string name = "hydra_axil_item");
    super.new(name);
  endfunction

  function void do_copy(uvm_object rhs);
    hydra_axil_item rhs_;
    $cast(rhs_, rhs);
    super.do_copy(rhs);
    this.addr = rhs_.addr;
    this.data = rhs_.data;
    this.write = rhs_.write;
    this.delay = rhs_.delay;
  endfunction

  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    hydra_axil_item rhs_;
    bit status = 1;
    $cast(rhs_, rhs);
    status &= super.do_compare(rhs, comparer);
    status &= (this.addr == rhs_.addr);
    status &= (this.data == rhs_.data);
    status &= (this.write == rhs_.write);
    return status;
  endfunction

  function string convert2string();
    string s;
    s = $sformatf("AXI-Lite Transaction: %s Addr=0x%08h Data=0x%08h Delay=%0d",
                  write ? "WRITE" : "READ", addr, data, delay);
    return s;
  endfunction

  function void do_print(uvm_printer printer);
    printer.print_field("addr", addr, 32, UVM_HEX);
    printer.print_field("data", data, 32, UVM_HEX);
    printer.print_field("write", write, 1, UVM_BIN);
    printer.print_field("delay", delay, 32, UVM_DEC);
  endfunction

endclass : hydra_axil_item

`endif
