// qspi_device_tb.v - Simple testbench for qspi_device module
// Tests basic read/write commands in 1, 2, 4 lane modes.
 // For reads: 0x03 (single), 0x3B (dual with dummy 8), 0x6B (quad with dummy 8)
 // For writes: 0x02 (single), 0x32 (quad)
 // Includes WEL (0x06) before writes.
 // Supports multi-lane by driving/reading multiple IOs.
 // Timing: Set data on negedge, sample on posedge.
 // Author: Grok 4 (built by xAI)
 // Date: July 16, 2025

`timescale 1ns / 1ps

module qspi_device_tb;

    // QSPI Signals
    reg qspi_sclk = 0;
    reg qspi_cs_n = 1;
    wire qspi_io0;
    wire qspi_io1;
    wire qspi_io2;
    wire qspi_io3;

    // Master side drivers for inout (multi-lane)
    reg [3:0] master_out = 0;
    reg [3:0] master_oe = 0; // Enable for driving IOs
    assign qspi_io0 = master_oe[0] ? master_out[0] : 1'bz;
    assign qspi_io1 = master_oe[1] ? master_out[1] : 1'bz;
    assign qspi_io2 = master_oe[2] ? master_out[2] : 1'bz;
    assign qspi_io3 = master_oe[3] ? master_out[3] : 1'bz;

    wire [3:0] master_in = {qspi_io3, qspi_io2, qspi_io1, qspi_io0}; // Read from all IOs

    // Instantiate Device (Flash)
    qspi_device dut (
        .qspi_sclk(qspi_sclk),
        .qspi_cs_n(qspi_cs_n),
        .qspi_io0(qspi_io0),
        .qspi_io1(qspi_io1),
        .qspi_io2(qspi_io2),
        .qspi_io3(qspi_io3)
    );

    // Clock generation for SCLK
    always #5 qspi_sclk = ~qspi_sclk; // 100 MHz clock for sim

    // Test sequence
    initial begin
        $dumpfile("qspi_device_tb.vcd");
        $dumpvars(0, qspi_device_tb);
        $dumpvars(0, qspi_device_tb.dut);

        // Initial reset-like state
        qspi_cs_n = 1;
        master_oe = 0;
        #20;

        // Sync to negedge
        @(negedge qspi_sclk);

        // Test Single Lane Read (0x03, no dummy)
        $display("Testing Single Lane Read");
        send_command(8'h03, 24'h000000, 1, 1, 0, 1, 0, 1); // has_addr=1
        read_data(1, 4); // data_lanes=1, read 4 bytes
        #10;

        // Test Write Enable (0x06, single lane)
        $display("Testing Write Enable");
        send_command(8'h06, 24'h000000, 1, 1, 0, 1, 0, 0); // has_addr=0
        qspi_cs_n = 1;
        #10;

        // Single Lane Page Program (0x02, 4 bytes)
        $display("Testing Single Lane Write");
        send_command(8'h02, 24'h000000, 1, 1, 0, 1, 4, 1); // data_len=4, has_addr=1
        send_data(1, 8'hAA);
        send_data(1, 8'hBB);
        send_data(1, 8'hCC);
        send_data(1, 8'hDD);
        qspi_cs_n = 1;
        #10;

        // Single Lane Read back
        $display("Single Lane Read Back");
        send_command(8'h03, 24'h000000, 1, 1, 0, 1, 0, 1);
        read_data(1, 4); // Expect AA BB CC DD
        qspi_cs_n = 1;
        #10;

        // Test Dual Lane Read (0x3B, dummy 8, addr/data dual)
        $display("Testing Dual Lane Read");
        send_command(8'h3B, 24'h000000, 1, 2, 7, 2, 0, 1); // has_addr=1
        read_data(2, 4);
        qspi_cs_n = 1;
        #10;

        // Test Quad Lane Read (0x6B, dummy 8, addr/data quad)
        $display("Testing Quad Lane Read");
        send_command(8'h6B, 24'h000000, 1, 4, 8, 4, 0, 1);
        read_data(4, 4);
        qspi_cs_n = 1;
        #10;

        // Write Enable again for quad write
        send_command(8'h06, 24'h000000, 1, 1, 0, 1, 0, 0);
        qspi_cs_n = 1;
        #10;

        // Quad Lane Page Program (0x32, 4 bytes, addr/data quad)
        $display("Testing Quad Lane Write");
        send_command(8'h32, 24'h000010, 1, 4, 0, 4, 4, 1); // Addr 0x10, has_addr=1
        send_data(4, 8'h11);
        send_data(4, 8'h22);
        send_data(4, 8'h33);
        send_data(4, 8'h44);
        qspi_cs_n = 1;
        #10;

        // Quad Lane Read back
        $display("Quad Lane Read Back");
        send_command(8'h6B, 24'h000010, 1, 4, 8, 4, 0, 1);
        read_data(4, 4); // Expect 11 22 33 44
        qspi_cs_n = 1;
        #10;

        $display("Test Complete");
        $finish;
    end

    // Task to send command + address + dummy, prepare for data
    task send_command;
        input [7:0] cmd;
        input [23:0] addr;
        input [3:0] cmd_lanes; // Always 1
        input [3:0] addr_lanes;
        input [4:0] dummy;
        input [3:0] data_lanes;
        input [31:0] data_len; // >0 write, 0 read
        input has_addr; // 1 if has address
        begin
            qspi_cs_n = 0;
            master_oe = 4'b0001;

            // Cmd always 1 lane

            send_data(1, cmd);

            // Addr if has_addr
            if (has_addr) begin
                master_oe = (1 << addr_lanes) - 1;
                send_data(addr_lanes, addr[23:16]);
                send_data(addr_lanes, addr[15:8]);
                send_data(addr_lanes, addr[7:0]);
            end

            // Dummy cycles (no drive)
            master_oe = 4'b0000;
            repeat (dummy) #10;

            // For write, master drives, for read, device drives
            if (data_len > 0) master_oe = (1 << data_lanes) - 1;
            else master_oe = 4'b0000;
        end
    endtask

    // Task to send data byte(s) with given lanes (for write phase)
    task send_data;
        input [3:0] data_lanes;
        input [7:0] data;
        begin
            if (data_lanes == 1) begin
                master_out[0] = data[7];
                #10;
                master_out[0] = data[6];
                #10;
                master_out[0] = data[5];
                #10;
                master_out[0] = data[4];
                #10;
                master_out[0] = data[3];
                #10;
                master_out[0] = data[2];
                #10;
                master_out[0] = data[1];
                #10;
                master_out[0] = data[0];
                #10;
            end else if (data_lanes == 2) begin
                master_out[1] = data[7];
                master_out[0] = data[6];
                #10;
                master_out[1] = data[5];
                master_out[0] = data[4];
                #10;
                master_out[1] = data[3];
                master_out[0] = data[2];
                #10;
                master_out[1] = data[1];
                master_out[0] = data[0];
                #10;
            end else if (data_lanes == 4) begin
                master_out[3] = data[7];
                master_out[2] = data[6];
                master_out[1] = data[5];
                master_out[0] = data[4];
                #10;
                master_out[3] = data[3];
                master_out[2] = data[2];
                master_out[1] = data[1];
                master_out[0] = data[0];
                #10;
            end
        end
    endtask

    // Task to read n bytes with given lanes (for read phase)
    task read_data;
        input [3:0] data_lanes;
        input [31:0] n;
        reg [7:0] received_byte;
        integer byte_count;
        begin
            for (byte_count = 0; byte_count < n; byte_count = byte_count + 1) begin
                received_byte = 8'h00;
                if (data_lanes == 1) begin
                    #10;
                    received_byte[7] = master_in[1];
                    #10;
                    received_byte[6] = master_in[1];
                    #10;
                    received_byte[5] = master_in[1];
                    #10;
                    received_byte[4] = master_in[1];
                    #10;
                    received_byte[3] = master_in[1];
                    #10;
                    received_byte[2] = master_in[1];
                    #10;
                    received_byte[1] = master_in[1];
                    #10;
                    received_byte[0] = master_in[1];
                end else if (data_lanes == 2) begin
                    #10;
                    received_byte[7] = master_in[1];
                    received_byte[6] = master_in[0];
                    #10;
                    received_byte[5] = master_in[1];
                    received_byte[4] = master_in[0];
                    #10;
                    received_byte[3] = master_in[1];
                    received_byte[2] = master_in[0];
                    #10;
                    received_byte[1] = master_in[1];
                    received_byte[0] = master_in[0];
                end else if (data_lanes == 4) begin
                    #10;
                    received_byte[7] = master_in[3];
                    received_byte[6] = master_in[2];
                    received_byte[5] = master_in[1];
                    received_byte[4] = master_in[0];
                    #10;
                    received_byte[3] = master_in[3];
                    received_byte[2] = master_in[2];
                    received_byte[1] = master_in[1];
                    received_byte[0] = master_in[0];
                end
                $display("Read Byte %d: %h", byte_count + 1, received_byte);
            end
            qspi_cs_n = 1;
        end
    endtask

endmodule