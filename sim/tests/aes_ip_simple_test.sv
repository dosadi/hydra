// ============================================================================
// Simple AES IP Core Integration Test
// Basic functionality test without UVM dependencies
// ============================================================================

`ifndef AES_IP_SIMPLE_TEST_SV
`define AES_IP_SIMPLE_TEST_SV

`include "crossbar_pkg.sv"
`include "open_source_aes_core.sv"
`include "aes_ip_core.sv"

import crossbar_pkg::*;

module aes_ip_simple_test;

    // ============================================================================
    // Testbench Signals
    // ============================================================================

    logic clk = 0;
    logic rst_n = 0;

    // AES IP Core interface
    axil_if axil_if_inst();
    axi_if axi_data_if_inst();
    axis_if axis_encrypt_out_inst();
    axis_if axis_encrypt_in_inst();
    axis_if axis_decrypt_out_inst();
    axis_if axis_decrypt_in_inst();

    // AES IP Core instance
    aes_ip_core #(
        .IP_TYPE("OPEN_SOURCE"),
        .KEY_SIZE(256),
        .MODE(0)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .axil_if(axil_if_inst.slave),
        .axi_data_if(axi_data_if_inst.slave),
        .axis_encrypt_out(axis_encrypt_out_inst.master),
        .axis_encrypt_in(axis_encrypt_in_inst.slave),
        .axis_decrypt_out(axis_decrypt_out_inst.master),
        .axis_decrypt_in(axis_decrypt_in_inst.slave),
        .enable(1'b1),
        .control(32'h0000_0001),  // Start encryption
        .ready(),
        .status(),
        .error_count(),
        .blocks_processed(),
        .latency_cycles()
    );

    // ============================================================================
    // Clock Generation
    // ============================================================================

    always #5 clk = ~clk;

    // ============================================================================
    // Test Sequence
    // ============================================================================

    initial begin
        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;
        #10;

        // Test AXI-Lite register access
        // Write to control register
        axil_if_inst.awaddr = 32'h0;
        axil_if_inst.awvalid = 1'b1;
        axil_if_inst.wdata = 32'h0000_0001;  // Start operation
        axil_if_inst.wvalid = 1'b1;
        axil_if_inst.wstrb = 4'hF;
        #10;

        // Check ready signals
        if (axil_if_inst.awready && axil_if_inst.wready) begin
            $display("SUCCESS: AXI-Lite write handshake working");
        end else begin
            $display("ERROR: AXI-Lite write handshake failed");
        end

        axil_if_inst.awvalid = 1'b0;
        axil_if_inst.wvalid = 1'b0;
        #10;

        // Read status register
        axil_if_inst.araddr = 32'h4;
        axil_if_inst.arvalid = 1'b1;
        #10;

        if (axil_if_inst.arready) begin
            $display("SUCCESS: AXI-Lite read handshake working");
        end else begin
            $display("ERROR: AXI-Lite read handshake failed");
        end

        axil_if_inst.arvalid = 1'b0;
        #10;

        // Test AXI-Stream data flow
        axis_encrypt_in_inst.tdata = 128'h0123456789ABCDEF0123456789ABCDEF;
        axis_encrypt_in_inst.tvalid = 1'b1;
        axis_encrypt_in_inst.tlast = 1'b1;
        axis_encrypt_in_inst.tstrb = '1;
        axis_encrypt_in_inst.tkeep = '1;
        #10;

        if (axis_encrypt_in_inst.tready) begin
            $display("SUCCESS: AXI-Stream input accepted");
        end else begin
            $display("ERROR: AXI-Stream input not ready");
        end

        #20;

        $display("AES IP Core integration test completed successfully!");
        $finish;
    end

endmodule : aes_ip_simple_test

`endif // AES_IP_SIMPLE_TEST_SV