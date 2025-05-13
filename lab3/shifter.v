module shifter #(
    parameter SIZE = 4  // default width of shift register
)(
    input                  clk,
    input                  rst_n,         // Active-low async reset
    input  [SIZE-1:0]      data_in,       // Parallel input
    output wire             read,          // High during LOAD cycle
    output wire            serial_out     // Serial output (MSB first)
);

    reg [SIZE-1:0] shift_reg;
    reg [$clog2(SIZE)-1:0] bit_count;

    localparam LOAD  = 1'b0;
    localparam SHIFT = 1'b1;

    reg state, next_state;

    // Next state logic
    always @(*) begin
        case (state)
            LOAD:  next_state = SHIFT;
            SHIFT: next_state = (bit_count == (SIZE-1)) ? LOAD : SHIFT;
            default: next_state = LOAD;
        endcase
    end

    // State and shift logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg   <= 'b0;
            bit_count   <= 1;
            state       <= LOAD;
        end else begin
            state <= next_state;
            case (state)
                LOAD: begin
                    shift_reg   <= data_in;
                    bit_count   <= 1;
                end

                SHIFT: begin
                    shift_reg   <= shift_reg << 1;  // Shift MSB-first
                    bit_count   <= bit_count + 1;
                end
            endcase
        end
    end
    assign read = ( state == LOAD);
    assign serial_out = shift_reg[SIZE-1];  // Always reflect MSB

endmodule