#------------------------------------------------------------------------------
# Generic Makefile for Verilog Projects (Icarus Verilog + GTKWave)
#------------------------------------------------------------------------------

# Top-level testbench module (without .v extension)
TOP     ?= counter_tb

# All source files (auto-adds all .v files in current directory)
SRCS    := $(wildcard *.v)

# Output simulation binary and VCD file
OUT     := sim
VCD     := $(TOP).vcd

# Compiler and viewer
IVERILOG  := iverilog
VVP       := vvp
GTK       := gtkwave

# Flags
IVERILOG_FLAGS := -g2012 -Wall -o $(OUT).vvp

# Default target
all: build run

# Compile all source files
build:
	@echo "Compiling: $(SRCS)"
	$(IVERILOG) $(IVERILOG_FLAGS) -s $(TOP) $(SRCS)

# Run the simulation
run: build
	@echo "Running simulation..."
	$(VVP) $(OUT).vvp

# View waveform using GTKWave
wave: run
	@echo "Launching GTKWave..."
	$(GTK) $(VCD)

# Clean temporary files
clean:
	rm -f *.vvp *.vcd *.lxt *.gtkw *.log

.PHONY: all build run wave clean