`ifndef AXIL_CROSSBAR_SV
`define AXIL_CROSSBAR_SV

// ============================================================================
// AXI-Lite Crossbar Interconnect
// Lightweight multi-master, multi-slave AXI-Lite crossbar for control interfaces
// ============================================================================

module axil_crossbar #(
    parameter int NUM_MASTERS = 4,
    parameter int NUM_SLAVES = 4,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter bit [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_BASE_ADDRS = '0,
    parameter bit [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_ADDR_MASKS = '0,
    parameter int ARBITRATION_MODE = 0  // 0=round-robin, 1=priority
)(
    input  logic clk,
    input  logic rst_n,

    // Master interfaces (AXI-Lite)
    input  logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]       m_awaddr,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_awprot,
    input  logic [NUM_MASTERS-1:0]                       m_awvalid,
    output logic [NUM_MASTERS-1:0]                       m_awready,

    input  logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0]       m_wdata,
    input  logic [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0]     m_wstrb,
    input  logic [NUM_MASTERS-1:0]                       m_wvalid,
    output logic [NUM_MASTERS-1:0]                       m_wready,

    output logic [NUM_MASTERS-1:0][1:0]                  m_bresp,
    output logic [NUM_MASTERS-1:0]                       m_bvalid,
    input  logic [NUM_MASTERS-1:0]                       m_bready,

    input  logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]       m_araddr,
    input  logic [NUM_MASTERS-1:0][2:0]                  m_arprot,
    input  logic [NUM_MASTERS-1:0]                       m_arvalid,
    output logic [NUM_MASTERS-1:0]                       m_arready,

    output logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0]       m_rdata,
    output logic [NUM_MASTERS-1:0][1:0]                  m_rresp,
    output logic [NUM_MASTERS-1:0]                       m_rvalid,
    input  logic [NUM_MASTERS-1:0]                       m_rready,

    // Slave interfaces (AXI-Lite)
    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]        s_awaddr,
    output logic [NUM_SLAVES-1:0][2:0]                   s_awprot,
    output logic [NUM_SLAVES-1:0]                        s_awvalid,
    input  logic [NUM_SLAVES-1:0]                        s_awready,

    output logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]        s_wdata,
    output logic [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0]      s_wstrb,
    output logic [NUM_SLAVES-1:0]                        s_wvalid,
    input  logic [NUM_SLAVES-1:0]                        s_wready,

    input  logic [NUM_SLAVES-1:0][1:0]                   s_bresp,
    input  logic [NUM_SLAVES-1:0]                        s_bvalid,
    output logic [NUM_SLAVES-1:0]                        s_bready,

    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]        s_araddr,
    output logic [NUM_SLAVES-1:0][2:0]                   s_arprot,
    output logic [NUM_SLAVES-1:0]                        s_arvalid,
    input  logic [NUM_SLAVES-1:0]                        s_arready,

    input  logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]        s_rdata,
    input  logic [NUM_SLAVES-1:0][1:0]                   s_rresp,
    input  logic [NUM_SLAVES-1:0]                        s_rvalid,
    output logic [NUM_SLAVES-1:0]                        s_rready
);

    // ============================================================================
    // Local Parameters and Types
    // ============================================================================

    localparam MASTER_ID_WIDTH = $clog2(NUM_MASTERS);
    localparam SLAVE_ID_WIDTH = $clog2(NUM_SLAVES);

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
    logic [MASTER_ID_WIDTH-1:0] aw_priority;
    logic [MASTER_ID_WIDTH-1:0] ar_priority;

    // Round-robin arbitration with priority support
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_priority <= '0;
            ar_priority <= '0;
        end else begin
            // Update priorities after each arbitration
            if (|aw_grant) begin
                aw_priority <= aw_priority + 1;
                if (aw_priority >= NUM_MASTERS-1) aw_priority <= '0;
            end
            if (|ar_grant) begin
                ar_priority <= ar_priority + 1;
                if (ar_priority >= NUM_MASTERS-1) ar_priority <= '0;
            end
        end
    end

    generate
        if (ARBITRATION_MODE == 0) begin : g_round_robin
            // Round-robin arbitration
            always_comb begin
                aw_grant = '0;
                ar_grant = '0;
                aw_request = m_awvalid;
                ar_request = m_arvalid;

                // AW channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    int idx = (i + aw_priority) % NUM_MASTERS;
                    if (aw_request[idx] && !(|aw_grant)) begin
                        aw_grant[idx] = 1'b1;
                    end
                end

                // AR channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    int idx = (i + ar_priority) % NUM_MASTERS;
                    if (ar_request[idx] && !(|ar_grant)) begin
                        ar_grant[idx] = 1'b1;
                    end
                end
            end
        end else begin : g_priority
            // Priority-based arbitration (lower index = higher priority)
            always_comb begin
                aw_grant = '0;
                ar_grant = '0;

                // AW channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    if (m_awvalid[i] && !(|aw_grant)) begin
                        aw_grant[i] = 1'b1;
                    end
                end

                // AR channel arbitration
                for (int i = 0; i < NUM_MASTERS; i++) begin
                    if (m_arvalid[i] && !(|ar_grant)) begin
                        ar_grant[i] = 1'b1;
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
        s_awaddr = '0;
        s_awprot = '0;
        m_awready = '0;

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (aw_grant[m]) begin
                automatic logic [SLAVE_ID_WIDTH-1:0] slave_id = decode_address(m_awaddr[m]);
                s_awvalid[slave_id] = m_awvalid[m];
                s_awaddr[slave_id] = m_awaddr[m];
                s_awprot[slave_id] = m_awprot[m];
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
                    // Find which master granted access to this slave
                    for (int m = 0; m < NUM_MASTERS; m++) begin
                        if (aw_grant[m] && decode_address(m_awaddr[m]) == s) begin
                            w_owner[s] <= m[MASTER_ID_WIDTH-1:0];
                            w_owner_valid[s] <= 1'b1;
                            break;
                        end
                    end
                end else if (s_wvalid[s] && s_wready[s]) begin
                    w_owner_valid[s] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        s_wvalid = '0;
        s_wdata = '0;
        s_wstrb = '0;
        m_wready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (w_owner_valid[s]) begin
                automatic int master_id = w_owner[s];
                s_wvalid[s] = m_wvalid[master_id];
                s_wdata[s] = m_wdata[master_id];
                s_wstrb[s] = m_wstrb[master_id];
                m_wready[master_id] = s_wready[s];
            end
        end
    end

    // ============================================================================
    // Write Response Channel Routing
    // ============================================================================

    always_comb begin
        m_bvalid = '0;
        m_bresp = '0;
        s_bready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (s_bvalid[s]) begin
                automatic int master_id = w_owner[s];
                m_bvalid[master_id] = s_bvalid[s];
                m_bresp[master_id] = s_bresp[s];
                s_bready[s] = m_bready[master_id];
            end
        end
    end

    // ============================================================================
    // Read Address Channel Routing
    // ============================================================================

    always_comb begin
        s_arvalid = '0;
        s_araddr = '0;
        s_arprot = '0;
        m_arready = '0;

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (ar_grant[m]) begin
                automatic logic [SLAVE_ID_WIDTH-1:0] slave_id = decode_address(m_araddr[m]);
                s_arvalid[slave_id] = m_arvalid[m];
                s_araddr[slave_id] = m_araddr[m];
                s_arprot[slave_id] = m_arprot[m];
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
                    // Find which master granted access to this slave
                    for (int m = 0; m < NUM_MASTERS; m++) begin
                        if (ar_grant[m] && decode_address(m_araddr[m]) == s) begin
                            r_owner[s] <= m[MASTER_ID_WIDTH-1:0];
                            r_owner_valid[s] <= 1'b1;
                            break;
                        end
                    end
                end else if (s_rvalid[s] && s_rready[s]) begin
                    r_owner_valid[s] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        m_rvalid = '0;
        m_rdata = '0;
        m_rresp = '0;
        s_rready = '0;

        for (int s = 0; s < NUM_SLAVES; s++) begin
            if (s_rvalid[s]) begin
                automatic int master_id = r_owner[s];
                m_rvalid[master_id] = s_rvalid[s];
                m_rdata[master_id] = s_rdata[s];
                m_rresp[master_id] = s_rresp[s];
                s_rready[s] = m_rready[master_id];
            end
        end
    end

endmodule : axil_crossbar

`endif // AXIL_CROSSBAR_SV
