// qspi_device.v - Full fixed version

module qspi_device (
    input  wire qspi_sclk,
    input  wire qspi_cs_n,
    inout  wire qspi_io0,
    inout  wire qspi_io1,
    inout  wire qspi_io2,
    inout  wire qspi_io3
);

parameter MEM_SIZE = 1024 * 1024;
parameter ADDR_BITS = 24;
parameter PAGE_SIZE = 256;
parameter SECTOR_SIZE = 4096;

reg [7:0] memory [0:MEM_SIZE-1];

reg [3:0] io_oe;
reg [3:0] io_do;
wire [3:0] io_di = {qspi_io3, qspi_io2, qspi_io1, qspi_io0};

assign qspi_io0 = io_oe[0] ? io_do[0] : 1'bz;
assign qspi_io1 = io_oe[1] ? io_do[1] : 1'bz;
assign qspi_io2 = io_oe[2] ? io_do[2] : 1'bz;
assign qspi_io3 = io_oe[3] ? io_do[3] : 1'bz;

reg [7:0] status_reg = 8'h00;
reg [7:0] cmd_reg;
reg [ADDR_BITS-1:0] addr_reg;
reg [7:0] mode_bits;
reg [7:0] shift_in;
reg [7:0] shift_out;
reg [3:0] lanes;
reg [4:0] dummy_cycles;
reg continuous_read;

localparam ST_IDLE = 4'h0, ST_CMD = 4'h1, ST_ADDR = 4'h2, ST_MODE = 4'h3, ST_DUMMY = 4'h4, ST_DATA_READ = 4'h5, ST_DATA_WRITE = 4'h6, ST_ERASE = 4'h7, ST_STATUS = 4'h8;
reg [3:0] state = ST_IDLE;

reg [31:0] bit_cnt;
reg [31:0] byte_cnt;
reg wip;

initial begin
    integer i;
    for (i = 0; i < MEM_SIZE; i = i + 1) begin
        memory[i] = 8'hFF;
    end
    wip = 0;
end

