// SPDX-License-Identifier: BSD-3-Clause
// Test bench for axi_sdram_stub: test multi-beat burst handling
`timescale 1ns/1ps

module test_axi_sdram_burst;
    reg clk    = 0;
    reg rst_n  = 0;

    // Write channel
    reg [3:0]  awid   = 4'd0;
    reg [27:0] awaddr = 28'd0;
    reg [7:0]  awlen  = 8'd0;
    reg [2:0]  awsize = 3'd3;
    reg [1:0]  awburst= 2'd1;
    reg        awvalid= 1'b0;
    wire       awready;
    reg [63:0] wdata  = 64'd0;
    reg [7:0]  wstrb  = 8'hFF;
    reg        wlast  = 1'b1;
    reg        wvalid = 1'b0;
    wire       wready;
    wire [1:0] bresp;
    wire       bvalid;
    reg        bready = 1'b0;

    // Read channel - not present in this stub, use debug port instead
    // Debug port for reading back data
    reg        dbg_we = 1'b0;
    reg [27:0] dbg_addr = 28'd0;
    reg [63:0] dbg_wdata = 64'd0;
    reg        dbg_re = 1'b0;
    wire [63:0] dbg_rdata;

    axi_sdram_stub dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .s_axi_awid (awid),
        .s_axi_awaddr(awaddr),
        .s_axi_awlen(awlen),
        .s_axi_awsize(awsize),
        .s_axi_awburst(awburst),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bid(),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),

        .dbg_we(dbg_we),
        .dbg_addr(dbg_addr),
        .dbg_wdata(dbg_wdata),
        .dbg_re(dbg_re),
        .dbg_rdata(dbg_rdata)
    );

    always #5 clk = ~clk;

    task automatic issue_aw(input [27:0] addr, input [7:0] len, input [1:0] burst);
        begin
            awaddr  <= addr;
            awlen   <= len;
            awburst <= burst;
            awvalid <= 1'b1;
            while (!(awvalid && awready)) begin
                @(posedge clk);
            end
            @(posedge clk);
            awvalid <= 1'b0;
        end
    endtask

    task automatic issue_w_burst(input [7:0] len, output [1:0] resp);
        begin
            bready <= 1'b1;
            for (int i = 0; i <= len; i++) begin
                wdata  <= 64'hDEADBEEF00000000 + i;
                wlast  <= (i == len) ? 1'b1 : 1'b0;
                wvalid <= 1'b1;
                while (!(wvalid && wready)) begin
                    @(posedge clk);
                end
                @(posedge clk);
                wvalid <= 1'b0;
            end
            // wait for response
            while (!bvalid) @(posedge clk);
            resp = bresp;
            bready <= 1'b0;
        end
    endtask

    task automatic issue_ar(input [27:0] addr, input [7:0] len, input [1:0] burst);
        begin
            // Not implemented - use debug port instead
            $display("Read not supported in this stub - use debug port");
        end
    endtask

    task automatic read_burst(input [7:0] len);
        begin
            // Not implemented - use debug port instead
            $display("Read not supported in this stub - use debug port");
        end
    endtask

    reg [1:0] resp;

    initial begin
        $display("test_axi_sdram_burst: start");
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // Test 1: Single beat (awlen=0)
        $display("Test 1: Single beat write");
        issue_aw(28'h0, 8'd0, 2'b01); // INCR burst
        issue_w_burst(8'd0, resp);
        $display("Single beat write resp=%b", resp);
        if (resp != 2'b00) begin
            $fatal(1, "Expected OKAY on single beat write");
        end
        @(posedge clk);

        // Test 2: Multi-beat burst (awlen=3, 4 beats)
        $display("Test 2: 4-beat INCR burst write");
        issue_aw(28'h40, 8'd3, 2'b01); // INCR burst, 4 beats
        issue_w_burst(8'd3, resp);
        $display("4-beat write resp=%b", resp);
        if (resp != 2'b00) begin
            $fatal(1, "Expected OKAY on 4-beat write");
        end
        @(posedge clk);

        // Test 3: Read back the burst data via debug port
        $display("Test 3: Read back 4-beat burst via debug port");
        for (int i = 0; i <= 8'd3; i++) begin
            dbg_addr <= 28'h40 + i * 8;
            dbg_re <= 1'b1;
            @(posedge clk);
            $display("Debug read addr 0x%h: data=0x%h (expected: 0x%h)", 
                    28'h40 + i * 8, dbg_rdata, 64'hDEADBEEF00000000 + i);
            if (dbg_rdata !== 64'hDEADBEEF00000000 + i) begin
                $fatal(1, "Data mismatch at addr 0x%h", 28'h40 + i * 8);
            end
            dbg_re <= 1'b0;
            @(posedge clk);
        end

        // Test 4: WRAP burst
        $display("Test 4: 4-beat WRAP burst write");
        issue_aw(28'h80, 8'd3, 2'b10); // WRAP burst, 4 beats
        issue_w_burst(8'd3, resp);
        $display("4-beat WRAP write resp=%b", resp);
        if (resp != 2'b00) begin
            $fatal(1, "Expected OKAY on 4-beat WRAP write");
        end
        @(posedge clk);

        // Test 5: Read back WRAP burst via debug port
        $display("Test 5: Read back 4-beat WRAP burst via debug port");
        for (int i = 0; i <= 8'd3; i++) begin
            // WRAP burst address calculation: addr = (start & ~(len*size)) | ((start + i*size) & (len*size))
            // For len=3 (4 beats), size=8: mask = 3*8 = 24, so ~(24) = ~32 = all bits except lower 5
            // But simplified for this test - just sequential for now
            dbg_addr <= 28'h80 + i * 8;
            dbg_re <= 1'b1;
            @(posedge clk);
            $display("Debug read addr 0x%h: data=0x%h (expected: 0x%h)", 
                    28'h80 + i * 8, dbg_rdata, 64'hDEADBEEF00000000 + i);
            if (dbg_rdata !== 64'hDEADBEEF00000000 + i) begin
                $fatal(1, "Data mismatch at addr 0x%h", 28'h80 + i * 8);
            end
            dbg_re <= 1'b0;
            @(posedge clk);
        end

        $display("test_axi_sdram_burst: PASS");
        $finish;
    end
endmodule