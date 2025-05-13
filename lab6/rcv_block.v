module rcv_block
(
   input wire clk,
   input wire rst_n,
   input wire serial_in,
   input wire data_read,
   output reg [7:0] rx_data,
   output reg data_ready,
   output reg overrun_error,
   output reg framing_error
);

wire load_buffer;
wire sbc_enable;
wire sbc_clear;
wire enable_timer;
wire packet_done;
wire start_bit_detected;

wire shift_strobe;

wire stop_bit;
wire [7:0] packet_data;

rx_data_buff BUF(.clk(clk), .rst_n(rst_n), .load_buffer(load_buffer), .packet_data(packet_data), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));

sr_9bit SR9(.clk(clk), .rst_n(rst_n), .shift_strobe(shift_strobe), .serial_in(serial_in), .packet_data(packet_data), .stop_bit(stop_bit));

start_bit_det SBD(.clk(clk), .rst_n(rst_n), .serial_in(serial_in), .start_bit_detected(start_bit_detected));

stop_bit_chk SBC(.clk(clk), .rst_n(rst_n), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));

rcu RCU(.clk(clk), .rst_n(rst_n), .start_bit_detected(start_bit_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));

timer TMR(.clk(clk), .rst_n(rst_n), .enable_timer(enable_timer), .shift_enable(shift_strobe), .packet_done(packet_done));

endmodule
