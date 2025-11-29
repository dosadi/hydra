`ifndef UI_SCANNER_TEST_SV
`define UI_SCANNER_TEST_SV

// ============================================================================
// UI Scanner UVM Test
// Comprehensive verification of UI scanning and looping functionality
// ============================================================================

class ui_scanner_test extends uvm_test;

    `uvm_component_utils(ui_scanner_test)

    // ============================================================================
    // Test Components
    // ============================================================================

    ui_scanner_env env;
    ui_scanner_sequence seq;

    // ============================================================================
    // Constructor
    // ============================================================================

    function new(string name = "ui_scanner_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // ============================================================================
    // Build Phase
    // ============================================================================

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create environment
        env = ui_scanner_env::type_id::create("env", this);

        // Create sequence
        seq = ui_scanner_sequence::type_id::create("seq");

        // Configure environment
        uvm_config_db#(int)::set(this, "env", "num_sequences", 10);
    endfunction : build_phase

    // ============================================================================
    // Run Phase
    // ============================================================================

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting UI Scanner Test", UVM_MEDIUM)

        // Run the test sequence
        seq.start(env.agent.sequencer);

        // Wait for completion
        phase.drop_objection(this);

        `uvm_info(get_type_name(), "UI Scanner Test Completed", UVM_MEDIUM)
    endtask : run_phase

endclass : ui_scanner_test

// ============================================================================
// UI Scanner Environment
// ============================================================================

