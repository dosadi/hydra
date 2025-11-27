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

// Simple stub behavior: never complete and no error by default.
// Use explicit 1'b0 to avoid synthesis/tool warnings about implicit integers.
assign done = 1'b0;
assign err  = 1'b0;

// Stub note: default idle outputs; integrate with LiteX MMIO and AXI
// streaming (and proper interrupt handling) when the LiteX host is
// available. This file intentionally drives "done"/"err" low for now.

endmodule
