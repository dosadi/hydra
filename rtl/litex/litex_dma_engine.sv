// LiteX DMA engine stub
module litex_dma_engine #(
    parameter integer BURST_WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              start,
    input  wire [31:0]       src_addr,
    input  wire [31:0]       dst_addr,
    input  wire [15:0]       length,
    output wire              done,
    output wire              err
);

assign done = 0;
assign err  = 0;

// TODO: integrate with LiteX MMIO, add AXI streaming support, respect LiteX interrupts

endmodule
