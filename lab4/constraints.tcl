create_clock -name core_clk -period 5.0 [get_ports clk]
create_clock -name bus_clk -period 10.0 [get_ports bus_clk]