// ============================================================================
// axil_csr_stub.sv
// - Minimal AXI4-Lite slave stub with an internal register file.
// - Useful for simulation or as a placeholder BAR/CSR block until a real fabric
//   is integrated. Supports single-beat AXI-Lite reads/writes.
// ============================================================================
`timescale 1ns/1ps

module axil_csr_stub #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer DATA_WIDTH = 32,
    parameter integer STRB_WIDTH = DATA_WIDTH/8,
    parameter integer NUM_REGS   = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // AXI-Lite slave: write address
    input  wire [ADDR_WIDTH-1:0]     s_axil_awaddr,
    input  wire                      s_axil_awvalid,
    output reg                       s_axil_awready,
    // write data
    input  wire [DATA_WIDTH-1:0]     s_axil_wdata,
    input  wire [STRB_WIDTH-1:0]     s_axil_wstrb,
    input  wire                      s_axil_wvalid,
    output reg                       s_axil_wready,
    // write response
    output reg  [1:0]                s_axil_bresp,
    output reg                       s_axil_bvalid,
    input  wire                      s_axil_bready,

    // read address
    input  wire [ADDR_WIDTH-1:0]     s_axil_araddr,
    input  wire                      s_axil_arvalid,
    output reg                       s_axil_arready,
    // read data/resp
    output reg [DATA_WIDTH-1:0]      s_axil_rdata,
    output reg [1:0]                 s_axil_rresp,
    output reg                       s_axil_rvalid,
    input  wire                      s_axil_rready
);

    localparam [1:0] RESP_OKAY = 2'b00;

    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];

    integer idx;
`ifndef SYNTHESIS
    initial begin
        for (idx = 0; idx < NUM_REGS; idx = idx + 1)
            regs[idx] = {DATA_WIDTH{1'b0}};
        s_axil_awready = 1'b0;
        s_axil_wready  = 1'b0;
        s_axil_bresp   = RESP_OKAY;
        s_axil_bvalid  = 1'b0;
        s_axil_arready = 1'b0;
        s_axil_rdata   = {DATA_WIDTH{1'b0}};
        s_axil_rresp   = RESP_OKAY;
        s_axil_rvalid  = 1'b0;
    end
`endif

    wire [ADDR_WIDTH-1:0] awaddr_aligned = {s_axil_awaddr[ADDR_WIDTH-1:STRB_WIDTH], {STRB_WIDTH{1'b0}}};
    wire [ADDR_WIDTH-1:0] araddr_aligned = {s_axil_araddr[ADDR_WIDTH-1:STRB_WIDTH], {STRB_WIDTH{1'b0}}};
    wire [$clog2(NUM_REGS)-1:0] awidx = awaddr_aligned[$clog2(NUM_REGS)+STRB_WIDTH-1:STRB_WIDTH];
    wire [$clog2(NUM_REGS)-1:0] aridx = araddr_aligned[$clog2(NUM_REGS)+STRB_WIDTH-1:STRB_WIDTH];

    // Write channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b0;
            s_axil_wready  <= 1'b0;
            s_axil_bvalid  <= 1'b0;
            s_axil_bresp   <= RESP_OKAY;
        end else begin
            // Accept address/data independently (AXI-Lite)
            if (!s_axil_awready)
                s_axil_awready <= s_axil_awvalid;
            if (!s_axil_wready)
                s_axil_wready  <= s_axil_wvalid;

            if (s_axil_awready && s_axil_awvalid &&
                s_axil_wready  && s_axil_wvalid  &&
                !s_axil_bvalid) begin
                // Apply strobes
                for (idx = 0; idx < STRB_WIDTH; idx = idx + 1) begin
                    if (s_axil_wstrb[idx])
                        regs[awidx][8*idx +: 8] <= s_axil_wdata[8*idx +: 8];
                end
                s_axil_bresp  <= RESP_OKAY;
                s_axil_bvalid <= 1'b1;
                s_axil_awready<= 1'b0;
                s_axil_wready <= 1'b0;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end

    // Read channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid  <= 1'b0;
            s_axil_rdata   <= {DATA_WIDTH{1'b0}};
            s_axil_rresp   <= RESP_OKAY;
        end else begin
            if (!s_axil_arready)
                s_axil_arready <= s_axil_arvalid;

            if (s_axil_arready && s_axil_arvalid && !s_axil_rvalid) begin
                s_axil_rdata   <= regs[aridx];
                s_axil_rresp   <= RESP_OKAY;
                s_axil_rvalid  <= 1'b1;
                s_axil_arready <= 1'b0;
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end

endmodule
