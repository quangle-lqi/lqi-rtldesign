// qspi_controller_tb.v - Testbench for QSPI Controller connected to QSPI Device (NOR Flash model)
// Tests Command mode (with FIFO and DMA) and XIP mode
// Assumptions:
// - AXI data width 64-bit
// - Simple AXI slave model for DMA (DRAM simulation)
// - APB master simulation in TB
// - AXI master simulation in TB for XIP
// - Clock period 10ns
// - Basic tests: Write data via Command mode, read back via XIP and Command

`timescale 1ns / 1ps

module qspi_controller_tb;

    // Parameters
    localparam AXI_DATA_WIDTH = 64;
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

    // AXI Master (DMA) - Simple slave model for DRAM
    wire [AXI_ID_WIDTH-1:0] axim_awid;
    wire [AXI_ADDR_WIDTH-1:0] axim_awaddr;
    wire [7:0] axim_awlen;
    wire [2:0] axim_awsize;
    wire [1:0] axim_awburst;
    wire axim_awlock;
    wire [3:0] axim_awcache;
    wire [2:0] axim_awprot;
    wire axim_awvalid;
    reg axim_awready = 0;
    wire [AXI_DATA_WIDTH-1:0] axim_wdata;
    wire [AXI_DATA_WIDTH/8-1:0] axim_wstrb;
    wire axim_wlast;
    wire axim_wvalid;
    reg axim_wready = 0;
    reg [AXI_ID_WIDTH-1:0] axim_bid = 0;
    reg [1:0] axim_bresp = 0;
    reg axim_bvalid = 0;
    wire axim_bready;
    wire [AXI_ID_WIDTH-1:0] axim_arid;
    wire [AXI_ADDR_WIDTH-1:0] axim_araddr;
    wire [7:0] axim_arlen;
    wire [2:0] axim_arsize;
    wire [1:0] axim_arburst;
    wire axim_arlock;
    wire [3:0] axim_arcache;
    wire [2:0] axim_arprot;
    wire axim_arvalid;
    reg axim_arready = 0;
    reg [AXI_ID_WIDTH-1:0] axim_rid = 0;
    reg [AXI_DATA_WIDTH-1:0] axim_rdata = 0;
    reg [1:0] axim_rresp = 0;
    reg axim_rlast = 0;
    reg axim_rvalid = 0;
    wire axim_rready;

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
        .axim_awid(axim_awid),
        .axim_awaddr(axim_awaddr),
        .axim_awlen(axim_awlen),
        .axim_awsize(axim_awsize),
        .axim_awburst(axim_awburst),
        .axim_awlock(axim_awlock),
        .axim_awcache(axim_awcache),
        .axim_awprot(axim_awprot),
        .axim_awvalid(axim_awvalid),
        .axim_awready(axim_awready),
        .axim_wdata(axim_wdata),
        .axim_wstrb(axim_wstrb),
        .axim_wlast(axim_wlast),
        .axim_wvalid(axim_wvalid),
        .axim_wready(axim_wready),
        .axim_bid(axim_bid),
        .axim_bresp(axim_bresp),
        .axim_bvalid(axim_bvalid),
        .axim_bready(axim_bready),
        .axim_arid(axim_arid),
        .axim_araddr(axim_araddr),
        .axim_arlen(axim_arlen),
        .axim_arsize(axim_arsize),
        .axim_arburst(axim_arburst),
        .axim_arlock(axim_arlock),
        .axim_arcache(axim_arcache),
        .axim_arprot(axim_arprot),
        .axim_arvalid(axim_arvalid),
        .axim_arready(axim_arready),
        .axim_rid(axim_rid),
        .axim_rdata(axim_rdata),
        .axim_rresp(axim_rresp),
        .axim_rlast(axim_rlast),
        .axim_rvalid(axim_rvalid),
        .axim_rready(axim_rready),
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

    // Simple DRAM model for AXI Master (DMA)
    reg [7:0] dram [0:1023]; // Small DRAM simulation, 1KB
    reg [7:0] dma_burst_cnt;
    always @(posedge clk) begin
        if (axim_awvalid) begin
            axim_awready <= 1;
        end else axim_awready <= 0;
        if (axim_awvalid && axim_awready) dma_burst_cnt <= 0;
        if (axim_wvalid && axim_wready) begin
            // Write to DRAM
            dram[axim_awaddr + dma_burst_cnt* (AXI_DATA_WIDTH/8)] <= axim_wdata[7:0]; // Byte write, simplify
            // Extend for full width
            dma_burst_cnt <= dma_burst_cnt + 1;
            if (axim_wlast) axim_bvalid <= 1;
        end
        axim_wready <= 1; // Always ready
        if (axim_bvalid && axim_bready) axim_bvalid <= 0;
        axim_bid <= axim_awid;
        axim_bresp <= 2'b00;

        if (axim_arvalid) begin
            axim_arready <= 1;
        end else axim_arready <= 0;
        if (axim_arvalid && axim_arready) dma_burst_cnt <= 0;
        if (axim_rready) begin
            axim_rvalid <= 1;
            axim_rdata <= {8{dram[axim_araddr + dma_burst_cnt * (AXI_DATA_WIDTH/8)]}}; // Replicate byte
            dma_burst_cnt <= dma_burst_cnt + 1;
            axim_rlast <= (dma_burst_cnt == axim_arlen);
            if (axim_rlast) axim_rvalid <= 0;
        end
        axim_rid <= axim_arid;
        axim_rresp <= 2'b00;
    end

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
            axis_arsize = 3; // 8 bytes
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
        // Reset
        #20 rst_n = 1;

        // Configure
        apb_write(12'h014, 32'h01);
        apb_write(12'h004, 32'h01);

        // Write Enable
        apb_write(12'h024, 32'h00000000);
        apb_write(12'h028, 32'h00000006);
        apb_write(12'h004, 32'h00000101);
        #100;
        apb_read(12'h008, status); if (status[2]) $display("Write Enable Done");

        // Page Program with FIFO, write 4 bytes separately
        apb_write(12'h024, 32'h00000101);
        apb_write(12'h028, 32'h00000002);
        apb_write(12'h02C, 32'h00000000);
        apb_write(12'h030, 32'h00000004);
        apb_write(12'h044, 32'h000000DD);
        apb_write(12'h044, 32'h000000CC);
        apb_write(12'h044, 32'h000000BB);
        apb_write(12'h044, 32'h000000AA);
        apb_write(12'h004, 32'h00000101);
        #500;
        apb_read(12'h008, status); if (status[2]) $display("Page Program FIFO Done");

        // Read Data
        apb_write(12'h024, 32'h00000141);
        apb_write(12'h028, 32'h00000003);
        apb_write(12'h02C, 32'h00000000);
        apb_write(12'h030, 32'h00000004);
        apb_write(12'h004, 32'h00000101);
        #500;
        apb_read(12'h048, rdata); $display("Read Byte 1: %h", rdata[7:0]);
        apb_read(12'h048, rdata); $display("Read Byte 2: %h", rdata[7:0]);
        apb_read(12'h048, rdata); $display("Read Byte 3: %h", rdata[7:0]);
        apb_read(12'h048, rdata); $display("Read Byte 4: %h", rdata[7:0]);

        // DMA test - Write Enable
        apb_write(12'h028, 32'h00000006);
        apb_write(12'h004, 32'h00000101);
        #100;
        // Page Program with DMA
        apb_write(12'h004, 32'h00000201);
        apb_write(12'h038, 32'h00000003);
        apb_write(12'h03C, 32'h00000000);
        apb_write(12'h040, 32'h00000004);
        apb_write(12'h028, 32'h00000002);
        apb_write(12'h02C, 32'h00000004);
        apb_write(12'h030, 32'h00000004);
        apb_write(12'h004, 32'h00000301);
        #1000;
        apb_read(12'h008, status); if (status[3]) $display("DMA Program Done");

        // XIP
        apb_write(12'h01C, 32'h00000022);
        apb_write(12'h020, 32'h000000EB);
        apb_write(12'h004, 32'h00000002);
        #100;
        axi_read(32'h00000000, 8);
        #1000;

        $display("Test Complete");
        $finish;
    end
    
    reg [31:0] status, rdata;

endmodule