module alu_17bit (
    input  wire [16:0] src1_data,
    input  wire [16:0] src2_data,
    input  wire [1:0]  opcode,
    output reg  [16:0] dest_data,
    output reg         overflow
);

    wire [17:0] sum_result;     // One extra bit for overflow
    wire [17:0] sub_result;     // One extra bit for overflow
    wire [33:0] mul_result;     // Full multiplication result

    assign sum_result = {1'b0, src1_data} + {1'b0, src2_data};
    assign sub_result = {1'b0, src1_data} - {1'b0, src2_data};
    assign mul_result = src1_data * src2_data;

    always @(*) begin
        case (opcode)
            2'b00: begin // ADD
                dest_data = sum_result[16:0];
                overflow  = sum_result[17];
            end
            2'b01: begin // SUB
                dest_data = sub_result[16:0];
                overflow  = sub_result[17];
            end
            2'b10: begin // MUL (output upper 17 bits)
                dest_data = mul_result[32:16];
                overflow  = 1'b0;  // overflow not meaningful for MUL upper
            end
            default: begin
                dest_data = 17'b0;
                overflow  = 1'b0;
            end
        endcase
    end

endmodule