`timescale 1ns/1ps

module test_dma_stub_direct;
    reg clk = 0;
    reg rst_n = 0;

    // DMA control
    reg        start;
    reg [27:0] src_addr;
    reg [27:0] dst_addr;
    reg [31:0] len_bytes;
    wire       busy;
    wire       done;

    // AXI wires
    wire [3:0]  m_awid;
    wire [27:0] m_awaddr;
    wire [7:0]  m_awlen;
    wire [2:0]  m_awsize;
    wire [1:0]  m_awburst;
    wire        m_awvalid;
    wire        m_awready;
    wire [63:0] m_wdata;
    wire [7:0]  m_wstrb;
    wire        m_wlast;
    wire        m_wvalid;
    wire        m_wready;
    wire [3:0]  m_bid;
    wire [1:0]  m_bresp;
    wire        m_bvalid;
    wire        m_bready;
    wire [3:0]  m_arid;
    wire [27:0] m_araddr;
    wire [7:0]  m_arlen;
    wire [2:0]  m_arsize;
    wire [1:0]  m_arburst;
    wire        m_arvalid;
    wire        m_arready;
    wire [3:0]  m_rid;
    wire [63:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rlast;
    wire        m_rvalid;
    wire        m_rready;

    // Clock
    always #5 clk = ~clk;

    // DUT: DMA stub
    axi_dma_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4)
    ) u_dma (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start),
        .src_addr      (src_addr),
        .dst_addr      (dst_addr),
        .len_bytes     (len_bytes),
        .busy          (busy),
        .done          (done),
        .m_axi_awid    (m_awid),
        .m_axi_awaddr  (m_awaddr),
        .m_axi_awlen   (m_awlen),
        .m_axi_awsize  (m_awsize),
        .m_axi_awburst (m_awburst),
        .m_axi_awvalid (m_awvalid),
        .m_axi_awready (m_awready),
        .m_axi_wdata   (m_wdata),
        .m_axi_wstrb   (m_wstrb),
        .m_axi_wlast   (m_wlast),
        .m_axi_wvalid  (m_wvalid),
        .m_axi_wready  (m_wready),
        .m_axi_bid     (m_bid),
        .m_axi_bresp   (m_bresp),
        .m_axi_bvalid  (m_bvalid),
        .m_axi_bready  (m_bready),
        .m_axi_arid    (m_arid),
        .m_axi_araddr  (m_araddr),
        .m_axi_arlen   (m_arlen),
        .m_axi_arsize  (m_arsize),
        .m_axi_arburst (m_arburst),
        .m_axi_arvalid (m_arvalid),
        .m_axi_arready (m_arready),
        .m_axi_rid     (m_rid),
        .m_axi_rdata   (m_rdata),
        .m_axi_rresp   (m_rresp),
        .m_axi_rlast   (m_rlast),
        .m_axi_rvalid  (m_rvalid),
        .m_axi_rready  (m_rready)
    );

    // Simple SDRAM stub hooked directly to DMA
    axi_sdram_stub #(
        .ADDR_WIDTH(28),
        .DATA_WIDTH(64),
        .ID_WIDTH  (4)
    ) u_mem (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_awid    (m_awid),
        .s_axi_awaddr  (m_awaddr),
        .s_axi_awlen   (m_awlen),
        .s_axi_awsize  (m_awsize),
        .s_axi_awburst (m_awburst),
        .s_axi_awvalid (m_awvalid),
        .s_axi_awready (m_awready),
        .s_axi_wdata   (m_wdata),
        .s_axi_wstrb   (m_wstrb),
        .s_axi_wlast   (m_wlast),
        .s_axi_wvalid  (m_wvalid),
        .s_axi_wready  (m_wready),
        .s_axi_bid     (m_bid),
        .s_axi_bresp   (m_bresp),
        .s_axi_bvalid  (m_bvalid),
        .s_axi_bready  (m_bready),
        .s_axi_arid    (m_arid),
        .s_axi_araddr  (m_araddr),
        .s_axi_arlen   (m_arlen),
        .s_axi_arsize  (m_arsize),
        .s_axi_arburst (m_arburst),
        .s_axi_arvalid (m_arvalid),
        .s_axi_arready (m_arready),
        .s_axi_rid     (m_rid),
        .s_axi_rdata   (m_rdata),
        .s_axi_rresp   (m_rresp),
        .s_axi_rlast   (m_rlast),
        .s_axi_rvalid  (m_rvalid),
        .s_axi_rready  (m_rready),
        .dbg_we        (1'b0),
        .dbg_addr      (28'd0),
        .dbg_wdata     (64'd0),
        .dbg_re        (1'b0),
        .dbg_rdata     ()
    );

    initial begin
        $display("DMA_STUB_DIRECT: starting");
        $dumpfile("dma_stub_direct.vcd");
        $dumpvars(0, test_dma_stub_direct);

        start     = 0;
        src_addr  = 28'h0000_0000;
        dst_addr  = 28'h0000_0100;
        len_bytes = 32'd64;

        #20 rst_n = 1;
        #20;
        start = 1'b1;
        #10;
        start = 1'b0;

        wait(done === 1'b1);
        $display("DMA_STUB_DIRECT: done busy=%0b", busy);
        #100;
        $finish;
    end

endmodule
