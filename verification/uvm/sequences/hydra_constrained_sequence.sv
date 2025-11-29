`ifndef HYDRA_CONSTRAINED_SEQUENCE_SV
`define HYDRA_CONSTRAINED_SEQUENCE_SV

// Constrained Random Testing Sequences
// Advanced verification with randomization and constraints

class hydra_constrained_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_constrained_sequence)

  // Randomization parameters
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand int delay;
  rand hydra_operation_e operation;

  // Constraints
  constraint addr_range {
    addr inside {[32'h00000000:32'h0000FFFF]};  // Valid address range
  }

  constraint data_alignment {
    (addr % 4) == 0;  // 32-bit aligned addresses
  }

  constraint delay_range {
    delay inside {[0:10]};  // Reasonable delay range
  }

  constraint operation_distribution {
    operation dist {
      HYDRA_OP_FRAME_RENDER := 20,
      HYDRA_OP_DMA_TRANSFER := 30,
      HYDRA_OP_BLIT_OPERATION := 25,
      HYDRA_OP_SURFACE_EXTRACT := 25
    };
  }

  function new(string name = "hydra_constrained_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("CONSTR_SEQ", "Starting constrained random sequence", UVM_LOW)

    // Generate constrained random transactions
    repeat (50) begin
      if (!this.randomize()) begin
        `uvm_error("CONSTR_SEQ", "Randomization failed")
        continue;
      end

      // Execute based on randomized operation
      case (operation)
        HYDRA_OP_FRAME_RENDER: execute_frame_render();
        HYDRA_OP_DMA_TRANSFER: execute_dma_transfer();
        HYDRA_OP_BLIT_OPERATION: execute_blit_operation();
        HYDRA_OP_SURFACE_EXTRACT: execute_surface_extract();
      endcase

      wait_cycles(delay);
    end

    `uvm_info("CONSTR_SEQ", "Constrained random sequence complete", UVM_LOW)
  endtask

  task execute_frame_render();
    bit [31:0] read_data;

    `uvm_info("CONSTR_SEQ", $sformatf("Frame render: addr=0x%08h", addr), UVM_MEDIUM)

    // Configure frame buffer address
    axil_write(`FRAMEBUFFER_OFFSET, addr);

    // Enable frame rendering
    axil_write(`CTRL_OFFSET, 32'h00000001);

    // Wait for completion
    poll_frame_completion();
  endtask

  task execute_dma_transfer();
    bit [31:0] read_data;

    `uvm_info("CONSTR_SEQ", $sformatf("DMA transfer: addr=0x%08h data=0x%08h", addr, data), UVM_MEDIUM)

    // Configure DMA parameters
    axil_write(`DMA_SRC_OFFSET, addr);
    axil_write(`DMA_DST_OFFSET, data);
    axil_write(`DMA_LEN_OFFSET, 32'h00001000);  // 4KB transfer

    // Start DMA
    axil_write(`DMA_CMD_OFFSET, `DMA_CMD_START);

    // Wait for completion
    poll_dma_completion();
  endtask

  task execute_blit_operation();
    bit [31:0] read_data;

    `uvm_info("CONSTR_SEQ", $sformatf("Blit operation: addr=0x%08h", addr), UVM_MEDIUM)

    // Configure blitter
    axil_write(`BLIT_DST_OFFSET, addr);
    axil_write(`BLIT_SIZE_OFFSET, 32'h02000100);  // 256x512

    // Start blitter
    axil_write(`BLIT_CTRL_OFFSET, 32'h00000001);

    // Wait for completion
    poll_blit_completion();
  endtask

  task execute_surface_extract();
    bit [31:0] read_data;

    `uvm_info("CONSTR_SEQ", $sformatf("Surface extract: addr=0x%08h", addr), UVM_MEDIUM)

    // Configure surface extraction
    axil_write(`REGION0_CFG_OFFSET, addr);

    // Trigger extraction
    axil_write(`CTRL_OFFSET, 32'h00000002);

    wait_cycles(100);  // Allow time for processing
  endtask

  task poll_frame_completion();
    bit [31:0] status;
    int timeout = 100000;

    do begin
      axil_read(`CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("CONSTR_SEQ", "Frame rendering timeout")
    end
  endtask

  task poll_dma_completion();
    bit [31:0] status;
    int timeout = 1000;

    do begin
      axil_read(`DMA_CMD_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while (status != `DMA_CMD_IDLE && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("CONSTR_SEQ", "DMA transfer timeout")
    end
  endtask

  task poll_blit_completion();
    bit [31:0] status;
    int timeout = 10000;

    do begin
      axil_read(`BLIT_CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("CONSTR_SEQ", "Blitter operation timeout")
    end
  endtask

endclass : hydra_constrained_sequence

`endif
