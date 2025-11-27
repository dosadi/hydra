// Auto-generated SystemVerilog properties
property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property frame_start_to_done; @(posedge clk) disable iff (!rst_n) start_frame_ext |-> ##[1:$] frame_done; endproperty
frame_start_to_done_sva: assert property (frame_start_to_done);

property pixel_addr_monotonic; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr >= $past(pixel_addr); endproperty
pixel_addr_monotonic_sva: assert property (pixel_addr_monotonic);

property pixel_write_no_overlap; @(posedge clk) disable iff (!rst_n) pixel_write_en |-> pixel_addr != $past(pixel_addr); endproperty
pixel_write_no_overlap_sva: assert property (pixel_write_no_overlap);

