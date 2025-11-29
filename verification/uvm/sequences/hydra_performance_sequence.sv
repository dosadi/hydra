`ifndef HYDRA_PERFORMANCE_SEQUENCE_SV
`define HYDRA_PERFORMANCE_SEQUENCE_SV

// Performance Profiling Sequence
// Measures throughput, latency, and performance characteristics

class hydra_performance_sequence extends hydra_base_sequence;
  `uvm_object_utils(hydra_performance_sequence)

  // Performance metrics
  real dma_throughput_mbps;
  real blit_throughput_mpixels_sec;
  real frame_render_fps;
  time dma_latency_ns;
  time blit_latency_ns;
  time frame_render_latency_ns;

  // Test parameters
  int num_iterations = 10;
  int dma_transfer_size = 1024 * 1024;  // 1MB
  int blit_width = 1920;
  int blit_height = 1080;

  function new(string name = "hydra_performance_sequence");
    super.new(name);
  endfunction

  task body();
    `uvm_info("PERF_SEQ", "Starting performance profiling sequence", UVM_LOW)

    // Profile DMA performance
    profile_dma_performance();

    // Profile blitter performance
    profile_blit_performance();

    // Profile frame rendering performance
    profile_frame_render_performance();

    // Report results
    report_performance_metrics();

    `uvm_info("PERF_SEQ", "Performance profiling complete", UVM_LOW)
  endtask

  task profile_dma_performance();
    time start_time, end_time;
    bit [31:0] read_data;

    `uvm_info("PERF_SEQ", "Profiling DMA performance", UVM_MEDIUM)

    dma_latency_ns = 0;

    for (int i = 0; i < num_iterations; i++) begin
      // Configure DMA transfer
      axil_write(`DMA_SRC_OFFSET, 32'h10000000 + (i * dma_transfer_size));
      axil_write(`DMA_DST_OFFSET, 32'h20000000 + (i * dma_transfer_size));
      axil_write(`DMA_LEN_OFFSET, dma_transfer_size);

      // Start timing
      start_time = $time;

      // Start DMA transfer
      axil_write(`DMA_CMD_OFFSET, `DMA_CMD_START);

      // Wait for completion
      poll_dma_completion();

      // End timing
      end_time = $time;

      // Accumulate latency
      dma_latency_ns += (end_time - start_time);
    end

    // Calculate average latency and throughput
    dma_latency_ns /= num_iterations;
    dma_throughput_mbps = (dma_transfer_size * 8.0 * 1000) / dma_latency_ns;  // Mbps

    `uvm_info("PERF_SEQ", $sformatf("DMA Latency: %.2f ns, Throughput: %.2f Mbps",
              dma_latency_ns, dma_throughput_mbps), UVM_MEDIUM)
  endtask

  task profile_blit_performance();
    time start_time, end_time;
    bit [31:0] read_data;

    `uvm_info("PERF_SEQ", "Profiling blitter performance", UVM_MEDIUM)

    blit_latency_ns = 0;

    for (int i = 0; i < num_iterations; i++) begin
      // Configure blitter operation
      axil_write(`BLIT_DST_OFFSET, 32'h30000000 + (i * blit_width * blit_height * 4));
      axil_write(`BLIT_SIZE_OFFSET, (blit_height << 16) | blit_width);

      // Start timing
      start_time = $time;

      // Start blitter
      axil_write(`BLIT_CTRL_OFFSET, 32'h00000001);

      // Wait for completion
      poll_blit_completion();

      // End timing
      end_time = $time;

      // Accumulate latency
      blit_latency_ns += (end_time - start_time);
    end

    // Calculate average latency and throughput
    blit_latency_ns /= num_iterations;
    blit_throughput_mpixels_sec = (blit_width * blit_height * 1000000000.0) / blit_latency_ns;  // MPixels/sec

    `uvm_info("PERF_SEQ", $sformatf("Blit Latency: %.2f ns, Throughput: %.2f MPixels/sec",
              blit_latency_ns, blit_throughput_mpixels_sec), UVM_MEDIUM)
  endtask

  task profile_frame_render_performance();
    time start_time, end_time;
    bit [31:0] read_data;

    `uvm_info("PERF_SEQ", "Profiling frame rendering performance", UVM_MEDIUM)

    frame_render_latency_ns = 0;

    for (int i = 0; i < num_iterations; i++) begin
      // Configure frame buffer
      axil_write(`FRAMEBUFFER_OFFSET, 32'h40000000 + (i * 1920 * 1080 * 4));

      // Start timing
      start_time = $time;

      // Start frame rendering
      axil_write(`CTRL_OFFSET, 32'h00000001);

      // Wait for completion
      poll_frame_completion();

      // End timing
      end_time = $time;

      // Accumulate latency
      frame_render_latency_ns += (end_time - start_time);
    end

    // Calculate average latency and FPS
    frame_render_latency_ns /= num_iterations;
    frame_render_fps = 1000000000.0 / frame_render_latency_ns;  // FPS

    `uvm_info("PERF_SEQ", $sformatf("Frame Render Latency: %.2f ns, FPS: %.2f",
              frame_render_latency_ns, frame_render_fps), UVM_MEDIUM)
  endtask

  task report_performance_metrics();
    `uvm_info("PERF_REPORT", "========================================", UVM_LOW)
    `uvm_info("PERF_REPORT", "     HYDRA PERFORMANCE REPORT", UVM_LOW)
    `uvm_info("PERF_REPORT", "========================================", UVM_LOW)
    `uvm_info("PERF_REPORT", "", UVM_LOW)

    `uvm_info("PERF_REPORT", "DMA Performance:", UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Average Latency: %.2f ns", dma_latency_ns), UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Throughput: %.2f Mbps", dma_throughput_mbps), UVM_LOW)
    `uvm_info("PERF_REPORT", "", UVM_LOW)

    `uvm_info("PERF_REPORT", "Blitter Performance:", UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Average Latency: %.2f ns", blit_latency_ns), UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Throughput: %.2f MPixels/sec", blit_throughput_mpixels_sec), UVM_LOW)
    `uvm_info("PERF_REPORT", "", UVM_LOW)

    `uvm_info("PERF_REPORT", "Frame Rendering Performance:", UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Average Latency: %.2f ns", frame_render_latency_ns), UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Frame Rate: %.2f FPS", frame_render_fps), UVM_LOW)
    `uvm_info("PERF_REPORT", "", UVM_LOW)

    // Performance assessment
    assess_performance();

    `uvm_info("PERF_REPORT", "========================================", UVM_LOW)
  endtask

  function void assess_performance();
    string dma_assessment, blit_assessment, frame_assessment;

    // DMA assessment
    if (dma_throughput_mbps > 1000) dma_assessment = "EXCELLENT";
    else if (dma_throughput_mbps > 500) dma_assessment = "GOOD";
    else if (dma_throughput_mbps > 100) dma_assessment = "ADEQUATE";
    else dma_assessment = "POOR";

    // Blitter assessment
    if (blit_throughput_mpixels_sec > 1000) blit_assessment = "EXCELLENT";
    else if (blit_throughput_mpixels_sec > 500) blit_assessment = "GOOD";
    else if (blit_throughput_mpixels_sec > 100) blit_assessment = "ADEQUATE";
    else blit_assessment = "POOR";

    // Frame rendering assessment
    if (frame_render_fps > 60) frame_assessment = "EXCELLENT";
    else if (frame_render_fps > 30) frame_assessment = "GOOD";
    else if (frame_render_fps > 15) frame_assessment = "ADEQUATE";
    else frame_assessment = "POOR";

    `uvm_info("PERF_REPORT", "Performance Assessment:", UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  DMA: %s (%.2f Mbps)", dma_assessment, dma_throughput_mbps), UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Blitter: %s (%.2f MPixels/sec)", blit_assessment, blit_throughput_mpixels_sec), UVM_LOW)
    `uvm_info("PERF_REPORT", $sformatf("  Frame Render: %s (%.2f FPS)", frame_assessment, frame_render_fps), UVM_LOW)
  endfunction

  task poll_dma_completion();
    bit [31:0] status;
    int timeout = 10000;

    do begin
      axil_read(`DMA_CMD_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while (status != `DMA_CMD_IDLE && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("PERF_SEQ", "DMA timeout during performance test")
    end
  endtask

  task poll_blit_completion();
    bit [31:0] status;
    int timeout = 50000;

    do begin
      axil_read(`BLIT_CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("PERF_SEQ", "Blitter timeout during performance test")
    end
  endtask

  task poll_frame_completion();
    bit [31:0] status;
    int timeout = 200000;

    do begin
      axil_read(`CTRL_OFFSET, status);
      wait_cycles(1);
      timeout--;
    end while ((status & 32'h00000001) != 0 && timeout > 0);

    if (timeout == 0) begin
      `uvm_error("PERF_SEQ", "Frame render timeout during performance test")
    end
  endtask

endclass : hydra_performance_sequence

`endif
