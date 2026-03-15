# =========================
# Design Compiler run script
# =========================

# ---- USER EDIT: set these paths ----
set RTL_DIR   "../Design"
set LIB_DIR   "../Git_hub_repo/nangate/lib"

# Nangate typical corner liberty
set TARGET_LIB "${LIB_DIR}/NangateOpenCellLibrary_typical.lib"

# ---- DC setup ----
set_app_var search_path [list . $RTL_DIR $LIB_DIR]
set_app_var target_library [list $TARGET_LIB]
set_app_var link_library   [list "*" $TARGET_LIB]
set_app_var synthetic_library [list dw_foundation.sldb]

# If you have DesignWare licensed, keep dw_foundation.sldb.
# If not, you may need to remove it.

# ---- Read RTL ----
analyze -format verilog [list \
  $RTL_DIR/ecc_engine_top.v \
  $RTL_DIR/ecc_encoder.v \
  $RTL_DIR/ecc_decoder.v \
  $RTL_DIR/gf_mul_16.v \
]

# Top module name (confirmed from your file)
elaborate ecc_engine_top

# Resolve references
link

# Basic sanity checks
check_design
report_hierarchy

# ---- Constraints (MINIMUM viable) ----
# You MUST set a clock for meaningful synthesis.
# Replace clk port name if your top uses a different name.
# (If you don't know the clock port name, open ecc_engine_top.v and confirm.)

create_clock -name clk -period 2.0 [get_ports clk]  
 # 500 MHz example

# Typical simple IO assumptions (tune later)
set_input_delay  0.2 -clock clk [all_inputs]
set_output_delay 0.2 -clock clk [all_outputs]

# Don't apply input delay to clock itself
set_input_delay 0 -clock clk [get_ports clk]

# Optional: give a generic output load (helps gate sizing)
set_load 0.05 [all_outputs]

# ---- Compile ----
# compile_ultra if available; else use compile
compile_ultra

# ---- Reports ----
report_qor           > reports/qor.rpt
report_timing -max_paths 20 > reports/timing.rpt
report_area          > reports/area.rpt
report_power         > reports/power.rpt

# ---- Write outputs ----
file mkdir outputs
write -format verilog -hierarchy -output outputs/ecc_engine_top_mapped.v
write_sdc outputs/ecc_engine_top.sdc
write_sdf outputs/ecc_engine_top.sdf

# Optional: save ddc
write -format ddc -hierarchy -output outputs/ecc_engine_top.ddc

quit