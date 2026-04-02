// This is a verilog File Generated
// By The C++ program That Generates
// ARG1 and ARG2 Adder
// And uses GF Adder and Multiplier

module GF8SigmaAdder8t( 
arg_i1,
arg_i2,
NewSigma
);
  // Declaration of the inputs
  input [71:0] arg_i1;
  input [71:0] arg_i2;
  output wire [71:0] NewSigma;
 
  // Declaration of registers and Wire is Here 

 assign NewSigma = arg_i1^arg_i2;

endmodule

