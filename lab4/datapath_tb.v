`timescale 1ns / 1ps

module datapath_tb;
    reg         clk;
    reg         rst_n;
    reg  [2:0]  op;
    reg  [3:0]  src1, src2, dest;
    reg  [16:0] ext_data1, ext_data2;
    wire [16:0] outreg_data;
    wire        overflow;
    wire [271:0] regs_flat;
    reg         last_overflow;

    // Instantiate the DUT
    datapath dut (
        .clk(clk),
        .rst_n(rst_n),
        .op(op),
        .src1(src1),
        .src2(src2),
        .dest(dest),
        .ext_data1(ext_data1),
        .ext_data2(ext_data2),
        .outreg_data(outreg_data),
        .overflow(overflow)
        // Note: regs_flat wired internally via rf_inst
    );

    assign regs_flat = dut.rf_inst.regs_flat;

    // Clock generation
    always #5 clk = ~clk;

    task reset();
    begin
        rst_n = 0;
        clk = 0;
        #10;
        rst_n = 1;
        #10;
    end
    endtask

    task run_op(
        input [2:0] op_code,
        input [3:0] s1,
        input [3:0] s2,
        input [3:0] d,
        input [16:0] ed1,
        input [16:0] ed2
    );
    begin
        @(posedge clk);
        op        = op_code;
        src1      = s1;
        src2      = s2;
        dest      = d;
        ext_data1 = ed1;
        ext_data2 = ed2;
        @(posedge clk);
        last_overflow = overflow;
        op = 3'b000; // return to NOP after operation
    end
    endtask

    function [16:0] get_reg;
        input integer index;
        begin
            get_reg = regs_flat[index*17 +: 17];
        end
    endfunction

    initial begin
        $dumpfile("datapath_tb.vcd");
        $dumpvars(0, datapath_tb);
        $dumpvars(0, datapath_tb.dut.rf_inst);
        $dumpvars(0, datapath_tb.dut.alu_inst);

        reset();

        // LOAD1: Write ext_data1 to R1
        run_op(3'b010, 4'd0, 4'd0, 4'd1, 17'd25, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (get_reg(1) !== 17'd25) $display("LOAD1 FAIL");

        // LOAD2: Write ext_data2 to R2
        run_op(3'b011, 4'd0, 4'd0, 4'd2, 17'd0, 17'd12);
        #1; // let simulation settle and update regs_flat
        if (get_reg(2) !== 17'd12) $display("LOAD2 FAIL");

        // COPY: R1 -> R3
        run_op(3'b001, 4'd1, 4'd0, 4'd3, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (get_reg(3) !== 17'd25) $display("COPY FAIL");

        // ADD: R1 + R2 -> R4
        run_op(3'b100, 4'd1, 4'd2, 4'd4, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (get_reg(4) !== 17'd37 || last_overflow) $display("ADD FAIL");

        // SUB: R1 - R2 -> R5
        run_op(3'b110, 4'd1, 4'd2, 4'd5, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (get_reg(5) !== 17'd13 || last_overflow) $display("SUB FAIL");

        // MUL: R1 * R2 -> R6 (upper 17 bits)
        run_op(3'b111, 4'd1, 4'd2, 4'd6, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (get_reg(6) !== 17'd0 || last_overflow) $display("MUL FAIL");

        // Overflow test: R7=max, R8=1
        run_op(3'b010, 4'd0, 4'd0, 4'd7, 17'h1FFFF, 17'd0);
        run_op(3'b011, 4'd0, 4'd0, 4'd8, 17'd0, 17'h00001);

        // ADD overflow: R7 + R8 -> R9
        run_op(3'b100, 4'd7, 4'd8, 4'd9, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (!last_overflow) $display("ADD OVERFLOW TEST FAIL");

        // SUB overflow: R8 - R7 -> R10
        run_op(3'b110, 4'd8, 4'd7, 4'd10, 17'd0, 17'd0);
        #1; // let simulation settle and update regs_flat
        if (!last_overflow) $display("SUB OVERFLOW TEST FAIL");

        // Copy result to R0 for observation
        run_op(3'b001, 4'd4, 4'd0, 4'd0, 17'd0, 17'd0);
        #10;

        $display("outreg_data = %d", outreg_data);
        $display("Testbench completed.");
        $finish;
    end
endmodule
