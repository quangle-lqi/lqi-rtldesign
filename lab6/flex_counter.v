module flex_counter
#(
  parameter NUM_CNT_BITS = 4
)
(
  input wire clk,
  input wire rst_n,
  input wire clear,
  input wire count_enable,
  input wire [(NUM_CNT_BITS-1):0] rollover_val,
  output wire [(NUM_CNT_BITS-1):0] count_out,
  output wire rollover_flag
);

reg [(NUM_CNT_BITS - 1):0] counter;
wire [(NUM_CNT_BITS - 1):0] nxt_count;
wire nxt_flag; 

always_ff @ (posedge clk, negedge rst_n) 
begin
   if(rst_n == 1'b0) begin
      counter <= 'h0;
   end
   else begin
      if(clear == 1'b1) begin
         counter <= 'h0;
      end
      else if(count_enable == 1'b1) begin
         counter <= nxt_count;
      end
   end
end


assign nxt_count = (rollover_val == counter ? 'h1 : (counter + 'h1));

assign nxt_flag = (counter == rollover_val);
assign count_out = counter;
assign rollover_flag = nxt_flag;

endmodule