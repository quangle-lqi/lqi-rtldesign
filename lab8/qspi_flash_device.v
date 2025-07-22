
module qspi_flash_device (
    input wire cs_n,
    input wire sck,
    inout wire [3:0] io
);
    parameter MEM_SIZE = 1024;
    reg [7:0] memory [0:MEM_SIZE-1];
    reg [7:0] shift_reg = 8'h00;
    reg [3:0] bit_cnt = 0;
    reg [23:0] addr = 0;
    reg [1:0] state = 0; // 0=IDLE, 1=CMD, 2=ADDR, 3=READ
    reg [3:0] io_out;
    reg io_oe = 0;

    assign io = io_oe ? io_out : 4'bz;

    initial begin
        integer i;
        for (i = 0; i < MEM_SIZE; i = i + 1)
            memory[i] = 8'hFF;
    end

    always @(negedge cs_n) begin
        state <= 1; // Start command reception
        bit_cnt <= 0;
    end

    always @(posedge sck) begin
        if (!cs_n) begin
            case (state)
                1: begin // Read command
                    shift_reg = {shift_reg[6:0], io[1]};
                    bit_cnt = bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        if (shift_reg == 8'h03) begin
                            state <= 2;
                            bit_cnt <= 0;
                        end else begin
                            state <= 0;
                        end
                    end
                end
                2: begin // Address
                    addr = {addr[22:0], io[1]};
                    bit_cnt = bit_cnt + 1;
                    if (bit_cnt == 23) begin
                        state <= 3;
                        bit_cnt <= 0;
                        shift_reg <= memory[addr];
                        io_oe <= 1;
                        io_out <= memory[addr][7:4];
                    end
                end
                3: begin // Output data
                    case (bit_cnt)
                        0: io_out <= memory[addr][3:0];
                        1: begin
                            addr <= addr + 1;
                            shift_reg <= memory[addr];
                            io_out <= memory[addr][7:4];
                        end
                        2: io_out <= memory[addr][3:0];
                    endcase
                    bit_cnt <= bit_cnt + 1;
                end
            endcase
        end else begin
            io_oe <= 0;
            state <= 0;
        end
    end
endmodule
