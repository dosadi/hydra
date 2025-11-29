`ifndef CROSSBAR_INTERCONNECT_SV
`define CROSSBAR_INTERCONNECT_SV

// ============================================================================
// Crossbar Interconnect System
// Comprehensive crossbar infrastructure for FPGA designs
// ============================================================================

`include "crossbar_pkg.sv"

import crossbar_pkg::*;

// ============================================================================
// Universal Crossbar Router
// Routes transactions between multiple masters and slaves
// ============================================================================

module crossbar_router #(
    parameter int NUM_PORTS = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter crossbar_pkg::crossbar_config_t CONFIG = '0
)(
    input  logic clk,
    input  logic rst_n,

    // Control interface
    input  logic enable,
    input  logic [3:0] mode_select,

    // Status interface
    output logic [31:0] status,
    output logic [31:0] error_count,

    // AXI-Lite interfaces (when DATA_WIDTH == 32)
    crossbar_pkg::axil_if.master m_axil [NUM_PORTS-1:0],
    crossbar_pkg::axil_if.slave  s_axil [NUM_PORTS-1:0],

    // AXI4 interfaces (when DATA_WIDTH > 32)
    crossbar_pkg::axi_if.master m_axi [NUM_PORTS-1:0],
    crossbar_pkg::axi_if.slave  s_axi [NUM_PORTS-1:0],

    // AXI-Stream interfaces
    crossbar_pkg::axis_if.master m_axis [NUM_PORTS-1:0],
    crossbar_pkg::axis_if.slave  s_axis [NUM_PORTS-1:0]
);

    // ============================================================================
    // Internal Routing Logic
    // ============================================================================

    // Address decoding based on configuration
    function automatic logic [$clog2(NUM_PORTS)-1:0] decode_address(
        input logic [ADDR_WIDTH-1:0] addr
    );
        // Simple round-robin for now - can be enhanced with CONFIG
        return addr[$clog2(NUM_PORTS)-1:0];
    endfunction

    // ============================================================================
    // AXI-Lite Crossbar Instance (for 32-bit data)
    // ============================================================================

    generate
        if (DATA_WIDTH == 32) begin : g_axil_crossbar
            axil_crossbar #(
                .NUM_MASTERS(NUM_PORTS),
                .NUM_SLAVES(NUM_PORTS),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .SLAVE_BASE_ADDRS(CONFIG.SLAVE_BASE_ADDRS),
                .SLAVE_ADDR_MASKS(CONFIG.SLAVE_ADDR_MASKS),
                .ARBITRATION_MODE(CONFIG.ARBITRATION_MODE)
            ) axil_cb (
                .clk(clk),
                .rst_n(rst_n),
                // Connect AXI-Lite interfaces
                .m_awaddr(m_axil.awaddr),
                .m_awprot(m_axil.awprot),
                .m_awvalid(m_axil.awvalid),
                .m_awready(m_axil.awready),
                .m_wdata(m_axil.wdata),
                .m_wstrb(m_axil.wstrb),
                .m_wvalid(m_axil.wvalid),
                .m_wready(m_axil.wready),
                .m_bresp(m_axil.bresp),
                .m_bvalid(m_axil.bvalid),
                .m_bready(m_axil.bready),
                .m_araddr(m_axil.araddr),
                .m_arprot(m_axil.arprot),
                .m_arvalid(m_axil.arvalid),
                .m_arready(m_axil.arready),
                .m_rdata(m_axil.rdata),
                .m_rresp(m_axil.rresp),
                .m_rvalid(m_axil.rvalid),
                .m_rready(m_axil.rready),
                .s_awaddr(s_axil.awaddr),
                .s_awprot(s_axil.awprot),
                .s_awvalid(s_axil.awvalid),
                .s_awready(s_axil.awready),
                .s_wdata(s_axil.wdata),
                .s_wstrb(s_axil.wstrb),
                .s_wvalid(s_axil.wvalid),
                .s_wready(s_axil.wready),
                .s_bresp(s_axil.bresp),
                .s_bvalid(s_axil.bvalid),
                .s_bready(s_axil.bready),
                .s_araddr(s_axil.araddr),
                .s_arprot(s_axil.arprot),
                .s_arvalid(s_axil.arvalid),
                .s_arready(s_axil.arready),
                .s_rdata(s_axil.rdata),
                .s_rresp(s_axil.rresp),
                .s_rvalid(s_axil.rvalid),
                .s_rready(s_axil.rready)
            );
        end
    endgenerate

    // ============================================================================
    // AXI4 Crossbar Instance (for 64-bit+ data)
    // ============================================================================

    generate
        if (DATA_WIDTH > 32) begin : g_axi_crossbar
            axi_crossbar #(
                .NUM_MASTERS(NUM_PORTS),
                .NUM_SLAVES(NUM_PORTS),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .ID_WIDTH(8),
                .SLAVE_BASE_ADDRS(CONFIG.SLAVE_BASE_ADDRS),
                .SLAVE_ADDR_MASKS(CONFIG.SLAVE_ADDR_MASKS),
                .ARBITRATION_MODE(CONFIG.ARBITRATION_MODE)
            ) axi_cb (
                .clk(clk),
                .rst_n(rst_n),
                // Connect AXI4 interfaces
                .m_awid(m_axi.awid),
                .m_awaddr(m_axi.awaddr),
                .m_awlen(m_axi.awlen),
                .m_awsize(m_axi.awsize),
                .m_awburst(m_axi.awburst),
                .m_awlock(m_axi.awlock),
                .m_awcache(m_axi.awcache),
                .m_awprot(m_axi.awprot),
                .m_awqos(m_axi.awqos),
                .m_awregion(m_axi.awregion),
                .m_awuser(m_axi.awuser),
                .m_awvalid(m_axi.awvalid),
                .m_awready(m_axi.awready),
                .m_wdata(m_axi.wdata),
                .m_wstrb(m_axi.wstrb),
                .m_wlast(m_axi.wlast),
                .m_wuser(m_axi.wuser),
                .m_wvalid(m_axi.wvalid),
                .m_wready(m_axi.wready),
                .m_bid(m_axi.bid),
                .m_bresp(m_axi.bresp),
                .m_buser(m_axi.buser),
                .m_bvalid(m_axi.bvalid),
                .m_bready(m_axi.bready),
                .m_arid(m_axi.arid),
                .m_araddr(m_axi.araddr),
                .m_arlen(m_axi.arlen),
                .m_arsize(m_axi.arsize),
                .m_arburst(m_axi.arburst),
                .m_arlock(m_axi.arlock),
                .m_arcache(m_axi.arcache),
                .m_arprot(m_axi.arprot),
                .m_arqos(m_axi.arqos),
                .m_arregion(m_axi.arregion),
                .m_aruser(m_axi.aruser),
                .m_arvalid(m_axi.arvalid),
                .m_arready(m_axi.arready),
                .m_rid(m_axi.rid),
                .m_rdata(m_axi.rdata),
                .m_rresp(m_axi.rresp),
                .m_rlast(m_axi.rlast),
                .m_ruser(m_axi.ruser),
                .m_rvalid(m_axi.rvalid),
                .m_rready(m_axi.rready),
                .s_awid(s_axi.awid),
                .s_awaddr(s_axi.awaddr),
                .s_awlen(s_axi.awlen),
                .s_awsize(s_axi.awsize),
                .s_awburst(s_axi.awburst),
                .s_awlock(s_axi.awlock),
                .s_awcache(s_axi.awcache),
                .s_awprot(s_axi.awprot),
                .s_awqos(s_axi.awqos),
                .s_awregion(s_axi.awregion),
                .s_awuser(s_axi.awuser),
                .s_awvalid(s_axi.awvalid),
                .s_awready(s_axi.awready),
                .s_wdata(s_axi.wdata),
                .s_wstrb(s_axi.wstrb),
                .s_wlast(s_axi.wlast),
                .s_wuser(s_axi.wuser),
                .s_wvalid(s_axi.wvalid),
                .s_wready(s_axi.wready),
                .s_bid(s_axi.bid),
                .s_bresp(s_axi.bresp),
                .s_buser(s_axi.buser),
                .s_bvalid(s_axi.bvalid),
                .s_bready(s_axi.bready),
                .s_arid(s_axi.arid),
                .s_araddr(s_axi.araddr),
                .s_arlen(s_axi.arlen),
                .s_arsize(s_axi.arsize),
                .s_arburst(s_axi.arburst),
                .s_arlock(s_axi.arlock),
                .s_arcache(s_axi.arcache),
                .s_arprot(s_axi.arprot),
                .s_arqos(s_axi.arqos),
                .s_arregion(s_axi.arregion),
                .s_aruser(s_axi.aruser),
                .s_arvalid(s_axi.arvalid),
                .s_arready(s_axi.arready),
                .s_rid(s_axi.rid),
                .s_rdata(s_axi.rdata),
                .s_rresp(s_axi.rresp),
                .s_rlast(s_axi.rlast),
                .s_ruser(s_axi.ruser),
                .s_rvalid(s_axi.rvalid),
                .s_rready(s_axi.rready)
            );
        end
    endgenerate

    // ============================================================================
    // AXI-Stream Router (simple round-robin)
    // ============================================================================

    logic [$clog2(NUM_PORTS)-1:0] axis_round_robin;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axis_round_robin <= '0;
        end else if (enable) begin
            axis_round_robin <= axis_round_robin + 1;
        end
    end

    generate
        for (genvar i = 0; i < NUM_PORTS; i++) begin : g_axis_routing
            always_comb begin
                // Simple routing: each master connects to next slave in round-robin
                automatic int target = (i + axis_round_robin) % NUM_PORTS;

                m_axis[i].tdata = s_axis[target].tdata;
                m_axis[i].tstrb = s_axis[target].tstrb;
                m_axis[i].tkeep = s_axis[target].tkeep;
                m_axis[i].tlast = s_axis[target].tlast;
                m_axis[i].tuser = s_axis[target].tuser;
                m_axis[i].tdest = s_axis[target].tdest;
                m_axis[i].tid = s_axis[target].tid;
                m_axis[i].tvalid = s_axis[target].tvalid && (mode_select[0]); // Enable stream routing
                s_axis[target].tready = m_axis[i].tready && (mode_select[0]);
            end
        end
    endgenerate

    // ============================================================================
    // Status and Error Monitoring
    // ============================================================================

    logic [31:0] transaction_count;
    logic [31:0] error_counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transaction_count <= '0;
            error_counter <= '0;
        end else begin
            // Count transactions (simplified)
            if (DATA_WIDTH == 32) begin
                if (m_axil[0].awvalid && m_axil[0].awready) transaction_count <= transaction_count + 1;
                if (m_axil[0].arvalid && m_axil[0].arready) transaction_count <= transaction_count + 1;
            end else begin
                if (m_axi[0].awvalid && m_axi[0].awready) transaction_count <= transaction_count + 1;
                if (m_axi[0].arvalid && m_axi[0].arready) transaction_count <= transaction_count + 1;
            end

            // Count errors (simplified - check for DECERR responses)
            if (DATA_WIDTH == 32) begin
                if (m_axil[0].bvalid && m_axil[0].bready && m_axil[0].bresp == 2'b11) error_counter <= error_counter + 1;
                if (m_axil[0].rvalid && m_axil[0].rready && m_axil[0].rresp == 2'b11) error_counter <= error_counter + 1;
            end else begin
                if (m_axi[0].bvalid && m_axi[0].bready && m_axi[0].bresp == 2'b11) error_counter <= error_counter + 1;
                if (m_axi[0].rvalid && m_axi[0].rready && m_axi[0].rresp == 2'b11) error_counter <= error_counter + 1;
            end
        end
    end

    assign status = {enable, mode_select, transaction_count[27:0]};
    assign error_count = error_counter;

endmodule : crossbar_router

`endif // CROSSBAR_INTERCONNECT_SV
