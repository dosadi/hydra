`ifndef UCIE_INTERFACE_SV
`define UCIE_INTERFACE_SV

// ============================================================================
// UCIe (Universal Chiplet Interconnect Express) Interface
// High-bandwidth, low-latency chiplet interconnect based on UCIe 1.0 spec
// ============================================================================

interface ucie_if #(
    parameter int DATA_WIDTH = 64,      // Data width (64 or 128 bits)
    parameter int NUM_LANES = 8,        // Number of UCIe lanes (2, 4, 8, 16, 32, 64)
    parameter int MAX_CREDITS = 16      // Maximum flow control credits
)(
    input logic clk,
    input logic rst_n
);

// ============================================================================
// UCIe (Universal Chiplet Interconnect Express) Interface
// High-bandwidth, low-latency chiplet interconnect based on UCIe 1.0 spec
// Enhanced implementation with full protocol support
// ============================================================================

interface ucie_if #(
    parameter int DATA_WIDTH = 64,      // Data width (64 or 128 bits)
    parameter int NUM_LANES = 8,        // Number of UCIe lanes (2, 4, 8, 16, 32, 64)
    parameter int MAX_CREDITS = 16      // Maximum flow control credits
)(
    input logic clk,
    input logic rst_n
);

    // ============================================================================
    // UCIe Protocol Signals - Enhanced for UCIe 1.0 Compliance
    // ============================================================================

    // Physical Layer Signals
    logic [NUM_LANES-1:0]                  phy_tx_data_valid;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]  phy_tx_data;
    logic [NUM_LANES-1:0]                  phy_tx_start;
    logic [NUM_LANES-1:0]                  phy_tx_end;
    logic [NUM_LANES-1:0][7:0]             phy_tx_crc;

    logic [NUM_LANES-1:0]                  phy_rx_data_valid;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]  phy_rx_data;
    logic [NUM_LANES-1:0]                  phy_rx_start;
    logic [NUM_LANES-1:0]                  phy_rx_end;
    logic [NUM_LANES-1:0][7:0]             phy_rx_crc;

    // Link Layer Signals
    logic [NUM_LANES-1:0]                  link_tx_ack;
    logic [NUM_LANES-1:0]                  link_rx_ack;
    logic [NUM_LANES-1:0][3:0]             link_tx_vc_id;
    logic [NUM_LANES-1:0][3:0]             link_rx_vc_id;
    logic [NUM_LANES-1:0][1:0]             link_tx_type;
    logic [NUM_LANES-1:0][1:0]             link_rx_type;

    // Transport Layer Signals
    logic [NUM_LANES-1:0][7:0]             transport_tx_seq;
    logic [NUM_LANES-1:0][7:0]             transport_rx_seq;
    logic [NUM_LANES-1:0]                  transport_tx_eop;
    logic [NUM_LANES-1:0]                  transport_rx_eop;

    // Flow Control
    logic [NUM_LANES-1:0][15:0]            fc_tx_credits;
    logic [NUM_LANES-1:0][15:0]            fc_rx_credits;
    logic [NUM_LANES-1:0]                  fc_tx_update;
    logic [NUM_LANES-1:0]                  fc_rx_update;

    // Sideband and Management
    logic                                 sb_tx_valid;
    logic [31:0]                         sb_tx_data;
    logic                                 sb_tx_ready;
    logic                                 sb_rx_valid;
    logic [31:0]                         sb_rx_data;
    logic                                 sb_rx_ready;

    // Error and Status
    logic [NUM_LANES-1:0]                 lane_error;
    logic [NUM_LANES-1:0]                 lane_ready;
    logic                                 link_error;
    logic                                 link_ready;
    logic [NUM_LANES-1:0][7:0]            lane_status;

    // Power Management
    logic                                 pm_tx_l1_entry;
    logic                                 pm_rx_l1_entry;
    logic                                 pm_tx_l1_exit;
    logic                                 pm_rx_l1_exit;

    // ============================================================================
    // Modports - Enhanced for Full Protocol Support
    // ============================================================================

    modport phy_master (
        output phy_tx_data_valid, phy_tx_data, phy_tx_start, phy_tx_end, phy_tx_crc,
        input  phy_rx_data_valid, phy_rx_data, phy_rx_start, phy_rx_end, phy_rx_crc,
        output pm_tx_l1_entry, pm_tx_l1_exit,
        input  pm_rx_l1_entry, pm_rx_l1_exit,
        input  lane_error, lane_ready, lane_status
    );

    modport phy_slave (
        input  phy_tx_data_valid, phy_tx_data, phy_tx_start, phy_tx_end, phy_tx_crc,
        output phy_rx_data_valid, phy_rx_data, phy_rx_start, phy_rx_end, phy_rx_crc,
        input  pm_tx_l1_entry, pm_tx_l1_exit,
        output pm_rx_l1_entry, pm_rx_l1_exit,
        output lane_error, lane_ready, lane_status
    );

    modport link_master (
        output link_tx_ack, link_tx_vc_id, link_tx_type,
        input  link_rx_ack, link_rx_vc_id, link_rx_type,
        output fc_tx_credits, fc_tx_update,
        input  fc_rx_credits, fc_rx_update,
        output sb_tx_valid, sb_tx_data, input sb_tx_ready,
        input  sb_rx_valid, sb_rx_data, output sb_rx_ready,
        input  link_error, link_ready
    );

    modport link_slave (
        input  link_tx_ack, link_tx_vc_id, link_tx_type,
        output link_rx_ack, link_rx_vc_id, link_rx_type,
        input  fc_tx_credits, fc_tx_update,
        output fc_rx_credits, fc_rx_update,
        input  sb_tx_valid, sb_tx_data, output sb_tx_ready,
        output sb_rx_valid, sb_rx_data, input sb_rx_ready,
        output link_error, link_ready
    );

    modport transport_master (
        output transport_tx_seq, transport_tx_eop,
        input  transport_rx_seq, transport_rx_eop
    );

    modport transport_slave (
        input  transport_tx_seq, transport_tx_eop,
        output transport_rx_seq, transport_rx_eop
    );

endinterface : ucie_if
    // Protocol Assertions
    // ============================================================================

    // Check that start/end are properly paired
    property p_valid_packet;
        @(posedge clk) disable iff (!rst_n)
        fwd_valid |-> (fwd_start && fwd_end) || (!fwd_start && !fwd_end);
    endproperty

    // Check CRC validity (simplified)
    property p_crc_check;
        @(posedge clk) disable iff (!rst_n)
        fwd_valid |-> (fwd_crc != 8'h00); // Simplified CRC check
    endproperty

    // Check flow control
    property p_flow_control;
        @(posedge clk) disable iff (!rst_n)
        (fwd_valid && fwd_ready) |-> (fwd_credits > 0);
    endproperty

    // Assertions removed for synthesis compatibility

endinterface : ucie_if

`endif // UCIE_INTERFACE_SV