always @(posedge qspi_sclk or posedge qspi_cs_n) begin
    if (qspi_cs_n) begin
        state = ST_IDLE;
        io_oe = 4'b0000;
        continuous_read = 0;
    end else begin
        if (state == ST_IDLE) begin
            state = ST_CMD;
            bit_cnt = 0;
            lanes = 1;
            shift_in = 0;
        end else if (state == ST_CMD) begin
            shift_in = {shift_in[6:0], io_di[0]};
            bit_cnt = bit_cnt + 1;
            if (bit_cnt == 7) begin
                cmd_reg = {shift_in[6:0], io_di[0]};
                bit_cnt = 0;
                byte_cnt = 0;
                if ({shift_in[6:0], io_di[0]} == 8'h9F) begin
                    state = ST_DATA_READ;
                    lanes = 1;
                    dummy_cycles = 0;
                    shift_out = 8'hEF;
                    io_oe = 4'b0001;
                end else if ({shift_in[6:0], io_di[0]} == 8'h05) begin
                    state = ST_STATUS;
                    lanes = 1;
                    shift_out = status_reg;
                    io_oe = 4'b0001;
                end else if ({shift_in[6:0], io_di[0]} == 8'h06) begin
                    status_reg[1] = 1;
                    state = ST_IDLE;
                end else if ({shift_in[6:0], io_di[0]} == 8'h04) begin
                    status_reg[1] = 0;
                    state = ST_IDLE;
                end else if ({shift_in[6:0], io_di[0]} == 8'h03 || {shift_in[6:0], io_di[0]} == 8'h0B || {shift_in[6:0], io_di[0]} == 8'h3B || {shift_in[6:0], io_di[0]} == 8'h6B || {shift_in[6:0], io_di[0]} == 8'hEB) begin
                    state = ST_ADDR;
                    addr_reg = 0;
                    if (cmd_reg == 8'h03) lanes = 1;
                    else if (cmd_reg == 8'h3B) lanes = 2;
                    else lanes = 4;
                    dummy_cycles = (cmd_reg == 8'h03) ? 0 : (cmd_reg == 8'hEB ? 6 : 8);
                end else if ({shift_in[6:0], io_di[0]} == 8'h02 || {shift_in[6:0], io_di[0]} == 8'h32) begin
                    if (status_reg[1]) begin
                        state = ST_ADDR;
                        lanes = (cmd_reg == 8'h02) ? 1 : 4;
                    end else state = ST_IDLE;
                end else if ({shift_in[6:0], io_di[0]} == 8'h20 || {shift_in[6:0], io_di[0]} == 8'hD8 || {shift_in[6:0], io_di[0]} == 8'hC7) begin
                    if (status_reg[1]) begin
                        state = (cmd_reg == 8'hC7) ? ST_ERASE : ST_ADDR;
                    end else state = ST_IDLE;
                end else state = ST_IDLE;
            end
        end else if (state == ST_ADDR) begin
            if (lanes == 1) shift_in = {shift_in[6:0], io_di[0]};
            else if (lanes == 2) shift_in = {shift_in[5:0], io_di[1:0]};
            else if (lanes == 4) shift_in = {shift_in[3:0], io_di[3:0]};
            bit_cnt = bit_cnt + lanes;
            if (bit_cnt == 8) begin
                addr_reg = {addr_reg[ADDR_BITS-9:0], shift_in[7:0]};
                byte_cnt = byte_cnt + 1;
                bit_cnt = 0;
                if (byte_cnt == (ADDR_BITS/8) - 1) begin
                    if (cmd_reg == 8'h0B || cmd_reg == 8'h3B || cmd_reg == 8'h6B || cmd_reg == 8'hEB) state = (dummy_cycles > 0 ? ST_DUMMY : (cmd_reg == 8'h02 || cmd_reg == 8'h32 ? ST_DATA_WRITE : ST_DATA_READ));
                    else if (cmd_reg == 8'h20 || cmd_reg == 8'hD8) state = ST_ERASE;
                    if (cmd_reg == 8'hEB) state = ST_MODE;
                end
            end
        end else if (state == ST_MODE) begin
            if (lanes == 1) shift_in = {shift_in[6:0], io_di[0]};
            else if (lanes == 2) shift_in = {shift_in[5:0], io_di[1:0]};
            else if (lanes == 4) shift_in = {shift_in[3:0], io_di[3:0]};
            bit_cnt = bit_cnt + lanes;
            if (bit_cnt == 8) begin
                mode_bits = shift_in;
                continuous_read = (shift_in == 8'hA0);
                state = ST_DUMMY;
                bit_cnt = 0;
            end
        end else if (state == ST_DUMMY) begin
            bit_cnt = bit_cnt + 1;
            if (bit_cnt == dummy_cycles) begin
                state = (cmd_reg == 8'h02 || cmd_reg == 8'h32 ? ST_DATA_WRITE : ST_DATA_READ);
                bit_cnt = 0;
                byte_cnt = 0;
                if (cmd_reg == 8'h02 || cmd_reg == 8'h32) io_oe = 4'b0000;
                else if (lanes == 1) io_oe = 4'b0001;
                else if (lanes == 2) io_oe = 4'b0011;
                else io_oe = 4'b1111;
                shift_out = memory[addr_reg];
            end
        end else if (state == ST_DATA_READ) begin
            if (lanes == 1) io_do[0] = shift_out[7];
            else if (lanes == 2) io_do[1:0] = shift_out[7:6];
            else if (lanes == 4) io_do[3:0] = shift_out[7:4];
            shift_out = shift_out << lanes;
            bit_cnt = bit_cnt + lanes;
            if (bit_cnt == 8) begin
                addr_reg = addr_reg + 1;
                shift_out = memory[addr_reg + 1];
                bit_cnt = 0;
                if (!continuous_read && byte_cnt == MEM_SIZE - addr_reg) state = ST_IDLE;
                byte_cnt = byte_cnt + 1;
            end
        end else if (state == ST_DATA_WRITE) begin
            if (lanes == 1) shift_in = {shift_in[6:0], io_di[0]};
            else if (lanes == 2) shift_in = {shift_in[5:0], io_di[1:0]};
            else if (lanes == 4) shift_in = {shift_in[3:0], io_di[3:0]};
            bit_cnt = bit_cnt + lanes;
            if (bit_cnt == 8) begin
                if (addr_reg < MEM_SIZE && (addr_reg % PAGE_SIZE != PAGE_SIZE - 1)) begin
                    memory[addr_reg] = shift_in;
                    addr_reg = addr_reg + 1;
                end
                bit_cnt = 0;
                byte_cnt = byte_cnt + 1;
                wip = 1;
                wip = 0;
            end
        end else if (state == ST_ERASE) begin
            integer j;
            if (cmd_reg == 8'h20) begin
                for (j = addr_reg; j < addr_reg + SECTOR_SIZE; j = j + 1) memory[j] = 8'hFF;
            end else if (cmd_reg == 8'hD8) begin
                for (j = addr_reg; j < addr_reg + 65536; j = j + 1) memory[j] = 8'hFF;
            end else if (cmd_reg == 8'hC7) begin
                for (j = 0; j < MEM_SIZE; j = j + 1) memory[j] = 8'hFF;
            end
            wip = 1;
            wip = 0;
            state = ST_IDLE;
        end else if (state == ST_STATUS) begin
            io_do = shift_out[7];
            shift_out = shift_out << 1;
            bit_cnt = bit_cnt + 1;
            if (bit_cnt == 8) state = ST_IDLE;
        end
    end
end

always @* status_reg[0] = wip;

endmodule