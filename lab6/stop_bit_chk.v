`timescale 1ns / 10ps

module stop_bit_chk
(
  input  wire clk,
  input  wire rst_n,
  input  wire sbc_clear,
  input  wire sbc_enable,
  input  wire stop_bit,
  output reg  framing_error
);

  reg nxt_framing_error;
  
  always @ (negedge rst_n, posedge clk)
  begin : REG_LOGIC
    if(1'b0 == rst_n)
    begin
      framing_error  <= 1'b0; // Initialize to inactive value
    end
    else
    begin
      framing_error <= nxt_framing_error;
    end
  end
  
  always @ (framing_error, sbc_clear, sbc_enable, stop_bit)
  begin : NXT_LOGIC
    // Set default value(s)
    nxt_framing_error <= framing_error;
    
    // Define override condition(s)
    if(1'b1 == sbc_clear) // Synchronus clear/reset takes top priority for value
    begin
      nxt_framing_error <= 1'b0;
    end
    else if(1'b1 == sbc_enable) // Stop bit checker is enabled
    begin
      if(1'b1 == stop_bit) // Proper stop bit -> framming error flag should be inactive
      begin
        nxt_framing_error <= 1'b0;
      end
      else // Improper stop bit -> framing error flag should be asserted
      begin
        nxt_framing_error <= 1'b1;
      end
    end
  end
  
  
endmodule
