# ================================================================
# lib2db.tcl
# Run:
#   lc_shell -f lib2db.tcl
# ================================================================

suppress_message LBDB-1054
suppress_message LBDB-607
suppress_message LIBG-10
suppress_message LIBG-205
suppress_message LIBG-265
suppress_message LIBG-275
suppress_message UIL-3

set_app_var sh_enable_page_mode false

# ---- Hardcoded paths ----
# set lib_file "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/NangateOpenCellLibrary_typical.lib"
# set lib_file_a "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_32x64.lib"
# set lib_file_b "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_64x7.lib"
# set lib_file_c "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_64x15.lib"
# set lib_file_d "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_64x21.lib"
# set lib_file_e "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_64x32.lib"
# set lib_file_f "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_64x96.lib"
# set lib_file_g "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_256x34.lib"
# set lib_file_h "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_256x95.lib"
# set lib_file_i "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_256x96.lib"
# set lib_file_j "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_512x64.lib"
# set lib_file_k "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_1024x32.lib"
# set lib_file_l "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/fakeram45_2048x39.lib"
set lib_file_m "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/lib/merged.lib"
set out_dir  "/home/grads/b/bhushan_123/thesis_project/Git_hub_repo/nangate/db_files"

# ---- Create output directory ----
file mkdir $out_dir

# ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_a"
# read_lib $lib_file_a

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_b"
# read_lib $lib_file_b

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_c"
# read_lib $lib_file_c

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_d"
# read_lib $lib_file_d

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_e"
# read_lib $lib_file_e

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_f"
# read_lib $lib_file_f

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_g"
# read_lib $lib_file_g

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_h"
# read_lib $lib_file_h

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_i"
# read_lib $lib_file_i

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_j"
# read_lib $lib_file_j

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_k"
# read_lib $lib_file_k

# # ---- Read Liberty file ----
# puts "INFO: Reading Liberty file: $lib_file_l"
# read_lib $lib_file_l

# ---- Read Liberty file ----
puts "INFO: Reading Liberty file: $lib_file_m"
read_lib $lib_file_m


# ---- Write .db file ----
puts "INFO: Writing DB file..."
# write_lib NangateOpenCellLibrary -format db -output "$out_dir/NangateOpenCellLibrary.db"
# write_lib fakeram45_32x64 -format db -output "$out_dir/fakeram45_32x64.db"
# write_lib fakeram45_64x7 -format db -output "$out_dir/fakeram45_64x7.db"
# write_lib fakeram45_64x15 -format db -output "$out_dir/fakeram45_64x15.db"
# write_lib fakeram45_64x21 -format db -output "$out_dir/fakeram45_64x21.db"
# write_lib fakeram45_64x32 -format db -output "$out_dir/fakeram45_64x32.db"
# write_lib fakeram45_64x96 -format db -output "$out_dir/fakeram45_64x96.db"
# write_lib fakeram45_256x34 -format db -output "$out_dir/fakeram45_256x34.db"
# write_lib fakeram45_256x95 -format db -output "$out_dir/fakeram45_256x95.db"
# write_lib fakeram45_256x96 -format db -output "$out_dir/fakeram45_256x96.db"
# write_lib fakeram45_512x64 -format db -output "$out_dir/fakeram45_512x64.db"
# write_lib fakeram45_1024x32 -format db -output "$out_dir/fakeram45_1024x32.db"
# write_lib fakeram45_2048x39 -format db -output "$out_dir/fakeram45_2048x39.db"
write_lib nangate45_merged -format db -output "$out_dir/merged.db"
puts "\nSUCCESS: DB written to: $out_dir/NangateOpenCellLibrary.db\n"
exit 0
