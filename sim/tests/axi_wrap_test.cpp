#include "Vaxi_sdram_stub.h"
#include "verilated.h"
#include <iostream>
#include <cstdint>

static void tick(Vaxi_sdram_stub* top) {
    top->clk = 0;
    top->eval();
    top->clk = 1;
    top->eval();
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vaxi_sdram_stub* top = new Vaxi_sdram_stub;

    // Initialize signals
    top->clk = 0;
    top->rst_n = 0;
    top->s_axi_awvalid = 0;
    top->s_axi_wvalid = 0;
    top->s_axi_wlast = 0;
    top->s_axi_bready = 1; // we will accept responses
    top->s_axi_arvalid = 0;
    top->s_axi_rready = 1;
    top->dbg_we = 0;
    top->dbg_re = 0;

    // reset for a few cycles
    for (int i = 0; i < 5; ++i) tick(top);
    top->rst_n = 1;
    for (int i = 0; i < 5; ++i) tick(top);

    // Test parameters: 64-bit data, 4-beat burst (AWLEN=3), size=3 (8 bytes), WRAP burst
    uint64_t base_addr = 16; // start such that wrap occurs
    uint8_t awlen = 3; // 4 beats
    uint8_t awsize = 3; // 8 bytes
    uint8_t awburst = 2; // WRAP (2'b10)

    // Drive AW
    top->s_axi_awaddr = base_addr;
    top->s_axi_awlen  = awlen;
    top->s_axi_awsize = awsize;
    top->s_axi_awburst= awburst;
    top->s_axi_awvalid= 1;

    // Wait for AWREADY
    for (int i = 0; i < 200; ++i) {
        tick(top);
        if (top->s_axi_awready) break;
    }
    top->s_axi_awvalid = 0;

    // Send W beats
    const uint64_t patterns[4] = {0x1111111111111111ULL, 0x2222222222222222ULL,
                                  0x3333333333333333ULL, 0x4444444444444444ULL};
    for (int b = 0; b <= awlen; ++b) {
        top->s_axi_wdata = patterns[b];
        top->s_axi_wstrb = 0xFF;
        top->s_axi_wlast = (b == awlen) ? 1 : 0;
        top->s_axi_wvalid= 1;
        // wait for WREADY
        for (int i = 0; i < 200; ++i) {
            tick(top);
            if (top->s_axi_wready) break;
        }
        top->s_axi_wvalid = 0;
        top->s_axi_wlast = 0;
    }

    // Wait for BVALID and handshake
    for (int i = 0; i < 500; ++i) {
        tick(top);
        if (top->s_axi_bvalid) break;
    }
    if (!top->s_axi_bvalid) {
        std::cerr << "ERROR: no BVALID seen\n";
        return 2;
    }
    // accept response
    tick(top);

    // Read back via debug port. Addresses for writes (byte addresses): 16,24,0,8 (wrap around 32-byte boundary)
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
