// SPDX-License-Identifier: BSD-3-Clause
// Simple test bench for axi_sdram_stub: ensure out-of-range addresses return SLVERR.
`timescale 1ns/1ps

module test_axi_sdram_error;
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

    // Read channel
    reg [3:0]  arid   = 4'd0;
    reg [27:0] araddr = 28'd0;
    reg [7:0]  arlen  = 8'd0;
    reg [2:0]  arsize = 3'd3;
    reg [1:0]  arburst= 2'd1;
    reg        arvalid= 1'b0;
    wire       arready;
    wire [3:0] rid;
    wire [63:0] rdata;
    wire [1:0]  rresp;
    wire        rlast;
    wire        rvalid;
    reg         rready = 1'b0;

    axi_sdram_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4),
        .MEM_WORDS (1 << 4) // keep small to trigger error easily
    ) dut (
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

        .s_axi_arid(arid),
        .s_axi_araddr(araddr),
        .s_axi_arlen(arlen),
        .s_axi_arsize(arsize),
        .s_axi_arburst(arburst),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rid(rid),
        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),

        .dbg_we(1'b0),
        .dbg_addr(28'd0),
        .dbg_wdata(64'd0),
        .dbg_re(1'b0),
        .dbg_rdata()
    );

    always #5 clk = ~clk;

    task automatic issue_aw(input [27:0] addr);
        begin
            awaddr  <= addr;
            awvalid <= 1'b1;
            while (!(awvalid && awready)) begin
                @(posedge clk);
            end
            @(posedge clk);
            awvalid <= 1'b0;
        end
    endtask

    task automatic issue_w(output [1:0] resp);
        begin
            wvalid <= 1'b1;
            bready <= 1'b1;
            while (!(wvalid && wready)) begin
                @(posedge clk);
            end
            @(posedge clk);
            wvalid <= 1'b0;
            // wait for response
            while (!bvalid) @(posedge clk);
            resp = bresp;
            bready <= 1'b0;
        end
    endtask

    task automatic issue_ar(input [27:0] addr);
        begin
            araddr  <= addr;
            arvalid <= 1'b1;
            while (!(arvalid && arready)) begin
                @(posedge clk);
            end
            @(posedge clk);
            arvalid <= 1'b0;
        end
    endtask

    reg [1:0] resp;

    initial begin
        $display("test_axi_sdram_error: start");
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // Issue write beyond MEM_WORDS: expect SLVERR
        issue_aw(28'h1000_000);
        issue_w(resp);
        $display("write resp=%b bvalid=%b bresp=%b", resp, bvalid, bresp);
        if (resp != 2'b10) begin
            $fatal(1, "Expected SLVERR on write");
        end
        @(posedge clk);

        // Issue read beyond MEM_WORDS: expect SLVERR and no data payload.
        issue_ar(28'h1000_000);
        rready <= 1'b1;
        while (!rvalid) @(posedge clk);
        $display("read resp=%b rvalid=%b rresp=%b", rresp, rvalid, rresp);
        if (rresp != 2'b10) begin
            $fatal(1, "Expected SLVERR on read");
        end
        if (rdata != 64'd0) begin
            $fatal(1, "Error read should return zeros, got 0x%h", rdata);
        end
        @(posedge clk);
        rready <= 1'b0;

        $display("test_axi_sdram_error: PASS");
        $finish;
    end
endmodule
