
# Initialize path settings
set init_lef_file {/your_path/syn_pnr_flow/NangateOpenCellLibrary_PDKv1_3_v2010_12/Back_End/lef/NangateOpenCellLibrary.lef /your_path/syn_pnr_flow/NangateOpenCellLibrary_PDKv1_3_v2010_12/Back_End/lef/NangateOpenCellLibrary.macro.lef}
set init_verilog "/your_path/your_design_netlist.v"
set init_mmmc_file "/your_path/mmmc_1.tcl"

# Initial Design
init_design

set_switching_activity -static_probability 0.2 -toggle_rate 0.1 [all_nets]

setPlaceMode -place_design_floorplan_mode false


# Placement execution
place_opt_design

# CTS execution
ccopt_design

# CTS op
setOptMode -opt_area_recovery true
setOptMode -opt_skew_ccopt extreme
setOptMode -opt_skew true

# CTS op
optDesign -postCTS

# Routing 
globalRoute
detailRoute

optDesign -postRoute

# Report

report_timing -summary
report_power  
report_area   


# Exit 
quit
