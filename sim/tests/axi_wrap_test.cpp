#include "Vaxi_sdram_stub.h"
#include "verilated.h"
#include <iostream>
#include <cstdint>

static void tick(Vaxi_sdram_stub* top) {
    // apply inputs, clockkk toggle cloc
    top->eval();
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
}

// perform only the rising-edge portion of a clock cycle (leave clk high)
static void tick_rise(Vaxi_sdram_stub* top) {
    top->eval();
    top->clk = 1;
    top->eval();
}

// perform the falling-edge portion (assumes clk currently high)
static void tick_fall(Vaxi_sdram_stub* top) {
    top->clk = 0;
    top->eval();
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vaxi_sdram_stub* top = new Vaxi_sdram_stub;

    std::cerr << "HARNESS: started\n";

    // Initialize signals
    top->clk = 0;
    top->rst_n = 0;
    top->s_axi_awvalidx = 0; // stub uses AWVALIDX
    top->s_axi_wvalid = 0;
    top->s_axi_wlast = 0;
    top->s_axi_bready = 1; // accept responses
    top->dbg_we = 0;
    top->dbg_re = 0;

    // reset for a few cycles
    for (int i = 0; i < 5; ++i) tick(top);
    top->rst_n = 1;
    for (int i = 0; i < 5; ++i) tick(top);

    // Test parameters
    uint64_t base_addr = 16; // starting byte address
    uint8_t awlen = 3; // 4 beats
    uint8_t awsize = 3; // 8 bytes per beat
    uint8_t awburst = 2; // WRAP

    // Drive AW
    top->s_axi_awid = 0;
    top->s_axi_awaddr = base_addr;
    top->s_axi_awlen  = awlen;
    top->s_axi_awsize = awsize;
    top->s_axi_awburst= awburst;
    top->s_axi_awvalidx= 1;
    std::cerr << "HARNESS: drove AW awaddr="<< top->s_axi_awaddr << " awlen="<<int(top->s_axi_awlen)
              << " awsize="<<int(top->s_axi_awsize) << " awburst="<<int(top->s_axi_awburst) <<"\n";

    // Wait for AWREADY
    for (int i = 0; i < 200; ++i) {
        tick(top);
        if (top->s_axi_awready) {
            std::cerr << "HARNESS: AWREADY seen at i="<<i<<"\n";
            break;
        }
    }
    top->s_axi_awvalidx = 0;
    // Give the DUT one extra full cycle to stabilise AW->W handover signals
    // (some timing variations can make the first W beat miss the stub if we
    // drive it immediately).
    tick(top);

    // Send W beats
    const uint64_t patterns[4] = {0x1111111111111111ULL, 0x2222222222222222ULL,
                                  0x3333333333333333ULL, 0x4444444444444444ULL};
    bool b_seen = false;
    for (int b = 0; b <= awlen; ++b) {
        top->s_axi_wdata = patterns[b];
        top->s_axi_wstrb = 0xFF;
        top->s_axi_wlast = (b == awlen) ? 1 : 0;
        top->s_axi_wvalid= 1;
        // wait for WREADY (hold WVALID until DUT has had a chance to assert WREADY
        // and then accept the beat on the following rising edge). This aligns with
        // the stub's use of non-blocking updates for s_axi_wready.
        for (int i = 0; i < 200; ++i) {
            // Drive the rising-edge explicitly so the DUT samples WVALID at
            // the posedge where we know our signals are already stable.
            tick_rise(top);
            if (top->s_axi_bvalid) b_seen = true;
            if (top->s_axi_wready) {
                // DUT indicated readiness on the rising edge we just drove.
                // Clear master-side signals now so they are not still asserted
                // for the next rising edge (avoids duplicate acceptance).
                top->s_axi_wvalid = 0;
                top->s_axi_wlast = 0;
                // complete the falling half of the cycle
                tick_fall(top);
                break;
            }
            // complete the falling half of the cycle and try again
            tick_fall(top);
        }
        // If this was the last beat, give the DUT a few cycles to assert BVALID
        if (b == awlen) {
            for (int ex = 0; ex < 6; ++ex) {
                tick(top);
                if (top->s_axi_bvalid) {
                    b_seen = true;
                    break;
                }
            }
        }
        // ensure signals are cleared (already cleared on handshake path)
        top->s_axi_wvalid = 0;
        top->s_axi_wlast = 0;
    }

    // Wait for BVALID (skip if we already observed it during extra ticks)
    if (!b_seen) {
        for (int i = 0; i < 500; ++i) {
            tick(top);
            if (top->s_axi_bvalid) break;
        }
        if (!top->s_axi_bvalid) {
            std::cerr << "ERROR: no BVALID seen\n";
            return 2;
        }
    }
    // accept response
    tick(top);

    // Read back via debug port
    uint64_t expected_addrs[4] = {16,24,0,8};
    uint64_t expected_data[4] = {patterns[0], patterns[1], patterns[2], patterns[3]};

    for (int i = 0; i < 4; ++i) {
        top->dbg_re = 1;
        top->dbg_addr = expected_addrs[i];
        tick(top);
        top->dbg_re = 0;
        tick(top);
        uint64_t read = top->dbg_rdata;
        if (read != expected_data[i]) {
            std::cerr << "AXI WRAP test FAILED at index " << i << ": read=0x" << std::hex << read
                      << " expected=0x" << expected_data[i] << std::dec << "\n";
            return 3;
        }
    }

    std::cout << "AXI WRAP test PASSED\n";
    return 0;
}
