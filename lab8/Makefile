# Makefile for AXI QSPI Flash Controller testbench
# Usage:
#   make         → compile and run simulation
#   make view    → open waveform in GTKWave
#   make clean   → remove build files

# Source files
SRC =  qspi_flash_device.v tb_qspi_flash_device.v
TOP = tb_qspi_flash_device
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