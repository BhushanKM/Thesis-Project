// Include directories
-incdir ../tb
-incdir ../test
-incdir ../design

// RTL Design files (compile first)
../design/gf_mul_16.v
../design/ecc_encoder.v
../design/ecc_decoder.v
../design/ecc_engine_top.v

// UVM Package (includes all TB components via `include)
../tb/ecc_pkg.sv

// Top module (includes ecc_interface.sv and ecc_defines.sv)
../tb/ecc_top.sv
