// Test module for TOSLINK interconnect
module toslink_test(
    input  logic clk,
    input  logic rst_n,
    input  logic enable,
    input  logic loopback_en,
    input  logic bypass_en,
    input  logic [3:0] mode,
    input  logic [31:0] axis_tx_tdata,
    input  logic axis_tx_tvalid,
    output logic axis_tx_tready,
    input  logic axis_tx_tlast,
    output logic [31:0] axis_rx_tdata,
    output logic axis_rx_tvalid,
    input  logic axis_rx_tready,
    output logic axis_rx_tlast,
    output logic link_up,
    output logic [31:0] link_status,
    output logic [31:0] phy_status,
    output logic [31:0] error_count
);

    // Optical interface (simulated)
    logic tx_optical, rx_optical;

    toslink_interconnect dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_optical(tx_optical),
        .rx_optical(rx_optical),
        .enable(enable),
        .mode(mode),
        .loopback_en(loopback_en),
        .bypass_en(bypass_en),
        .link_up(link_up),
        .link_status(link_status),
        .phy_status(phy_status),
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

    // For loopback testing, connect tx to rx
    assign rx_optical = loopback_en ? tx_optical : 1'b0;

endmodule
