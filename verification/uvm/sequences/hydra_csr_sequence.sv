`ifndef HYDRA_CSR_SEQUENCE_SV
`define HYDRA_CSR_SEQUENCE_SV

class hydra_csr_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_csr_sequence)

  function new(string name = "hydra_csr_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("CSR_SEQ", "Starting Hydra CSR register test sequence", UVM_LOW)

    // Test CSR register read/write operations
    test_csr_registers();

    `uvm_info("CSR_SEQ", "Hydra CSR sequence complete", UVM_LOW)
  endtask

  task test_csr_registers();
    bit [31:0] read_data;

    // Test Control register
    `uvm_info("CSR_SEQ", "Testing Control register", UVM_MEDIUM)
    axil_write(`CTRL_OFFSET, 32'h00000001);  // Enable frame rendering
    axil_read(`CTRL_OFFSET, read_data);
    assert(read_data == 32'h00000001) else `uvm_error("CSR_SEQ", "Control register mismatch")

    axil_write(`CTRL_OFFSET, 32'h00000000);  // Disable
    axil_read(`CTRL_OFFSET, read_data);
    assert(read_data == 32'h00000000) else `uvm_error("CSR_SEQ", "Control register mismatch")

    // Test Interrupt Mask register
    `uvm_info("CSR_SEQ", "Testing Interrupt Mask register", UVM_MEDIUM)
    axil_write(`INT_MASK_OFFSET, 32'hFFFFFFFF);  // Mask all interrupts
    axil_read(`INT_MASK_OFFSET, read_data);
    assert(read_data == 32'hFFFFFFFF) else `uvm_error("CSR_SEQ", "Interrupt Mask register mismatch")

    axil_write(`INT_MASK_OFFSET, 32'h00000000);  // Unmask all
    axil_read(`INT_MASK_OFFSET, read_data);
    assert(read_data == 32'h00000000) else `uvm_error("CSR_SEQ", "Interrupt Mask register mismatch")

    // Test Interrupt Status register (read-only in some implementations)
    `uvm_info("CSR_SEQ", "Testing Interrupt Status register", UVM_MEDIUM)
    axil_read(`INT_STATUS_OFFSET, read_data);
    `uvm_info("CSR_SEQ", $sformatf("Interrupt Status: 0x%08h", read_data), UVM_MEDIUM)

    // Test DMA Command register
    `uvm_info("CSR_SEQ", "Testing DMA Command register", UVM_MEDIUM)
    axil_write(`DMA_CMD_OFFSET, `DMA_CMD_START);
    axil_read(`DMA_CMD_OFFSET, read_data);
    assert(read_data == `DMA_CMD_START) else `uvm_error("CSR_SEQ", "DMA Command register mismatch")

    // Test Blitter Control register
    `uvm_info("CSR_SEQ", "Testing Blitter Control register", UVM_MEDIUM)
    axil_write(`BLIT_CTRL_OFFSET, 32'h00000001);  // Enable blitter
    axil_read(`BLIT_CTRL_OFFSET, read_data);
    assert(read_data == 32'h00000001) else `uvm_error("CSR_SEQ", "Blitter Control register mismatch")

    // Test HDMI CRC register
    `uvm_info("CSR_SEQ", "Testing HDMI CRC register", UVM_MEDIUM)
    axil_read(`HDMI_CRC_OFFSET, read_data);
    `uvm_info("CSR_SEQ", $sformatf("HDMI CRC: 0x%08h", read_data), UVM_MEDIUM)

    wait_cycles(10);  // Wait a few cycles between tests
  endtask

endclass : hydra_csr_sequence

`endif
