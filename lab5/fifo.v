`timescale 1ns / 1ps

module fifo #(
    parameter SIZE = 8,      // Depth
    parameter WIDTH = 32     // Data width
) (
    input  wire           clk,
    input  wire           rst_n,

    // Write port
    input  wire           wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire           full,

    // Read port
    input  wire           rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire           empty
);

    reg [WIDTH-1:0] mem [0:SIZE-1];    
    reg [$clog2(SIZE)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(SIZE):0] count;

    assign full  = (count >= (SIZE - 1)); //reduce size by one to allow start of axi read in same cycle of full
    assign empty = (count == 0);
    assign rd_data = mem[rd_ptr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Write
            if (wr_en) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1;
            end
            // Read
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
            end
            // Update count
            case ({wr_en, rd_en && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

endmodule
