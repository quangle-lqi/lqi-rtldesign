module pattern_detector_1011 (
    input  wire clk,
    input  wire rst_n,              // Active-low async reset
    input  wire serial_in,          // Serial input bit stream
    output reg  pattern_detected    // 1-cycle pulse on match
);

    // State encoding
    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;

    reg [2:0] state, next_state;

    // State transition logic
    always @(*) begin
        case (state)
            S0:  next_state = serial_in ? S1 : S0;
            S1:  next_state = serial_in ? S1 : S2;
            S2:  next_state = serial_in ? S3 : S0;
            S3:  next_state = serial_in ? S4 : S2;
            S4:  next_state = serial_in ? S1 : S2; // allow overlap
            default: next_state = S0;
        endcase
    end

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S0;
        else
            state <= next_state;
    end

    // Output logic (1-cycle pulse on 1011 detected)
    always @(*) begin
        pattern_detected = (state == S3 && serial_in == 1'b1);
    end

endmodule
