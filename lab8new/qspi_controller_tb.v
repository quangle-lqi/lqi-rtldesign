// qspi_controller_tb.v - Testbench for Simplified QSPI Controller
// Tests XIP mode (default after reset) with single lane read, and basic Command mode.
// AXI data width 32 bits.
// Author: Grok 4 (built by xAI)
// Date: July 16, 2025
// Version: 1.1 (updated for simplified RTL, no DMA)

`timescale 1ns / 1ps

module qspi_controller_tb;

    // Parameters
    localparam AXI_DATA_WIDTH = 32;
    localparam AXI_ADDR_WIDTH = 32;
    localparam AXI_ID_WIDTH = 4;
    localparam FIFO_DEPTH_LOG = 4;

    // Clock and Reset
    reg clk = 0;
    reg rst_n = 0;
    always #5 clk = ~clk;

    // Interrupt
    wire irq;

    // APB Signals
    reg psel = 0;
    reg penable = 0;
    reg [11:0] paddr = 0;
    reg pwrite = 0;
    reg [31:0] pwdata = 0;
    wire pready;
    wire [31:0] prdata;
    wire pslverr;

    // AXI Slave (XIP) - TB acts as master
    reg [AXI_ID_WIDTH-1:0] axis_awid = 0;
    reg [AXI_ADDR_WIDTH-1:0] axis_awaddr = 0;
    reg [7:0] axis_awlen = 0;
    reg [2:0] axis_awsize = 0;
    reg [1:0] axis_awburst = 0;
    reg axis_awlock = 0;
    reg [3:0] axis_awcache = 0;
    reg [2:0] axis_awprot = 0;
    reg axis_awvalid = 0;
    wire axis_awready;
    reg [AXI_DATA_WIDTH-1:0] axis_wdata = 0;
    reg [AXI_DATA_WIDTH/8-1:0] axis_wstrb = 0;
    reg axis_wlast = 0;
    reg axis_wvalid = 0;
    wire axis_wready;
    wire [AXI_ID_WIDTH-1:0] axis_bid;
    wire [1:0] axis_bresp;
    wire axis_bvalid;
    reg axis_bready = 0;
    reg [AXI_ID_WIDTH-1:0] axis_arid = 0;
    reg [AXI_ADDR_WIDTH-1:0] axis_araddr = 0;
    reg [7:0] axis_arlen = 0;
    reg [2:0] axis_arsize = 0;
    reg [1:0] axis_arburst = 0;
    reg axis_arlock = 0;
    reg [3:0] axis_arcache = 0;
    reg [2:0] axis_arprot = 0;
    reg axis_arvalid = 0;
    wire axis_arready;
    wire [AXI_ID_WIDTH-1:0] axis_rid;
    wire [AXI_DATA_WIDTH-1:0] axis_rdata;
    wire [1:0] axis_rresp;
    wire axis_rlast;
    wire axis_rvalid;
    reg axis_rready = 0;

    // QSPI Wires
    wire qspi_sclk;
    wire qspi_cs_n;
    wire qspi_io0;
    wire qspi_io1;
    wire qspi_io2;
    wire qspi_io3;

    // Instantiate Controller
    qspi_controller #(
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        .FIFO_DEPTH_LOG(FIFO_DEPTH_LOG)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .irq(irq),
        .psel(psel),
        .penable(penable),
        .paddr(paddr),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pready(pready),
        .prdata(prdata),
        .pslverr(pslverr),
        .axis_awid(axis_awid),
        .axis_awaddr(axis_awaddr),
        .axis_awlen(axis_awlen),
        .axis_awsize(axis_awsize),
        .axis_awburst(axis_awburst),
        .axis_awlock(axis_awlock),
        .axis_awcache(axis_awcache),
        .axis_awprot(axis_awprot),
        .axis_awvalid(axis_awvalid),
        .axis_awready(axis_awready),
        .axis_wdata(axis_wdata),
        .axis_wstrb(axis_wstrb),
        .axis_wlast(axis_wlast),
        .axis_wvalid(axis_wvalid),
        .axis_wready(axis_wready),
        .axis_bid(axis_bid),
        .axis_bresp(axis_bresp),
        .axis_bvalid(axis_bvalid),
        .axis_bready(axis_bready),
        .axis_arid(axis_arid),
        .axis_araddr(axis_araddr),
        .axis_arlen(axis_arlen),
        .axis_arsize(axis_arsize),
        .axis_arburst(axis_arburst),
        .axis_arlock(axis_arlock),
        .axis_arcache(axis_arcache),
        .axis_arprot(axis_arprot),
        .axis_arvalid(axis_arvalid),
        .axis_arready(axis_arready),
        .axis_rid(axis_rid),
        .axis_rdata(axis_rdata),
        .axis_rresp(axis_rresp),
        .axis_rlast(axis_rlast),
        .axis_rvalid(axis_rvalid),
        .axis_rready(axis_rready),
        .qspi_sclk(qspi_sclk),
        .qspi_cs_n(qspi_cs_n),
        .qspi_io0(qspi_io0),
        .qspi_io1(qspi_io1),
        .qspi_io2(qspi_io2),
        .qspi_io3(qspi_io3)
    );

    // Instantiate Device (Flash)
    qspi_device flash (
        .qspi_sclk(qspi_sclk),
        .qspi_cs_n(qspi_cs_n),
        .qspi_io0(qspi_io0),
        .qspi_io1(qspi_io1),
        .qspi_io2(qspi_io2),
        .qspi_io3(qspi_io3)
    );

    // APB Write Task
    task apb_write;
        input [11:0] addr;
        input [31:0] data;
        begin
            paddr = addr;
            pwdata = data;
            pwrite = 1;
            psel = 1;
            #10 penable = 1;
            wait (pready);
            #10 penable = 0;
            psel = 0;
        end
    endtask

    // APB Read Task
    task apb_read;
        input [11:0] addr;
        output [31:0] rdata;
        begin
            paddr = addr;
            pwrite = 0;
            psel = 1;
            #10 penable = 1;
            wait (pready);
            rdata = prdata;
            #10 penable = 0;
            psel = 0;
        end
    endtask

    // AXI Read Task for XIP
    task axi_read;
        input [AXI_ADDR_WIDTH-1:0] addr;
        input [7:0] len;
        begin
            axis_araddr = addr;
            axis_arlen = len - 1;
            axis_arsize = 2; // 4 bytes for 32-bit
            axis_arburst = 1; // INCR
            axis_arvalid = 1;
            wait (axis_arready);
            #10 axis_arvalid = 0;
            axis_rready = 1;
            repeat (len) begin
                wait (axis_rvalid);
                $display("AXI Read Data: %h", axis_rdata);
                #10;
            end
            axis_rready = 0;
        end
    endtask

    // Test Sequence
    initial begin
       $dumpfile("qspi_controller_tb.vcd");
       $dumpvars(0, qspi_controller_tb);
       $dumpvars(0, qspi_controller_tb.dut);
       $dumpvars(0, qspi_controller_tb.flash);        
        // Reset
        #20 rst_n = 1;

        // No programming needed, default XIP single lane
        // Test XIP read immediately after reset
        axi_read(32'h00000000, 4); // Read 4 beats (16 bytes) from address 0
        #500;

        // Optional: Test Command mode - Write Enable (0x06)
        apb_write(12'h009, 32'h00000000); // CMD_CFG: single lane, no addr, no data
        apb_write(12'h00A, 32'h00000006); // OPCODE = 0x06
        apb_write(12'h001, 32'h00000100); // TRIGGER = 1 (bit 8), disable XIP temporarily if needed
        #100; // Wait for completion
        apb_read(12'h002, status); if (status[2]) $display("Write Enable Done");

        // Page Program (0x02) with FIFO, single lane, 4 bytes data at addr 0x000000
        apb_write(12'h009, 32'h00000101); // CMD_CFG: single all, 3 addr bytes, DIR=0 (write)
        apb_write(12'h00A, 32'h00000002); // OPCODE = 0x02
        apb_write(12'h00B, 32'h00000000); // ADDR = 0
        apb_write(12'h00C, 32'h00000004); // LEN = 4
        apb_write(12'h011, 32'h000000DD); // FIFO_TX byte 1
        apb_write(12'h011, 32'h000000CC); // byte 2
        apb_write(12'h011, 32'h000000BB); // byte 3
        apb_write(12'h011, 32'h000000AA); // byte 4
        apb_write(12'h001, 32'h00000100); // TRIGGER
        #500; // Wait
        apb_read(12'h002, status); if (status[2]) $display("Page Program Done");

        // Read Data (0x03) with FIFO
        apb_write(12'h009, 32'h00000141); // DIR=1 (read)
        apb_write(12'h00A, 32'h00000003);
        apb_write(12'h00B, 32'h00000000);
        apb_write(12'h00C, 32'h00000004);
        apb_write(12'h001, 32'h00000100); // TRIGGER
        #500;
        apb_read(12'h012, rdata); $display("Read Byte 1: %h", rdata[7:0]);
        apb_read(12'h012, rdata); $display("Read Byte 2: %h", rdata[7:0]);
        apb_read(12'h012, rdata); $display("Read Byte 3: %h", rdata[7:0]);
        apb_read(12'h012, rdata); $display("Read Byte 4: %h", rdata[7:0]);

        // Re-enable XIP if disabled
        apb_write(12'h001, 32'h00000002); // XIP_EN = 1
        axi_read(32'h00000000, 4); // Read again via XIP

        $display("Test Complete");
        $finish;
    end

    reg [31:0] status, rdata;

endmodule