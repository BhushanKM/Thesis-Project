# Sourcing the setup file
source -echo ./setup.tcl

# Create a library
create_lib router.dlib -technology $TECH_FILE -ref_libs $REFERENCE_LIBRARY

# Reading the RTL
analyze -format verilog [glob rtl/*.v]

# Elaborate gtech cells created for the rtl
elaborate router_top

# Setting the top module
set_top_module router_top

# To know what are the blocks present in the library
get_block
get_modules

# Reading parasitic files tlu+ for RC delays
read_parasitic_tech -layermap ./constraints/ref/tech/saed32nm_tf_itf_tluplus.map \
                    -tlup ./constraints/ref/tech/saed32nm_lp9m_Cmax.lv.nxtgrd \
                    -name maxTLU

read_parasitic_tech -layermap ./constraints/ref/tech/saed32nm_tf_itf_tluplus.map \
                    -tlup ./constraints/ref/tech/saed32nm_lp9m_Cmin.lv.nxtgrd \
                    -name minTLU

# Reporting the parasitic delay information
get_parasitic_tech
report_lib -parasitic_tech router.dlib

# Sourcing the sdc, which contains the information about clock
source -echo constraints/router.sdc

# Setting symmetry along Y axis
get_site_defs
set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

# Setting the metal layer directions
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction vertical
get_attribute [get_layers M?] routing_direction

# MCMM Timing Setup
source -echo mcmm_risc_core.tcl

# Report Scenarios
report_scenarios
report_pvt

# Setting up the svf file which is further used by formality tool
set_svf netlist.svf

# Initialize the custom floorplan
compile_fusion -from initial_map -to logic_opt

# Initialize floorplan
initialize_floorplan -shape L -orientation W -side_ratio {1 1 1 1} -core_offset {10}
create_placement -floorplan

report_optimization_history

# Setting the pin location using switch called -self
set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M7} \
                          -side {2 1 12} -pin_spacing_distance 10

place_pins -ports [get_ports -filter {direction == in}]

set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M7} \
                          -sides {6 7 8} -pin_spacing_distance 5

place_pins -ports [get_ports -filter {direction == out}]

change_selection [get_ports *data_in]
change_selection [get_ports *data_out_0]
change_selection [get_ports *data_out_1]
change_selection [get_ports *data_out_2]
change_selection [get_ports router_clock]

# Setting up the PG connections
source -echo ./scripts/pns.tcl

# Arranging the standard cells with respect to the rows
legalize_placement

# Final optimizing the placement
place_opt

# Timing analysis before and after Clock Tree synthesis
report_timing
report_timing -delay_type max
report_timing -delay_type min
report_constraints -all_violators
report_multistage_timing
report_clock -skew
report_clock_balance_points

clock_opt

report_timing -delay_type max
report_timing -delay_type min
report_constraints -all_violators
report_multistage_timing
report_clock -skew
report_clock_balance_points
report_clock_qor

# Routing
report_design
route_auto
route_opt
report_design
check_legality
save_block -as router_top.design_routing