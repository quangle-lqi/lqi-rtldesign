module timer 
(
  input wire clk,
  input wire rst_n,
  input wire enable_timer,
  output wire shift_enable,
  output wire packet_done
);
wire [3:0] shift_count;
wire [3:0] bit_count;
wire shift_en_int;

flex_counter shift_cnt(.clk(clk), .rst_n(rst_n), .clear(!enable_timer), .count_enable(enable_timer), .rollover_val(4'd10), .count_out(shift_count), .rollover_flag());
assign shift_en_int = shift_count == 4'd3;



flex_counter packet_done_cnt(.clk(clk), .rst_n(rst_n), .clear(!enable_timer), .count_enable(shift_en_int), .rollover_val(4'd10), .count_out(bit_count), .rollover_flag(packet_done));
assign shift_enable = bit_count != 4'b0000 ? shift_en_int : 1'b0;

endmodule