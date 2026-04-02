// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field 
// Hardware Inversion Circuit takes m-1 clockcycles

module GF8Inverse(clk_i, rst_i, 
  valid_i, // Valid Input Set it to High When giving the input
  inv_i, // Gallios Field Inverter input 
  valid_o, // Valid Out High When The output is ready
  inv_o   // Gallios Field Inversion output
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input valid_i;
  input [7:0] inv_i;
  output reg valid_o;
  output wire [7:0] inv_o;
  // Declaration of Wires And Register are here 
  reg [7:0] regSquare, regMult;
  reg [2:0] cnt;
  reg [0:0] state;
  wire [7:0] multSquare_o, multMult_o;

  assign inv_o = regMult;

  GF8GenMult SQUARE(
    .mult_i1(regSquare), // Gallios Field Generic Multiplier input 1
    .mult_i2(regSquare), // Gallios Field Generic Multiplier input 2
    .mult_o(multSquare_o));   // Gallios Field Generic Multiplier output
  GF8GenMult MULTIPLY(
    .mult_i1(multSquare_o), // Gallios Field Generic Multiplier input 1
    .mult_i2(regMult), // Gallios Field Generic Multiplier input 2
    .mult_o(multMult_o));   // Gallios Field Generic Multiplier output
  parameter WAIT = 1'b0;
  parameter PROCESS = 1'b1;
  // CONTROLLER TO VALIDATE THE OUTPUT
  always @(posedge clk_i) begin
	  if(rst_i) begin
      cnt = 0;
      regSquare <= 0;
      regMult <= 0;
      valid_o <= 0;
      state <= WAIT;
    end
    else begin
      case(state)
        WAIT:    if(valid_i) begin      
                   // State machine
                   state <= PROCESS;

                   // REGISTER
                   regSquare<= inv_i;
                   regMult[0]<= 1'b1;
                   regMult[1]<= 1'b0;
                   regMult[2]<= 1'b0;
                   regMult[3]<= 1'b0;
                   regMult[4]<= 1'b0;
                   regMult[5]<= 1'b0;
                   regMult[6]<= 1'b0;
                   regMult[7]<= 1'b0;

                   // VALIDATION
                   cnt = 0;
                   valid_o <= 0;
                 end else begin
                   // State machine
                   state <= WAIT;

                   // REGISTER
                   regSquare <= 0;
                   regMult <= 0;

                   // VALIDATION
                   valid_o <= 0;
                   cnt = 0;
                 end
        PROCESS: if(cnt == 7) begin 
                   // State machine
                   state <= WAIT;

                   // REGISTER
                   regSquare <= regSquare;
                   regMult <= regMult;

                   // VALIDATION
                   cnt = 0;
                   valid_o <= 1;
                 end else begin
                   // State machine
                   state <= PROCESS;

                   // REGISTER
                   regSquare <= multSquare_o;
                   regMult <= multMult_o;

                   // VALIDATION
                   cnt = cnt + 1;
                   valid_o <= 0;
                 end
        default : state <= WAIT;
      endcase
    end
  end
endmodule
