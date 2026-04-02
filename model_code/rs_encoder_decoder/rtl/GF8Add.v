// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Hardware Adder

module GF8Add(
  add_i1, // Gallios Field Adder input 1
  add_i2, // Gallios Field Adder input 2
  add_o   // Gallios Field Adder output
  );
  // Inputs are declared here
  input [7:0] add_i1,add_i2;
  output wire [7:0] add_o;

  // Declaration of Wires And Register are here 
 
  // Combinational Logic Body 
  assign add_o[0] = add_i1[0]^add_i2[0];
  assign add_o[1] = add_i1[1]^add_i2[1];
  assign add_o[2] = add_i1[2]^add_i2[2];
  assign add_o[3] = add_i1[3]^add_i2[3];
  assign add_o[4] = add_i1[4]^add_i2[4];
  assign add_o[5] = add_i1[5]^add_i2[5];
  assign add_o[6] = add_i1[6]^add_i2[6];
  assign add_o[7] = add_i1[7]^add_i2[7];
endmodule
