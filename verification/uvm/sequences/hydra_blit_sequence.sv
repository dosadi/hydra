`ifndef HYDRA_BLIT_SEQUENCE_SV
`define HYDRA_BLIT_SEQUENCE_SV

class hydra_blit_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_blit_sequence)

  function new(string name = "hydra_blit_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("BLIT_SEQ", "Starting Hydra Blitter test sequence", UVM_LOW)

    // Test blitter operations
    test_blit_operations();

    `uvm_info("BLIT_SEQ", "Hydra Blitter sequence complete", UVM_LOW)
  endtask

  task test_blit_operations();
    bit [31:0] read_data;

    // Configure blitter source region
    `uvm_info("BLIT_SEQ", "Configuring blitter source region", UVM_MEDIUM)
    axil_write(`REGION0_CFG_OFFSET, 32'h00000000);  // Source region config
    axil_read(`REGION0_CFG_OFFSET, read_data);
    assert(read_data == 32'h00000000) else `uvm_error("BLIT_SEQ", "Region config mismatch")

    // Configure blitter destination
    `uvm_info("BLIT_SEQ", "Configuring blitter destination", UVM_MEDIUM)
    axil_write(`BLIT_DST_OFFSET, 32'h30000000);  // Destination address
    axil_read(`BLIT_DST_OFFSET, read_data);
    assert(read_data == 32'h30000000) else `uvm_error("BLIT_SEQ", "Blit destination mismatch")

    // Configure blitter dimensions
    `uvm_info("BLIT_SEQ", "Configuring blitter dimensions", UVM_MEDIUM)
    axil_write(`BLIT_SIZE_OFFSET, 32'h02000100);  // 256x512 pixels
    axil_read(`BLIT_SIZE_OFFSET, read_data);
    assert(read_data == 32'h02000100) else `uvm_error("BLIT_SEQ", "Blit size mismatch")

    // Start blitter operation (memcpy)
    `uvm_info("BLIT_SEQ", "Starting blitter memcpy operation", UVM_MEDIUM)
    axil_write(`BLIT_CTRL_OFFSET, 32'h00000001);  // Start memcpy

    // Wait for blitter completion
    poll_blit_completion();

    // Verify blitter completion
    axil_read(`BLIT_CTRL_OFFSET, read_data);
    assert((read_data & 32'h00000001) == 0) else `uvm_error("BLIT_SEQ", "Blitter did not complete")

    `uvm_info("BLIT_SEQ", "Blitter operation completed successfully", UVM_MEDIUM)

    wait_cycles(10);
  endtask

  task poll_blit_completion();
    bit [31:0] status;
    int timeout = 10000;  // Maximum polling cycles (longer for blitter)

    `uvm_info("BLIT_SEQ", "Polling for blitter completion", UVM_MEDIUM)

    do begin
      axil_read(`BLIT_CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("BLIT_SEQ", "Blitter operation timeout")
    end else begin
      `uvm_info("BLIT_SEQ", "Blitter operation completed", UVM_MEDIUM)
    end
  endtask

endclass : hydra_blit_sequence

`endif
