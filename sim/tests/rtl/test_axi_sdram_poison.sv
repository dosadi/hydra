// SPDX-License-Identifier: BSD-3-Clause
// Verify POISON_ON_UNINIT returns X data for unwritten addresses.
`timescale 1ns/1ps

module test_axi_sdram_poison;
    reg clk = 0;
    reg rst_n = 0;

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

    wire       awready;
    wire       wready;
    wire [1:0] bresp;
    wire       bvalid;

    axi_sdram_stub #(
        .MEM_WORDS        (1 << 4),
        .POISON_ON_UNINIT (1)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .s_axi_awid (4'd0),
        .s_axi_awaddr(28'd0),
        .s_axi_awlen(8'd0),
        .s_axi_awsize(3'd3),
        .s_axi_awburst(2'd1),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(awready),
        .s_axi_wdata(64'd0),
        .s_axi_wstrb(8'hFF),
        .s_axi_wlast(1'b1),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(wready),
        .s_axi_bid(),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(1'b0),

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

    task automatic issue_ar;
        begin
            araddr  <= 28'h0;
            arvalid <= 1'b1;
            while (!(arvalid && arready)) @(posedge clk);
            @(posedge clk);
            arvalid <= 1'b0;
        end
    endtask

    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        issue_ar;
        rready <= 1'b1;
        while (!rvalid) @(posedge clk);
        if (rresp != 2'b00) $fatal(1, "Poison read returned non-OKAY");
        if (!$isunknown(rdata)) $fatal(1, "Expected X data when unwritten, got 0x%h", rdata);
        $display("test_axi_sdram_poison: PASS");
        $finish;
    end
endmodule
