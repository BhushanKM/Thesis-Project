// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Serial Hardware Multiplier

module GF8lfsr(clk_i, rst_i, 
  en_i, // Valid Input Set it to High When giving the input
  lfsr_o   // Gallios Field Generic Bit Serial Multiplier output
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input en_i;
  output reg [7:0] lfsr_o;
  // Declaration of Wires And Register are here 

  always @(posedge clk_i or posedge rst_i) begin 
    if(rst_i) begin
      lfsr_o[7] <=1'b0;
      lfsr_o[6] <=1'b0;
      lfsr_o[5] <=1'b0;
      lfsr_o[4] <=1'b0;
      lfsr_o[3] <=1'b0;
      lfsr_o[2] <=1'b0;
      lfsr_o[1] <=1'b0;
      lfsr_o[0] <=1'b1;
    end
    else if(en_i) begin
      lfsr_o[1] <= lfsr_o[0];
      lfsr_o[2] <= lfsr_o[1]^lfsr_o[7];
      lfsr_o[3] <= lfsr_o[2]^lfsr_o[7];
      lfsr_o[4] <= lfsr_o[3]^lfsr_o[7];
      lfsr_o[5] <= lfsr_o[4];
      lfsr_o[6] <= lfsr_o[5];
      lfsr_o[7] <= lfsr_o[6];
      lfsr_o[0] <= lfsr_o[7];
    end
  end
endmodule
