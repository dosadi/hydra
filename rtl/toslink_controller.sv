// ============================================================================
// TOSLINK Controller
// Protocol controller for TOSLINK-based board interconnect
// ============================================================================

`ifndef TOSLINK_CONTROLLER_SV
`define TOSLINK_CONTROLLER_SV

module toslink_controller #(
    parameter int DATA_WIDTH = 32,
    parameter int SAMPLE_RATE = 48000,
    parameter int OVERSAMPLE = 64,
    parameter int MAX_CREDITS = 16
)(
    input  logic clk,                   // System clock
    input  logic rst_n,                 // Active low reset

    // PHY interface
    output logic [DATA_WIDTH-1:0] phy_tx_data,
    output logic                  phy_tx_valid,
    input  logic                  phy_tx_ready,

    input  logic [DATA_WIDTH-1:0] phy_rx_data,
    input  logic                  phy_rx_valid,
    output logic                  phy_rx_ready,

    // Control interface
    input  logic enable,               // Enable controller
    input  logic [3:0] mode,           // Operating mode
    input  logic loopback_en,          // Loopback enable

    // Status outputs
    output logic link_up,              // Link is established
    output logic [31:0] status,        // Status register
    output logic [31:0] error_count,   // Error counter

    // AXI-Stream interfaces
    input  logic [DATA_WIDTH-1:0] axis_tx_tdata,
    input  logic                  axis_tx_tvalid,
    output logic                  axis_tx_tready,
    input  logic                  axis_tx_tlast,

    output logic [DATA_WIDTH-1:0] axis_rx_tdata,
    output logic                  axis_rx_tvalid,
    input  logic                  axis_rx_tready,
    output logic                  axis_rx_tlast
);

    // Link states
    typedef enum logic [2:0] {
        LINK_RESET     = 3'b000,
        LINK_INIT      = 3'b001,
        LINK_TRAINING  = 3'b010,
        LINK_UP        = 3'b011,
        LINK_ERROR     = 3'b100
    } link_state_t;

    link_state_t link_state;

    // Simple implementation - just pass through for now
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            link_state <= LINK_RESET;
            link_up <= 1'b0;
        end else begin
            case (link_state)
                LINK_RESET: if (enable) link_state <= LINK_UP;
                LINK_UP: link_up <= 1'b1;
                default: link_state <= LINK_RESET;
            endcase
        end
    end

    // Direct connection for now
    assign phy_tx_data = axis_tx_tdata;
    assign phy_tx_valid = axis_tx_tvalid;
    assign axis_tx_tready = phy_tx_ready;

    assign axis_rx_tdata = phy_rx_data;
    assign axis_rx_tvalid = phy_rx_valid;
    assign phy_rx_ready = axis_rx_tready;

    assign axis_rx_tlast = 1'b0;  // Continuous stream
    assign status = {29'b0, link_state};
    assign error_count = 32'b0;

endmodule : toslink_controller

`endif // TOSLINK_CONTROLLER_SV
