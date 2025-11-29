`ifndef AES_IP_CORE_SV
`define AES_IP_CORE_SV

// ============================================================================
// AES Encryption/Decryption IP Core Integration
// Supports both open source and commercial AES implementations
// ============================================================================

import crossbar_pkg::*;

module aes_ip_core #(
    parameter string IP_TYPE = "OPEN_SOURCE",  // "OPEN_SOURCE" or "COMMERCIAL"
    parameter int    KEY_SIZE = 256,          // 128, 192, or 256 bits
    parameter int    MODE = 0                 // 0=ECB, 1=CBC, 2=CTR, 3=GCM
)(
    // ============================================================================
    // Standard Hydra Interfaces
    // ============================================================================

    input  logic        clk,
    input  logic        rst_n,

    // Control interface (AXI-Lite)
    axil_if.slave  axil_if,

    // Data interface (AXI4 for bulk data)
    axi_if.slave   axi_data_if,

    // Streaming interfaces for real-time encryption/decryption
    axis_if.master axis_encrypt_out,
    axis_if.slave  axis_encrypt_in,
    axis_if.master axis_decrypt_out,
    axis_if.slave  axis_decrypt_in,

    // ============================================================================
    // AES-Specific Interfaces
    // ============================================================================

    // Key interface (secure key loading) - now internal
    output logic                 key_valid,
    output logic                 key_ready,

    // Initialization vector (for CBC/CTR/GCM modes) - now internal
    output logic                 iv_valid,
    output logic                 iv_ready,

    // ============================================================================
    // Control and Status
    // ============================================================================

    input  logic        enable,
    input  logic [31:0] control,
    output logic        ready,
    output logic [31:0] status,
    output logic [31:0] error_count,

    // Performance counters
    output logic [63:0] blocks_processed,
    output logic [31:0] latency_cycles
);

    // ============================================================================
    // Internal Signals and State
    // ============================================================================

    logic aes_ready, aes_error;
    logic [31:0] aes_status;
    logic [31:0] error_counter;

    // Internal key and IV storage
    logic [KEY_SIZE-1:0] internal_aes_key;
    logic [127:0]        internal_iv;

    // Control register fields
    logic [1:0]  operation_mode;    // 0=encrypt, 1=decrypt, 2=key expansion
    logic        start_operation;
    logic        clear_errors;
    logic [1:0]  key_size_select;   // 0=128, 1=192, 2=256
    logic [1:0]  cipher_mode;       // 0=ECB, 1=CBC, 2=CTR, 3=GCM

    // ============================================================================
    // Control Register Decoding
    // ============================================================================

    assign operation_mode   = control[1:0];
    assign start_operation  = control[2];
    assign clear_errors     = control[3];
    assign key_size_select  = control[5:4];
    assign cipher_mode      = control[7:6];

    // ============================================================================
    // AES Core Instantiation
    // ============================================================================

    generate
        if (IP_TYPE == "COMMERCIAL") begin : gen_commercial_aes
            // Commercial AES IP instantiation
            // NOTE: Replace with actual commercial AES core interface
            commercial_aes_core #(
                .KEY_SIZE(KEY_SIZE),
                .MODE(MODE)
            ) commercial_aes (
                .clk(clk),
                .rst_n(rst_n && enable),
                .key(internal_aes_key),
                .key_valid(key_valid),
                .key_ready(key_ready),
                .iv(internal_iv),
                .iv_valid(iv_valid),
                .iv_ready(iv_ready),
                .operation_mode(operation_mode),
                .cipher_mode(cipher_mode),
                .start(start_operation),

                // AXI-Stream interfaces for data
                .axis_encrypt_in_tdata(axis_encrypt_in.tdata),
                .axis_encrypt_in_tvalid(axis_encrypt_in.tvalid),
                .axis_encrypt_in_tready(axis_encrypt_in.tready),
                .axis_encrypt_in_tlast(axis_encrypt_in.tlast),

                .axis_encrypt_out_tdata(axis_encrypt_out.tdata),
                .axis_encrypt_out_tvalid(axis_encrypt_out.tvalid),
                .axis_encrypt_out_tready(axis_encrypt_out.tready),
                .axis_encrypt_out_tlast(axis_encrypt_out.tlast),

                .axis_decrypt_in_tdata(axis_decrypt_in.tdata),
                .axis_decrypt_in_tvalid(axis_decrypt_in.tvalid),
                .axis_decrypt_in_tready(axis_decrypt_in.tready),
                .axis_decrypt_in_tlast(axis_decrypt_in.tlast),

                .axis_decrypt_out_tdata(axis_decrypt_out.tdata),
                .axis_decrypt_out_tvalid(axis_decrypt_out.tvalid),
                .axis_decrypt_out_tready(axis_decrypt_out.tready),
                .axis_decrypt_out_tlast(axis_decrypt_out.tlast),

                // Status and control
                .ready(aes_ready),
                .status(aes_status),
                .error(aes_error),
                .blocks_processed(blocks_processed),
                .latency_cycles(latency_cycles)
            );
        end else begin : gen_open_source_aes
            // Open source AES implementation
            // Using secworks/aes as reference
            open_source_aes_core #(
                .KEY_SIZE(KEY_SIZE),
                .MODE(MODE)
            ) open_source_aes (
                .clk(clk),
                .rst_n(rst_n && enable),
                .key(internal_aes_key),
                .key_valid(key_valid),
                .key_ready(key_ready),
                .iv(internal_iv),
                .iv_valid(iv_valid),
                .iv_ready(iv_ready),
                .operation_mode(operation_mode),
                .cipher_mode(cipher_mode),
                .start(start_operation),

                // AXI-Stream interfaces
                .axis_encrypt_in(axis_encrypt_in),
                .axis_encrypt_out(axis_encrypt_out),
                .axis_decrypt_in(axis_decrypt_in),
                .axis_decrypt_out(axis_decrypt_out),

                // Status
                .ready(aes_ready),
                .status(aes_status),
                .error(aes_error),
                .blocks_processed(blocks_processed),
                .latency_cycles(latency_cycles)
            );
        end
    endgenerate

    // ============================================================================
    // AXI-Lite Control Interface
    // ============================================================================

    // Register map
    localparam int AES_CONTROL_REG = 0;   // Control register (RW)
    localparam int AES_STATUS_REG = 4;   // Status register (RO)
    localparam int AES_KEY_LOW_REG = 8;   // Key bits 31:0 (WO)
    localparam int AES_KEY_HIGH_REG = 12;  // Key bits 63:32 (WO)
    localparam int AES_IV_LOW_REG = 16;  // IV bits 31:0 (WO)
    localparam int AES_IV_HIGH_REG = 20;  // IV bits 63:32 (WO)
    localparam int AES_ERROR_REG = 24;  // Error count (RO)
    localparam int AES_BLOCKS_REG = 28;  // Blocks processed low (RO)
    localparam int AES_LATENCY_REG = 32;  // Latency measurement (RO)

    // Internal registers
    logic [31:0] control_reg;
    logic [255:0] key_reg;  // Support up to 256-bit keys
    logic [127:0] iv_reg;

    // AXI-Lite write logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= '0;
            key_reg <= '0;
            iv_reg <= '0;
        end else if (axil_if.awvalid && axil_if.awready && axil_if.wvalid && axil_if.wready) begin
            case (axil_if.awaddr)
                AES_CONTROL_REG: control_reg <= axil_if.wdata;
                AES_KEY_LOW_REG: key_reg[31:0] <= axil_if.wdata;
                AES_KEY_HIGH_REG: key_reg[63:32] <= axil_if.wdata;
                AES_IV_LOW_REG: iv_reg[31:0] <= axil_if.wdata;
                AES_IV_HIGH_REG: iv_reg[63:32] <= axil_if.wdata;
                // Add more key registers for 192/256-bit keys
                default: ; // No operation for undefined registers
            endcase
        end
    end

    // AXI-Lite read logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axil_if.rdata <= '0;
            axil_if.rvalid <= 1'b0;
        end else if (axil_if.arvalid && axil_if.arready) begin
            case (axil_if.araddr)
                AES_CONTROL_REG: axil_if.rdata <= control_reg;
                AES_STATUS_REG:  axil_if.rdata <= aes_status;
                AES_ERROR_REG:   axil_if.rdata <= error_counter;
                AES_BLOCKS_REG:  axil_if.rdata <= blocks_processed[31:0];
                AES_LATENCY_REG: axil_if.rdata <= latency_cycles;
                default:         axil_if.rdata <= 32'hDEAD_BEEF;
            endcase
            axil_if.rvalid <= 1'b1;
        end else if (axil_if.rready) begin
            axil_if.rvalid <= 1'b0;
        end
    end

    // AXI-Lite handshake
    assign axil_if.awready = 1'b1;  // Always ready for writes
    assign axil_if.wready  = 1'b1;  // Always ready for writes
    assign axil_if.arready = !axil_if.rvalid;  // Ready when not responding
    assign axil_if.bvalid  = axil_if.awvalid && axil_if.wvalid;  // Simple response
    assign axil_if.bresp   = 2'b00;  // OKAY response
    assign axil_if.rresp   = 2'b00;  // OKAY response

    // ============================================================================
    // Key and IV Interface Logic
    // ============================================================================

    // Key and IV are loaded via AXI-Lite registers
    // Connect internal registers to AES core
    assign key_valid = 1'b1;  // Key is always valid once loaded
    assign iv_valid = 1'b1;   // IV is always valid once loaded

    // Key/IV ready logic (simplified)
    assign key_ready = 1'b1;  // Always ready for new keys
    assign iv_ready = 1'b1;   // Always ready for new IVs

    // Connect internal registers to AES core inputs
    assign internal_aes_key = key_reg[KEY_SIZE-1:0];
    assign internal_iv = iv_reg;

    // ============================================================================
    // Error Handling and Status
    // ============================================================================

    // Error counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_counter <= '0;
        end else if (clear_errors) begin
            error_counter <= '0;
        end else if (aes_error) begin
            error_counter <= error_counter + 1;
        end
    end

    // Status register
    assign status = {
        aes_ready,              // [31] AES core ready
        aes_error,              // [30] AES error flag
        key_valid && key_ready, // [29] Key loaded
        iv_valid && iv_ready,   // [28] IV loaded
        cipher_mode,            // [27:26] Cipher mode
        key_size_select,        // [25:24] Key size
        operation_mode,         // [23:22] Operation mode
        IP_TYPE == "COMMERCIAL" ? 1'b1 : 1'b0,  // [21] Commercial IP flag
        21'h0                   // [20:0] Reserved
    };

    assign ready = aes_ready;
    assign error_count = error_counter;

    // ============================================================================
    // Performance Monitoring
    // ============================================================================

    // Blocks processed counter (already connected from AES core)
    // Latency measurement (already connected from AES core)

    // ============================================================================
    // Assertions and Debug
    // ============================================================================

    // Basic interface checks
    if (IP_TYPE != "COMMERCIAL") begin : gen_assertions
        // Key size validation
        assert property (@(posedge clk) disable iff (!rst_n)
            key_size_select inside {0,1,2})
            else $error("Invalid key size selection");

        // Cipher mode validation
        assert property (@(posedge clk) disable iff (!rst_n)
            cipher_mode inside {0,1,2,3})
            else $error("Invalid cipher mode selection");

        // Operation mode validation
        assert property (@(posedge clk) disable iff (!rst_n)
            operation_mode inside {0,1,2})
            else $error("Invalid operation mode");
    end

endmodule : aes_ip_core

`endif // AES_IP_CORE_SV
