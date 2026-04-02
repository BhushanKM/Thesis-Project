// This is a verilog File Generated
// By The C++ program That Generates
// Gallios Field Based FIR Filter
// And uses GF Adder and Multiplier

module GF8Fir8t(clk_i, rst_i, 
  en_i,         // Gallios Field FIR Filter enable 1
  fir_i,        // Gallios Field FIR Filter input 1
  sel_i,        // Gallios Field FIR Filter input 1
  coeff_i,      // Concatinated Coefficient Input
  fir_o,        // Gallios Field FIR out
  done_dec_i    // Done Decoding
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input en_i;             // Enable The input 
  input sel_i;             // Enable The input 
  input done_dec_i;
  input [7:0] fir_i;
  input [71:0] coeff_i;
  
  output wire [7:0] fir_o;
  // Declaration of Wires And Register are here 
  wire [7:0] mult_o[0:8];
  wire [7:0] add_o [0:7];
  wire [7:0] output_mux;
  wire [7:0] input_mux;
  reg [7:0] shift_reg[0:8];
 
  assign input_mux = sel_i ? mult_o[8] : fir_i;
  assign output_mux = sel_i ? add_o[6] : shift_reg[8];
  assign fir_o = sel_i ? mult_o[8] : add_o[7];
 
 
  // Sequential Body
  always @(posedge clk_i) begin
    if ((rst_i)||(done_dec_i)) begin
      shift_reg[0] <= 0;
      shift_reg[1] <= 0;
      shift_reg[2] <= 0;
      shift_reg[3] <= 0;
      shift_reg[4] <= 0;
      shift_reg[5] <= 0;
      shift_reg[6] <= 0;
      shift_reg[7] <= 0;
      shift_reg[8] <= 0;
    end
    else if(en_i) begin
      shift_reg[0] <= input_mux;
      shift_reg[1] <= shift_reg[0];
      shift_reg[2] <= shift_reg[1];
      shift_reg[3] <= shift_reg[2];
      shift_reg[4] <= shift_reg[3];
      shift_reg[5] <= shift_reg[4];
      shift_reg[6] <= shift_reg[5];
      shift_reg[7] <= shift_reg[6];
      shift_reg[8] <= shift_reg[7];
    end
  end
 
  GF8GenMult MULT0(
    .mult_i1(coeff_i[71:64]), // Generic Multiplier input 1
    .mult_i2(shift_reg[0]), // Generic Multiplier input 2
    .mult_o(mult_o[0]));   // Generic Multiplier output
 
  GF8GenMult MULT1(
    .mult_i1(coeff_i[63:56]), // Generic Multiplier input 1
    .mult_i2(shift_reg[1]), // Generic Multiplier input 2
    .mult_o(mult_o[1]));   // Generic Multiplier output
 
  GF8GenMult MULT2(
    .mult_i1(coeff_i[55:48]), // Generic Multiplier input 1
    .mult_i2(shift_reg[2]), // Generic Multiplier input 2
    .mult_o(mult_o[2]));   // Generic Multiplier output
 
  GF8GenMult MULT3(
    .mult_i1(coeff_i[47:40]), // Generic Multiplier input 1
    .mult_i2(shift_reg[3]), // Generic Multiplier input 2
    .mult_o(mult_o[3]));   // Generic Multiplier output
 
  GF8GenMult MULT4(
    .mult_i1(coeff_i[39:32]), // Generic Multiplier input 1
    .mult_i2(shift_reg[4]), // Generic Multiplier input 2
    .mult_o(mult_o[4]));   // Generic Multiplier output
 
  GF8GenMult MULT5(
    .mult_i1(coeff_i[31:24]), // Generic Multiplier input 1
    .mult_i2(shift_reg[5]), // Generic Multiplier input 2
    .mult_o(mult_o[5]));   // Generic Multiplier output
 
  GF8GenMult MULT6(
    .mult_i1(coeff_i[23:16]), // Generic Multiplier input 1
    .mult_i2(shift_reg[6]), // Generic Multiplier input 2
    .mult_o(mult_o[6]));   // Generic Multiplier output
 
  GF8GenMult MULT7(
    .mult_i1(coeff_i[15:8]), // Generic Multiplier input 1
    .mult_i2(shift_reg[7]), // Generic Multiplier input 2
    .mult_o(mult_o[7]));   // Generic Multiplier output
 
  GF8GenMult MULTLAST(
    .mult_i1(coeff_i[7:0]), // Generic Multiplier input 1
    .mult_i2(output_mux), // Generic Multiplier input 2
    .mult_o(mult_o[8]));   // Generic Multiplier output
 
  //////////  ADDER TREE ////////// 
  GF8Add Add_0(  
    .add_i1(mult_o[0]),
    .add_i2(mult_o[1]),
    .add_o(add_o[0]));
 
  GF8Add Add1(
    .add_i1(add_o[0]),
    .add_i2(mult_o[2]),
    .add_o(add_o[1]));
 
  GF8Add Add2(
    .add_i1(add_o[1]),
    .add_i2(mult_o[3]),
    .add_o(add_o[2]));
 
  GF8Add Add3(
    .add_i1(add_o[2]),
    .add_i2(mult_o[4]),
    .add_o(add_o[3]));
 
  GF8Add Add4(
    .add_i1(add_o[3]),
    .add_i2(mult_o[5]),
    .add_o(add_o[4]));
 
  GF8Add Add5(
    .add_i1(add_o[4]),
    .add_i2(mult_o[6]),
    .add_o(add_o[5]));
 
  GF8Add Add6(
    .add_i1(add_o[5]),
    .add_i2(mult_o[7]),
    .add_o(add_o[6]));
 
  GF8Add Add7(
    .add_i1(add_o[6]),
    .add_i2(mult_o[8]),
    .add_o(add_o[7]));
 
  //////////////////// 
endmodule
