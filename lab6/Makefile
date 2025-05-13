
TOP_MODULE=tb_rcv_block
VFILES= flex_counter.v flex_stp_sr.v rcu.v rx_data_buff.v start_bit_det.v stop_bit_chk.v sr_9bit.v  stp_sr_4_msb.v timer.v  rcv_block.v $(TOP_MODULE).v
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