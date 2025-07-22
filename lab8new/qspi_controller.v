// qspi_controller.v - Simplified Quad SPI Controller IP Core
// Supports Execute-In-Place (XIP) mode for memory-mapped access and Command mode for programmable operations.
// CSR access via APB slave, XIP via AXI slave (read-only).
// Default after reset: XIP mode with single lane, standard read (0x03), 3 address bytes, no dummy, ready for immediate read.
// AXI data width set to 32 bits for simplicity.
// Author: Grok 4 (built by xAI)
// Date: July 16, 2025
// Version: 1.1 (simplified, no DMA, single lane default XIP)

module qspi_controller #(
    parameter AXI_DATA_WIDTH = 32,  // Width of AXI data bus (simplified to 32 bits)
    parameter AXI_ADDR_WIDTH = 32,  // Width of AXI address bus
    parameter AXI_ID_WIDTH   = 4,   // Width of AXI ID bus
    parameter FIFO_DEPTH_LOG = 4,   // Log2 of FIFO depth for TX/RX buffers
    parameter FIFO_DEPTH     = 1 << FIFO_DEPTH_LOG  // Calculated FIFO depth
) (
    input  wire clk,    // System clock input
    input  wire rst_n,  // Active-low asynchronous reset

    output reg irq,     // Interrupt request output

    // APB Slave Interface for CSR access (configuration and status)
    input  wire             psel,       // APB select
    input  wire             penable,    // APB enable
    input  wire [11:0]      paddr,      // APB address (12 bits for 4KB space)
    input  wire             pwrite,     // APB write enable
    input  wire [31:0]      pwdata,     // APB write data
    output wire             pready,     // APB ready (always 1 for single-cycle transfers)
    output wire [31:0]      prdata,     // APB read data
    output wire             pslverr,    // APB slave error (always 0 in this implementation)

    // AXI4 Slave Interface for XIP mode (memory-mapped reads only)
    // Write Channel (not supported)
    input  wire [AXI_ID_WIDTH-1:0]    axis_awid,
    input  wire [AXI_ADDR_WIDTH-1:0]  axis_awaddr,
    input  wire [7:0]                 axis_awlen,
    input  wire [2:0]                 axis_awsize,
    input  wire [1:0]                 axis_awburst,
    input  wire                       axis_awlock,
    input  wire [3:0]                 axis_awcache,
    input  wire [2:0]                 axis_awprot,
    input  wire                       axis_awvalid,
    output wire                       axis_awready,
    input  wire [AXI_DATA_WIDTH-1:0]  axis_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0]axis_wstrb,
    input  wire                       axis_wlast,
    input  wire                       axis_wvalid,
    output wire                       axis_wready,
    output wire [AXI_ID_WIDTH-1:0]    axis_bid,
    output wire [1:0]                 axis_bresp,
    output wire                       axis_bvalid,
    input  wire                       axis_bready,
    // Read Channel
    input  wire [AXI_ID_WIDTH-1:0]    axis_arid,
    input  wire [AXI_ADDR_WIDTH-1:0]  axis_araddr,
    input  wire [7:0]                 axis_arlen,
    input  wire [2:0]                 axis_arsize,
    input  wire [1:0]                 axis_arburst,
    input  wire                       axis_arlock,
    input  wire [3:0]                 axis_arcache,
    input  wire [2:0]                 axis_arprot,
    input  wire                       axis_arvalid,
    output wire                       axis_arready,
    output reg [AXI_ID_WIDTH-1:0]     axis_rid,
    output reg [AXI_DATA_WIDTH-1:0]   axis_rdata,
    output reg [1:0]                  axis_rresp,
    output reg                        axis_rlast,
    output reg                        axis_rvalid,
    input  wire                       axis_rready,

    // QSPI pins
    output reg qspi_sclk,
    output reg qspi_cs_n,
    inout  wire qspi_io0,
    inout  wire qspi_io1,
    inout  wire qspi_io2,
    inout  wire qspi_io3
);

