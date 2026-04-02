//  This is a verilog File Generated
//  By The C++ program That Generates
//  An Gallios Field Hardware Mux

module Mux8To1(sel_i, // Select Line
  mux_i0, //Input 0
  mux_i1, //Input 1
  mux_o //Output from the MUX
);
  // Inputs are declared here
  // Ports are declared here
  input sel_i;
  input [7:0] mux_i0, mux_i1;
  output wire [7:0] mux_o;
 
  assign mux_o = sel_i?mux_i1:mux_i0;

endmodule
