`ifndef AES_IP_TEST_SV
`define AES_IP_TEST_SV

// ============================================================================
// AES IP Core Testbench
// Demonstrates integration with Hydra crossbar system
// ============================================================================

import uvm_pkg::*;
`include "uvm_macros.svh"

import crossbar_pkg::*;

module aes_ip_test;

    // ============================================================================
    // Testbench Signals
    // ============================================================================

    logic clk = 1'b0;
    logic rst_n = 1'b0;

    always #5ns clk = ~clk;  // 100MHz clock

    initial begin
        #10ns rst_n = 1'b1;
    end

    // ============================================================================
    // Interface Declarations
    // ============================================================================

    // Crossbar system interfaces
    axil_if axil_master (.*);
    axi_if  axi_master (.*);
    axis_if axis_encrypt_in (.*);
    axis_if axis_encrypt_out (.*);
    axis_if axis_decrypt_in (.*);
    axis_if axis_decrypt_out (.*);

    // AES-specific signals
    logic [255:0] aes_key;
    logic         key_valid;
    logic         key_ready;
    logic [127:0] iv;
    logic         iv_valid;
    logic         iv_ready;

    // Control and status
    logic        enable = 1'b1;
    logic [31:0] control;
    logic        ready;
    logic [31:0] status;
    logic [31:0] error_count;
    logic [63:0] blocks_processed;
    logic [31:0] latency_cycles;

    // ============================================================================
    // DUT Instantiation
    // ============================================================================

    aes_ip_core #(
        .IP_TYPE("OPEN_SOURCE"),
        .KEY_SIZE(256),
        .MODE(0)  // ECB mode
    ) dut (
        .axil_if(axil_master),
        .axi_data_if(axi_master),
        .axis_encrypt_out(axis_encrypt_out),
        .axis_encrypt_in(axis_encrypt_in),
        .axis_decrypt_out(axis_decrypt_out),
        .axis_decrypt_in(axis_decrypt_in),
        .aes_key(aes_key),
        .key_valid(key_valid),
        .key_ready(key_ready),
        .iv(iv),
        .iv_valid(iv_valid),
        .iv_ready(iv_ready),
        .enable(enable),
        .control(control),
        .ready(ready),
        .status(status),
        .error_count(error_count),
        .blocks_processed(blocks_processed),
        .latency_cycles(latency_cycles)
    );

    // ============================================================================
    // Test Tasks
    // ============================================================================

    task automatic axil_write(input logic [31:0] addr, input logic [31:0] data);
        axil_master.awaddr = addr;
        axil_master.awvalid = 1'b1;
        axil_master.wdata = data;
        axil_master.wvalid = 1'b1;
        axil_master.bready = 1'b1;

        wait(axil_master.awready && axil_master.wready);

        axil_master.awvalid = 1'b0;
        axil_master.wvalid = 1'b0;

        wait(axil_master.bvalid);
        axil_master.bready = 1'b0;

        $display("AXI-Lite Write: addr=0x%08x, data=0x%08x", addr, data);
    endtask

    task automatic axil_read(input logic [31:0] addr, output logic [31:0] data);
        axil_master.araddr = addr;
        axil_master.arvalid = 1'b1;
        axil_master.rready = 1'b1;

        wait(axil_master.arready);
        axil_master.arvalid = 1'b0;

        wait(axil_master.rvalid);
        data = axil_master.rdata;
        axil_master.rready = 1'b0;

        $display("AXI-Lite Read: addr=0x%08x, data=0x%08x", addr, data);
    endtask

    task automatic load_aes_key(input logic [255:0] key);
        aes_key = key;
        key_valid = 1'b1;
        wait(key_ready);
        #10ns;
        key_valid = 1'b0;
        $display("AES Key loaded: 0x%x", key);
    endtask

    task automatic load_iv(input logic [127:0] init_vector);
        iv = init_vector;
        iv_valid = 1'b1;
        wait(iv_ready);
        #10ns;
        iv_valid = 1'b0;
        $display("AES IV loaded: 0x%x", init_vector);
    endtask

    task automatic send_encrypt_data(input logic [127:0] plaintext);
        axis_encrypt_in.tdata = plaintext;
        axis_encrypt_in.tvalid = 1'b1;
        axis_encrypt_in.tlast = 1'b1;

        wait(axis_encrypt_in.tready);
        #10ns;
        axis_encrypt_in.tvalid = 1'b0;
        axis_encrypt_in.tlast = 1'b0;

        $display("Encryption input: 0x%x", plaintext);
    endtask

    task automatic receive_encrypt_data(output logic [127:0] ciphertext);
        axis_encrypt_out.tready = 1'b1;
        wait(axis_encrypt_out.tvalid);
        ciphertext = axis_encrypt_out.tdata;
        #10ns;
        axis_encrypt_out.tready = 1'b0;

        $display("Encryption output: 0x%x", ciphertext);
    endtask

    task automatic send_decrypt_data(input logic [127:0] ciphertext);
        axis_decrypt_in.tdata = ciphertext;
        axis_decrypt_in.tvalid = 1'b1;
        axis_decrypt_in.tlast = 1'b1;

        wait(axis_decrypt_in.tready);
        #10ns;
        axis_decrypt_in.tvalid = 1'b0;
        axis_decrypt_in.tlast = 1'b0;

        $display("Decryption input: 0x%x", ciphertext);
    endtask

    task automatic receive_decrypt_data(output logic [127:0] plaintext);
        axis_decrypt_out.tready = 1'b1;
        wait(axis_decrypt_out.tvalid);
        plaintext = axis_decrypt_out.tdata;
        #10ns;
        axis_decrypt_out.tready = 1'b0;

        $display("Decryption output: 0x%x", plaintext);
    endtask

    // ============================================================================
    // Test Sequences
    // ============================================================================

    task automatic test_aes_ecb_encryption();
        $display("\n=== Testing AES-256 ECB Encryption ===");

        logic [255:0] key = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
        logic [127:0] plaintext = 128'h6bc1bee22e409f96e93d7e117393172a;
        logic [127:0] expected_ciphertext = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;
        logic [127:0] actual_ciphertext;

        // Load key
        load_aes_key(key);

        // Configure for encryption
        axil_write(0, 32'h0000_0004);  // operation_mode=0 (encrypt), start=1

        // Send plaintext
        send_encrypt_data(plaintext);

        // Receive ciphertext
        receive_encrypt_data(actual_ciphertext);

        // Verify result
        if (actual_ciphertext == expected_ciphertext) begin
            $display("✓ Encryption test PASSED");
        end else begin
            $display("✗ Encryption test FAILED");
            $display("  Expected: 0x%x", expected_ciphertext);
            $display("  Actual:   0x%x", actual_ciphertext);
        end
    endtask

    task automatic test_aes_ecb_decryption();
        $display("\n=== Testing AES-256 ECB Decryption ===");

        logic [255:0] key = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
        logic [127:0] ciphertext = 128'hf3eed1bdb5d2a03c064b5a7e3db181f8;
        logic [127:0] expected_plaintext = 128'h6bc1bee22e409f96e93d7e117393172a;
        logic [127:0] actual_plaintext;

        // Load key
        load_aes_key(key);

        // Configure for decryption
        axil_write(0, 32'h0000_0005);  // operation_mode=1 (decrypt), start=1

        // Send ciphertext
        send_decrypt_data(ciphertext);

        // Receive plaintext
        receive_decrypt_data(actual_plaintext);

        // Verify result
        if (actual_plaintext == expected_plaintext) begin
            $display("✓ Decryption test PASSED");
        end else begin
            $display("✗ Decryption test FAILED");
            $display("  Expected: 0x%x", expected_plaintext);
            $display("  Actual:   0x%x", actual_plaintext);
        end
    endtask

    task automatic test_round_trip();
        $display("\n=== Testing AES Round-Trip (Encrypt → Decrypt) ===");

        logic [255:0] key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        logic [127:0] original_plaintext = 128'h00112233445566778899aabbccddeeff;
        logic [127:0] ciphertext, decrypted_plaintext;

        // Load key
        load_aes_key(key);

        // Encrypt
        axil_write(0, 32'h0000_0004);  // Encrypt mode, start
        send_encrypt_data(original_plaintext);
        receive_encrypt_data(ciphertext);

        // Decrypt
        axil_write(0, 32'h0000_0005);  // Decrypt mode, start
        send_decrypt_data(ciphertext);
        receive_decrypt_data(decrypted_plaintext);

        // Verify round-trip
        if (decrypted_plaintext == original_plaintext) begin
            $display("✓ Round-trip test PASSED");
            $display("  Original:  0x%x", original_plaintext);
            $display("  Cipher:    0x%x", ciphertext);
            $display("  Decrypted: 0x%x", decrypted_plaintext);
        end else begin
            $display("✗ Round-trip test FAILED");
        end
    endtask

    task automatic test_performance();
        $display("\n=== Testing AES Performance ===");

        logic [255:0] key = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;
        logic [127:0] test_data[10] = '{
            128'h6bc1bee22e409f96e93d7e117393172a,
            128'hae2d8a571e03ac9c9eb76fac45af8e51,
            128'h30c81c46a35ce411e5fbc1191a0a52ef,
            128'hf69f2445df4f9b17ad2b417be66c3710,
            128'h00112233445566778899aabbccddeeff,
            128'hffeeddccbbaa99887766554433221100,
            128'h0123456789abcdef0123456789abcdef,
            128'hfedcba9876543210fedcba9876543210,
            128'h00000000000000000000000000000000,
            128'hffffffffffffffffffffffffffffffff
        };

        logic [63:0] start_blocks, end_blocks;
        logic [31:0] start_time, end_time;

        // Load key
        load_aes_key(key);

        // Get initial counters
        start_blocks = blocks_processed;
        start_time = $time / 10;  // Convert to ns

        // Process multiple blocks
        foreach (test_data[i]) begin
            logic [127:0] dummy;
            axil_write(0, 32'h0000_0004);  // Encrypt
            send_encrypt_data(test_data[i]);
            receive_encrypt_data(dummy);
        end

        // Get final counters
        end_blocks = blocks_processed;
        end_time = $time / 10;

        // Calculate performance
        logic [63:0] blocks_processed_total = end_blocks - start_blocks;
        logic [31:0] time_elapsed = end_time - start_time;
        real throughput = (blocks_processed_total * 128.0) / time_elapsed;  // Mbps

        $display("Performance Results:");
        $display("  Blocks processed: %0d", blocks_processed_total);
        $display("  Time elapsed: %0d ns", time_elapsed);
        $display("  Throughput: %0.2f Mbps", throughput);
        $display("  Latency: %0d cycles/block", latency_cycles);
    endtask

    // ============================================================================
    // Main Test Execution
    // ============================================================================

    initial begin
        $display("Starting AES IP Core Testbench");
        $display("=================================");

        // Wait for reset
        @(posedge rst_n);
        #100ns;

        // Run tests
        test_aes_ecb_encryption();
        #100ns;

        test_aes_ecb_decryption();
        #100ns;

        test_round_trip();
        #100ns;

        test_performance();
        #100ns;

        // Check final status
        begin
            logic [31:0] final_status, final_errors;
            logic [63:0] total_blocks;
            axil_read(4, final_status);      // Status register
            axil_read(24, final_errors);     // Error count
            total_blocks = blocks_processed;

            $display("\n=== Final Test Results ===");
            $display("Status: 0x%08x", final_status);
            $display("Errors: %0d", final_errors);
            $display("Total blocks processed: %0d", total_blocks);
        end

        $display("\nAES IP Core testbench completed");
        $finish;
    end

    // ============================================================================
    // Waveform Dumping
    // ============================================================================

    initial begin
        $dumpfile("aes_ip_test.vcd");
        $dumpvars(0, aes_ip_test);
    end

    // ============================================================================
    // Timeout Protection
    // ============================================================================

    initial begin
        #1000000ns;  // 1ms timeout
        $error("Testbench timeout");
        $finish;
    end

endmodule : aes_ip_test

`endif // AES_IP_TEST_SV