// Internal CSR registers with default values for XIP single lane
reg [31:0] id_reg = 32'h00100101; // Device ID and version
reg [31:0] ctrl_reg = 32'h00000002; // Default: XIP_EN = 1
reg [31:0] status_reg = 0; // Status register (busy, done, etc.)
reg [31:0] int_en_reg = 0; // Interrupt enable mask
reg [31:0] int_stat_reg = 0; // Interrupt status (RW1C)
reg [31:0] clk_div_reg = 32'h00000001; // Default divider = 1 for sim
reg [31:0] cs_ctrl_reg = 32'h00000001; // Default: CS_AUTO = 1
reg [31:0] xip_cfg_reg = 32'h00000000; // Default: ADDR_BYTES = 3, DATA_LANES = 0, DUMMY = 0
reg [31:0] xip_cmd_reg = 32'h00000003; // Default: READ_OP = 0x03
reg [31:0] cmd_cfg_reg = 0; // Command mode configuration (lanes, direction)
reg [31:0] cmd_op_reg = 0; // Command opcode and mode bits
reg [31:0] cmd_addr_reg = 0; // Command flash address
reg [31:0] cmd_len_reg = 0; // Command data length in bytes
reg [31:0] cmd_dummy_reg = 0; // Additional dummy cycles for command
reg [31:0] err_stat_reg = 0; // Error status (timeout, overrun, etc.)

// FIFO buffers for command mode
reg [7:0] tx_fifo [FIFO_DEPTH-1:0]; // TX FIFO buffer
reg [FIFO_DEPTH_LOG-1:0] tx_wr_ptr = 0, tx_rd_ptr = 0; // TX write/read pointers
reg [7:0] rx_fifo [FIFO_DEPTH-1:0]; // RX FIFO buffer
reg [FIFO_DEPTH_LOG-1:0] rx_wr_ptr = 0, rx_rd_ptr = 0; // RX write/read pointers
wire tx_full = ((tx_wr_ptr + 1) == tx_rd_ptr); // TX FIFO full flag
wire tx_empty = (tx_wr_ptr == tx_rd_ptr); // TX FIFO empty flag
wire rx_full = ((rx_wr_ptr + 1) == rx_rd_ptr); // RX FIFO full flag
wire rx_empty = (rx_wr_ptr == rx_rd_ptr); // RX FIFO empty flag
reg [FIFO_DEPTH_LOG:0] tx_level, rx_level; // Current FIFO levels

// APB interface - Always ready, no errors
assign pready = 1'b1;
assign pslverr = 0;

reg [31:0] pr_data_reg; // Temporary register for APB read data
assign prdata = pr_data_reg; // Assign to output port

