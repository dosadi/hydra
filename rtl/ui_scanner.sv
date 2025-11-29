`ifndef UI_SCANNER_SV
`define UI_SCANNER_SV

// ============================================================================
// UI Scanner and Looper Module
// Scans through physical UI elements (LEDs, buttons, switches) in a loop
// ============================================================================

module ui_scanner #(
    parameter int LED_COUNT = 4,
    parameter int BTN_COUNT = 4,
    parameter int SW_COUNT = 4,
    parameter int SCAN_PERIOD = 1000000,  // Clock cycles between scans
    parameter int LOOP_MODES = 4          // Number of different loop modes
)(
    input  logic clk,
    input  logic rst_n,

    // Physical UI inputs
    input  logic [BTN_COUNT-1:0] btn,      // Push buttons
    input  logic [SW_COUNT-1:0]  sw,       // DIP switches

    // Physical UI outputs
    output logic [LED_COUNT-1:0] led,      // LEDs

    // Control interface
    input  logic enable,                   // Enable scanning
    input  logic [1:0] mode_select,        // Loop mode selection
    input  logic manual_scan,              // Manual scan trigger
    output logic scan_complete,            // Scan cycle complete
    output logic [7:0] scan_status         // Current scan status
);

    // ============================================================================
    // Local Parameters and Types
    // ============================================================================

    typedef enum logic [1:0] {
        MODE_SEQUENTIAL = 2'b00,    // Sequential LED scanning
        MODE_BINARY     = 2'b01,    // Binary counter on LEDs
        MODE_BUTTON_ECHO = 2'b10,   // Echo button states to LEDs
        MODE_SWITCH_LOOP = 2'b11    // Loop through switch patterns
    } loop_mode_t;

    typedef enum logic [2:0] {
        SCAN_IDLE       = 3'b000,
        SCAN_LEDS       = 3'b001,
        SCAN_BUTTONS    = 3'b010,
        SCAN_SWITCHES   = 3'b011,
        SCAN_WAIT       = 3'b100,
        SCAN_COMPLETE   = 3'b101
    } scan_state_t;

    // ============================================================================
    // Internal Signals
    // ============================================================================

    loop_mode_t current_mode;
    scan_state_t scan_state;
    logic [31:0] scan_counter;
    logic [LED_COUNT-1:0] led_pattern;
    logic [7:0] scan_cycle_count;
    logic scan_trigger;

    // Button debouncing
    logic [BTN_COUNT-1:0] btn_debounced;
    logic [BTN_COUNT-1:0] btn_prev;
    logic [15:0] debounce_counter [BTN_COUNT];

    // Switch filtering
    logic [SW_COUNT-1:0] sw_filtered;
    logic [SW_COUNT-1:0] sw_prev;
    logic [15:0] filter_counter [SW_COUNT];

    // ============================================================================
    // Mode Selection Logic
    // ============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_mode <= MODE_SEQUENTIAL;
        end else begin
            current_mode <= loop_mode_t'(mode_select);
        end
    end

    // ============================================================================
    // Scan Trigger Logic
    // ============================================================================

    assign scan_trigger = enable && (manual_scan || (scan_counter == 0));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_counter <= SCAN_PERIOD - 1;
        end else if (scan_trigger) begin
            scan_counter <= SCAN_PERIOD - 1;
        end else if (scan_counter > 0) begin
            scan_counter <= scan_counter - 1;
        end
    end

    // ============================================================================
    // Button Debouncing
    // ============================================================================

    genvar i;
    generate
        for (i = 0; i < BTN_COUNT; i++) begin : g_debounce
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    btn_debounced[i] <= 1'b0;
                    btn_prev[i] <= 1'b0;
                    debounce_counter[i] <= 16'h0000;
                end else begin
                    btn_prev[i] <= btn[i];

                    if (btn[i] != btn_prev[i]) begin
                        debounce_counter[i] <= 16'hFFFF; // Reset counter on change
                    end else if (debounce_counter[i] > 0) begin
                        debounce_counter[i] <= debounce_counter[i] - 1;
                        if (debounce_counter[i] == 1) begin
                            btn_debounced[i] <= btn[i]; // Stable value
                        end
                    end
                end
            end
        end
    endgenerate

    // ============================================================================
    // Switch Filtering
    // ============================================================================

    generate
        for (i = 0; i < SW_COUNT; i++) begin : g_filter
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    sw_filtered[i] <= 1'b0;
                    sw_prev[i] <= 1'b0;
                    filter_counter[i] <= 16'h0000;
                end else begin
                    sw_prev[i] <= sw[i];

                    if (sw[i] != sw_prev[i]) begin
                        filter_counter[i] <= 16'h00FF; // Shorter filter for switches
                    end else if (filter_counter[i] > 0) begin
                        filter_counter[i] <= filter_counter[i] - 1;
                        if (filter_counter[i] == 1) begin
                            sw_filtered[i] <= sw[i]; // Filtered value
                        end
                    end
                end
            end
        end
    endgenerate

    // ============================================================================
    // UI Scanning State Machine
    // ============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_state <= SCAN_IDLE;
            scan_cycle_count <= 8'h00;
            scan_complete <= 1'b0;
        end else begin
            scan_complete <= 1'b0;

            case (scan_state)
                SCAN_IDLE: begin
                    if (scan_trigger) begin
                        scan_state <= SCAN_LEDS;
                        scan_cycle_count <= scan_cycle_count + 1;
                    end
                end

                SCAN_LEDS: begin
                    // LED scanning complete, move to buttons
                    scan_state <= SCAN_BUTTONS;
                end

                SCAN_BUTTONS: begin
                    // Button scanning complete, move to switches
                    scan_state <= SCAN_SWITCHES;
                end

                SCAN_SWITCHES: begin
                    // Switch scanning complete, wait for next cycle
                    scan_state <= SCAN_WAIT;
                end

                SCAN_WAIT: begin
                    // Wait for scan period to complete
                    if (scan_counter == SCAN_PERIOD/2) begin
                        scan_state <= SCAN_COMPLETE;
                    end
                end

                SCAN_COMPLETE: begin
                    scan_complete <= 1'b1;
                    scan_state <= SCAN_IDLE;
                end

                default: begin
                    scan_state <= SCAN_IDLE;
                end
            endcase
        end
    end

    // ============================================================================
    // LED Pattern Generation Based on Mode
    // ============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_pattern <= {LED_COUNT{1'b0}};
        end else if (enable) begin
            case (current_mode)
                MODE_SEQUENTIAL: begin
                    // Sequential LED scanning: 0001 -> 0010 -> 0100 -> 1000 -> 0001...
                    case (scan_cycle_count[1:0])
                        2'b00: led_pattern <= 4'b0001;
                        2'b01: led_pattern <= 4'b0010;
                        2'b10: led_pattern <= 4'b0100;
                        2'b11: led_pattern <= 4'b1000;
                        default: led_pattern <= 4'b0001;
                    endcase
                end

                MODE_BINARY: begin
                    // Binary counter on LEDs
                    led_pattern <= scan_cycle_count[LED_COUNT-1:0];
                end

                MODE_BUTTON_ECHO: begin
                    // Echo debounced button states to LEDs
                    led_pattern <= btn_debounced[LED_COUNT-1:0];
                end

                MODE_SWITCH_LOOP: begin
                    // Loop through filtered switch patterns
                    led_pattern <= sw_filtered[LED_COUNT-1:0];
                end

                default: begin
                    led_pattern <= {LED_COUNT{1'b0}};
                end
            endcase
        end else begin
            led_pattern <= {LED_COUNT{1'b0}};
        end
    end

    // ============================================================================
    // Output Assignments
    // ============================================================================

    assign led = enable ? led_pattern : {LED_COUNT{1'b0}};

    // Status output: [7:6]=mode, [5:3]=scan_state, [2:0]=cycle_count[2:0]
    assign scan_status = {
        current_mode,
        scan_state,
        scan_cycle_count[2:0]
    };

endmodule : ui_scanner

`endif // UI_SCANNER_SV
