# example_synthesis.tcl


# Set target library and linked libraries
set target_library [glob /{your_PDK_path}/db/NLDM/*.db]
set link_library "* [glob /{your_PDK_path}/db/NLDM/*.db]"
set search_path ". /{your_PDK_path}/db/NLDM"

# Read the design file and set the current design.
read_verilog "{design_path}"
current_design {design_name}
elaborate {design_name}

# Set up design libraries and constraints
set auto_wire_load_selection true
create_clock -period 1.0 [get_ports clk]
set_input_delay 0.1 -clock {your_clock_name} [all_inputs]
set_output_delay 0.1 -clock {your_clock_name} [all_outputs]

# Set comprehensive constraint parameters
set_max_fanout 10 [all_designs]
set_max_transition 1 [get_nets *]
set_max_capacitance 0.5 [get_nets *]

# Set up a high fan-out network
set_app_var high_fanout_net_threshold 20

# Automatically select wire load model
set_app_var auto_wire_load_selection true

# Logic synthesis
compile_ultra

# Generate gate-level netlist
write -format verilog -hierarchy -output "{output_dir}/{design_name}_{index}_netlist.v"

# Generate report
#report_timing > {output_dir}/{design_name}_{index}_timing.rpt
report_qor  > {output_dir}/{design_name}_{index}_qor.rpt
report_power > {output_dir}/{design_name}_{index}_power.rpt
report_area > {output_dir}/{design_name}_{index}_area.rpt

# Exit dc_shell
quit
