# Makefile for  QSPI Controller testbench
# Usage:
#   make         → compile and run simulation
#   make view    → open waveform in GTKWave
#   make clean   → remove build files

# Source files
SRC = qspi_controller.v  qspi_device.v qspi_controller_tb.v
TOP = qspi_controller_tb
VCD = wave.vcd
OUT = sim.out

# Default target
all: $(OUT)
	./$(OUT)

# Compile with Icarus Verilog
$(OUT): $(SRC)
	iverilog -g2012 -o $(OUT) -s $(TOP) $(SRC)

# View waveform
view: $(VCD)
	gtkwave $(VCD)

# Clean build files
clean:
	rm -f $(OUT) $(VCD)