# Set variables
set TOP_MODULE datapath       ;# Change if actual top is different
set RTL_FILE   datapath.v
set WORK_DIR   ./genus_work
set OUT_DIR    ./output

# Create work/output dirs
file mkdir $WORK_DIR
file mkdir $OUT_DIR

# Setup environment
set_attribute lib_search_path "/path/to/lib"  ;# Replace with actual path
set_attribute library [list "your_lib.db"]    ;# Replace with standard cell lib

# Read RTL
read_hdl -sv $RTL_FILE
elaborate $TOP_MODULE

# Constraints
create_clock -name clk -period 5 [get_ports clk]
set_input_delay 4.5 -clock clk [all_inputs]
set_output_delay 2 -clock clk [all_outputs]

# Synthesize
synthesize -to_mapped

# Report and write outputs
report_area > $OUT_DIR/area.rpt
report_timing > $OUT_DIR/timing.rpt
report_power > $OUT_DIR/power.rpt

write_hdl > $OUT_DIR/${TOP_MODULE}_mapped.v
write_sdf > $OUT_DIR/${TOP_MODULE}.sdf
write_sdc > $OUT_DIR/${TOP_MODULE}.sdc