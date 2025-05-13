module datapath (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  op,          // operation code
    input  wire [3:0]  src1,        // register index for src1
    input  wire [3:0]  src2,        // register index for src2
    input  wire [3:0]  dest,        // destination register index
    input  wire [16:0] ext_data1,   // external data input 1
    input  wire [16:0] ext_data2,   // external data input 2
    output wire [16:0] outreg_data, // output from register 0
    output wire        overflow     // output overflow from ALU
);

    // Internal signals
    wire [16:0] r1_data, r2_data;
    wire [16:0] alu_result;
    wire        alu_overflow;
    reg  [16:0] write_data;
    reg         write_enable;
    reg  [1:0]  alu_op;

    // Register File Instance
    register_file_16x17 rf_inst (
        .clk(clk),
        .rst_n(rst_n),
        .r1_sel(src1),
        .r2_sel(src2),
        .w_sel(dest),
        .w_data(write_data),
        .w_en(write_enable),
        .r1_data(r1_data),
        .r2_data(r2_data),
        .outreg_data(outreg_data),
        .regs_flat() // optional debug port for GTKWave
    );

    // ALU Instance
    alu_17bit alu_inst (
        .src1_data(r1_data),
        .src2_data(r2_data),
        .opcode(alu_op),
        .dest_data(alu_result),
        .overflow(alu_overflow)
    );

    // Control logic
    always @(*) begin
        write_enable = 1'b0;
        write_data   = 17'b0;
        alu_op       = 2'b00;

        case (op)
            3'b000: begin // NOP
                alu_op       = 2'b00;
                write_enable = 1'b0;
                write_data   = 17'b0;
            end
            3'b001: begin // COPY src1 to dest
                alu_op       = 2'b00;
                write_enable = 1'b1;
                write_data   = r1_data;
            end
            3'b010: begin // LOAD1 from ext_data1
                alu_op       = 2'b00;
                write_enable = 1'b1;
                write_data   = ext_data1;
            end
            3'b011: begin // LOAD2 from ext_data2
                alu_op       = 2'b00;
                write_enable = 1'b1;
                write_data   = ext_data2;
            end
            3'b100: begin // ADD src1 + src2
                alu_op       = 2'b00;
                write_enable = 1'b1;
                write_data   = alu_result;
            end
            3'b110: begin // SUB src1 - src2
                alu_op       = 2'b01;
                write_enable = 1'b1;
                write_data   = alu_result;
            end
            3'b111: begin // MUL src1 * src2
                alu_op       = 2'b10;
                write_enable = 1'b1;
                write_data   = alu_result;
            end
            default: begin
                alu_op       = 2'b00;
                write_enable = 1'b0;
                write_data   = 17'b0;
            end
        endcase
    end

    assign overflow = alu_overflow;

endmodule
