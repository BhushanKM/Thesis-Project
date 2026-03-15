lappend search_path scripts design_data

set TECH_FILE "./constraints/ref/tech/saed32nm_lp9m.tcl"
set REFLIB "./constraints/ref/CLIBs"

set REFERENCE_LIBRARY [join "
$REFLIB/saed32_hvt.ndm
$REFLIB/saed32_lvt.ndm
$REFLIB/saed32_rvt.ndm
$REFLIB/saed32_sram_lp.ndm
"]