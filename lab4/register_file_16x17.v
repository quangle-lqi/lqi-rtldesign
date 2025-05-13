// register_file_16x17 with debug view for GTKWave
module register_file_16x17 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  r1_sel,
    input  wire [3:0]  r2_sel,
    input  wire [3:0]  w_sel,
    input  wire [16:0] w_data,
    input  wire        w_en,
    output wire [16:0] r1_data,
    output wire [16:0] r2_data,
    output wire [16:0] outreg_data,
    output wire [271:0] regs_flat // debug: 16 x 17-bit packed wire
);

    reg [16:0] regs [0:15];

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < 16; i = i + 1)
                regs[i] <= 17'b0;
        end else if (w_en) begin
            regs[w_sel] <= w_data;
        end
    end

    // Read logic
    assign r1_data     = regs[r1_sel];
    assign r2_data     = regs[r2_sel];
    assign outreg_data = regs[0];

    // Flatten regs for GTKWave
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : flatten
            assign regs_flat[i*17 +: 17] = regs[i];
        end
    endgenerate

endmodule
