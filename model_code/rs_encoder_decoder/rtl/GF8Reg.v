// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Hardware Register

module GF8Reg(clk_i, rst_i, 
  en_i, // Enable Signal
  reg_i, // Gallios Field Register input 1
  reg_o   // Gallios Field Register output
  );
  // Inputs are declared here
  input clk_i,rst_i,en_i;			// Clock and Reset Declaration
  input [7:0] reg_i;
  output reg [7:0] reg_o;

  // Declaration of Wires And Register are here 
 
  // Sequential Body
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      reg_o = 0;
    else if(en_i)
      reg_o = reg_i;
  end
endmodule
