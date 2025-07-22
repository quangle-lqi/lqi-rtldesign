parameter DEPTH = 64
localparam WIDTH = $clog2(DEPTH)
wire [WIDTH-1:0] data_in,
wire parity_out,
// XOR reduction (even parity)
assign parity_out = ^data_in;  