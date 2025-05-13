`timescale 1ns / 1ps

module alu_tb;

    // Inputs
    reg  [16:0] src1_data;
    reg  [16:0] src2_data;
    reg  [2:0]  opcode;

    // Outputs
    wire [16:0] dest_data;
    wire        overflow;

    // Expected values
    reg  [16:0] expected_result;
    reg         expected_overflow;
    integer     total_tests = 0;
    integer     passed_tests = 0;

    // Instantiate the ALU
    alu uut (
        .src1_data(src1_data),
        .src2_data(src2_data),
        .opcode(opcode),
        .dest_data(dest_data),
        .overflow(overflow)
    );

    // Task to run and check a test
    task run_test;
        input [2:0] op;
        input signed [16:0] a, b;
        input signed [16:0] exp_result;
        input exp_overflow;
        input [127:0] label;
        begin
            total_tests = total_tests + 1;
            opcode      = op;
            src1_data   = a;
            src2_data   = b;
            expected_result   = exp_result;
            expected_overflow = exp_overflow;
            #1;

            if (dest_data === expected_result && overflow === expected_overflow) begin
                $display("✅ PASS: %s | A=%0d, B=%0d => Result=%0d, OF=%b", label, a, b, dest_data, overflow);
                passed_tests = passed_tests + 1;
            end else begin
                $display("❌ FAIL: %s", label);
                $display("    Inputs:   A=%0d, B=%0d", a, b);
                $display("    Expected: Result=%0d, OF=%b", exp_result, exp_overflow);
                $display("    Got:      Result=%0d, OF=%b", dest_data, overflow);
            end
        end
    endtask

    initial begin
        $display("Starting ALU Tests...\n");
        // ✅ Enable VCD waveform dump
        $dumpfile("alu_tb.vcd");       // VCD output file
        $dumpvars(0, alu_tb);          // Dump all variables in this module

        // ADD tests
        run_test(3'b000, 17'sd50, 17'sd25, 17'sd75, 1'b0, "ADD");
        run_test(3'b000, 17'sd65536, 17'sd1, 17'sd1, 1'b1, "ADD Overflow");

        // SUB tests
        run_test(3'b001, 17'sd100, 17'sd50, 17'sd50, 1'b0, "SUB");
        run_test(3'b001, -17'sd65536, 17'sd1, 17'sd65535, 1'b1, "SUB Overflow");

        // AND, OR, XOR
        run_test(3'b010, 17'b10101010101010101, 17'b11110000111100001, 17'b10100000101000001, 1'b0, "AND");
        run_test(3'b011, 17'b10101010101010101, 17'b11110000111100001, 17'b11111010111110101, 1'b0, "OR");
        run_test(3'b100, 17'b10101010101010101, 17'b11110000111100001, 17'b01011010010110100, 1'b0, "XOR");

        // MULT tests
        run_test(3'b101, 17'sd1000, 17'sd50, (1000*50)>>17, 1'b1, "MULT (positive, overflow)");
        run_test(3'b101, -17'sd3000, 17'sd10, (-3000*10)>>17, 1'b1, "MULT (negative, overflow)");
        run_test(3'b101, 17'sd1, 17'sd1, 17'sd0, 1'b1, "MULT (low result, upper zero)");

        // Summary
        #2;
        if (total_tests == passed_tests) begin
            $display("\n🎉 ALL TESTS PASSED (%0d tests)\n", total_tests);
        end else begin
            $display("\n⚠️  SOME TESTS FAILED: %0d of %0d passed\n", passed_tests, total_tests);
        end

        $finish;
    end

endmodule