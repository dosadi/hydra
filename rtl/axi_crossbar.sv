`ifndef AXI_CROSSBAR_SV
`define AXI_CROSSBAR_SV

// ============================================================================
// AXI Crossbar Interconnect
// Configurable multi-master, multi-slave AXI crossbar with QoS support
// ============================================================================

module axi_crossbar #(
    parameter int NUM_MASTERS = 4,
    parameter int NUM_SLAVES = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH = 8,
    parameter int AWUSER_WIDTH = 1,
    parameter int WUSER_WIDTH = 1,
    parameter int BUSER_WIDTH = 1,
    parameter int ARUSER_WIDTH = 1,
    parameter int RUSER_WIDTH = 1,
    parameter bit [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_BASE_ADDRS = '0,
    parameter bit [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_ADDR_MASKS = '0,
    parameter int MAX_TRANSACTIONS = 16,
    parameter int ARBITRATION_MODE = 0  // 0=round-robin, 1=priority, 2=weighted
)(
    input  logic clk,
    input  logic rst_n,

    // Master interfaces
    input  logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]         m_awid,
    input  logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]       m_awaddr,
    input  logic [NUM_MASTERS-1:0][7:0]                  m_awlen,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_awsize,
    input  logic [NUM_MASTERS-1:0][1:0]                  m_awburst,
    input  logic [NUM_MASTERS-1:0]                       m_awlock,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_awcache,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_awprot,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_awqos,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_awregion,
    input  logic [NUM_MASTERS-1:0][AWUSER_WIDTH-1:0]     m_awuser,
    input  logic [NUM_MASTERS-1:0]                       m_awvalid,
    output logic [NUM_MASTERS-1:0]                       m_awready,

    input  logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0]       m_wdata,
    input  logic [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0]     m_wstrb,
    input  logic [NUM_MASTERS-1:0]                       m_wlast,
    input  logic [NUM_MASTERS-1:0][WUSER_WIDTH-1:0]      m_wuser,
    input  logic [NUM_MASTERS-1:0]                       m_wvalid,
    output logic [NUM_MASTERS-1:0]                       m_wready,

    output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]         m_bid,
    output logic [NUM_MASTERS-1:0][1:0]                  m_bresp,
    output logic [NUM_MASTERS-1:0][BUSER_WIDTH-1:0]      m_buser,
    output logic [NUM_MASTERS-1:0]                       m_bvalid,
    input  logic [NUM_MASTERS-1:0]                       m_bready,

    input  logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]         m_arid,
    input  logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]       m_araddr,
    input  logic [NUM_MASTERS-1:0][7:0]                  m_arlen,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_arsize,
    input  logic [NUM_MASTERS-1:0][1:0]                  m_arburst,
    input  logic [NUM_MASTERS-1:0]                       m_arlock,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_arcache,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_arprot,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_arqos,
    input  logic [NUM_MASTERS-1:0][3:0]                  m_arregion,
    input  logic [NUM_MASTERS-1:0][ARUSER_WIDTH-1:0]     m_aruser,
    input  logic [NUM_MASTERS-1:0]                       m_arvalid,
    output logic [NUM_MASTERS-1:0]                       m_arready,

    output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]         m_rid,
    output logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0]       m_rdata,
    output logic [NUM_MASTERS-1:0][1:0]                  m_rresp,
    output logic [NUM_MASTERS-1:0]                       m_rlast,
    output logic [NUM_MASTERS-1:0][RUSER_WIDTH-1:0]      m_ruser,
    output logic [NUM_MASTERS-1:0]                       m_rvalid,
    input  logic [NUM_MASTERS-1:0]                       m_rready,

    // Slave interfaces
    output logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]          s_awid,
    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]        s_awaddr,
    output logic [NUM_SLAVES-1:0][7:0]                   s_awlen,
    output logic [NUM_SLAVES-1:0][2:0]                   s_awsize,
    output logic [NUM_SLAVES-1:0][1:0]                   s_awburst,
    output logic [NUM_SLAVES-1:0]                        s_awlock,
    output logic [NUM_SLAVES-1:0][3:0]                   s_awcache,
    output logic [NUM_SLAVES-1:0][2:0]                   s_awprot,
    output logic [NUM_SLAVES-1:0][3:0]                   s_awqos,
    output logic [NUM_SLAVES-1:0][3:0]                   s_awregion,
    output logic [NUM_SLAVES-1:0][AWUSER_WIDTH-1:0]      s_awuser,
    output logic [NUM_SLAVES-1:0]                        s_awvalid,
    input  logic [NUM_SLAVES-1:0]                        s_awready,

    output logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]        s_wdata,
    output logic [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0]      s_wstrb,
    output logic [NUM_SLAVES-1:0]                        s_wlast,
    output logic [NUM_SLAVES-1:0][WUSER_WIDTH-1:0]       s_wuser,
    output logic [NUM_SLAVES-1:0]                        s_wvalid,
    input  logic [NUM_SLAVES-1:0]                        s_wready,

    input  logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]          s_bid,
    input  logic [NUM_SLAVES-1:0][1:0]                   s_bresp,
    input  logic [NUM_SLAVES-1:0][BUSER_WIDTH-1:0]       s_buser,
    input  logic [NUM_SLAVES-1:0]                        s_bvalid,
    output logic [NUM_SLAVES-1:0]                        s_bready,

    output logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]          s_arid,
    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]        s_araddr,
    output logic [NUM_SLAVES-1:0][7:0]                   s_arlen,
    output logic [NUM_SLAVES-1:0][2:0]                   s_arsize,
    output logic [NUM_SLAVES-1:0][1:0]                   s_arburst,
    output logic [NUM_SLAVES-1:0]                        s_arlock,
    output logic [NUM_SLAVES-1:0][3:0]                   s_arcache,
    output logic [NUM_SLAVES-1:0][2:0]                   s_arprot,
    output logic [NUM_SLAVES-1:0][3:0]                   s_arqos,
    output logic [NUM_SLAVES-1:0][3:0]                   s_arregion,
    output logic [NUM_SLAVES-1:0][ARUSER_WIDTH-1:0]      s_aruser,
    output logic [NUM_SLAVES-1:0]                        s_arvalid,
    input  logic [NUM_SLAVES-1:0]                        s_arready,

    input  logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]          s_rid,
    input  logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]        s_rdata,
    input  logic [NUM_SLAVES-1:0][1:0]                   s_rresp,
    input  logic [NUM_SLAVES-1:0]                        s_rlast,
    input  logic [NUM_SLAVES-1:0][RUSER_WIDTH-1:0]       s_ruser,
    input  logic [NUM_SLAVES-1:0]                        s_rvalid,
    output logic [NUM_SLAVES-1:0]                        s_rready
);

    // ============================================================================
    // Local Parameters and Types
    // ============================================================================

    localparam int MASTER_ID_WIDTH = $clog2(NUM_MASTERS);
    localparam int SLAVE_ID_WIDTH = $clog2(NUM_SLAVES);

    typedef struct packed {
        logic [ID_WIDTH-1:0]         id;
        logic [ADDR_WIDTH-1:0]       addr;
        logic [7:0]                  len;
        logic [2:0]                  size;
        logic [1:0]                  burst;
        logic                       lock;
        logic [3:0]                  cache;
        logic [2:0]                  prot;
        logic [3:0]                  qos;
        logic [3:0]                  region;
        logic [AWUSER_WIDTH-1:0]     user;
    } aw_channel_t;

    typedef struct packed {
        logic [DATA_WIDTH-1:0]       data;
        logic [DATA_WIDTH/8-1:0]     strb;
        logic                       last;
        logic [WUSER_WIDTH-1:0]      user;
    } w_channel_t;

    typedef struct packed {
        logic [ID_WIDTH-1:0]         id;
        logic [1:0]                  resp;
        logic [BUSER_WIDTH-1:0]      user;
    } b_channel_t;

    typedef struct packed {
        logic [ID_WIDTH-1:0]         id;
        logic [ADDR_WIDTH-1:0]       addr;
        logic [7:0]                  len;
        logic [2:0]                  size;
        logic [1:0]                  burst;
        logic                       lock;
        logic [3:0]                  cache;
        logic [2:0]                  prot;
        logic [3:0]                  qos;
        logic [3:0]                  region;
        logic [ARUSER_WIDTH-1:0]     user;
    } ar_channel_t;

    typedef struct packed {
        logic [ID_WIDTH-1:0]         id;
        logic [DATA_WIDTH-1:0]       data;
        logic [1:0]                  resp;
        logic                       last;
        logic [RUSER_WIDTH-1:0]      user;
    } r_channel_t;

    // ============================================================================
    // Address Decoding
    // ============================================================================

    function automatic logic [SLAVE_ID_WIDTH-1:0] decode_address(
        input logic [ADDR_WIDTH-1:0] addr
    );
        for (int i = 0; i < NUM_SLAVES; i++) begin
            logic [ADDR_WIDTH-1:0] base = SLAVE_BASE_ADDRS[i*ADDR_WIDTH +: ADDR_WIDTH];
            logic [ADDR_WIDTH-1:0] mask = SLAVE_ADDR_MASKS[i*ADDR_WIDTH +: ADDR_WIDTH];
            if ((addr & mask) == base) begin
                return i[SLAVE_ID_WIDTH-1:0];
            end
        end
        return '0; // Default to slave 0
    endfunction

    // ============================================================================
    // Arbitration Logic
    // ============================================================================

    logic [NUM_MASTERS-1:0] aw_grant;
    logic [NUM_MASTERS-1:0] ar_grant;
    logic [NUM_MASTERS-1:0] aw_request;
    logic [NUM_MASTERS-1:0] ar_request;

    // Round-robin arbitration
    generate
        if (ARBITRATION_MODE == 0) begin : g_round_robin
            // Round-robin arbitration logic would go here
            // For now, simple priority-based
            always_comb begin
                aw_grant = '0;
                ar_grant = '0;

                // AW channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    if (m_awvalid[i] && !aw_grant[i]) begin
                        aw_grant[i] = 1'b1;
                        break;
                    end
                end

                // AR channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    if (m_arvalid[i] && !ar_grant[i]) begin
                        ar_grant[i] = 1'b1;
                        break;
                    end
                end
            end
        end
    endgenerate

    // ============================================================================
    // Write Address Channel Routing
    // ============================================================================

    always_comb begin
        s_awvalid = '0;
        s_awid = '0;
        s_awaddr = '0;
        s_awlen = '0;
        s_awsize = '0;
        s_awburst = '0;
        s_awlock = '0;
        s_awcache = '0;
        s_awprot = '0;
        s_awqos = '0;
        s_awregion = '0;
        s_awuser = '0;
        m_awready = '0;

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (aw_grant[m]) begin
                automatic logic [SLAVE_ID_WIDTH-1:0] slave_id = decode_address(m_awaddr[m]);
                s_awvalid[slave_id] = m_awvalid[m];
                s_awid[slave_id] = {m[MASTER_ID_WIDTH-1:0], m_awid[m][ID_WIDTH-MASTER_ID_WIDTH-1:0]};
                s_awaddr[slave_id] = m_awaddr[m];
                s_awlen[slave_id] = m_awlen[m];
                s_awsize[slave_id] = m_awsize[m];
                s_awburst[slave_id] = m_awburst[m];
                s_awlock[slave_id] = m_awlock[m];
                s_awcache[slave_id] = m_awcache[m];
                s_awprot[slave_id] = m_awprot[m];
                s_awqos[slave_id] = m_awqos[m];
                s_awregion[slave_id] = m_awregion[m];
                s_awuser[slave_id] = m_awuser[m];
                m_awready[m] = s_awready[slave_id];
            end
        end
    end

    // ============================================================================
    // Write Data Channel Routing
    // ============================================================================

    // Track which master owns each slave's W channel
    logic [NUM_SLAVES-1:0][MASTER_ID_WIDTH-1:0] w_owner;
    logic [NUM_SLAVES-1:0] w_owner_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_owner <= '0;
            w_owner_valid <= '0;
        end else begin
            for (int s = 0; s < NUM_SLAVES; s++) begin
                if (s_awvalid[s] && s_awready[s]) begin
                    w_owner[s] <= s_awid[s][ID_WIDTH-1 -: MASTER_ID_WIDTH];
                    w_owner_valid[s] <= 1'b1;
                end else if (s_wvalid[s] && s_wready[s] && s_wlast[s]) begin
                    w_owner_valid[s] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        s_wvalid = '0;
        s_wdata = '0;
        s_wstrb = '0;
        s_wlast = '0;
        s_wuser = '0;
        m_wready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (w_owner_valid[s]) begin
                automatic int master_id = w_owner[s];
                s_wvalid[s] = m_wvalid[master_id];
                s_wdata[s] = m_wdata[master_id];
                s_wstrb[s] = m_wstrb[master_id];
                s_wlast[s] = m_wlast[master_id];
                s_wuser[s] = m_wuser[master_id];
                m_wready[master_id] = s_wready[s];
            end
        end
    end

    // ============================================================================
    // Write Response Channel Routing
    // ============================================================================

    always_comb begin
        m_bvalid = '0;
        m_bid = '0;
        m_bresp = '0;
        m_buser = '0;
        s_bready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (s_bvalid[s]) begin
                automatic int master_id = s_bid[s][ID_WIDTH-1 -: MASTER_ID_WIDTH];
                m_bvalid[master_id] = s_bvalid[s];
                m_bid[master_id] = s_bid[s][MASTER_ID_WIDTH-1:0];
                m_bresp[master_id] = s_bresp[s];
                m_buser[master_id] = s_buser[s];
                s_bready[s] = m_bready[master_id];
            end
        end
    end

    // ============================================================================
    // Read Address Channel Routing
    // ============================================================================

    always_comb begin
        s_arvalid = '0;
        s_arid = '0;
        s_araddr = '0;
        s_arlen = '0;
        s_arsize = '0;
        s_arburst = '0;
        s_arlock = '0;
        s_arcache = '0;
        s_arprot = '0;
        s_arqos = '0;
        s_arregion = '0;
        s_aruser = '0;
        m_arready = '0;

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (ar_grant[m]) begin
                automatic logic [SLAVE_ID_WIDTH-1:0] slave_id = decode_address(m_araddr[m]);
                s_arvalid[slave_id] = m_arvalid[m];
                s_arid[slave_id] = {m[MASTER_ID_WIDTH-1:0], m_arid[m][ID_WIDTH-MASTER_ID_WIDTH-1:0]};
                s_araddr[slave_id] = m_araddr[m];
                s_arlen[slave_id] = m_arlen[m];
                s_arsize[slave_id] = m_arsize[m];
                s_arburst[slave_id] = m_arburst[m];
                s_arlock[slave_id] = m_arlock[m];
                s_arcache[slave_id] = m_arcache[m];
                s_arprot[slave_id] = m_arprot[m];
                s_arqos[slave_id] = m_arqos[m];
                s_arregion[slave_id] = m_arregion[m];
                s_aruser[slave_id] = m_aruser[m];
                m_arready[m] = s_arready[slave_id];
            end
        end
    end

    // ============================================================================
    // Read Data Channel Routing
    // ============================================================================

    // Track which master owns each slave's R channel
    logic [NUM_SLAVES-1:0][MASTER_ID_WIDTH-1:0] r_owner;
    logic [NUM_SLAVES-1:0] r_owner_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_owner <= '0;
            r_owner_valid <= '0;
        end else begin
            for (int s = 0; s < NUM_SLAVES; s++) begin
                if (s_arvalid[s] && s_arready[s]) begin
                    r_owner[s] <= s_arid[s][ID_WIDTH-1 -: MASTER_ID_WIDTH];
                    r_owner_valid[s] <= 1'b1;
                end else if (s_rvalid[s] && s_rready[s] && s_rlast[s]) begin
                    r_owner_valid[s] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        m_rvalid = '0;
        m_rid = '0;
        m_rdata = '0;
        m_rresp = '0;
        m_rlast = '0;
        m_ruser = '0;
        s_rready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (s_rvalid[s]) begin
                automatic int master_id = r_owner[s];
                m_rvalid[master_id] = s_rvalid[s];
                m_rid[master_id] = s_rid[s][MASTER_ID_WIDTH-1:0];
                m_rdata[master_id] = s_rdata[s];
                m_rresp[master_id] = s_rresp[s];
                m_rlast[master_id] = s_rlast[s];
                m_ruser[master_id] = s_ruser[s];
                s_rready[s] = m_rready[master_id];
            end
        end
    end

endmodule : axi_crossbar

`endif // AXI_CROSSBAR_SV
