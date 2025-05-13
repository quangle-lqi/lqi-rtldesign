# Makefile for sequential testbench simulation

TOP_MODULE=sequential_tb
VFILES= shifter.v pattern_detector_1011.v counter.v sequential.v $(TOP_MODULE).v
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