// ============================================================================
// UCIe SERDES Interconnect Module
// Complete SERDES-based interconnect with UCIe controller and SERDES PHY
// ============================================================================

`ifndef UCIE_SERDES_INTERCONNECT_SV
`define UCIE_SERDES_INTERCONNECT_SV

module ucie_serdes_interconnect #(
    parameter int NUM_LANES = 8,
    parameter int DATA_WIDTH = 64,
    parameter int MAX_CREDITS = 16,
    parameter int SERIAL_RATE = 32,     // Serial data rate in Gbps
    parameter int REFCLK_FREQ = 100     // Reference clock frequency in MHz
)(
    input  logic clk,                   // System clock
    input  logic rst_n,                 // Active low reset

    // High-speed Serial Interface (to external chiplet)
    input  logic [NUM_LANES-1:0]                  rx_p,      // Positive RX differential pair
    input  logic [NUM_LANES-1:0]                  rx_n,      // Negative RX differential pair
    output logic [NUM_LANES-1:0]                  tx_p,      // Positive TX differential pair
    output logic [NUM_LANES-1:0]                  tx_n,      // Negative TX differential pair

    // Reference Clock
    input  logic refclk_p,                        // Positive reference clock
    input  logic refclk_n,                        // Negative reference clock

    // Control interface
    input  logic enable,                          // Interconnect enable
    input  logic [3:0] mode,                      // Operating mode
    input  logic [3:0] tx_preemph,                // TX pre-emphasis control
    input  logic [3:0] rx_eq,                     // RX equalization control
    input  logic loopback_en,                     // Loopback enable for testing

    // Status outputs
    output logic link_up,                         // Link up status
    output logic [31:0] link_status,              // Link status
    output logic [31:0] serdes_status,            // SERDES status
    output logic [31:0] error_count,              // Error count

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

    // ============================================================================
    // Internal Signals - Controller to SERDES
    // ============================================================================

    // TX path
    logic [NUM_LANES-1:0]                  ctrl_tx_valid;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]  ctrl_tx_data;
    logic [NUM_LANES-1:0]                  ctrl_tx_start;
    logic [NUM_LANES-1:0]                  ctrl_tx_end;
    logic [NUM_LANES-1:0][7:0]             ctrl_tx_crc;

    // RX path
    logic [NUM_LANES-1:0]                  ctrl_rx_valid;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]  ctrl_rx_data;
    logic [NUM_LANES-1:0]                  ctrl_rx_start;
    logic [NUM_LANES-1:0]                  ctrl_rx_end;
    logic [NUM_LANES-1:0][7:0]             ctrl_rx_crc;

    // SERDES status
    logic [NUM_LANES-1:0]                  serdes_lane_ready;
    logic [NUM_LANES-1:0]                  serdes_lane_locked;
    logic [NUM_LANES-1:0][7:0]             serdes_lane_status;
    logic [31:0]                           serdes_overall_status;

    // ============================================================================
    // UCIe Controller Instance
    // ============================================================================

    ucie_controller #(
        .NUM_LANES(NUM_LANES),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_CREDITS(MAX_CREDITS)
    ) ucie_ctrl (
        .clk(clk),
        .rst_n(rst_n),

        // SERDES interface
        .serdes_tx_valid(ctrl_tx_valid),
        .serdes_tx_data(ctrl_tx_data),
        .serdes_tx_start(ctrl_tx_start),
        .serdes_tx_end(ctrl_tx_end),
        .serdes_tx_crc(ctrl_tx_crc),

        .serdes_rx_valid(ctrl_rx_valid),
        .serdes_rx_data(ctrl_rx_data),
        .serdes_rx_start(ctrl_rx_start),
        .serdes_rx_end(ctrl_rx_end),
        .serdes_rx_crc(ctrl_rx_crc),

        // SERDES status
        .serdes_lane_ready(serdes_lane_ready),
        .serdes_lane_locked(serdes_lane_locked),
        .serdes_lane_status(serdes_lane_status),
        .serdes_status(serdes_overall_status),

        // Control
        .enable(enable),
        .mode(mode),
        .link_up(link_up),
        .status(link_status),
        .error_count(error_count),

        // AXI-Stream data
        .axis_tx_tdata(axis_tx_tdata),
        .axis_tx_tvalid(axis_tx_tvalid),
        .axis_tx_tready(axis_tx_tready),
        .axis_tx_tlast(axis_tx_tlast),

        .axis_rx_tdata(axis_rx_tdata),
        .axis_rx_tvalid(axis_rx_tvalid),
        .axis_rx_tready(axis_rx_tready),
        .axis_rx_tlast(axis_rx_tlast)
    );

    // ============================================================================
    // SERDES PHY Instance
    // ============================================================================

    ucie_serdes #(
        .NUM_LANES(NUM_LANES),
        .DATA_WIDTH(DATA_WIDTH),
        .SERIAL_RATE(SERIAL_RATE),
        .REFCLK_FREQ(REFCLK_FREQ)
    ) serdes_phy (
        .clk(clk),
        .rst_n(rst_n),

        // Controller interface
        .tx_data_valid(ctrl_tx_valid),
        .tx_data(ctrl_tx_data),
        .tx_start(ctrl_tx_start),
        .tx_end(ctrl_tx_end),
        .tx_crc(ctrl_tx_crc),

        .rx_data_valid(ctrl_rx_valid),
        .rx_data(ctrl_rx_data),
        .rx_start(ctrl_rx_start),
        .rx_end(ctrl_rx_end),
        .rx_crc(ctrl_rx_crc),

        // High-speed serial interface
        .rx_p(rx_p),
        .rx_n(rx_n),
        .tx_p(tx_p),
        .tx_n(tx_n),

        // Reference clock
        .refclk_p(refclk_p),
        .refclk_n(refclk_n),

        // Control
        .enable(enable),
        .tx_preemph(tx_preemph),
        .rx_eq(rx_eq),
        .loopback_en(loopback_en),

        // Status
        .lane_ready(serdes_lane_ready),
        .lane_locked(serdes_lane_locked),
        .lane_status(serdes_lane_status),
        .serdes_status(serdes_status)
    );

    // ============================================================================
    // Status Aggregation
    // ============================================================================

    // Combine link and SERDES status for external monitoring
    assign serdes_status = serdes_overall_status;

endmodule : ucie_serdes_interconnect

`endif // UCIE_SERDES_INTERCONNECT_SV
