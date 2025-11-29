`ifndef CHIPLET_CROSSBAR_SV
`define CHIPLET_CROSSBAR_SV

// ============================================================================
// Chiplet Crossbar with UCIe Interfaces
// Multi-chiplet interconnect using UCIe for high-bandwidth communication
// ============================================================================

module chiplet_crossbar #(
    parameter int NUM_CHIPLETS = 4,
    parameter int UCIE_DATA_WIDTH = 64,
    parameter int UCIE_NUM_LANES = 8,
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 64,
    parameter int AXI_ID_WIDTH = 8
)(
    input  logic clk,
    input  logic rst_n,

    // UCIe interfaces to external chiplets
    ucie_if ucie_tx [NUM_CHIPLETS-1:0],
    ucie_if ucie_rx [NUM_CHIPLETS-1:0],

    // Internal AXI interfaces (for local chiplet access)
    // Master interfaces (from local masters to crossbar)
    input  logic [NUM_CHIPLETS-1:0][AXI_ID_WIDTH-1:0]         m_awid,
    input  logic [NUM_CHIPLETS-1:0][AXI_ADDR_WIDTH-1:0]       m_awaddr,
    input  logic [NUM_CHIPLETS-1:0][7:0]                      m_awlen,
    input  logic [NUM_CHIPLETS-1:0][2:0]                      m_awsize,
    input  logic [NUM_CHIPLETS-1:0][1:0]                      m_awburst,
    input  logic [NUM_CHIPLETS-1:0]                           m_awvalid,
    output logic [NUM_CHIPLETS-1:0]                           m_awready,

    input  logic [NUM_CHIPLETS-1:0][AXI_DATA_WIDTH-1:0]       m_wdata,
    input  logic [NUM_CHIPLETS-1:0][AXI_DATA_WIDTH/8-1:0]     m_wstrb,
    input  logic [NUM_CHIPLETS-1:0]                           m_wlast,
    input  logic [NUM_CHIPLETS-1:0]                           m_wvalid,
    output logic [NUM_CHIPLETS-1:0]                           m_wready,

    output logic [NUM_CHIPLETS-1:0][AXI_ID_WIDTH-1:0]         m_bid,
    output logic [NUM_CHIPLETS-1:0][1:0]                      m_bresp,
    output logic [NUM_CHIPLETS-1:0]                           m_bvalid,
    input  logic [NUM_CHIPLETS-1:0]                           m_bready,

    input  logic [NUM_CHIPLETS-1:0][AXI_ID_WIDTH-1:0]         m_arid,
    input  logic [NUM_CHIPLETS-1:0][AXI_ADDR_WIDTH-1:0]       m_araddr,
    input  logic [NUM_CHIPLETS-1:0][7:0]                      m_arlen,
    input  logic [NUM_CHIPLETS-1:0][2:0]                      m_arsize,
    input  logic [NUM_CHIPLETS-1:0][1:0]                      m_arburst,
    input  logic [NUM_CHIPLETS-1:0]                           m_arvalid,
    output logic [NUM_CHIPLETS-1:0]                           m_arready,

    output logic [NUM_CHIPLETS-1:0][AXI_DATA_WIDTH-1:0]       m_rdata,
    output logic [NUM_CHIPLETS-1:0][1:0]                      m_rresp,
    output logic [NUM_CHIPLETS-1:0]                           m_rlast,
    output logic [NUM_CHIPLETS-1:0]                           m_rvalid,
    input  logic [NUM_CHIPLETS-1:0]                           m_rready,

    // Control interface
    input  logic enable,
    input  logic [3:0] routing_mode,
    output logic [NUM_CHIPLETS-1:0] chiplet_ready,
    output logic [31:0] status,
    output logic [31:0] error_count
);

    // ============================================================================
    // Internal Signals
    // ============================================================================

    // UCIe controllers for each chiplet
    logic [NUM_CHIPLETS-1:0] ucie_link_up;
    logic [NUM_CHIPLETS-1:0][31:0] ucie_status;
    logic [NUM_CHIPLETS-1:0][31:0] ucie_error_count;

    // AXI-Stream interfaces between AXI and UCIe
    logic [NUM_CHIPLETS-1:0][AXI_DATA_WIDTH-1:0] axis_tx_tdata;
    logic [NUM_CHIPLETS-1:0]                     axis_tx_tvalid;
    logic [NUM_CHIPLETS-1:0]                     axis_tx_tready;
    logic [NUM_CHIPLETS-1:0]                     axis_tx_tlast;

    logic [NUM_CHIPLETS-1:0][AXI_DATA_WIDTH-1:0] axis_rx_tdata;
    logic [NUM_CHIPLETS-1:0]                     axis_rx_tvalid;
    logic [NUM_CHIPLETS-1:0]                     axis_rx_tready;
    logic [NUM_CHIPLETS-1:0]                     axis_rx_tlast;

    // Routing table - determines which chiplet handles which address range
    logic [NUM_CHIPLETS-1:0][AXI_ADDR_WIDTH-1:0] route_base_addr;
    logic [NUM_CHIPLETS-1:0][AXI_ADDR_WIDTH-1:0] route_mask;

    // ============================================================================
    // Routing Logic
    // ============================================================================

    // Address-based routing function
    function automatic logic [NUM_CHIPLETS-1:0] route_transaction(
        input logic [AXI_ADDR_WIDTH-1:0] addr
    );
        logic [NUM_CHIPLETS-1:0] route;
        route = '0;

        for (int i = 0; i < NUM_CHIPLETS; i++) begin
            if ((addr & route_mask[i]) == route_base_addr[i]) begin
                route[i] = 1'b1;
                break; // First match wins
            end
        end

        // Default to chiplet 0 if no match
        if (route == '0) route[0] = 1'b1;

        return route;
    endfunction

    // Initialize routing table
    initial begin
        // Default routing: each chiplet handles 1/NUM_CHIPLETS of address space
        for (int i = 0; i < NUM_CHIPLETS; i++) begin
            route_base_addr[i] = (AXI_ADDR_WIDTH'(i) << (AXI_ADDR_WIDTH - $clog2(NUM_CHIPLETS)));
            route_mask[i] = ~((1 << (AXI_ADDR_WIDTH - $clog2(NUM_CHIPLETS))) - 1);
        end
    end

    // ============================================================================
    // UCIe Controllers
    // ============================================================================

    generate
        for (genvar i = 0; i < NUM_CHIPLETS; i++) begin : g_ucie_ctrl
            ucie_controller #(
                .NUM_LANES(UCIE_NUM_LANES),
                .DATA_WIDTH(UCIE_DATA_WIDTH),
                .MAX_CREDITS(16)
            ) ucie_ctrl (
                .clk(clk),
                .rst_n(rst_n),
                .ucie(ucie_tx[i]),
                .enable(enable),
                .mode(routing_mode),
                .link_up(ucie_link_up[i]),
                .status(ucie_status[i]),
                .error_count(ucie_error_count[i]),
                .axis_tx_tdata(axis_tx_tdata[i]),
                .axis_tx_tvalid(axis_tx_tvalid[i]),
                .axis_tx_tready(axis_tx_tready[i]),
                .axis_tx_tlast(axis_tx_tlast[i]),
                .axis_rx_tdata(axis_rx_tdata[i]),
                .axis_rx_tvalid(axis_rx_tvalid[i]),
                .axis_rx_tready(axis_rx_tready[i]),
                .axis_rx_tlast(axis_rx_tlast[i])
            );
        end
    endgenerate

    // ============================================================================
    // AXI to AXI-Stream Conversion
    // ============================================================================

    generate
        for (genvar i = 0; i < NUM_CHIPLETS; i++) begin : g_axi_to_axis
            // Write channel: AXI AW/W -> AXI-Stream
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    axis_tx_tvalid[i] <= 1'b0;
                    axis_tx_tdata[i] <= '0;
                    axis_tx_tlast[i] <= 1'b0;
                    m_awready[i] <= 1'b0;
                    m_wready[i] <= 1'b0;
                end else begin
                    // Simplified: direct conversion for demo
                    m_awready[i] <= axis_tx_tready[i] && ucie_link_up[i];
                    m_wready[i] <= axis_tx_tready[i] && ucie_link_up[i];

                    if (m_awvalid[i] && m_awready[i] && m_wvalid[i] && m_wready[i]) begin
                        axis_tx_tvalid[i] <= 1'b1;
                        axis_tx_tdata[i] <= m_wdata[i];
                        axis_tx_tlast[i] <= m_wlast[i];
                    end else begin
                        axis_tx_tvalid[i] <= 1'b0;
                    end
                end
            end

            // Read channel: AXI-Stream -> AXI R
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    m_rvalid[i] <= 1'b0;
                    m_rdata[i] <= '0;
                    m_rlast[i] <= 1'b0;
                    m_rresp[i] <= 2'b00;
                    axis_rx_tready[i] <= 1'b0;
                    m_arready[i] <= 1'b0;
                end else begin
                    axis_rx_tready[i] <= m_rready[i];
                    m_arready[i] <= axis_rx_tready[i] && ucie_link_up[i];

                    if (axis_rx_tvalid[i] && axis_rx_tready[i]) begin
                        m_rvalid[i] <= 1'b1;
                        m_rdata[i] <= axis_rx_tdata[i];
                        m_rlast[i] <= axis_rx_tlast[i];
                        m_rresp[i] <= 2'b00; // OKAY
                    end else begin
                        m_rvalid[i] <= 1'b0;
                    end
                end
            end

            // Write response (simplified)
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    m_bvalid[i] <= 1'b0;
                    m_bresp[i] <= 2'b00;
                    m_bid[i] <= '0;
                end else begin
                    if (m_wvalid[i] && m_wready[i] && m_wlast[i]) begin
                        m_bvalid[i] <= 1'b1;
                        m_bresp[i] <= 2'b00; // OKAY
                        m_bid[i] <= m_awid[i];
                    end else if (m_bvalid[i] && m_bready[i]) begin
                        m_bvalid[i] <= 1'b0;
                    end
                end
            end
        end
    endgenerate

    // ============================================================================
    // Crossbar Routing Logic
    // ============================================================================

    // For multi-chiplet communication, route transactions to appropriate UCIe links
    generate
        for (genvar master = 0; master < NUM_CHIPLETS; master++) begin : g_routing
            always_comb begin
                // Determine target chiplet based on address
                automatic logic [NUM_CHIPLETS-1:0] target_mask = route_transaction(m_awaddr[master]);

                // Route to appropriate UCIe interface
                for (int chiplet = 0; chiplet < NUM_CHIPLETS; chiplet++) begin
                    if (target_mask[chiplet] && chiplet != master) begin
                        // Route to external chiplet via UCIe
                        axis_tx_tdata[chiplet] = m_wdata[master];
                        axis_tx_tvalid[chiplet] = m_wvalid[master] && m_awvalid[master];
                        axis_tx_tlast[chiplet] = m_wlast[master];
                        break;
                    end
                end
            end
        end
    endgenerate

    // ============================================================================
    // Status and Monitoring
    // ============================================================================

    assign chiplet_ready = ucie_link_up;

    // Aggregate status
    always_comb begin
        status = '0;
        error_count = '0;

        for (int i = 0; i < NUM_CHIPLETS; i++) begin
            status |= ucie_status[i];
            error_count += ucie_error_count[i];
        end

        // Add crossbar-specific status bits
        status[31:28] = {enable, routing_mode};
    end

endmodule : chiplet_crossbar

`endif // CHIPLET_CROSSBAR_SV
