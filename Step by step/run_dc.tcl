# =========================
# Design Compiler run script
# =========================

# ---- Absolute paths — no more relative path issues ----
set RTL_DIR  "/home/grads/b/bhushan_123/thesis_project/Design"
set LIB_DIR  "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/db_files"

set TARGET_LIB "${LIB_DIR}/merged.db"

# ---- DC setup ----
set_app_var search_path    [list . $RTL_DIR $LIB_DIR]
set_app_var target_library [list $TARGET_LIB]
set_app_var link_library   [list "*" $TARGET_LIB]
set_app_var synthetic_library [list dw_foundation.sldb]

# ---- Read RTL ----
analyze -format verilog [list \
  $RTL_DIR/ecc_engine_top.v \
  $RTL_DIR/ecc_encoder.v \
  $RTL_DIR/ecc_decoder.v \
  $RTL_DIR/gf_mul_16.v \
]

elaborate ecc_engine_top
link
check_design
report_hierarchy

# ---- Constraints ----
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay  0.2 -clock clk [all_inputs]
set_output_delay 0.2 -clock clk [all_outputs]
set_input_delay  0.0 -clock clk [get_ports clk]
set_load 0.05 [all_outputs]

# ---- Compile ----
compile_ultra

# ---- Reports ----
file mkdir reports
report_qor              > reports/qor.rpt
report_timing -max_paths 20 > reports/timing.rpt
report_area             > reports/area.rpt
report_power            > reports/power.rpt

# ---- Write outputs ----
file mkdir outputs
write -format verilog -hierarchy -output outputs/ecc_engine_top_mapped.v
write_sdc outputs/ecc_engine_top.sdc
write_sdf outputs/ecc_engine_top.sdf
write -format ddc -hierarchy -output outputs/ecc_engine_top.ddc

quit
