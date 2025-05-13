`timescale 1ns/1ps

module sequential_tb;

  reg clk = 0;
  reg rst_n;
  reg [3:0] data_in;
  wire read;
  wire [15:0] count;

  // Instantiate DUT
  sequential dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .read(read),
    .count(count)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Control variables
  integer i;
  integer timeout;
  integer expected_count = 0;
  integer bit_ptr = 0;

  // Track full bitstream
  reg [1023:0] bitstream;

  initial begin
    $display("Starting sequential pattern test...");
    $dumpfile("sequential_tb.vcd");
    $dumpvars(0, sequential_tb);
    $dumpvars(0, sequential_tb.dut);         // DUT wrapper
    $dumpvars(0, sequential_tb.dut.s0);     // Shifter
    $dumpvars(0, sequential_tb.dut.pd0);     // Pattern detector
    $dumpvars(0, sequential_tb.dut.c0);      // Counter

    rst_n = 0;
    data_in = 0;
    bitstream = 0;

    // Deassert reset after a few cycles
    repeat (3) @(negedge clk);
    rst_n = 1;

    // Feed 64 inputs = 256 bits total
    for (i = 0; i < 64; i = i + 1) begin
      // Wait for read == 1
      timeout = 1000;
      while (!read && timeout > 0) begin
        @(posedge clk);
        timeout = timeout - 1;
      end
      if (timeout == 0)
        $fatal(1, "Timeout waiting for read at index %0d", i);

      // Provide 4-bit data
      data_in = $random;
      $display("Cycle %0t: data_in = %b", $time, data_in);

      // Push MSB-first into bitstream
      bitstream[bit_ptr ] = data_in[3];
      bitstream[bit_ptr + 1] = data_in[2];
      bitstream[bit_ptr + 2] = data_in[1];
      bitstream[bit_ptr + 3] = data_in[0];
      bit_ptr = bit_ptr + 4;

      // Wait for read to go low (ensures one data per pulse)
      while (read) @(posedge clk);
    end

    // Wait for final bits to shift out
    repeat (20) @(posedge clk);

    // Software pattern detection
    expected_count = 0;
    for (i = 0; i <= bit_ptr - 4; i = i + 1) begin
      if (bitstream[i +: 4] == 4'b1101) //need to compare with inverse pattern
        expected_count = expected_count + 1;
    end

    $display("Expected count: %0d", expected_count);
    $display("Hardware  count: %0d", count);

    if (count !== expected_count) begin
      $fatal(1, "Mismatch! Expected: %0d, Got: %0d", expected_count, count);
    end else begin
      $display("✅ Test PASSED: pattern 1011 detected correctly.");
    end

    $finish;
  end

endmodule