class ui_scanner_env extends uvm_env;

    `uvm_component_utils(ui_scanner_env)

    ui_scanner_agent agent;
    ui_scanner_scoreboard scoreboard;
    ui_scanner_coverage coverage;

    int num_sequences;

    function new(string name = "ui_scanner_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get configuration
        if (!uvm_config_db#(int)::get(this, "", "num_sequences", num_sequences)) begin
            num_sequences = 5;
        end

        // Create components
        agent = ui_scanner_agent::type_id::create("agent", this);
        scoreboard = ui_scanner_scoreboard::type_id::create("scoreboard", this);
        coverage = ui_scanner_coverage::type_id::create("coverage", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect analysis ports
        agent.monitor.analysis_port.connect(scoreboard.analysis_export);
        agent.monitor.analysis_port.connect(coverage.analysis_export);
    endfunction : connect_phase

endclass : ui_scanner_env

// ============================================================================
// UI Scanner Agent
// ============================================================================

class ui_scanner_agent extends uvm_agent;

    `uvm_component_utils(ui_scanner_agent)

    ui_scanner_sequencer sequencer;
    ui_scanner_driver driver;
    ui_scanner_monitor monitor;

    function new(string name = "ui_scanner_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = ui_scanner_sequencer::type_id::create("sequencer", this);
        driver = ui_scanner_driver::type_id::create("driver", this);
        monitor = ui_scanner_monitor::type_id::create("monitor", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction : connect_phase

endclass : ui_scanner_agent

// ============================================================================
// UI Scanner Transaction
// ============================================================================

class ui_scanner_transaction extends uvm_sequence_item;

    `uvm_object_utils(ui_scanner_transaction)

    // Transaction fields
    rand logic enable;
    rand logic [1:0] mode_select;
    rand logic manual_scan;
    rand logic [3:0] btn_input;
    rand logic [3:0] sw_input;

    // Response fields
    logic [3:0] led_output;
    logic scan_complete;
    logic [7:0] scan_status;

    constraint valid_inputs {
        enable dist {1'b1 := 80, 1'b0 := 20};
        mode_select inside {[0:3]};
        btn_input dist {[0:15] :/ 1};  // Uniform distribution
        sw_input dist {[0:15] :/ 1};
    }

    function new(string name = "ui_scanner_transaction");
        super.new(name);
    endfunction : new

endclass : ui_scanner_transaction

// ============================================================================
// UI Scanner Sequence
// ============================================================================

class ui_scanner_sequence extends uvm_sequence#(ui_scanner_transaction);

    `uvm_object_utils(ui_scanner_sequence)

    function new(string name = "ui_scanner_sequence");
        super.new(name);
    endfunction : new

    virtual task body();
        ui_scanner_transaction trans;

        // Test different modes
        repeat (10) begin
            trans = ui_scanner_transaction::type_id::create("trans");

            // Randomize transaction
            if (!trans.randomize()) begin
                `uvm_error("SEQUENCE", "Failed to randomize transaction")
            end

            start_item(trans);
            finish_item(trans);
        end
    endtask : body

endclass : ui_scanner_sequence

// ============================================================================
// UI Scanner Sequencer
// ============================================================================

class ui_scanner_sequencer extends uvm_sequencer#(ui_scanner_transaction);

    `uvm_component_utils(ui_scanner_sequencer)

    function new(string name = "ui_scanner_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

endclass : ui_scanner_sequencer

// ============================================================================
// UI Scanner Driver
// ============================================================================

class ui_scanner_driver extends uvm_driver#(ui_scanner_transaction);

    `uvm_component_utils(ui_scanner_driver)

    virtual ui_scanner_if vif;

    function new(string name = "ui_scanner_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual ui_scanner_if)::get(this, "", "vif", vif)) begin
            `uvm_error("DRIVER", "Failed to get virtual interface")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        ui_scanner_transaction trans;

        forever begin
            seq_item_port.get_next_item(trans);

            // Drive the DUT
            vif.enable = trans.enable;
            vif.mode_select = trans.mode_select;
            vif.manual_scan = trans.manual_scan;
            vif.btn = trans.btn_input;
            vif.sw = trans.sw_input;

            // Wait for response
            @(posedge vif.clk);
            trans.led_output = vif.led;
            trans.scan_complete = vif.scan_complete;
            trans.scan_status = vif.scan_status;

            seq_item_port.item_done();
        end
    endtask : run_phase

endclass : ui_scanner_driver

// ============================================================================
// UI Scanner Monitor
// ============================================================================

class ui_scanner_monitor extends uvm_monitor;

    `uvm_component_utils(ui_scanner_monitor)

    virtual ui_scanner_if vif;
    uvm_analysis_port#(ui_scanner_transaction) analysis_port;

    function new(string name = "ui_scanner_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual ui_scanner_if)::get(this, "", "vif", vif)) begin
            `uvm_error("MONITOR", "Failed to get virtual interface")
        end
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        ui_scanner_transaction trans;

        forever begin
            @(posedge vif.clk);

            // Monitor DUT outputs
            if (vif.scan_complete) begin
                trans = ui_scanner_transaction::type_id::create("trans");
                trans.enable = vif.enable;
                trans.mode_select = vif.mode_select;
                trans.manual_scan = vif.manual_scan;
                trans.btn_input = vif.btn;
                trans.sw_input = vif.sw;
                trans.led_output = vif.led;
                trans.scan_complete = vif.scan_complete;
                trans.scan_status = vif.scan_status;

                analysis_port.write(trans);
            end
        end
    endtask : run_phase

endclass : ui_scanner_monitor

// ============================================================================
// UI Scanner Scoreboard
// ============================================================================

class ui_scanner_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(ui_scanner_scoreboard)

    uvm_analysis_imp#(ui_scanner_transaction, ui_scanner_scoreboard) analysis_export;

    // Expected behavior model
    logic [3:0] expected_led;
    logic [7:0] expected_status;
    int scan_count;

    function new(string name = "ui_scanner_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        scan_count = 0;
    endfunction : new

    virtual function void write(ui_scanner_transaction trans);
        scan_count++;

        // Model expected behavior based on mode
        case (trans.mode_select)
            2'b00: begin  // MODE_SEQUENTIAL
                case (scan_count % 4)
                    1: expected_led = 4'b0001;
                    2: expected_led = 4'b0010;
                    3: expected_led = 4'b0100;
                    0: expected_led = 4'b1000;
                endcase
            end

            2'b01: begin  // MODE_BINARY
                expected_led = scan_count[3:0];
            end

            2'b10: begin  // MODE_BUTTON_ECHO
                expected_led = trans.btn_input;
            end

            2'b11: begin  // MODE_SWITCH_LOOP
                expected_led = trans.sw_input;
            end
        endcase

        // Check LED output
        if (trans.enable && trans.led_output !== expected_led) begin
            `uvm_error("SCOREBOARD", $sformatf("LED mismatch - Expected: %4b, Got: %4b",
                      expected_led, trans.led_output))
        end else if (!trans.enable && trans.led_output !== 4'b0000) begin
            `uvm_error("SCOREBOARD", $sformatf("LED should be off when disabled - Got: %4b",
                      trans.led_output))
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("LED check passed - Expected: %4b, Got: %4b",
                     expected_led, trans.led_output), UVM_HIGH)
        end

        // Check scan complete
        if (!trans.scan_complete) begin
            `uvm_error("SCOREBOARD", "Scan complete should be asserted")
        end
    endfunction : write

endclass : ui_scanner_scoreboard

// ============================================================================
// UI Scanner Coverage
// ============================================================================

class ui_scanner_coverage extends uvm_subscriber#(ui_scanner_transaction);

    `uvm_component_utils(ui_scanner_coverage)

    // Coverage groups
    covergroup ui_scanner_cg;
        mode_cp: coverpoint trans.mode_select {
            bins sequential = {0};
            bins binary = {1};
            bins button_echo = {2};
            bins switch_loop = {3};
        }

        enable_cp: coverpoint trans.enable {
            bins disabled = {0};
            bins enabled = {1};
        }

        btn_cp: coverpoint trans.btn_input {
            bins zero = {0};
            bins single = {[1:15]};
        }

        sw_cp: coverpoint trans.sw_input {
            bins zero = {0};
            bins non_zero = {[1:15]};
        }

        led_cp: coverpoint trans.led_output {
            bins zero = {0};
            bins patterns = {[1:15]};
        }

        mode_enable_cross: cross mode_cp, enable_cp;
        btn_led_cross: cross btn_cp, led_cp;
    endgroup : ui_scanner_cg

    function new(string name = "ui_scanner_coverage", uvm_component parent = null);
        super.new(name, parent);
        ui_scanner_cg = new();
    endfunction : new

    virtual function void write(ui_scanner_transaction trans);
        ui_scanner_cg.sample();
    endfunction : write

endclass : ui_scanner_coverage

`endif // UI_SCANNER_TEST_SV