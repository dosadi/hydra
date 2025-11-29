// ============================================================================
// Crossbar Package
// Common types and interfaces for crossbar interconnect system
// ============================================================================

`ifndef CROSSBAR_PKG_SV
`define CROSSBAR_PKG_SV

// ============================================================================
// AXI-Lite Interface
// ============================================================================

interface axil_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
);
    // Write address channel
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [2:0]            awprot;
    logic                  awvalid;
    logic                  awready;

    // Write data channel
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH/8-1:0] wstrb;
    logic                  wvalid;
    logic                  wready;

    // Write response channel
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

    // Read address channel
    logic [ADDR_WIDTH-1:0] araddr;
    logic [2:0]            arprot;
    logic                  arvalid;
    logic                  arready;

    // Read data channel
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    modport master (
        output awaddr, awprot, awvalid, input awready,
        output wdata, wstrb, wvalid, input wready,
        input bresp, bvalid, output bready,
        output araddr, arprot, arvalid, input arready,
        input rdata, rresp, rvalid, output rready
    );

    modport slave (
        input awaddr, awprot, awvalid, output awready,
        input wdata, wstrb, wvalid, output wready,
        output bresp, bvalid, input bready,
        input araddr, arprot, arvalid, output arready,
        output rdata, rresp, rvalid, input rready
    );
endinterface : axil_if

// ============================================================================
// AXI4 Interface
// ============================================================================

interface axi_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH = 8,
    parameter int AWUSER_WIDTH = 1,
    parameter int WUSER_WIDTH = 1,
    parameter int BUSER_WIDTH = 1,
    parameter int ARUSER_WIDTH = 1,
    parameter int RUSER_WIDTH = 1
);
    // Write address channel
    logic [ID_WIDTH-1:0]         awid;
    logic [ADDR_WIDTH-1:0]       awaddr;
    logic [7:0]                  awlen;
    logic [2:0]                  awsize;
    logic [1:0]                  awburst;
    logic                       awlock;
    logic [3:0]                  awcache;
    logic [2:0]                  awprot;
    logic [3:0]                  awqos;
    logic [3:0]                  awregion;
    logic [AWUSER_WIDTH-1:0]     awuser;
    logic                       awvalid;
    logic                       awready;

    // Write data channel
    logic [DATA_WIDTH-1:0]       wdata;
    logic [DATA_WIDTH/8-1:0]     wstrb;
    logic                       wlast;
    logic [WUSER_WIDTH-1:0]      wuser;
    logic                       wvalid;
    logic                       wready;

    // Write response channel
    logic [ID_WIDTH-1:0]         bid;
    logic [1:0]                  bresp;
    logic [BUSER_WIDTH-1:0]      buser;
    logic                       bvalid;
    logic                       bready;

    // Read address channel
    logic [ID_WIDTH-1:0]         arid;
    logic [ADDR_WIDTH-1:0]       araddr;
    logic [7:0]                  arlen;
    logic [2:0]                  arsize;
    logic [1:0]                  arburst;
    logic                       arlock;
    logic [3:0]                  arcache;
    logic [2:0]                  arprot;
    logic [3:0]                  arqos;
    logic [3:0]                  arregion;
    logic [ARUSER_WIDTH-1:0]     aruser;
    logic                       arvalid;
    logic                       arready;

    // Read data channel
    logic [ID_WIDTH-1:0]         rid;
    logic [DATA_WIDTH-1:0]       rdata;
    logic [1:0]                  rresp;
    logic                       rlast;
    logic [RUSER_WIDTH-1:0]      ruser;
    logic                       rvalid;
    logic                       rready;

    modport master (
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
        awqos, awregion, awuser, awvalid, input awready,
        output wdata, wstrb, wlast, wuser, wvalid, input wready,
        input bid, bresp, buser, bvalid, output bready,
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
        arqos, arregion, aruser, arvalid, input arready,
        input rid, rdata, rresp, rlast, ruser, rvalid, output rready
    );

    modport slave (
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot,
        awqos, awregion, awuser, awvalid, output awready,
        input wdata, wstrb, wlast, wuser, wvalid, output wready,
        output bid, bresp, buser, bvalid, input bready,
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot,
        arqos, arregion, aruser, arvalid, output arready,
        output rid, rdata, rresp, rlast, ruser, rvalid, input rready
    );
endinterface : axi_if

// ============================================================================
// AXI-Stream Interface
// ============================================================================

interface axis_if #(
    parameter int DATA_WIDTH = 32,
    parameter int USER_WIDTH = 1,
    parameter int DEST_WIDTH = 1,
    parameter int ID_WIDTH = 1
);
    logic [DATA_WIDTH-1:0]   tdata;
    logic [DATA_WIDTH/8-1:0] tstrb;
    logic [DATA_WIDTH/8-1:0] tkeep;
    logic                    tlast;
    logic [USER_WIDTH-1:0]   tuser;
    logic [DEST_WIDTH-1:0]   tdest;
    logic [ID_WIDTH-1:0]     tid;
    logic                    tvalid;
    logic                    tready;

    modport master (
        output tdata, tstrb, tkeep, tlast, tuser, tdest, tid, tvalid,
        input tready
    );

    modport slave (
        input tdata, tstrb, tkeep, tlast, tuser, tdest, tid, tvalid,
        output tready
    );
endinterface : axis_if

package crossbar_pkg;

    // ============================================================================
    // Configuration Structure
    // ============================================================================

    typedef struct packed {
        int NUM_MASTERS;
        int NUM_SLAVES;
        int ADDR_WIDTH;
        int DATA_WIDTH;
        int ID_WIDTH;
        bit [32*4-1:0] SLAVE_BASE_ADDRS;  // Up to 4 slaves
        bit [32*4-1:0] SLAVE_ADDR_MASKS;  // Up to 4 slaves
        int ARBITRATION_MODE;
        int MAX_TRANSACTIONS;
    } crossbar_config_t;

endpackage : crossbar_pkg

`endif // CROSSBAR_PKG_SV
