# Makefile for  QSPI Controller testbench
# Usage:
#   make         → compile and run simulation
#   make view    → open waveform in GTKWave
#   make clean   → remove build files

# Source files
SRC = qspi_controller.v  qspi_device.v qspi_controller_tb.v
TOP = qspi_controller_tb
SRC1 =  qspi_device.v qspi_device_tb.v
TOP1 = qspi_device_tb
VCD = wave.vcd
OUT = sim.out
OUT1 = sim1.out

# Default target
all: $(OUT)
	./$(OUT)

all1: $(OUT1)
	./$(OUT1)

# Compile with Icarus Verilog
$(OUT): $(SRC)
	iverilog -g2012 -o $(OUT) -s $(TOP) $(SRC)
# Compile with Icarus Verilog
$(OUT1): $(SRC1)
	iverilog -g2012 -o $(OUT1) -s $(TOP1) $(SRC1)

# View waveform
view: $(VCD)
	gtkwave $(VCD)

# Clean build files
clean:
	rm -f $(OUT) $(VCD)