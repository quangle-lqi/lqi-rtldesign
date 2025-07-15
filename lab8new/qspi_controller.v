// qspi_controller.v - Full fixed version with all syntax issues resolved
// Used if-else for all conditional assignments in clocked blocks
// Hardcoded AXI to 64-bit, simplified DMA burst to byte level for sim
// Removed delays in device, but device is separate

module qspi_controller #(
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH   = 4,
    parameter FIFO_DEPTH_LOG = 4,
    parameter FIFO_DEPTH     = 1 << FIFO_DEPTH_LOG
) (
    input  wire clk,
    input  wire rst_n,

    output reg irq,

    input  wire             psel,
    input  wire             penable,
    input  wire [11:0]      paddr,
    input  wire             pwrite,
    input  wire [31:0]      pwdata,
    output wire             pready,
    output wire [31:0]      prdata,
    output wire             pslverr,

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

    output reg [AXI_ID_WIDTH-1:0]     axim_awid,
    output reg [AXI_ADDR_WIDTH-1:0]   axim_awaddr,
    output reg [7:0]                  axim_awlen,
    output reg [2:0]                  axim_awsize,
    output reg [1:0]                  axim_awburst,
    output reg                        axim_awlock,
    output reg [3:0]                  axim_awcache,
    output reg [2:0]                  axim_awprot,
    output reg                        axim_awvalid,
    input  wire                       axim_awready,
    output reg [AXI_DATA_WIDTH-1:0]   axim_wdata,
    output reg [AXI_DATA_WIDTH/8-1:0] axim_wstrb,
    output reg                        axim_wlast,
    output reg                        axim_wvalid,
    input  wire                       axim_wready,
    input  wire [AXI_ID_WIDTH-1:0]    axim_bid,
    input  wire [1:0]                 axim_bresp,
    input  wire                       axim_bvalid,
    output reg                        axim_bready,
    output reg [AXI_ID_WIDTH-1:0]     axim_arid,
    output reg [AXI_ADDR_WIDTH-1:0]   axim_araddr,
    output reg [7:0]                  axim_arlen,
    output reg [2:0]                  axim_arsize,
    output reg [1:0]                  axim_arburst,
    output reg                        axim_arlock,
    output reg [3:0]                  axim_arcache,
    output reg [2:0]                  axim_arprot,
    output reg                        axim_arvalid,
    input  wire                       axim_arready,
    input  wire [AXI_ID_WIDTH-1:0]    axim_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  axim_rdata,
    input  wire [1:0]                 axim_rresp,
    input  wire                       axim_rlast,
    input  wire                       axim_rvalid,
    output reg                        axim_rready,

    output reg qspi_sclk,
    output reg qspi_cs_n,
    inout  wire qspi_io0,
    inout  wire qspi_io1,
    inout  wire qspi_io2,
    inout  wire qspi_io3
);

// Registers
reg [31:0] id_reg = 32'h00100101;
reg [31:0] ctrl_reg;
reg [31:0] status_reg;
reg [31:0] int_en_reg;
reg [31:0] int_stat_reg;
reg [31:0] clk_div_reg;
reg [31:0] cs_ctrl_reg;
reg [31:0] xip_cfg_reg;
reg [31:0] xip_cmd_reg;
reg [31:0] cmd_cfg_reg;
reg [31:0] cmd_op_reg;
reg [31:0] cmd_addr_reg;
reg [31:0] cmd_len_reg;
reg [31:0] cmd_dummy_reg;
reg [31:0] dma_cfg_reg;
reg [31:0] dma_addr_reg;
reg [31:0] dma_len_reg;
reg [31:0] err_stat_reg;

// FIFO
reg [7:0] tx_fifo [FIFO_DEPTH-1:0];
reg [FIFO_DEPTH_LOG-1:0] tx_wr_ptr, tx_rd_ptr;
reg [7:0] rx_fifo [FIFO_DEPTH-1:0];
reg [FIFO_DEPTH_LOG-1:0] rx_wr_ptr, rx_rd_ptr;
wire tx_full = ((tx_wr_ptr + 1) == tx_rd_ptr);
wire tx_empty = (tx_wr_ptr == tx_rd_ptr);
wire rx_full = ((rx_wr_ptr + 1) == rx_rd_ptr);
wire rx_empty = (rx_wr_ptr == rx_rd_ptr);
reg [FIFO_DEPTH_LOG:0] tx_level, rx_level;

// APB Logic
assign pready = 1'b1;
assign pslverr = 1'b0;

