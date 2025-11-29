`ifndef HYDRA_FRAME_SEQUENCE_SV
`define HYDRA_FRAME_SEQUENCE_SV

class hydra_frame_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_frame_sequence)

  function new(string name = "hydra_frame_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("FRAME_SEQ", "Starting Hydra Frame rendering test sequence", UVM_LOW)

    // Test frame rendering operations
    test_frame_rendering();

    `uvm_info("FRAME_SEQ", "Hydra Frame sequence complete", UVM_LOW)
  endtask

  task test_frame_rendering();
    bit [31:0] read_data;

    // Configure frame buffer address
    `uvm_info("FRAME_SEQ", "Configuring frame buffer address", UVM_MEDIUM)
    axil_write(`FRAMEBUFFER_OFFSET, 32'h40000000);  // Frame buffer base
    axil_read(`FRAMEBUFFER_OFFSET, read_data);
    assert(read_data == 32'h40000000) else `uvm_error("FRAME_SEQ", "Frame buffer address mismatch")

    // Configure display resolution
    `uvm_info("FRAME_SEQ", "Configuring display resolution", UVM_MEDIUM)
    axil_write(`DISPLAY_RES_OFFSET, 32'h04380780);  // 1920x1080
    axil_read(`DISPLAY_RES_OFFSET, read_data);
    assert(read_data == 32'h04380780) else `uvm_error("FRAME_SEQ", "Display resolution mismatch")

    // Enable frame rendering
    `uvm_info("FRAME_SEQ", "Enabling frame rendering", UVM_MEDIUM)
    axil_write(`CTRL_OFFSET, 32'h00000001);  // Enable bit

    // Wait for frame completion
    poll_frame_completion();

    // Verify frame completion
    axil_read(`CTRL_OFFSET, read_data);
    assert((read_data & 32'h00000001) == 0) else
      `uvm_error("FRAME_SEQ", "Frame rendering did not complete")

    `uvm_info("FRAME_SEQ", "Frame rendering completed successfully", UVM_MEDIUM)

    wait_cycles(10);
  endtask

  task poll_frame_completion();
    bit [31:0] status;
    int timeout = 100000;  // Maximum polling cycles (very long for frame rendering)

    `uvm_info("FRAME_SEQ", "Polling for frame rendering completion", UVM_MEDIUM)

    do begin
      axil_read(`CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("FRAME_SEQ", "Frame rendering timeout")
    end else begin
      `uvm_info("FRAME_SEQ", "Frame rendering completed", UVM_MEDIUM)
    end
  endtask

endclass : hydra_frame_sequence

`endif
