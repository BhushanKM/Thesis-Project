// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Serial Hardware Multiplier

module GF8GenMultBitSer(clk_i, rst_i, 
  valid_i, // Valid Input Set it to High When giving the input
  mult_i1, // Gallios Field Generic Bit Serial Multiplier input 1
  mult_i2, // Gallios Field Generic Bit Serial Multiplier input 2
  valid_o, // Valid Out High When The output is ready
  mult_o   // Gallios Field Generic Bit Serial Multiplier output
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input valid_i;
  input [7:0] mult_i1, mult_i2;
  output reg valid_o;
  output wire [7:0] mult_o;
  // Declaration of Wires And Register are here 
  reg [7:0] regA, regB, regC;
  reg [3:0] cnt;
  reg [0:0] state;

  assign mult_o = regA;

  parameter WAIT = 1'b0;
  parameter PROCESS = 1'b1;
  // Counter To Calculate The Clock cycles for the Output
  always @(posedge clk_i) begin
	  if(rst_i) begin
      cnt = 0;
      regA <= 0;
      regB <= 0;
      regC <= 0;
      valid_o <= 0;
      state <= WAIT;
    end
    else begin
      case(state)
        WAIT:    if(valid_i) begin      
                   state <= PROCESS;
                   regA <= 0;
                   regC[0]<= mult_i1[7];
                   regC[1]<= mult_i1[6];
                   regC[2]<= mult_i1[5];
                   regC[3]<= mult_i1[4];
                   regC[4]<= mult_i1[3];
                   regC[5]<= mult_i1[2];
                   regC[6]<= mult_i1[1];
                   regC[7]<= mult_i1[0];
                   regB[0]<= mult_i2[0];
                   regB[1]<= mult_i2[1];
                   regB[2]<= mult_i2[2];
                   regB[3]<= mult_i2[3];
                   regB[4]<= mult_i2[4];
                   regB[5]<= mult_i2[5];
                   regB[6]<= mult_i2[6];
                   regB[7]<= mult_i2[7];
                   cnt = 0;
                   valid_o <= 0;
                 end else begin
                   state <= WAIT;
                   cnt = 0;
                   regA <= 0;
                   regB <= 0;
                   regC <= 0;
                   valid_o <= 0;
                 end
        PROCESS: if(cnt == 8) begin 
                   state <= WAIT;
                   valid_o <= 1;
                   regA <= regA;
                   regB <= regB;
                   regC <= regC;
                 end else begin
                   state <= PROCESS;
                   regA[0] <= regA[0]^(regC[7]&regB[0]);
                   regA[1] <= regA[1]^(regC[7]&regB[1]);
                   regA[2] <= regA[2]^(regC[7]&regB[2]);
                   regA[3] <= regA[3]^(regC[7]&regB[3]);
                   regA[4] <= regA[4]^(regC[7]&regB[4]);
                   regA[5] <= regA[5]^(regC[7]&regB[5]);
                   regA[6] <= regA[6]^(regC[7]&regB[6]);
                   regA[7] <= regA[7]^(regC[7]&regB[7]);

                   regB[1] <= regB[0];
                   regB[2] <= regB[1]^regB[7];
                   regB[3] <= regB[2]^regB[7];
                   regB[4] <= regB[3]^regB[7];
                   regB[5] <= regB[4];
                   regB[6] <= regB[5];
                   regB[7] <= regB[6];
                   regB[0] <= regB[7];

                   regC[1] <= regC[0];
                   regC[2] <= regC[1];
                   regC[3] <= regC[2];
                   regC[4] <= regC[3];
                   regC[5] <= regC[4];
                   regC[6] <= regC[5];
                   regC[7] <= regC[6];
                   regC[0] <= regC[7];

                   cnt = cnt + 1;
                   valid_o <= 0;
                 end
        default : state <= WAIT;
      endcase
    end
  end
endmodule
