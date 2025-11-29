#include "Vtoslink_test.h"
#include "verilated.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vtoslink_test* top = new Vtoslink_test;

    // Initialize
    top->rst_n = 0;
    top->enable = 0;
    top->loopback_en = 1; // Enable loopback for testing
    top->bypass_en = 1;   // Enable bypass for testing
    top->mode = 0;
    top->axis_tx_tvalid = 0;
    top->axis_rx_tready = 1;
    top->axis_tx_tlast = 0;

    // Reset
    top->eval();
    top->rst_n = 1;
    top->eval();

    // Enable
    top->enable = 1;
    top->eval();

    // Test data transmission
    int sent_count = 0;
    int received_count = 0;
    const int MAX_CYCLES = 100000; // Allow enough time for S/PDIF transmission
    int cycle_count = 0;

    while (cycle_count < MAX_CYCLES && received_count < 10) {
        // Send data if ready and not all sent
        if (sent_count < 10 && top->axis_tx_tready && !top->axis_tx_tvalid) {
            top->axis_tx_tdata = sent_count * 0x11111111;
            top->axis_tx_tvalid = 1;
            top->axis_tx_tlast = (sent_count == 9);
            printf("Sending data: 0x%08x\n", top->axis_tx_tdata);
            sent_count++;
        }

        // Check for received data
        if (top->axis_rx_tvalid) {
            printf("Received data: 0x%08x\n", top->axis_rx_tdata);
            received_count++;
            top->axis_tx_tvalid = 0; // Clear valid after sending
        }

        // Print status every 10000 cycles
        if (cycle_count % 10000 == 0) {
            printf("Cycle %d: link_up=%d, tx_ready=%d, rx_valid=%d, phy_status=0x%08x\n", 
                   cycle_count, top->link_up, top->axis_tx_tready, top->axis_rx_tvalid, top->phy_status);
        }

        // Toggle clock
        top->clk = 1;
        top->eval();
        top->clk = 0;
        top->eval();

        cycle_count++;
    }

    if (received_count >= 10) {
        printf("Test PASSED: All data transmitted and received successfully\n");
    } else {
        printf("Test FAILED: Only received %d out of 10 packets after %d cycles\n", received_count, cycle_count);
    }

    delete top;
    return (received_count >= 10) ? 0 : 1;
}