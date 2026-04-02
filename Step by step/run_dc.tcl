# =========================
# Design Compiler run script
# =========================

# ---- Absolute paths — no more relative path issues ----
set RTL_DIR  "/home/grads/b/bhushan_123/thesis_project/design_version_2"
set LIB_DIR  "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/db_files"
set UPF_DIR "/home/grads/b/bhushan_123/thesis_project/upf_files"
set FILE_TYPE "ECC_ENCODER"

set TARGET_LIB "${LIB_DIR}/merged.db"

# ---- DC setup ----
set_app_var search_path    [list . $RTL_DIR $LIB_DIR]
set_app_var target_library [list $TARGET_LIB]
set_app_var link_library   [list "*" $TARGET_LIB]
set_app_var synthetic_library [list dw_foundation.sldb]

# ---- Read RTL ----
analyze -format verilog [list \
  $RTL_DIR/ecc_encoder.v \
  $RTL_DIR/gf_mul_16.v \
]
  # $RTL_DIR/ecc_engine_top.v \
  # $RTL_DIR/ecc_decoder.v \

elaborate ecc_encoder

link
# 1. Enable UPF flow
set_app_var upf_create_implicit_supply_sets false

# 2. Load your UPF file (Ensure the filename matches yours)
load_upf "${UPF_DIR}/encoder.upf"


# 3. Commit the power intent and check for multi-voltage errors
# This ensures your UPF matches your RTL hierarchy before you compile
check_mv_design -verbose > reports/mv_pre_compile.rpt
# =====================================================


check_design
report_hierarchy

# ---- Constraints ----
create_clock -name clk -period 2.0 [get_ports clk]
set_input_delay  0.2 -clock clk [all_inputs]
set_output_delay 0.2 -clock clk [all_outputs]
set_input_delay  0.0 -clock clk [get_ports clk]
set_load 0.05 [all_outputs]

# ---- Compile ----
# compile_ultra
compile_ultra -gate_clock

# ---- Reports ----
file mkdir reports
report_qor              > reports/qor.rpt
report_timing -max_paths 20 > reports/timing.rpt
report_area             > reports/area.rpt
report_power            > reports/power.rpt


# =====================================================
# ADD THESE POWER REPORTS
# =====================================================
report_power_domain    > reports/power_domain.rpt
report_mv_design       > reports/mv_violations.rpt
# =====================================================



# ---- Write outputs ----
file mkdir outputs
write -format verilog -hierarchy -output outputs/${FILE_TYPE}mapped.v

# =====================================================
# ADD THIS LINE TO SAVE THE MAPPED UPF
# =====================================================
# You NEED this file for Innovus or IC Compiler later
save_upf outputs/ecc_engine_top_mapped.upf
# =====================================================


write_sdc outputs/${FILE_TYPE}.sdc
write_sdf outputs/${FILE_TYPE}.sdf
write -format ddc -hierarchy -output outputs/${FILE_TYPE}.ddc

quit
