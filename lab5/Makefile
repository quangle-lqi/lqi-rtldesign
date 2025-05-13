
TOP_MODULE=dma_top_tb
VFILES=  dma.v apb_master.v axi4_ram_slave.v $(TOP_MODULE).v
VFILES_FIFO= fifo.v dma_fifo.v apb_master.v axi4_ram_slave.v $(TOP_MODULE).v
WAVEFORM=$(TOP_MODULE).vcd
OUT=sim.out

all: run

build:
	iverilog -g2012 -o $(OUT) $(VFILES)

build_fifo:
	iverilog -g2012 -o $(OUT) $(VFILES_FIFO)

run: build
	vvp $(OUT)

run_fifo: build_fifo
	vvp $(OUT)

waveform: $(WAVEFORM)
	gtkwave $(WAVEFORM)

clean:
	rm -f $(OUT) $(WAVEFORM)