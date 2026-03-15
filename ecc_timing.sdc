################################################################################
# SDC Timing Constraints for ECC Engine Top
# Design: ecc_engine_top
# Project: ECC implementation for HBM4
# Author: Bhushan Kiran Munoli
# Date: 2026
################################################################################

################################################################################
# CLOCK DEFINITION
################################################################################
# Primary clock - adjust period based on target frequency
# 5ns period = 200 MHz (conservative for FPGA)
# 2.5ns period = 400 MHz (aggressive)
# 2ns period = 500 MHz (high performance)

set CLK_PERIOD 5.0
set CLK_NAME clk

create_clock -name $CLK_NAME -period $CLK_PERIOD [get_ports clk]

# Clock uncertainty (includes jitter, skew, and margin)
# Typical values: 0.1-0.3ns for FPGA
set_clock_uncertainty 0.2 [get_clocks $CLK_NAME]

# Clock transition time
set_clock_transition 0.1 [get_clocks $CLK_NAME]

################################################################################
# INPUT CONSTRAINTS
################################################################################
# Input delay relative to clock edge
# Assumes external device has similar clock-to-output delay

set INPUT_DELAY_MAX [expr $CLK_PERIOD * 0.6]
set INPUT_DELAY_MIN [expr $CLK_PERIOD * 0.1]

# Control signals
set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports rst_n]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports rst_n]

set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports test_mode_en]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports test_mode_en]

set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports cw_sel]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports cw_sel]

# Write path signals
set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports wr_valid]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports wr_valid]

set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports wr_data[*]]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports wr_data[*]]

# Read path signals
set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports rd_valid]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports rd_valid]

set_input_delay -clock $CLK_NAME -max $INPUT_DELAY_MAX [get_ports rd_codeword[*]]
set_input_delay -clock $CLK_NAME -min $INPUT_DELAY_MIN [get_ports rd_codeword[*]]

################################################################################
# OUTPUT CONSTRAINTS
################################################################################
# Output delay relative to clock edge
# Assumes external device setup/hold requirements

set OUTPUT_DELAY_MAX [expr $CLK_PERIOD * 0.6]
set OUTPUT_DELAY_MIN [expr $CLK_PERIOD * 0.1]

# Write path outputs
set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports wr_ready]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports wr_ready]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports enc_valid_out]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports enc_valid_out]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports enc_codeword_out[*]]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports enc_codeword_out[*]]

# Read path outputs
set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports rd_out_valid]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports rd_out_valid]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports rd_data_out[*]]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports rd_data_out[*]]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports sev_out[*]]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports sev_out[*]]

# Status outputs
set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports error_detected]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports error_detected]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports error_corrected]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports error_corrected]

set_output_delay -clock $CLK_NAME -max $OUTPUT_DELAY_MAX [get_ports uncorrectable]
set_output_delay -clock $CLK_NAME -min $OUTPUT_DELAY_MIN [get_ports uncorrectable]

################################################################################
# ASYNCHRONOUS RESET
################################################################################
# Reset is asynchronous - set as false path for timing analysis
# but ensure proper synchronization in actual design

set_false_path -from [get_ports rst_n]

################################################################################
# MULTICYCLE PATHS (if applicable)
################################################################################
# The GF inverse computation (gf_inv_16) takes ~30 cycles
# If used in the design path, define multicycle constraint
# Uncomment if gf_inv_16 sequential module is instantiated in critical path

# set_multicycle_path 30 -setup -from [get_pins */gf_inv_16/start] -to [get_pins */gf_inv_16/done]
# set_multicycle_path 29 -hold  -from [get_pins */gf_inv_16/start] -to [get_pins */gf_inv_16/done]

################################################################################
# FALSE PATHS
################################################################################
# Test mode configuration is quasi-static (changes only during initialization)

set_false_path -from [get_ports test_mode_en]
set_false_path -from [get_ports cw_sel]

################################################################################
# MAX DELAY CONSTRAINTS (for combinational paths)
################################################################################
# Constrain maximum combinational delay for critical paths
# This helps prevent overly long combinational chains

set_max_delay [expr $CLK_PERIOD * 0.8] -from [get_ports wr_data[*]] -to [get_ports enc_codeword_out[*]]
set_max_delay [expr $CLK_PERIOD * 0.8] -from [get_ports rd_codeword[*]] -to [get_ports rd_data_out[*]]

################################################################################
# CLOCK GROUPS (if multiple clocks exist)
################################################################################
# Uncomment if design has multiple asynchronous clock domains

# set_clock_groups -asynchronous -group [get_clocks clk] -group [get_clocks clk2]

################################################################################
# DESIGN RULE CONSTRAINTS
################################################################################
# Maximum fanout to prevent excessive routing delays

set_max_fanout 32 [current_design]

# Maximum transition time
set_max_transition 0.5 [current_design]

################################################################################
# OPERATING CONDITIONS (optional - for ASIC flow)
################################################################################
# Uncomment for ASIC synthesis with specific library corners

# set_operating_conditions -max slow -min fast

################################################################################
# END OF CONSTRAINTS
################################################################################
