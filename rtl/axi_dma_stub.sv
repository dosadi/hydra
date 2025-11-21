// ============================================================================
// axi_dma_stub.sv
// - Very simple AXI master DMA for simulation/bring-up.
// - Copies len bytes (multiple of bus width) from src to dst using single-beat
//   INCR transfers. No outstanding transactions; one at a time.
// - Intended to drive axi_sdram_stub in the shell; not timing-accurate.
// ============================================================================
`timescale 1ns/1ps

module axi_dma_stub #(
    parameter integer ADDR_WIDTH = 28,
    parameter integer DATA_WIDTH = 64,
    parameter integer ID_WIDTH   = 4
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   start,
    input  wire [ADDR_WIDTH-1:0]  src_addr,
    input  wire [ADDR_WIDTH-1:0]  dst_addr,
    input  wire [31:0]            len_bytes, // must be multiple of DATA_WIDTH/8
    output reg                    busy,
    output reg                    done,

    // AXI master out
    output reg  [ID_WIDTH-1:0]    m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]  m_axi_awaddr,
    output reg  [7:0]             m_axi_awlen,
    output reg  [2:0]             m_axi_awsize,
    output reg  [1:0]             m_axi_awburst,
    output reg                    m_axi_awvalid,
    input  wire                   m_axi_awready,

    output reg  [DATA_WIDTH-1:0]  m_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                    m_axi_wlast,
    output reg                    m_axi_wvalid,
    input  wire                   m_axi_wready,

    input  wire [ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]             m_axi_bresp,
    input  wire                   m_axi_bvalid,
    output reg                    m_axi_bready,

    output reg  [ID_WIDTH-1:0]    m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]  m_axi_araddr,
    output reg  [7:0]             m_axi_arlen,
    output reg  [2:0]             m_axi_arsize,
    output reg  [1:0]             m_axi_arburst,
    output reg                    m_axi_arvalid,
    input  wire                   m_axi_arready,

    input  wire [ID_WIDTH-1:0]    m_axi_rid,
    input  wire [DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]             m_axi_rresp,
    input  wire                   m_axi_rlast,
    input  wire                   m_axi_rvalid,
    output reg                    m_axi_rready
);

    localparam [1:0] BURST_INCR = 2'b01;
    localparam integer STRB_WIDTH = DATA_WIDTH/8;

    localparam S_IDLE  = 3'd0;
    localparam S_AR    = 3'd1;
    localparam S_R     = 3'd2;
    localparam S_AW    = 3'd3;
    localparam S_W     = 3'd4;
    localparam S_B     = 3'd5;
    localparam S_DONE  = 3'd6;

    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] cur_src;
    reg [ADDR_WIDTH-1:0] cur_dst;
    reg [31:0] remaining;
    reg [DATA_WIDTH-1:0] read_data_hold;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            busy         <= 1'b0;
            done         <= 1'b0;
            cur_src      <= {ADDR_WIDTH{1'b0}};
            cur_dst      <= {ADDR_WIDTH{1'b0}};
            remaining    <= 32'd0;
            read_data_hold <= {DATA_WIDTH{1'b0}};

            m_axi_awid   <= {ID_WIDTH{1'b0}};
            m_axi_awaddr <= {ADDR_WIDTH{1'b0}};
            m_axi_awlen  <= 8'd0;
            m_axi_awsize <= $clog2(STRB_WIDTH);
            m_axi_awburst<= BURST_INCR;
            m_axi_awvalid<= 1'b0;
            m_axi_wdata  <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb  <= {STRB_WIDTH{1'b1}};
            m_axi_wlast  <= 1'b1;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;

            m_axi_arid   <= {ID_WIDTH{1'b0}};
            m_axi_araddr <= {ADDR_WIDTH{1'b0}};
            m_axi_arlen  <= 8'd0;
            m_axi_arsize <= $clog2(STRB_WIDTH);
            m_axi_arburst<= BURST_INCR;
            m_axi_arvalid<= 1'b0;
            m_axi_rready <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        busy      <= 1'b1;
                        cur_src   <= src_addr;
                        cur_dst   <= dst_addr;
                        remaining <= len_bytes;
                        state     <= S_AR;
                    end
                end

                S_AR: begin
                    m_axi_araddr  <= cur_src;
                    m_axi_arvalid <= 1'b1;
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state         <= S_R;
                    end
                end

                S_R: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        read_data_hold <= m_axi_rdata;
                        m_axi_rready   <= 1'b0;
                        state          <= S_AW;
                    end
                end

                S_AW: begin
                    m_axi_awaddr  <= cur_dst;
                    m_axi_awvalid <= 1'b1;
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wdata   <= read_data_hold;
                        m_axi_wvalid  <= 1'b1;
                        m_axi_wlast   <= 1'b1;
                        state         <= S_W;
                    end
                end

                S_W: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        m_axi_bready <= 1'b1;
                        state        <= S_B;
                    end
                end

                S_B: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        // Advance pointers
                        if (remaining <= STRB_WIDTH) begin
                            remaining <= 0;
                        end else begin
                            remaining <= remaining - STRB_WIDTH;
                            cur_src   <= cur_src + STRB_WIDTH;
                            cur_dst   <= cur_dst + STRB_WIDTH;
                        end
                        state <= (remaining <= STRB_WIDTH) ? S_DONE : S_AR;
                    end
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state<= S_IDLE;
                end
            endcase
        end
    end

endmodule
