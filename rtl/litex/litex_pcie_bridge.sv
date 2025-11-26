// LiteX PCIe bridge stub
module litex_pcie_bridge #(
    parameter integer AXI_DATA_WIDTH = 64
)(
    input  wire                         clk,
    input  wire                         rst_n,
    // TODO: connect LiteX PCIe PHY signals here

    output wire [AXI_DATA_WIDTH-1:0]    m_axi_awdata,
    output wire [3:0]                   m_axi_awlen,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,
    // ... other AXI signals omitted for now

    input  wire [AXI_DATA_WIDTH-1:0]    s_axi_awdata,
    input  wire [3:0]                   s_axi_awlen,
    input  wire                         s_axi_awvalid,
    output wire                         s_axi_awready
);

// Basic safe defaults for the stub: drive outputs to safe idle values so
// synthesis/simulation tools don't encounter floating outputs.
assign m_axi_awdata  = {AXI_DATA_WIDTH{1'b0}};
assign m_axi_awlen   = 4'd0;
assign m_axi_awvalid = 1'b0;

assign s_axi_awready = 1'b0;

// TODO: implement descriptor parsing, address mapping, and MSIX support

endmodule
