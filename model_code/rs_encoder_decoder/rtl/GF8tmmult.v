// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Serial Hardware Multiplier

module GF8tmmult(clk_i, rst_i, 
  en_i,       // Valid Input Set it to High When giving the input
  tmmult_i,   // Gallios Field Generic Bit Serial Multiplier output
  tmmult_o   // Gallios Field Generic Bit Serial Multiplier output
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input en_i;
  input [7:0] tmmult_i;
  output wire [7:0] tmmult_o;
 
  // Declaration of Wires 
  wire [7:0] lfsr;
  GF8lfsr LFSR(.clk_i(clk_i), .rst_i(rst_i), 
    .en_i(en_i), // Valid Input Set it to High When giving the input
    .lfsr_o(lfsr)   // Gallios Field Generic Bit Serial Multiplier output
  );
 
  GF8GenMult MULT(
    .mult_i1(lfsr),
    .mult_i2(tmmult_reg),
    .mult_o(tmmult_o));
 
endmodule
