module counter (
    input wire clk,        // Clock input
    input wire rst_n,      // Active-low asynchronous reset
    input wire ena,        // Enable signal
    output reg [3:0] cnt  // 4-bit counter output
    );
    reg [3:0] nextcnt;  // Next counter value
// Combinational logic to determine next counter value
    always @(*) begin
        if (ena)
            nextcnt = cnt + 1;
        else
            nextcnt = cnt;
    end
// Sequential block to update the counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'b0;  // Reset counter to 0
        else
            cnt <= nextcnt;  // Update counter with next value
    end

endmodule
