`timescale 1ns/1ps

module shifter_tb;

    parameter SIZE = 4;
    reg clk = 0;
    reg rst_n;
    reg [SIZE-1:0] data_in;
    wire read;
    wire serial_out;

    // Instantiate the shifter
    shifter #(.SIZE(SIZE)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .read(read),
        .serial_out(serial_out)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    // Test data
    reg [SIZE-1:0] test_vectors[0:2];
    reg [SIZE-1:0] expected_outputs[0:11];
    integer vec_index = 0;
    integer bit_index = 0;
    integer out_index = 0;

    initial begin
        // Initialize test vectors
        test_vectors[0] = 4'b1010; // Expected output: 1 0 1 0
        test_vectors[1] = 4'b1011; //                 1 0 1 1
        test_vectors[2] = 4'b0011; //                 0 0 1 1

        // Flatten expected output for checking
        expected_outputs[0]  = 1;
        expected_outputs[1]  = 0;
        expected_outputs[2]  = 1;
        expected_outputs[3]  = 0;
        expected_outputs[4]  = 1;
        expected_outputs[5]  = 0;
        expected_outputs[6]  = 1;
        expected_outputs[7]  = 1;
        expected_outputs[8]  = 0;
        expected_outputs[9]  = 0;
        expected_outputs[10] = 1;
        expected_outputs[11] = 1;

        $display("Starting test...");
        rst_n = 0;
        data_in = 0;
        #20;
        rst_n = 1;

        // Wait and apply inputs as signaled by `read`
        @(posedge clk); // Wait one cycle after reset
        while (out_index < 12) begin
            @(posedge clk);
            if (read) begin
                data_in = test_vectors[vec_index];
                $display("Cycle %0t: Loading data_in = %b", $time, data_in);
                vec_index = vec_index + 1;
            end

            // Check serial output every cycle
            #1;
            if (serial_out !== expected_outputs[out_index]) begin
                $fatal("Mismatch at cycle %0d: expected %b, got %b",
                        out_index, expected_outputs[out_index], serial_out);
            end else begin
                $display("Cycle %0t: serial_out = %b (OK)", $time, serial_out);
            end
            out_index = out_index + 1;
        end

        $display("All tests passed!");
        $finish;
    end

endmodule