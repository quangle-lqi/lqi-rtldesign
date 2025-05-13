`timescale 1ns / 10ps

module start_bit_det
(
  input  wire clk,
  input  wire rst_n,
  input  wire serial_in,
  output wire start_bit_detected,
  output wire new_package_detected
);

  reg old_sample;
  reg new_sample;
  reg sync_phase;
  
  always @ (negedge rst_n, posedge clk)
  begin : REG_LOGIC
    if(1'b0 == rst_n)
    begin
      old_sample  <= 1'b1; // Reset value to idle line value
      new_sample  <= 1'b1; // Reset value to idle line value
      sync_phase  <= 1'b1; // Reset value to idle line value
    end
    else
    begin
      old_sample  <= new_sample;
      new_sample  <= sync_phase;
      sync_phase  <= serial_in;
    end
  end
  
  // Output logic
  assign new_package_detected = old_sample & (~new_sample);
  assign start_bit_detected = old_sample & (~new_sample); // Detect a falling edge -> new sample must be '0' and old sample must be '1'

  
endmodule