// Combinatorial logic for APB read data selection
always @* begin
    pr_data_reg = 0;
    if (psel && !pwrite && penable) begin
        if (paddr[11:2] == 10'h0) pr_data_reg = id_reg;
        else if (paddr[11:2] == 10'h1) pr_data_reg = ctrl_reg;
        else if (paddr[11:2] == 10'h2) pr_data_reg = status_reg;
        else if (paddr[11:2] == 10'h3) pr_data_reg = int_en_reg;
        else if (paddr[11:2] == 10'h4) pr_data_reg = int_stat_reg;
        else if (paddr[11:2] == 10'h5) pr_data_reg = clk_div_reg;
        else if (paddr[11:2] == 10'h6) pr_data_reg = cs_ctrl_reg;
        else if (paddr[11:2] == 10'h7) pr_data_reg = xip_cfg_reg;
        else if (paddr[11:2] == 10'h8) pr_data_reg = xip_cmd_reg;
        else if (paddr[11:2] == 10'h9) pr_data_reg = cmd_cfg_reg;
        else if (paddr[11:2] == 10'hA) pr_data_reg = cmd_op_reg;
        else if (paddr[11:2] == 10'hB) pr_data_reg = cmd_addr_reg;
        else if (paddr[11:2] == 10'hC) pr_data_reg = cmd_len_reg;
        else if (paddr[11:2] == 10'hD) pr_data_reg = cmd_dummy_reg;
        else if (paddr[11:2] == 10'h12) pr_data_reg = rx_empty ? 0 : {24'b0, rx_fifo[rx_rd_ptr]};
        else if (paddr[11:2] == 10'h13) pr_data_reg = {22'b0, rx_full, tx_empty, rx_level[3:0], tx_level[3:0]};
        else if (paddr[11:2] == 10'h14) pr_data_reg = err_stat_reg;
    end
end

// Clocked logic for APB writes and FIFO updates
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset all registers to default values for XIP single lane
        ctrl_reg <= 32'h00000002; // XIP_EN = 1
        int_en_reg <= 0;
        clk_div_reg <= 32'h00000001; // Default divider = 1
        cs_ctrl_reg <= 32'h00000001; // CS_AUTO = 1
        xip_cfg_reg <= 32'h00000000; // ADDR_BYTES = 3, DATA_LANES = 0, DUMMY = 0
        xip_cmd_reg <= 32'h00000003; // READ_OP = 0x03
        cmd_cfg_reg <= 0;
        cmd_op_reg <= 0;
        cmd_addr_reg <= 0;
        cmd_len_reg <= 0;
        cmd_dummy_reg <= 0;
        status_reg <= 0;
        int_stat_reg <= 0;
        err_stat_reg <= 0;
        tx_wr_ptr <= 0;
        tx_rd_ptr <= 0;
        rx_wr_ptr <= 0;
        rx_rd_ptr <= 0;
        io_oe <= 0;
        io_do <= 0;
        shift_out <= 0;
        shift_in <= 0;
        lanes <= 1; // Default single lane
        bit_cnt <= 0;
        cnt <= 0;
        xip_busy <= 0;
        xip_id <= 0;
        xip_len <= 0;
        xip_addr <= 0;
        xip_burst_cnt <= 0;
        timeout_cnt <= 0;
        qspi_sclk <= 0;
        qspi_cs_n <= 1;
        cmd_trigger_d <= 0;
        div_cnt <= 0;
        sclk_en <= 0;
        state <= IDLE;
    end else if (psel && penable) begin
        if (pwrite) begin
            // Write to CSR or TX FIFO
            if (paddr[11:2] == 10'h1) ctrl_reg <= pwdata;
            else if (paddr[11:2] == 10'h3) int_en_reg <= pwdata;
            else if (paddr[11:2] == 10'h4) int_stat_reg <= int_stat_reg & ~pwdata;
            else if (paddr[11:2] == 10'h5) clk_div_reg <= pwdata;
            else if (paddr[11:2] == 10'h6) cs_ctrl_reg <= pwdata;
            else if (paddr[11:2] == 10'h7) xip_cfg_reg <= pwdata;
            else if (paddr[11:2] == 10'h8) xip_cmd_reg <= pwdata;
            else if (paddr[11:2] == 10'h9) cmd_cfg_reg <= pwdata;
            else if (paddr[11:2] == 10'hA) cmd_op_reg <= pwdata;
            else if (paddr[11:2] == 10'hB) cmd_addr_reg <= pwdata;
            else if (paddr[11:2] == 10'hC) cmd_len_reg <= pwdata;
            else if (paddr[11:2] == 10'hD) cmd_dummy_reg <= pwdata;
            else if (paddr[11:2] == 10'h11) if (!tx_full) begin
                tx_fifo[tx_wr_ptr] <= pwdata[7:0];
                tx_wr_ptr <= tx_wr_ptr + 1;
            end
        end else begin
            // Read from RX FIFO, advance pointer
            if (paddr[11:2] == 10'h12) if (!rx_empty) rx_rd_ptr <= rx_rd_ptr + 1;
        end
    end
end

// Combinatorial FIFO level calculation
always @* begin
    tx_level = tx_wr_ptr - tx_rd_ptr;
    rx_level = rx_wr_ptr - rx_rd_ptr;
end

// Combinatorial interrupt generation
always @* irq = | (int_stat_reg & int_en_reg);

// Clock divider logic for generating SCLK from clk
reg [7:0] div_cnt = 0; // Divider counter
reg sclk_en = 0; // Enable signal for SCLK toggle
always @(posedge clk or negedge rst_n) if (!rst_n) div_cnt <= 0;
else if (div_cnt == clk_div_reg[7:0]) div_cnt <= 0;
else div_cnt <= div_cnt + 1;
always @(posedge clk) sclk_en <= (div_cnt == 0); // Pulse when divider resets
always @(posedge clk) if (sclk_en) qspi_sclk <= ~qspi_sclk; // Toggle SCLK

// Chip select control logic
always @(posedge clk) if (cs_ctrl_reg[0]) qspi_cs_n <= status_reg[0] ? 0 : 1; // Auto mode based on busy
else qspi_cs_n <= cs_ctrl_reg[1]; // Manual mode

// QSPI IO handling
reg [3:0] io_oe = 0, io_do = 0; // Output enable and data for IO pins
wire [3:0] io_di = {qspi_io3, qspi_io2, qspi_io1, qspi_io0}; // Input data from IO pins
assign qspi_io0 = io_oe[0] ? io_do[0] : 1'bz; // Tri-state IO0
assign qspi_io1 = io_oe[1] ? io_do[1] : 1'bz; // Tri-state IO1
assign qspi_io2 = io_oe[2] ? io_do[2] : 1'bz; // Tri-state IO2
assign qspi_io3 = io_oe[3] ? io_do[3] : 1'bz; // Tri-state IO3

// Transaction state machine definitions
localparam IDLE = 4'h0, CMD = 4'h1, ADDR = 4'h2, MODE = 4'h3, DUMMY = 4'h4, DATA = 4'h5, DONE = 4'h6; // State codes
reg [3:0] state = IDLE, next_state; // Current and next state
reg [31:0] cnt = 0; // General counter for bytes/cycles
reg [4:0] bit_cnt = 0; // Bit counter within byte
reg [3:0] lanes = 1; // Number of active lanes (default single)
reg [7:0] shift_out = 0; // Shift register for output data
reg [7:0] shift_in = 0; // Shift register for input data
reg shift_en = 0, rx_en = 0, tx_en = 0; // Enable signals for shifting, RX, TX
reg cmd_trigger_d = 0; // Delayed trigger for edge detection
always @(posedge clk) cmd_trigger_d <= ctrl_reg[8]; // Delay for trigger

wire trigger = (cmd_trigger_d && !ctrl_reg[8]); // Detect rising edge on trigger bit

always @(posedge clk) if (trigger) ctrl_reg[8] <= 0; // Self-clear trigger bit

always @(posedge clk or negedge rst_n) if (!rst_n) state <= IDLE;
else state <= next_state;

reg [31:0] addr_bytes; // Number of address bytes
always @* addr_bytes = (ctrl_reg[1] ? xip_cfg_reg[1:0] == 0 ? 3 : 4 : cmd_cfg_reg[7:6] == 1 ? 3 : 4); // XIP or command

// Combinatorial next state logic
always @* begin
    next_state = state;
    if (state == IDLE) begin
        if (trigger && !ctrl_reg[1]) next_state = CMD;
    end else if (state == CMD) begin
        if (bit_cnt == 8) next_state = ADDR;
    end else if (state == ADDR) begin
        if (cnt == addr_bytes) next_state = cmd_cfg_reg[8] ? MODE : DUMMY;
    end else if (state == MODE) begin
        if (bit_cnt == 8) next_state = DUMMY;
    end else if (state == DUMMY) begin
        if (cnt == cmd_dummy_reg) next_state = DATA;
    end else if (state == DATA) begin
        if (cnt == cmd_len_reg) next_state = DONE;
    end else if (state == DONE) begin
        next_state = IDLE;
    end
end

// Clocked counter and bit count update
always @(posedge clk) if (sclk_en) begin
    if (state != next_state) cnt <= 0;
    else cnt <= cnt + 1;
    bit_cnt <= shift_en ? bit_cnt + lanes : 0;
end

// Combinatorial lane selection and enable signals
always @* begin
    lanes = 1;
    tx_en = 0;
    rx_en = 0;
    shift_en = 0;
    if (ctrl_reg[1]) begin // XIP mode, single lane default
        lanes = 1;
        tx_en = 0;
        rx_en = 1;
    end else if (state == CMD) begin
        lanes = 1;
        tx_en = 1;
    end else if (state == ADDR) begin
        lanes = 1;
        tx_en = 1;
    end else if (state == DATA) begin
        lanes = 1;
        tx_en = ~cmd_cfg_reg[13];
        rx_en = cmd_cfg_reg[13];
    end else if (state == DUMMY) begin
        lanes = 0;
    end else if (state == MODE) begin
        lanes = 1; tx_en = 1;
    end
    shift_en = (lanes > 0) && sclk_en;
end

// Clocked shift logic for output/input
always @(posedge clk) if (shift_en) begin
    io_do[0] <= shift_out[7];
    io_oe <= tx_en ? 4'b0001 : 4'b0000;
    shift_out <= shift_out << 1;
    shift_in <= {io_di[1], shift_in[7:1]}; // MSB first input on IO1
end

// Clocked load for shift_out register
always @(posedge clk) if (bit_cnt == 0) begin
    if (state == CMD) shift_out <= cmd_op_reg[7:0];
    else if (state == ADDR) shift_out <= cmd_addr_reg >> ((addr_bytes - cnt - 1) * 8);
    else if (state == MODE) shift_out <= cmd_op_reg[15:8];
    else if (state == DATA && tx_en) shift_out <= tx_fifo[tx_rd_ptr];
    else shift_out <= 0;
end

// Clocked storage for input shift_in to RX FIFO
always @(posedge clk) if (rx_en && bit_cnt == 8) begin
    rx_fifo[rx_wr_ptr] <= shift_in;
    rx_wr_ptr <= rx_wr_ptr + 1;
end

// Clocked advance for TX FIFO pointer
always @(posedge clk) if (tx_en && bit_cnt == 8) begin
    tx_rd_ptr <= tx_rd_ptr + 1;
end

// Clocked status updates
always @(posedge clk) status_reg[0] <= (state != IDLE); // Busy flag
always @(posedge clk) if (state == DONE) status_reg[2] <= 1; // Command done

// Clocked interrupt status updates
always @(posedge clk) if (status_reg[2] && !status_reg[0]) int_stat_reg[0] <= 1; // Command completion interrupt
always @(posedge clk) if (err_stat_reg != 0) int_stat_reg[2] <= 1; // Error interrupt
always @(posedge clk) if (tx_empty) int_stat_reg[3] <= 1; // TX empty interrupt
always @(posedge clk) if (rx_full) int_stat_reg[4] <= 1; // RX full interrupt

// XIP AXI Slave interface logic (read-only)
reg xip_busy = 0; // XIP transaction in progress
reg [AXI_ID_WIDTH-1:0] xip_id = 0; // Stored ID for response
reg [7:0] xip_len = 0; // Stored burst length
reg [AXI_ADDR_WIDTH-1:0] xip_addr = 0; // Stored address
reg [7:0] xip_burst_cnt = 0; // Current burst count
assign axis_awready = 0; // No write support
assign axis_wready = 0;
assign axis_bvalid = 0;
assign axis_bresp = 0;
assign axis_bid = 0;
assign axis_arready = !xip_busy; // Ready if not busy
always @(posedge clk) if (axis_arvalid && axis_arready) begin
    xip_busy <= 1;
    xip_id <= axis_arid;
    xip_len <= axis_arlen;
    xip_addr <= axis_araddr;
    xip_burst_cnt <= 0;
    status_reg[1] <= 1;
    // Trigger QSPI read for XIP
    cmd_addr_reg <= axis_araddr;
    cmd_len_reg <= (axis_arlen + 1) * (1 << axis_arsize); // Bytes
    cmd_op_reg <= xip_cmd_reg[7:0];
    cmd_dummy_reg <= xip_cfg_reg[7:4];
    state <= CMD; // Start transaction
end

always @(posedge clk) if (xip_busy) begin
    axis_rvalid <= 1;
    axis_rid <= xip_id;
    axis_rdata = {AXI_DATA_WIDTH/8 {rx_fifo[rx_rd_ptr]}};
    axis_rresp <= 2'b00;
    axis_rlast <= (xip_burst_cnt == xip_len);
    if (axis_rready && axis_rvalid) begin
        xip_burst_cnt <= xip_burst_cnt + 1;
        rx_rd_ptr <= rx_rd_ptr + (AXI_DATA_WIDTH/8);
        if (axis_rlast) xip_busy <= 0;
    end
end else axis_rvalid <= 0;

// Error handling logic
reg [31:0] timeout_cnt = 0; // Timeout counter for transactions
always @(posedge clk) if (status_reg[0]) timeout_cnt <= timeout_cnt + 1;
else timeout_cnt <= 0;
always @(posedge clk) if (timeout_cnt == 32'hFFFFFFFF) err_stat_reg[0] <= 1; // Set timeout error

always @(posedge clk) if (rx_en && rx_full) err_stat_reg[1] <= 1; // RX overrun error
always @(posedge clk) if (tx_en && tx_empty) err_stat_reg[2] <= 1; // TX underrun error

endmodule