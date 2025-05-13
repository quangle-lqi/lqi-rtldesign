// DMA with looped AXI4-Lite read-write using internal buffer
// DMA with looped AXI4-Lite read-write using internal buffer
`timescale 1ns / 1ps

module dma (
    input  wire        clk,
    input  wire        rst_n,

    // APB interface
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output reg         pready,

    // AXI4-Lite Write Address Channel
    output reg  [31:0] axi_awaddr,
    output reg         axi_awvalid,
    input  wire        axi_awready,

    // AXI4-Lite Write Data Channel
    output reg  [31:0] axi_wdata,
    output reg  [3:0]  axi_wstrb,
    output reg         axi_wvalid,
    input  wire        axi_wready,

    // AXI4-Lite Write Response Channel
    input  wire [1:0]  axi_bresp,
    input  wire        axi_bvalid,
    output reg         axi_bready,

    // AXI4-Lite Read Address Channel
    output reg  [31:0] axi_araddr,
    output reg         axi_arvalid,
    input  wire        axi_arready,

    // AXI4-Lite Read Data Channel
    input  wire [31:0] axi_rdata,
    input  wire [1:0]  axi_rresp,
    input  wire        axi_rvalid,
    output reg         axi_rready
);

    localparam IDLE = 2'd0, ADDR = 2'd1, DATA = 2'd2, RESP = 2'd3;

    // FSM state
    reg [1:0] wr_state, rd_state;

    // DMA control and status
    reg [31:0] dma_ctrl;      // bit 0 = start, bit 31:16 = size
    reg [31:0] dma_status;    // bit 0 = busy, bit 1 = done
    reg [31:0] dma_src_addr;
    reg [31:0] dma_dst_addr;

    reg [15:0] count;
    reg [31:0] buffer;
    reg         buffer_valid;

    wire       dma_start = dma_ctrl[0];
    wire [15:0] dma_size = dma_ctrl[31:16];

    // APB register interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_ctrl      <= 32'b0;
            dma_status    <= 32'b0;
            dma_src_addr  <= 32'b0;
            dma_dst_addr  <= 32'b0;
            pready        <= 0;
            prdata        <= 32'b0;
        end else begin
            pready <= 0;
            if (psel && penable) begin
                pready <= 1;
                if (pwrite) begin
                    case (paddr)
                        8'h00: 
                        begin
                        dma_ctrl     <= pwdata;
                        dma_status[1] <= 0; // clear done bit
                        end
                        8'h08: dma_src_addr <= pwdata;
                        8'h0C: dma_dst_addr <= pwdata;
                    endcase
                end else begin
                    case (paddr)
                        8'h00: prdata <= dma_ctrl;
                        8'h04: prdata <= dma_status;
                        8'h08: prdata <= dma_src_addr;
                        8'h0C: prdata <= dma_dst_addr;
                        default: prdata <= 32'b0;
                    endcase
                end
            end 
        end
    end

    // DMA read FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_state <= IDLE;
            axi_arvalid  <= 0;
            axi_araddr   <= 0;
            axi_rready   <= 0;
            buffer_valid <= 0;
        end else begin
            case (rd_state)
                IDLE: begin
                    if (dma_start && (count < dma_size)&& !buffer_valid) begin
                        axi_araddr  <= dma_src_addr + count;
                        axi_arvalid <= 1;
                        axi_rready  <= 0;
                        rd_state <= ADDR;
                    end
                end
                ADDR: begin
                    if (axi_arready && axi_arvalid) begin
                        axi_arvalid <= 0;
                        axi_rready  <= 1;
                        rd_state <= DATA;
                    end
                end
                DATA: begin
                    if (axi_rvalid && axi_rready) begin
                        buffer <= axi_rdata;
                        buffer_valid <= 1;
                        axi_rready <= 0;
                        rd_state <= IDLE;
                    end
                end
            endcase
        end
    end

    // DMA write FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_state <= IDLE;
            axi_awvalid  <= 0;
            axi_wvalid   <= 0;
            axi_bready   <= 0;
            axi_awaddr   <= 0;
            axi_wdata    <= 0;
            axi_wstrb    <= 4'hF;
            count    <= 0;
        end else begin
            case (wr_state)
                IDLE: begin
                    if (dma_start &&( count < dma_size )&& buffer_valid) begin
                        axi_awaddr  <= dma_dst_addr + count;
                        axi_wdata   <= buffer;
                        axi_awvalid <= 1;
                        axi_wvalid  <= 0;
                        axi_bready  <= 0;
                        wr_state <= ADDR;
                    end else if (count == dma_size) begin
                        dma_status[0] <= 0;
                        dma_status[1] <= 1;
                        dma_ctrl[0] <= 0; // clear start bit
                        count <= 0; //reset for next transaction
                    end
                end
                ADDR: begin
                    if (axi_awready && axi_awvalid) begin
                        axi_awvalid <= 0;
                        axi_wvalid  <= 1;
                        wr_state <= DATA;
                    end
                end
                DATA: begin
                    if (axi_wready && axi_wvalid) begin
                        axi_wvalid  <= 0;
                        axi_bready  <= 1;
                        wr_state <= RESP;
                    end
                end
                RESP: begin
                    if (axi_bvalid && axi_bready) begin
                        axi_bready  <= 0;
                        buffer_valid <= 0;
                        count   <= count + 4;
                        wr_state <= IDLE;
                    end
                end
            endcase

            if (dma_start && count == 0) begin
                dma_status[0] <= 1; // busy
                dma_status[1] <= 0; // clear done
            end
        end
    end
endmodule
