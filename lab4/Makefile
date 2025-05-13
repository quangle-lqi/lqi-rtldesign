# Makefile for sequential testbench simulation

TOP_MODULE=datapath_tb
VFILES= alu_17bit.v register_file_16x17.v datapath.v $(TOP_MODULE).v
WAVEFORM=$(TOP_MODULE).vcd
OUT=sim.out

all: run

build:
	iverilog -g2012 -o $(OUT) $(VFILES)

run: build
	vvp $(OUT)

waveform: $(WAVEFORM)
	gtkwave $(WAVEFORM)

clean:
	rm -f $(OUT) $(WAVEFORM)