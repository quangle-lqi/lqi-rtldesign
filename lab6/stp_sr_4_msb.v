module stp_sr_4_msb
(
  input wire clk,
  input wire rst_n,
  input wire serial_in,
  input wire shift_enable,
  output wire [3:0] parallel_out 
);

  flex_stp_sr 
  CORE(
    .clk(clk),
    .rst_n(rst_n),
    .serial_in(serial_in),
    .shift_enable(shift_enable),
    .parallel_out(parallel_out)
  );

endmodule
