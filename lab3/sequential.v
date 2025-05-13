module sequential (
    input wire clk,        // Clock input
    input wire rst_n,      // Active-low asynchronous reset
    input wire [3:0]data_in, 
    output wire read,       // read data on parallel input
    output reg [15:0] count  // count 
    );
 wire det_in, det_out;
// instantiate components
    // Instantiate the shifter
    shifter #(.SIZE(4)) s0 (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .read(read),
        .serial_out(det_in)
    );


    // Instantiate the pattern detector
    pattern_detector_1011  pd0 (
        .clk(clk),
        .rst_n(rst_n),        
        .serial_in(det_in),          // Serial input bit stream
        .pattern_detected(det_out)    // 1-cycle pulse on match
);

    // Instantiate the counter
    counter #(.SIZE(16)) c0 (
        .clk(clk),
        .rst_n(rst_n),
        .ena(det_out),
        .cnt(count)
    );

endmodule
