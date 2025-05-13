`timescale 1ns / 1ps

module counter_tb;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg ena;
    wire [3:0] cnt;

    // Instantiate the counter module
    counter uut (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .cnt(cnt)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("Starting counter rollover test...");

        // ✅ Enable VCD waveform dump
        $dumpfile("counter_tb.vcd");       // VCD output file
        $dumpvars(0, counter_tb);          // Dump all variables in this module

        // Initial conditions
        rst_n = 0;
        ena   = 0;

        // Apply reset
        #12;
        rst_n = 1;
        #10;

        // Enable the counter and begin counting
        ena = 1;

        // Count until we reach 5
        wait(cnt == 4'd5);
        $display("Reached cnt = 5 at time %0t", $time);

        // Disable for 1 cycle, check hold
        ena = 0;
        @(posedge clk);
        if (cnt !== 4'd5)
            $display("ERROR: Counter changed during ena=0!");
        else
            $display("PASS: Counter held value at %0d when ena=0", cnt);

        // Re-enable
        ena = 1;

        // Wait for rollover (15 -> 0)
        wait(cnt == 4'd15);
        @(posedge clk);  // One more cycle to roll over
        @(posedge clk);

        $display("Counter rolled over to %0d at time %0t", cnt, $time);
        $finish;
    end

endmodule