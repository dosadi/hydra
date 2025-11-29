`ifndef UI_SCANNER_TB_SV
`define UI_SCANNER_TB_SV

// ============================================================================
// UI Scanner Testbench
// Tests the UI scanning and looping functionality
// ============================================================================

module ui_scanner_tb;

    // ============================================================================
    // Testbench Parameters
    // ============================================================================

    localparam int LED_COUNT = 4;
    localparam int BTN_COUNT = 4;
    localparam int SW_COUNT = 4;
    localparam int SCAN_PERIOD = 1000;  // Faster for simulation
    localparam int CLK_PERIOD = 10;     // 10ns clock

    // ============================================================================
    // DUT Signals
    // ============================================================================

    logic clk;
    logic rst_n;

    // Physical UI inputs
    logic [BTN_COUNT-1:0] btn;
    logic [SW_COUNT-1:0]  sw;

    // Physical UI outputs
    logic [LED_COUNT-1:0] led;

    // Control interface
    logic enable;
    logic [1:0] mode_select;
    logic manual_scan;
    logic scan_complete;
    logic [7:0] scan_status;

    // ============================================================================
    // DUT Instantiation
    // ============================================================================

    ui_scanner #(
        .LED_COUNT(LED_COUNT),
        .BTN_COUNT(BTN_COUNT),
        .SW_COUNT(SW_COUNT),
        .SCAN_PERIOD(SCAN_PERIOD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn(btn),
        .sw(sw),
        .led(led),
        .enable(enable),
        .mode_select(mode_select),
        .manual_scan(manual_scan),
        .scan_complete(scan_complete),
        .scan_status(scan_status)
    );

    // ============================================================================
    // Clock Generation
    // ============================================================================

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ============================================================================
    // Test Stimulus
    // ============================================================================

    initial begin
        // Initialize signals
        rst_n = 1'b0;
        btn = '0;
        sw = '0;
        enable = 1'b0;
        mode_select = 2'b00;
        manual_scan = 1'b0;

        // Reset
        #(CLK_PERIOD * 5);
        rst_n = 1'b1;
        #(CLK_PERIOD * 5);

        $display("Starting UI Scanner Testbench");
        $display("==============================");

        // Test 1: Sequential Mode
        $display("\nTest 1: Sequential LED Scanning Mode");
        enable = 1'b1;
        mode_select = 2'b00;  // MODE_SEQUENTIAL

        // Wait for several scan cycles
        repeat (10) begin
            wait(scan_complete);
            $display("Scan complete - LEDs: %4b, Status: %8b", led, scan_status);
            #(CLK_PERIOD);
        end

        // Test 2: Binary Counter Mode
        $display("\nTest 2: Binary Counter Mode");
        mode_select = 2'b01;  // MODE_BINARY

        repeat (20) begin
            wait(scan_complete);
            $display("Scan complete - LEDs: %4b, Status: %8b", led, scan_status);
            #(CLK_PERIOD);
        end

        // Test 3: Button Echo Mode
        $display("\nTest 3: Button Echo Mode");
        mode_select = 2'b10;  // MODE_BUTTON_ECHO

        // Simulate button presses
        btn = 4'b0001; #(CLK_PERIOD * 100);
        btn = 4'b0010; #(CLK_PERIOD * 100);
        btn = 4'b0100; #(CLK_PERIOD * 100);
        btn = 4'b1000; #(CLK_PERIOD * 100);
        btn = 4'b1111; #(CLK_PERIOD * 100);
        btn = 4'b0000; #(CLK_PERIOD * 100);

        // Test 4: Switch Loop Mode
        $display("\nTest 4: Switch Loop Mode");
        mode_select = 2'b11;  // MODE_SWITCH_LOOP

        // Simulate switch changes
        sw = 4'b0001; #(CLK_PERIOD * 100);
        sw = 4'b0011; #(CLK_PERIOD * 100);
        sw = 4'b0111; #(CLK_PERIOD * 100);
        sw = 4'b1111; #(CLK_PERIOD * 100);
        sw = 4'b0000; #(CLK_PERIOD * 100);

        // Test 5: Manual Scan Trigger
        $display("\nTest 5: Manual Scan Trigger");
        enable = 1'b0;  // Disable automatic scanning
        #(CLK_PERIOD * 10);

        manual_scan = 1'b1; #(CLK_PERIOD);
        manual_scan = 1'b0;
        wait(scan_complete);
        $display("Manual scan complete - LEDs: %4b", led);

        manual_scan = 1'b1; #(CLK_PERIOD);
        manual_scan = 1'b0;
        wait(scan_complete);
        $display("Manual scan complete - LEDs: %4b", led);

        // Test 6: Disable/Enable
        $display("\nTest 6: Disable/Enable Functionality");
        enable = 1'b0;
        #(CLK_PERIOD * 100);
        $display("Disabled - LEDs: %4b (should be 0000)", led);

        enable = 1'b1;
        mode_select = 2'b00;  // Back to sequential
        repeat (5) begin
            wait(scan_complete);
            $display("Enabled - LEDs: %4b", led);
        end

        $display("\n==============================");
        $display("UI Scanner Testbench Complete");
        $finish;
    end

    // ============================================================================
    // Monitoring
    // ============================================================================

    always @(posedge scan_complete) begin
        $display("Time %0t: Scan cycle completed - Mode: %0d, State: %0d, LEDs: %4b",
                 $time, mode_select, scan_status[5:3], led);
    end

    // ============================================================================
    // Timeout Protection
    // ============================================================================

    initial begin
        #(CLK_PERIOD * 100000);  // 1ms timeout
        $display("Testbench timeout - ending simulation");
        $finish;
    end

endmodule : ui_scanner_tb

`endif // UI_SCANNER_TB_SV