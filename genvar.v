genvar i;

generate
  for (i = 0; i < N; i = i + 1) begin : gen_block_name
    // Repeated instantiation
    my_module u_inst (
      .in  (a[i]),
      .out (b[i])
    );
  end
endgenerate