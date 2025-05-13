module flex_stp_sr
#(
  parameter NUM_BITS = 4,
  parameter SHIFT_MSB = 1 
)
(
  input wire clk,
  input wire rst_n,
  input wire serial_in,
  input wire shift_enable,
  output wire [NUM_BITS - 1:0] parallel_out 
);

reg [NUM_BITS - 1:0] shift_reg;
wire [NUM_BITS - 1:0] next_shift_reg;
genvar i;
genvar j;



always_ff @ (posedge clk, negedge rst_n) begin
  if (rst_n == 1'b0) begin
     shift_reg <= {NUM_BITS{1'b1}};
  end
  else begin
     shift_reg <= next_shift_reg;
  end
end
generate 

for(i = 0; i < NUM_BITS; i = i + 1) begin
    assign next_shift_reg[i] = shift_enable == 1'b1 ? (i == 0 ? serial_in : shift_reg [i-1]) : shift_reg[i]; 
end
endgenerate
generate
for(j = 0; j < NUM_BITS; j = j + 1) begin
   if (SHIFT_MSB) begin
      assign parallel_out[j] = shift_reg[j];
   end
   else begin
      assign parallel_out[j] = shift_reg[(NUM_BITS - 1) - j];
   end
end
endgenerate


endmodule