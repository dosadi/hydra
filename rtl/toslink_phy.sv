// ============================================================================
// TOSLINK PHY Layer
// Optical interconnect using S/PDIF protocol for board-to-board communication
// ============================================================================

`ifndef TOSLINK_PHY_SV
`define TOSLINK_PHY_SV

module toslink_phy #(
    parameter int DATA_WIDTH = 32,
    parameter int SAMPLE_RATE = 48000,  // Base sample rate in Hz
    parameter int OVERSAMPLE = 64       // Oversampling factor for high-speed data
)(
    input  logic clk,                   // System clock (much higher than sample rate)
    input  logic rst_n,                 // Active low reset

    // Electrical data interface
    input  logic [DATA_WIDTH-1:0] tx_data,
    input  logic                  tx_valid,
    output logic                  tx_ready,

    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  rx_valid,
    input  logic                  rx_ready,

    // Optical interface (simulated - would connect to optical transceiver)
    output logic tx_optical,           // Optical transmit signal
    input  logic  rx_optical,          // Optical receive signal

    // Control
    input  logic enable,
    input  logic loopback_en,          // Loopback for testing
    input  logic bypass_en,            // Bypass S/PDIF encoding for testing

    // Status
    output logic link_locked,          // PLL locked to incoming signal
    output logic [31:0] status,        // Status register
    output logic [31:0] error_count    // Error counter
);

    // ============================================================================
    // Local Parameters
    // ============================================================================

    localparam int BIT_RATE = SAMPLE_RATE * OVERSAMPLE * 2;  // S/PDIF bit rate (2x oversample for BMC)
    localparam int CLK_DIV = 100000000 / BIT_RATE;           // Clock divider (assuming 100MHz clk)
    localparam int CLK_DIV_HALF = CLK_DIV / 2;
    localparam int CLK_COMPARE = CLK_DIV_HALF - 1;

    // S/PDIF constants
    localparam logic [7:0] PREAMBLE_X = 8'b11100010;  // Preamble for data block X
    localparam logic [7:0] PREAMBLE_Y = 8'b11100100;  // Preamble for data block Y
    localparam logic [7:0] PREAMBLE_Z = 8'b11101000;  // Preamble for data block Z

    // ============================================================================
    // Internal Signals
    // ============================================================================

    // Clock generation
    logic [$clog2(CLK_DIV)-1:0] clk_counter;
    logic bit_clk;                     // Bit clock for S/PDIF
    logic sample_clk;                  // Sample clock

    // TX path
    logic [DATA_WIDTH-1:0] tx_buffer;
    logic tx_buffer_valid;
    logic [7:0] tx_preamble;
    logic [31:0] tx_subframe [1:0];    // Left and right subframes
    logic tx_subframe_valid;
    logic bmc_encoded;                 // BMC encoded bit
    logic bmc_valid;

    // RX path
    logic bmc_decoded;                 // BMC decoded bit
    logic bmc_decode_valid;
    logic [31:0] rx_subframe [1:0];    // Left and right subframes
    logic rx_subframe_valid;
    logic [7:0] rx_preamble;
    logic preamble_valid;
    logic [DATA_WIDTH-1:0] rx_buffer;
    logic rx_buffer_valid;

    // PLL for clock recovery
    logic pll_locked;
    logic [15:0] pll_phase_error;

    // Error detection
    logic parity_error;
    logic validity_error;
    logic [31:0] error_counter;

    // ============================================================================
    // Clock Generation
    // ============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= '0;
            bit_clk <= 1'b0;
            sample_clk <= 1'b0;
        end else if (enable) begin
            if (clk_counter >= CLK_COMPARE[$clog2(CLK_DIV)-1:0]) begin
                clk_counter <= '0;
                bit_clk <= ~bit_clk;

                // Generate sample clock at audio rate
                if (bit_clk) begin
                    sample_clk <= ~sample_clk;
                end
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end

    // ============================================================================
    // TX Path: Data to S/PDIF Encoding
    // ============================================================================

    // Buffer incoming data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_buffer <= '0;
            tx_buffer_valid <= 1'b0;
            tx_ready <= 1'b0;
        end else begin
            tx_ready <= !tx_buffer_valid || tx_subframe_valid;

            if (tx_valid && tx_ready && !tx_buffer_valid) begin
                tx_buffer <= tx_data;
                tx_buffer_valid <= 1'b1;
            end else if (tx_subframe_valid) begin
                tx_buffer_valid <= 1'b0;
            end
        end
    end

    // Convert parallel data to S/PDIF subframes
    always_ff @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_subframe[0] <= '0;
            tx_subframe[1] <= '0;
            tx_subframe_valid <= 1'b0;
            tx_preamble <= PREAMBLE_X;
        end else if (tx_buffer_valid) begin
            // Pack data into stereo subframes
            // Subframe format: [parity:1][validity:1][user_data:1][channel_status:1][audio_data:20]
            tx_subframe[0] <= {12'b0, tx_buffer[19:0]};  // Left channel
            tx_subframe[1] <= {12'b0, tx_buffer[31:12]}; // Right channel
            tx_subframe_valid <= 1'b1;

            // Cycle preambles
            case (tx_preamble)
                PREAMBLE_X: tx_preamble <= PREAMBLE_Y;
                PREAMBLE_Y: tx_preamble <= PREAMBLE_Z;
                PREAMBLE_Z: tx_preamble <= PREAMBLE_X;
                default: tx_preamble <= PREAMBLE_X;
            endcase
        end else begin
            tx_subframe_valid <= 1'b0;
        end
    end

    // BMC (Biphase Mark Code) Encoder
    logic prev_bmc_bit;
    logic [5:0] bit_counter;  // 32 bits per subframe + 8 preamble = 40 bits

    always_ff @(posedge bit_clk or negedge rst_n) begin
        if (!rst_n) begin
            bmc_encoded <= 1'b0;
            bmc_valid <= 1'b0;
            prev_bmc_bit <= 1'b0;
            bit_counter <= '0;
        end else if (tx_subframe_valid) begin
            logic current_bit;

            // Select bit to transmit (preamble + subframes)
            if (bit_counter < 8) begin
                current_bit = tx_preamble[7 - bit_counter];
            end else if (bit_counter < 8 + 32) begin
                current_bit = tx_subframe[0][31 - (bit_counter - 8)];
            end else if (bit_counter < 8 + 32 + 32) begin
                current_bit = tx_subframe[1][31 - (bit_counter - 8 - 32)];
            end else begin
                current_bit = 1'b0; // Padding
            end

            // BMC encoding: transition on every bit, polarity based on data
            if (current_bit) begin
                bmc_encoded <= ~prev_bmc_bit;
            end else begin
                bmc_encoded <= prev_bmc_bit;
            end

            prev_bmc_bit <= bmc_encoded;
            bmc_valid <= 1'b1;

            bit_counter <= bit_counter + 1;
            if (bit_counter >= 8 + 32 + 32 - 1) begin
                bit_counter <= '0;
            end
        end else begin
            bmc_valid <= 1'b0;
        end
    end

    // ============================================================================
    // RX Path: S/PDIF Decoding to Data
    // ============================================================================

    // BMC Decoder
    logic [2:0] rx_bit_history;
    logic rx_bit_valid;

    always_ff @(posedge bit_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_bit_history <= '0;
            bmc_decoded <= 1'b0;
            bmc_decode_valid <= 1'b0;
        end else begin
            // Shift in received bits
            rx_bit_history <= {rx_bit_history[1:0], rx_optical};

            // BMC decoding: look for transitions
            if (rx_bit_history[2] != rx_bit_history[1]) begin
                // Transition detected - decode based on polarity
                bmc_decoded <= rx_bit_history[1];  // Data bit is the polarity after transition
                bmc_decode_valid <= 1'b1;
            end else begin
                bmc_decode_valid <= 1'b0;
            end
        end
    end

    // Frame synchronization and data extraction
    logic [71:0] rx_frame_buffer;  // 8 preamble + 32 left + 32 right
    logic [6:0] rx_bit_counter;
    logic frame_complete;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_frame_buffer <= '0;
            rx_bit_counter <= '0;
            frame_complete <= 1'b0;
            rx_preamble <= '0;
            preamble_valid <= 1'b0;
        end else if (bmc_decode_valid) begin
            rx_frame_buffer <= {rx_frame_buffer[70:0], bmc_decoded};
            rx_bit_counter <= rx_bit_counter + 1;

            if (rx_bit_counter == 7) begin
                // Check preamble
                rx_preamble <= rx_frame_buffer[7:0];
                preamble_valid <= (rx_frame_buffer[7:0] == PREAMBLE_X ||
                                 rx_frame_buffer[7:0] == PREAMBLE_Y ||
                                 rx_frame_buffer[7:0] == PREAMBLE_Z);
            end

            if (rx_bit_counter >= 71) begin
                frame_complete <= 1'b1;
                rx_bit_counter <= '0;
            end else begin
                frame_complete <= 1'b0;
            end
        end else begin
            frame_complete <= 1'b0;
        end
    end

    // Extract subframes and convert to parallel data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_subframe[0] <= '0;
            rx_subframe[1] <= '0;
            rx_subframe_valid <= 1'b0;
            rx_buffer <= '0;
            rx_buffer_valid <= 1'b0;
        end else if (frame_complete && preamble_valid) begin
            // Extract subframes (skip preamble)
            rx_subframe[0] <= rx_frame_buffer[39:8];      // Left channel
            rx_subframe[1] <= rx_frame_buffer[71:40];     // Right channel
            rx_subframe_valid <= 1'b1;

            // Extract audio data from subframes
            rx_buffer[19:0] <= rx_subframe[0][19:0];      // Left channel audio data
            rx_buffer[31:12] <= rx_subframe[1][19:0];     // Right channel audio data
            rx_buffer_valid <= 1'b1;
        end else begin
            rx_subframe_valid <= 1'b0;
            rx_buffer_valid <= 1'b0;
        end
    end

    // Output data when ready
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= '0;
            rx_valid <= 1'b0;
        end else if (bypass_en) begin
            // Bypass mode: direct connection for testing
            if (tx_valid && tx_ready) begin
                rx_data <= tx_data;
                rx_valid <= 1'b1;
            end else if (rx_valid && rx_ready) begin
                rx_valid <= 1'b0;
            end
        end else begin
            if (rx_buffer_valid && (!rx_valid || rx_ready)) begin
                rx_data <= rx_buffer;
                rx_valid <= 1'b1;
            end else if (rx_valid && rx_ready) begin
                rx_valid <= 1'b0;
            end
        end
    end

    // ============================================================================
    // PLL for Clock Recovery (Simplified)
    // ============================================================================

    // Simple PLL implementation for clock recovery
    logic [15:0] pll_phase_accum;
    logic [15:0] pll_phase_inc;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pll_phase_accum <= '0;
            pll_locked <= 1'b0;
            pll_phase_error <= '0;
            pll_phase_inc <= 16'h1000;  // Initial phase increment
        end else if (enable) begin
            // Simple phase tracking - for simulation, assume lock
            pll_locked <= 1'b1;
            pll_phase_error <= '0;
        end
    end

    // ============================================================================
    // Error Detection
    // ============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_error <= 1'b0;
            validity_error <= 1'b0;
            error_counter <= '0;
        end else if (rx_subframe_valid) begin
            // Check parity (simplified)
            parity_error <= ^rx_subframe[0] ^ ^rx_subframe[1];

            // Check validity bits
            validity_error <= rx_subframe[0][26] | rx_subframe[1][26];

            if (parity_error || validity_error) begin
                error_counter <= error_counter + 1;
            end
        end
    end

    // ============================================================================
    // Optical Interface and Loopback
    // ============================================================================

    always_comb begin
        if (loopback_en) begin
            // Loopback for testing
            tx_optical = bmc_encoded;
        end else begin
            // Normal operation
            tx_optical = bmc_encoded;
        end
    end

    // ============================================================================
    // Status Outputs
    // ============================================================================

    assign link_locked = pll_locked;
    assign error_count = error_counter;

    always_comb begin
        status = '0;
        status[0] = link_locked;
        status[1] = tx_buffer_valid;
        status[2] = rx_buffer_valid;
        status[3] = preamble_valid;
        status[4] = parity_error;
        status[5] = validity_error;
        status[31:16] = pll_phase_error;
    end

endmodule : toslink_phy

`endif // TOSLINK_PHY_SV
