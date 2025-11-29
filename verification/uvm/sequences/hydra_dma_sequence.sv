`ifndef HYDRA_DMA_SEQUENCE_SV
`define HYDRA_DMA_SEQUENCE_SV

class hydra_dma_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_dma_sequence)

  function new(string name = "hydra_dma_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("DMA_SEQ", "Starting Hydra DMA test sequence", UVM_LOW)

    // Test DMA operations
    test_dma_transfer();

    `uvm_info("DMA_SEQ", "Hydra DMA sequence complete", UVM_LOW)
  endtask

  task test_dma_transfer();
    bit [31:0] read_data;

    // Configure DMA source address
    `uvm_info("DMA_SEQ", "Configuring DMA source address", UVM_MEDIUM)
    axil_write(`DMA_SRC_OFFSET, 32'h10000000);  // Source address
    axil_read(`DMA_SRC_OFFSET, read_data);
    assert(read_data == 32'h10000000) else `uvm_error("DMA_SEQ", "DMA source address mismatch")

    // Configure DMA destination address
    `uvm_info("DMA_SEQ", "Configuring DMA destination address", UVM_MEDIUM)
    axil_write(`DMA_DST_OFFSET, 32'h20000000);  // Destination address
    axil_read(`DMA_DST_OFFSET, read_data);
    assert(read_data == 32'h20000000) else `uvm_error("DMA_SEQ", "DMA destination address mismatch")

    // Configure DMA transfer length
    `uvm_info("DMA_SEQ", "Configuring DMA transfer length", UVM_MEDIUM)
    axil_write(`DMA_LEN_OFFSET, 32'h00001000);  // 4096 bytes
    axil_read(`DMA_LEN_OFFSET, read_data);
    assert(read_data == 32'h00001000) else `uvm_error("DMA_SEQ", "DMA length mismatch")

    // Start DMA transfer
    `uvm_info("DMA_SEQ", "Starting DMA transfer", UVM_MEDIUM)
    axil_write(`DMA_CMD_OFFSET, `DMA_CMD_START);

    // Wait for DMA completion (polling status)
    poll_dma_completion();

    // Verify DMA completion
    axil_read(`DMA_CMD_OFFSET, read_data);
    assert(read_data == `DMA_CMD_IDLE) else `uvm_error("DMA_SEQ", "DMA did not complete")

    `uvm_info("DMA_SEQ", "DMA transfer completed successfully", UVM_MEDIUM)

    wait_cycles(10);
  endtask

  task poll_dma_completion();
    bit [31:0] status;
    int timeout = 1000;  // Maximum polling cycles

    `uvm_info("DMA_SEQ", "Polling for DMA completion", UVM_MEDIUM)

    do begin
      axil_read(`DMA_CMD_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while (status != `DMA_CMD_IDLE && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("DMA_SEQ", "DMA transfer timeout")
    end else begin
      `uvm_info("DMA_SEQ", "DMA transfer completed", UVM_MEDIUM)
    end
  endtask

endclass : hydra_dma_sequence

`endif
