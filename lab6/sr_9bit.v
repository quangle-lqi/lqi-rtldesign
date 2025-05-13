module sr_9bit
(
  input wire clk,
  input wire rst_n,
  input wire shift_strobe,
  input wire serial_in,
  output wire [7:0] packet_data,
  output wire stop_bit
);



flex_stp_sr #(9, 0) ninebit_sr(.clk(clk), .rst_n(rst_n), 
                    .serial_in(serial_in), 
                    .shift_enable(shift_strobe), 
                    .parallel_out({stop_bit, packet_data[7:0]}));

endmodule