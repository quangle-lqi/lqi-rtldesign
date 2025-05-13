module alu (
    input  [16:0] src1_data,     // 17-bit signed operand 1
    input  [16:0] src2_data,     // 17-bit signed operand 2
    input  [2:0]  opcode,        // Operation selector
    output reg [16:0] dest_data, // 17-bit signed result
    output reg       overflow    // Overflow flag
);

    reg signed [17:0] addsub_result;
    reg signed [33:0] mult_result;

    always @(*) begin
        dest_data    = 17'd0;
        overflow     = 1'b0;
        addsub_result = 18'd0;
        mult_result   = 34'd0;

        case (opcode)
            3'b000: begin // ADD
                addsub_result = $signed(src1_data) + $signed(src2_data);
                dest_data     = addsub_result[16:0];
                overflow      = (addsub_result[17] != addsub_result[16]);
            end

            3'b001: begin // SUB
                addsub_result = $signed(src1_data) - $signed(src2_data);
                dest_data     = addsub_result[16:0];
                overflow      = (addsub_result[17] != addsub_result[16]);
            end

            3'b010: begin // AND
                dest_data = src1_data & src2_data;
                overflow  = 0;
            end

            3'b011: begin // OR
                dest_data = src1_data | src2_data;
                overflow  = 0;
            end

            3'b100: begin // XOR
                dest_data = src1_data ^ src2_data;
                overflow  = 0;
            end

            3'b101: begin // MULT (upper 17 bits of signed product)
                mult_result = $signed(src1_data) * $signed(src2_data);
                dest_data   = mult_result[33:17];
                overflow    = |mult_result[16:0]; // overflow if discarded bits not zero
            end

            default: begin
                dest_data = 17'd0;
                overflow  = 0;
            end
        endcase
    end

endmodule