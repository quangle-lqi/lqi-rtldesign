
`timescale 1ns/1ps
module tb_qspi_flash_device;

    reg cs_n = 1;
    reg sck = 0;
    wire [3:0] io;

    // Instantiate QSPI Flash Device
    qspi_flash_device uut (
        .cs_n(cs_n),
        .sck(sck),
        .io(io)
    );

    // Bidirectional IOs driven here
    reg [3:0] io_drive = 4'b0;
    reg io_oe = 0;
    assign io = io_oe ? io_drive : 4'bz;

    // Generate clock
    always #5 sck = ~sck;

    initial begin
        $dumpfile("qspi_flash.vcd");
        $dumpvars(0, tb_qspi_flash_device);

        // Initialize
        cs_n = 1;
        io_oe = 0;
        io_drive = 4'h0;
        #20;

        // Start transaction
        cs_n = 0;

        // Send read command 0x03 bit by bit on io[1]
        io_oe = 1;
        repeat (8) begin
            io_drive = {3'b000, 1'b1}; // Send 0x03 = 0000_0011
            #10;
        end

        // Send 24-bit address 0x000000
        repeat (24) begin
            io_drive = {3'b000, 1'b0};
            #10;
        end

        // Wait and receive data
        io_oe = 0;
        repeat (64) #10;

        cs_n = 1;
        #50;
        $finish;
    end
endmodule
