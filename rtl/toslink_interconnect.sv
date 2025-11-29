// ============================================================================
// TOSLINK Interconnect Module
// Complete TOSLINK-based optical interconnect for board-to-board communication
// ============================================================================

`ifndef TOSLINK_INTERCONNECT_SV
`define TOSLINK_INTERCONNECT_SV

module toslink_interconnect #(
    parameter int DATA_WIDTH = 32,
    parameter int SAMPLE_RATE = 48000,
    parameter int OVERSAMPLE = 64,
    parameter int MAX_CREDITS = 16
)(
    input  logic clk,                   // System clock
    input  logic rst_n,                 // Active low reset

    // Optical interface (TOSLINK connectors)
    output logic tx_optical,           // Optical transmit signal
    input  logic  rx_optical,          // Optical receive signal

    // Control interface
    input  logic enable,               // Interconnect enable
    input  logic [3:0] mode,           // Operating mode
    input  logic loopback_en,          // Loopback enable for testing
    input  logic bypass_en,            // Bypass S/PDIF encoding for testing

    // Status outputs
    output logic link_up,              // Link up status
    output logic [31:0] link_status,   // Link status
    output logic [31:0] phy_status,    // PHY status
    output logic [31:0] error_count,   // Error count

    // AXI-Stream interfaces for data
    input  logic [DATA_WIDTH-1:0] axis_tx_tdata,
    input  logic                  axis_tx_tvalid,
    output logic                  axis_tx_tready,
    input  logic                  axis_tx_tlast,

    output logic [DATA_WIDTH-1:0] axis_rx_tdata,
    output logic                  axis_rx_tvalid,
    input  logic                  axis_rx_tready,
    output logic                  axis_rx_tlast
);

    // Internal signals
    logic [DATA_WIDTH-1:0] ctrl_tx_data, ctrl_rx_data;
    logic ctrl_tx_valid, ctrl_rx_valid;
    logic ctrl_tx_ready, ctrl_rx_ready;
    logic phy_link_locked;
    logic [31:0] phy_status_reg, phy_error_count;

    // TOSLINK Controller
    toslink_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .SAMPLE_RATE(SAMPLE_RATE),
        .OVERSAMPLE(OVERSAMPLE),
        .MAX_CREDITS(MAX_CREDITS)
    ) toslink_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .phy_tx_data(ctrl_tx_data),
        .phy_tx_valid(ctrl_tx_valid),
        .phy_tx_ready(ctrl_tx_ready),
        .phy_rx_data(ctrl_rx_data),
        .phy_rx_valid(ctrl_rx_valid),
        .phy_rx_ready(ctrl_rx_ready),
        .enable(enable),
        .mode(mode),
        .loopback_en(loopback_en),
        .link_up(link_up),
        .status(link_status),
        .error_count(error_count),
        .axis_tx_tdata(axis_tx_tdata),
        .axis_tx_tvalid(axis_tx_tvalid),
        .axis_tx_tready(axis_tx_tready),
        .axis_tx_tlast(axis_tx_tlast),
        .axis_rx_tdata(axis_rx_tdata),
        .axis_rx_tvalid(axis_rx_tvalid),
        .axis_rx_tready(axis_rx_tready),
        .axis_rx_tlast(axis_rx_tlast)
    );

    // TOSLINK PHY
    toslink_phy #(
        .DATA_WIDTH(DATA_WIDTH),
        .SAMPLE_RATE(SAMPLE_RATE),
        .OVERSAMPLE(OVERSAMPLE)
    ) toslink_phy_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(ctrl_tx_data),
        .tx_valid(ctrl_tx_valid),
        .tx_ready(ctrl_tx_ready),
        .rx_data(ctrl_rx_data),
        .rx_valid(ctrl_rx_valid),
        .rx_ready(ctrl_rx_ready),
        .tx_optical(tx_optical),
        .rx_optical(rx_optical),
        .enable(enable),
        .loopback_en(loopback_en),
        .bypass_en(bypass_en),
        .link_locked(phy_link_locked),
        .status(phy_status),
        .error_count(phy_error_count)
    );

    // Status aggregation
    assign phy_status = phy_status_reg;

endmodule : toslink_interconnect

`endif // TOSLINK_INTERCONNECT_SV
