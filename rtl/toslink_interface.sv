// ============================================================================
// TOSLINK Interface
// Optical interconnect interface using S/PDIF protocol for board communication
// ============================================================================

`ifndef TOSLINK_INTERFACE_SV
`define TOSLINK_INTERFACE_SV

interface toslink_if #(
    parameter int DATA_WIDTH = 32,
    parameter int SAMPLE_RATE = 48000,
    parameter int OVERSAMPLE = 64
)(
    input logic clk,
    input logic rst_n
);

    // ============================================================================
    // TOSLINK Protocol Signals
    // ============================================================================

    // Optical interface
    logic tx_optical;           // Optical transmit signal
    logic rx_optical;           // Optical receive signal

    // Electrical data interface (for testing/debugging)
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  tx_valid;
    logic                  tx_ready;

    logic [DATA_WIDTH-1:0] rx_data;
    logic                  rx_valid;
    logic                  rx_ready;

    // Control and status
    logic enable;               // Enable interface
    logic [3:0] mode;           // Operating mode
    logic loopback_en;          // Loopback enable for testing

    logic link_up;              // Link is established
    logic link_locked;          // PLL locked to incoming signal
    logic [31:0] status;        // Status register
    logic [31:0] error_count;   // Error counter

    // ============================================================================
    // Modports
    // ============================================================================

    modport master (
        output tx_optical, tx_data, tx_valid, enable, mode, loopback_en,
        input  rx_optical, tx_ready, link_up, link_locked, status, error_count,
        output rx_ready,
        input  rx_data, rx_valid
    );

    modport slave (
        input  tx_optical, tx_data, tx_valid, enable, mode, loopback_en,
        output rx_optical, tx_ready, link_up, link_locked, status, error_count,
        input  rx_ready,
        output rx_data, rx_valid
    );

endinterface : toslink_if

`endif // TOSLINK_INTERFACE_SV
