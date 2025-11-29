`ifndef HYDRA_COVERAGE_SV
`define HYDRA_COVERAGE_SV

class hydra_coverage extends uvm_subscriber#(hydra_axil_item);
  `uvm_component_utils(hydra_coverage)

  // Coverage groups
  covergroup axil_transaction_cg;
    option.per_instance = 1;

    // Address coverage
    addr_cp: coverpoint txn.addr {
      bins csr_ctrl = {`CTRL_OFFSET};
      bins csr_int_mask = {`INT_MASK_OFFSET};
      bins csr_int_status = {`INT_STATUS_OFFSET};
      bins csr_dma_src = {`DMA_SRC_OFFSET};
      bins csr_dma_dst = {`DMA_DST_OFFSET};
      bins csr_dma_len = {`DMA_LEN_OFFSET};
      bins csr_dma_cmd = {`DMA_CMD_OFFSET};
      bins csr_blit_ctrl = {`BLIT_CTRL_OFFSET};
      bins csr_hdmi_crc = {`HDMI_CRC_OFFSET};
      bins memory = default;
    }

    // Data coverage
    data_cp: coverpoint txn.data {
      bins zero = {0};
      bins all_ones = {32'hFFFFFFFF};
      bins low_byte = {[1:255]};
      bins other = default;
    }

    // Write/Read coverage
    write_cp: coverpoint txn.write {
      bins read = {0};
      bins write = {1};
    }

    // Delay coverage
    delay_cp: coverpoint txn.delay {
      bins no_delay = {0};
      bins small_delay = {[1:3]};
      bins medium_delay = {[4:7]};
      bins large_delay = {[8:10]};
    }

    // Cross coverage
    addr_x_write: cross addr_cp, write_cp;
    data_x_write: cross data_cp, write_cp;

  endgroup

  covergroup hydra_operation_cg;
    option.per_instance = 1;

    // Operation type coverage
    operation_cp: coverpoint operation_type {
      bins frame_render = {HYDRA_OP_FRAME_RENDER};
      bins dma_transfer = {HYDRA_OP_DMA_TRANSFER};
      bins blit_operation = {HYDRA_OP_BLIT_OPERATION};
      bins surface_extract = {HYDRA_OP_SURFACE_EXTRACT};
    }

    // DMA direction coverage
    dma_direction_cp: coverpoint dma_direction {
      bins host_to_fpga = {DMA_HOST_TO_FPGA};
      bins fpga_to_host = {DMA_FPGA_TO_HOST};
      bins fpga_internal = {DMA_FPGA_INTERNAL};
    }

    // Blitter operation coverage
    blit_op_cp: coverpoint blit_operation {
      bins memcpy = {BLIT_MEMCPY};
      bins draw_object = {BLIT_DRAW_OBJECT};
      bins move_object = {BLIT_MOVE_OBJECT};
      bins surface_extract = {BLIT_SURFACE_EXTRACT};
    }

  endgroup

  // Local variables for coverage
  hydra_op_type_e operation_type;
  dma_direction_e dma_direction;
  blit_op_type_e blit_operation;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    axil_transaction_cg = new();
    hydra_operation_cg = new();
  endfunction

  function void write(hydra_axil_item t);
    // Sample AXI-Lite transaction coverage
    axil_transaction_cg.sample();

    // Infer operation type from transaction
    infer_operation_type(t);

    // Sample operation coverage
    hydra_operation_cg.sample();
  endfunction

  function void infer_operation_type(hydra_axil_item t);
    // Infer operation type based on register writes
    case (t.addr)
      `CTRL_OFFSET: begin
        if (t.write && t.data[0]) operation_type = HYDRA_OP_FRAME_RENDER;
      end
      `DMA_CMD_OFFSET: begin
        if (t.write && t.data == `DMA_CMD_START) operation_type = HYDRA_OP_DMA_TRANSFER;
      end
      `BLIT_CTRL_OFFSET: begin
        if (t.write) operation_type = HYDRA_OP_BLIT_OPERATION;
      end
      `REGION0_CFG_OFFSET: begin
        if (t.write) operation_type = HYDRA_OP_SURFACE_EXTRACT;
      end
    endcase

    // Infer DMA direction from src/dst registers
    if (t.addr == `DMA_SRC_OFFSET && t.write) begin
      // This is a simplification - in reality would need more context
      dma_direction = DMA_HOST_TO_FPGA;
    end

    // Infer blitter operation from control register
    if (t.addr == `BLIT_CTRL_OFFSET && t.write) begin
      case (t.data[3:0])  // Assuming operation type in lower bits
        0: blit_operation = BLIT_MEMCPY;
        1: blit_operation = BLIT_DRAW_OBJECT;
        2: blit_operation = BLIT_MOVE_OBJECT;
        3: blit_operation = BLIT_SURFACE_EXTRACT;
      endcase
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("COVERAGE", "Coverage Report:", UVM_LOW)
    `uvm_info("COVERAGE", $sformatf("AXI-Lite Transaction Coverage: %.2f%%",
              axil_transaction_cg.get_coverage()), UVM_LOW)
    `uvm_info("COVERAGE", $sformatf("Hydra Operation Coverage: %.2f%%",
              hydra_operation_cg.get_coverage()), UVM_LOW)
  endfunction

endclass : hydra_coverage

`endif