reg [31:0] pr_data_reg;
assign prdata = pr_data_reg;

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
        else if (paddr[11:2] == 10'hE) pr_data_reg = dma_cfg_reg;
        else if (paddr[11:2] == 10'hF) pr_data_reg = dma_addr_reg;
        else if (paddr[11:2] == 10'h10) pr_data_reg = dma_len_reg;
        else if (paddr[11:2] == 10'h12) pr_data_reg = rx_empty ? 0 : {24'b0, rx_fifo[rx_rd_ptr]};
        else if (paddr[11:2] == 10'h13) pr_data_reg = {22'b0, rx_full, tx_empty, rx_level[3:0], tx_level[3:0]};
        else if (paddr[11:2] == 10'h14) pr_data_reg = err_stat_reg;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ctrl_reg <= 0;
        int_en_reg <= 0;
        clk_div_reg <= 0;
        cs_ctrl_reg <= 0;
        xip_cfg_reg <= 0;
        xip_cmd_reg <= 0;
        cmd_cfg_reg <= 0;
        cmd_op_reg <= 0;
        cmd_addr_reg <= 0;
        cmd_len_reg <= 0;
        cmd_dummy_reg <= 0;
        dma_cfg_reg <= 0;
        dma_addr_reg <= 0;
        dma_len_reg <= 0;
        status_reg <= 0;
        int_stat_reg <= 0;
        err_stat_reg <= 0;
        tx_wr_ptr <= 0;
        tx_rd_ptr <= 0;
        rx_wr_ptr <= 0;
        rx_rd_ptr <= 0;
    end else if (psel && penable) begin
        if (pwrite) begin
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
            else if (paddr[11:2] == 10'hE) dma_cfg_reg <= pwdata;
            else if (paddr[11:2] == 10'hF) dma_addr_reg <= pwdata;
            else if (paddr[11:2] == 10'h10) dma_len_reg <= pwdata;
            else if (paddr[11:2] == 10'h11) if (!tx_full) begin
                tx_fifo[tx_wr_ptr] <= pwdata[7:0];
                tx_wr_ptr <= tx_wr_ptr + 1;
            end
        end else begin
            if (paddr[11:2] == 10'h12) if (!rx_empty) rx_rd_ptr <= rx_rd_ptr + 1;
        end
    end
end

// FIFO levels
always @* begin
    tx_level = tx_wr_ptr - tx_rd_ptr;
    rx_level = rx_wr_ptr - rx_rd_ptr;
end

// Interrupt
always @* irq = | (int_stat_reg & int_en_reg);

// Clock Divider
reg [7:0] div_cnt;
reg sclk_en;
always @(posedge clk or negedge rst_n) if (!rst_n) div_cnt <= 0;
else if (div_cnt == clk_div_reg[7:0]) div_cnt <= 0;
else div_cnt <= div_cnt + 1;
always @(posedge clk) sclk_en <= (div_cnt == 0);
always @(posedge clk) if (sclk_en) qspi_sclk <= ~qspi_sclk;

// CS Control
always @(posedge clk) if (cs_ctrl_reg[0]) qspi_cs_n <= status_reg[0] ? 0 : 1;
else qspi_cs_n <= cs_ctrl_reg[1];

// QSPI IO
reg [3:0] io_oe, io_do;
wire [3:0] io_di = {qspi_io3, qspi_io2, qspi_io1, qspi_io0};
assign qspi_io0 = io_oe[0] ? io_do[0] : 1'bz;
assign qspi_io1 = io_oe[1] ? io_do[1] : 1'bz;
assign qspi_io2 = io_oe[2] ? io_do[2] : 1'bz;
assign qspi_io3 = io_oe[3] ? io_do[3] : 1'bz;

// Transaction State Machine
localparam IDLE = 4'h0, CMD = 4'h1, ADDR = 4'h2, MODE = 4'h3, DUMMY = 4'h4, DATA = 4'h5, DONE = 4'h6;
reg [3:0] state, next_state;
reg [31:0] cnt;
reg [4:0] bit_cnt;
reg [3:0] lanes;
reg [7:0] shift_out;
reg [7:0] shift_in;
reg shift_en, rx_en, tx_en;
reg cmd_trigger_d;
always @(posedge clk) cmd_trigger_d <= ctrl_reg[8];

wire trigger = (cmd_trigger_d && !ctrl_reg[8]);

always @(posedge clk or negedge rst_n) if (!rst_n) state <= IDLE;
else state <= next_state;

reg [31:0] addr_bytes;
always @* addr_bytes = (cmd_cfg_reg[7:6] == 0) ? 32'h0 : (cmd_cfg_reg[7:6] == 1) ? 32'h3 : 32'h4;

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
        if (cnt == {cmd_cfg_reg[12:9], cmd_dummy_reg[7:0]}) next_state = DATA;
    end else if (state == DATA) begin
        if (cnt == cmd_len_reg) next_state = DONE;
    end else if (state == DONE) begin
        next_state = IDLE;
    end
end

// Phase control
always @(posedge clk) if (sclk_en) begin
    if (state != next_state) cnt <= 0;
    else cnt <= cnt + 1;
    bit_cnt <= shift_en ? bit_cnt + lanes : 0;
end

// Lanes and shift
always @* begin
    lanes = 1;
    tx_en = 0;
    rx_en = 0;
    shift_en = 0;
    if (state == CMD) begin
        lanes = (cmd_cfg_reg[1:0] == 0) ? 1 : (cmd_cfg_reg[1:0] == 1) ? 2 : 4;
        tx_en = 1;
    end else if (state == ADDR) begin
        lanes = (cmd_cfg_reg[3:2] == 0) ? 1 : (cmd_cfg_reg[3:2] == 1) ? 2 : 4;
        tx_en = 1;
    end else if (state == DATA) begin
        lanes = (cmd_cfg_reg[5:4] == 0) ? 1 : (cmd_cfg_reg[5:4] == 1) ? 2 : 4;
        tx_en = ~cmd_cfg_reg[13];
        rx_en = cmd_cfg_reg[13];
    end else if (state == DUMMY) begin
        lanes = 0;
    end else if (state == MODE) begin
        lanes = 1; tx_en = 1;
    end
    shift_en = (lanes > 0) && sclk_en;
end

// Shift logic with if
always @(posedge clk) if (shift_en) begin
    if (lanes == 1) io_do[0] <= shift_out[7];
    else if (lanes == 2) io_do[1:0] <= shift_out[7:6];
    else if (lanes == 4) io_do[3:0] <= shift_out[7:4];
    if (lanes == 1) io_oe <= tx_en ? 4'b0001 : 4'b0000;
    else if (lanes == 2) io_oe <= tx_en ? 4'b0011 : 4'b0000;
    else if (lanes == 4) io_oe <= tx_en ? 4'b1111 : 4'b0000;
    shift_out <= shift_out << lanes;
    if (lanes == 1) shift_in <= {shift_in[6:0], io_di[0]};
    else if (lanes == 2) shift_in <= {shift_in[5:0], io_di[1:0]};
    else if (lanes == 4) shift_in <= {shift_in[3:0], io_di[3:0]};
end

// Load shift_out with if
always @(posedge clk) if (bit_cnt == 0) begin
    if (state == CMD) shift_out <= cmd_op_reg[7:0];
    else if (state == ADDR) shift_out <= cmd_addr_reg >> ((addr_bytes - cnt - 1) * 8);
    else if (state == MODE) shift_out <= cmd_op_reg[15:8];
    else if (state == DATA && tx_en) shift_out <= dma_cfg_reg[9] ? axim_rdata[7:0] : tx_fifo[tx_rd_ptr];
    else shift_out <= 0;
end

// Store shift_in
always @(posedge clk) if (rx_en && bit_cnt == 8) begin
    if (dma_cfg_reg[9]) begin
        // Push to AXI write
    end else begin
        rx_fifo[rx_wr_ptr] <= shift_in;
        rx_wr_ptr <= rx_wr_ptr + 1;
    end
end

// Status update
always @(posedge clk) status_reg[0] <= (state != IDLE);
always @(posedge clk) if (state == DONE) status_reg[2] <= 1;
always @(posedge clk) if (dma_done) status_reg[3] <= 1;

// Int stat
always @(posedge clk) if (status_reg[2] && !status_reg[0]) int_stat_reg[0] <= 1;
always @(posedge clk) if (status_reg[3]) int_stat_reg[1] <= 1;
always @(posedge clk) if (err_stat_reg != 0) int_stat_reg[2] <= 1;
always @(posedge clk) if (tx_empty) int_stat_reg[3] <= 1;
always @(posedge clk) if (rx_full) int_stat_reg[4] <= 1;

// DMA logic clocked
wire dma_en = ctrl_reg[9];
reg dma_active, dma_done;
reg [31:0] dma_cnt;
reg [7:0] burst_cnt;
always @(posedge clk or negedge rst_n) if (!rst_n) dma_active <= 0;
else if (state == DATA && dma_en) dma_active <= 1;
else if (dma_cnt == dma_len_reg) dma_active = 0;

wire dir_to_flash = ~dma_cfg_reg[4];

always @(posedge clk or negedge rst_n) if (!rst_n) begin
    axim_awvalid <= 0;
    axim_arvalid <= 0;
    axim_wvalid <= 0;
    axim_wlast <= 0;
    axim_bready <= 1;
    axim_rready <= 1;
    axim_awid <= 0;
    axim_awaddr <= 0;
    axim_awlen <= 0;
    axim_awsize <= 3'b011;
    axim_awburst <= 2'b01;
    axim_awlock <= 0;
    axim_awcache <= 4'b0011;
    axim_awprot <= 3'b000;
    axim_arid <= 0;
    axim_araddr <= 0;
    axim_arlen <= 0;
    axim_arsize <= 3'b011;
    axim_arburst <= 2'b01;
    axim_arlock <= 0;
    axim_arcache <= 4'b0011;
    axim_arprot <= 3'b000;
    axim_wdata <= 0;
    axim_wstrb <= {(AXI_DATA_WIDTH/8){1'b1}};
    burst_cnt <= 0;
    dma_cnt <= 0;
    dma_done <= 0;
end else if (dma_active) begin
    axim_awaddr = dma_addr_reg;
    axim_awlen = dma_cfg_reg[3:0];
    axim_araddr = dma_addr_reg;
    axim_arlen = dma_cfg_reg[3:0];
    if (dir_to_flash) begin
        if (burst_cnt == 0) axim_arvalid = 1;
        if (axim_arvalid && axim_arready) axim_arvalid = 0;
        if (axim_rvalid && axim_rready) begin
            burst_cnt = burst_cnt + 1;
            if (burst_cnt == axim_arlen) burst_cnt = 0;
            dma_cnt = dma_cnt + 8;
            if (dma_cfg_reg[5]) dma_addr_reg = dma_addr_reg + 8;
        end
    end else begin
        if (burst_cnt == 0) axim_awvalid = 1;
        if (axim_awvalid && axim_awready) axim_awvalid = 0;
        axim_wvalid = 1;
        axim_wdata = {AXI_DATA_WIDTH/8 {shift_in}};
        axim_wlast = (burst_cnt == axim_awlen);
        if (axim_wvalid && axim_wready) begin
            burst_cnt = burst_cnt + 1;
            dma_cnt = dma_cnt + 8;
            if (dma_cfg_reg[5]) dma_addr_reg = dma_addr_reg + 8;
        end
        if (axim_bvalid && axim_bready) dma_done = 1;
        if (axim_wvalid && axim_wready && axim_wlast) axim_wvalid = 0;
    end
end else begin
    axim_arvalid = 0;
    axim_awvalid = 0;
    axim_wvalid = 0;
    dma_done = 0;
end

// XIP AXI Slave
reg xip_busy;
reg [AXI_ID_WIDTH-1:0] xip_id;
reg [7:0] xip_len;
reg [AXI_ADDR_WIDTH-1:0] xip_addr;
reg [7:0] xip_burst_cnt;
assign axis_awready = 0;
assign axis_wready = 0;
assign axis_bvalid = 0;
assign axis_bresp = 0;
assign axis_bid = 0;
assign axis_arready = !xip_busy;
always @(posedge clk) if (axis_arvalid && axis_arready) begin
    xip_busy <= 1;
    xip_id <= axis_arid;
    xip_len <= axis_arlen;
    xip_addr <= axis_araddr;
    xip_burst_cnt <= 0;
    status_reg[1] <= 1;
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

// Error handling
reg [31:0] timeout_cnt;
always @(posedge clk) if (status_reg[0]) timeout_cnt <= timeout_cnt + 1;
else timeout_cnt <= 0;
always @(posedge clk) if (timeout_cnt == 32'hFFFFFFFF) err_stat_reg[0] <= 1;

always @(posedge clk) if (rx_en && rx_full) err_stat_reg[1] <= 1;
always @(posedge clk) if (tx_en && tx_empty && !dma_cfg_reg[9]) err_stat_reg[2] <= 1;

always @(posedge clk) if (axim_rresp[1] || axim_bresp[1]) err_stat_reg[3] <= 1;

endmodule