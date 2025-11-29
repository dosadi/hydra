`ifndef HYDRA_TESTBENCH_SV
`define HYDRA_TESTBENCH_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import hydra_uvm_pkg::*;

module hydra_testbench;

  // Clock and reset
  logic clk;
  logic rst_n;

  // Virtual interface
  hydra_axil_if axil_if(.clk(clk), .rst_n(rst_n));

  // DUT instantiation (placeholder - replace with actual DUT)
  // hydra_top dut (
  //   .clk(clk),
  //   .rst_n(rst_n),
  //   .axil_if(axil_if.dut)
  // );

  // Clock generation
  initial begin
    clk = 0;
    forever #5ns clk = ~clk;  // 100MHz clock
  end

  // Reset generation
  initial begin
    rst_n = 0;
    #100ns;
    rst_n = 1;
  end

  // UVM test execution
  initial begin
    // Set virtual interface in config DB
    uvm_config_db#(virtual hydra_axil_if)::set(null, "uvm_test_top.env.axil_agent*",
                                               "vif", axil_if);

    // Run the test
    run_test();
  end

  // Waveform dumping
  initial begin
    $dumpfile("hydra_testbench.vcd");
    $dumpvars(0, hydra_testbench);
  end

endmodule : hydra_testbench

`endif
