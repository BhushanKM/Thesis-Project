// This is a verilog File Generated
// By The C++ program That Generates
// Gallios Field Error Loc Poly finder using
// Barlekamp Messay Algorithm only contins
// This Contains Only the Circuit

module RS8ErrLocPoly8t(clk_i,rst_i,
  valid_i,      // input 1
  delta_i,      // input 1
  step_i,      // input 1
  done_dec_i,      // input 1
  valid_o,    // output 
  sigma_0_o,    // output 
  sigma_last_o,    // output 
  sigma_o,    // output 
  busy_o
  );
  // Declaration of the inputs
  input clk_i,rst_i;
  input valid_i;
  input done_dec_i;
  input [7:0] delta_i;
  input [7:0] step_i;
  output reg valid_o;
  output reg busy_o;
  output wire [71:0] sigma_0_o, sigma_o, sigma_last_o;
  
  // Declaration of Wires are here 
  wire [71:0] arg1;
  wire [71:0] arg2;
  wire [71:0] newSigma;
  wire [7:0] sigma_0_inv;
  wire [7:0] sigma_last_inv;
  wire signed [7:0] inL;
  wire signed [7:0] add_res;
  wire inv_done1, inv_done2;
 
  // Declaration of Register are here 
  reg [71:0] prevSigma, sigma_2L, sigma;
  reg [7:0] prevDelta;
  reg [7:0] L;
  reg [3:0] state;
  reg inv_en;

  assign sigma_o = sigma;
  assign sigma_0_o = sigma_2L;  
  assign sigma_last_o = prevSigma;
  
  GF8Inverse INVERS1(.clk_i(clk_i),.rst_i(rst_i),
    .valid_i(inv_en),        // 
    .inv_i(sigma[7:0]),     // 
    .valid_o(inv_done1),      // 
    .inv_o(sigma_last_inv));     // 
  
  GF8Inverse INVERS2(.clk_i(clk_i),.rst_i(rst_i),
    .valid_i(inv_en),        // 
    .inv_i(sigma[71:64]),     // 
    .valid_o(inv_done),      // 
    .inv_o(sigma_0_inv));     // 
  
  parameter INIT       = 4'b0000;
  parameter WAIT       = 4'b0001;
  parameter CALCSIGMA1 = 4'b0010;
  parameter CALCSIGMA2 = 4'b0011;
  parameter SHIFT      = 4'b0100;
  parameter UPDATE     = 4'b0101;
  parameter DONESTEP   = 4'b0110;
  parameter INVERSE    = 4'b0111;
  parameter DONEBM     = 4'b1000;

  assign add_res = step_i - L;
  assign inL = add_res +1;

  // Barlekamp Messey Algorithm State Machine
  always @(posedge clk_i) begin
	  if((rst_i)||(done_dec_i))begin
      state <= INIT;
      prevDelta <= 0;
      prevSigma <= 0;
      sigma_2L <= 0;
      sigma <= 0;
      L <= 0;
      valid_o <= 0;
      inv_en <= 0;
      busy_o <= 0;
    end
    else begin
      case(state)
        INIT: begin
          //state transition
          state <= WAIT;
          prevSigma <= 72'b000000010000000000000000000000000000000000000000000000000000000000000000;
          sigma <= 72'b000000010000000000000000000000000000000000000000000000000000000000000000;
          prevDelta <= 8'b00000001;
          sigma_2L <= 72'b000000010000000000000000000000000000000000000000000000000000000000000000;
          L <= 0;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        WAIT: begin
          //state transition
          if((valid_i) && (|delta_i)) begin
            state <= CALCSIGMA1;
          end
	        else if((valid_i) && (~(|delta_i)))begin
            state <= SHIFT;
          end
          else begin
            state <= WAIT;
          end
          prevSigma <= prevSigma;
          prevDelta <= prevDelta;
          sigma_2L  <= sigma_2L;
          sigma <= sigma;
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        CALCSIGMA1: begin
          //state transition
          state <= CALCSIGMA2;
          //output transition
          prevSigma <= sigma;
          sigma <= sigma;
          prevDelta <= prevDelta;
          sigma_2L <= sigma_2L;
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        CALCSIGMA2: begin
          //state transition
	        if (step_i<(L<<1))
            state <= SHIFT;
          else 
            state <= UPDATE;
          //output transition
          prevSigma <= prevSigma;
          sigma <= newSigma;
          prevDelta <= prevDelta;
          sigma_2L <= sigma_2L;
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        SHIFT: begin
          state <= DONESTEP;
          //output transition
          prevSigma <= prevSigma;
          sigma <= sigma;
          prevDelta <= prevDelta;
          sigma_2L <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0, sigma_2L[71:8]};
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        UPDATE: begin
          state <= DONESTEP;
          valid_o <= 0;
          prevSigma <= prevSigma;
          sigma <= sigma;
          prevDelta <= delta_i;
          sigma_2L <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0, prevSigma[71:8]};
          L <= inL;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        DONESTEP: begin
          if (step_i < 15) begin
            state <= WAIT;
            inv_en <= 0;
          end
          else begin
            state <= INVERSE;
            inv_en <= 1;
          end
          prevSigma <= prevSigma;
          prevDelta <= prevDelta;
          sigma_2L <= sigma_2L;
          sigma <= sigma;
          L <= L;
          valid_o <= 1;
          busy_o <= 0;
        end
        INVERSE: begin
          if (inv_done) begin
            state <= DONEBM;
          end
          else begin
            state <= INVERSE;
          end
          prevDelta <= prevDelta;
          sigma <= sigma;
          sigma_2L <= {sigma[63:0],sigma_0_inv};
          prevSigma <={sigma[71:8],sigma_last_inv};
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 1;
        end
        DONEBM: begin
          if(done_dec_i)
            state <= INIT;
          else
            state <= DONEBM;
          prevSigma <= prevSigma;
          prevDelta <= prevDelta;
          sigma_2L <= sigma_2L;
          sigma <= sigma;
          L <= L;
          valid_o <= 0;
          inv_en <= 0;
          busy_o <= 0;
        end
        default: begin
          state <= INIT;
          prevSigma <= prevSigma;
          prevDelta <= prevDelta;
          sigma_2L <= sigma_2L;
          sigma <= sigma;
          L <= 0;
          inv_en <= 0;
          busy_o <= 0;
          valid_o <= 0;
        end
      endcase
    end
  end
 
 ////////// ARG1 Multiplication ////////// 
    GF8GenMult ARG1MULT0(
      .mult_i1(prevSigma[7:0]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[7:0])); // Generic Multiplier output
    GF8GenMult ARG1MULT1(
      .mult_i1(prevSigma[15:8]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[15:8])); // Generic Multiplier output
    GF8GenMult ARG1MULT2(
      .mult_i1(prevSigma[23:16]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[23:16])); // Generic Multiplier output
    GF8GenMult ARG1MULT3(
      .mult_i1(prevSigma[31:24]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[31:24])); // Generic Multiplier output
    GF8GenMult ARG1MULT4(
      .mult_i1(prevSigma[39:32]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[39:32])); // Generic Multiplier output
    GF8GenMult ARG1MULT5(
      .mult_i1(prevSigma[47:40]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[47:40])); // Generic Multiplier output
    GF8GenMult ARG1MULT6(
      .mult_i1(prevSigma[55:48]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[55:48])); // Generic Multiplier output
    GF8GenMult ARG1MULT7(
      .mult_i1(prevSigma[63:56]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[63:56])); // Generic Multiplier output
    GF8GenMult ARG1MULT8(
      .mult_i1(prevSigma[71:64]), // Generic Multiplier input 1
      .mult_i2(prevDelta), // Generic Multiplier input 2
      .mult_o(arg1[71:64])); // Generic Multiplier output
 
 
 ////////// ARG2 Multiplication ////////// 
    GF8GenMult ARG2MULT0(
      .mult_i1(sigma_2L[7:0]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[7:0])); // Generic Multiplier output
    GF8GenMult ARG2MULT1(
      .mult_i1(sigma_2L[15:8]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[15:8])); // Generic Multiplier output
    GF8GenMult ARG2MULT2(
      .mult_i1(sigma_2L[23:16]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[23:16])); // Generic Multiplier output
    GF8GenMult ARG2MULT3(
      .mult_i1(sigma_2L[31:24]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[31:24])); // Generic Multiplier output
    GF8GenMult ARG2MULT4(
      .mult_i1(sigma_2L[39:32]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[39:32])); // Generic Multiplier output
    GF8GenMult ARG2MULT5(
      .mult_i1(sigma_2L[47:40]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[47:40])); // Generic Multiplier output
    GF8GenMult ARG2MULT6(
      .mult_i1(sigma_2L[55:48]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[55:48])); // Generic Multiplier output
    GF8GenMult ARG2MULT7(
      .mult_i1(sigma_2L[63:56]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[63:56])); // Generic Multiplier output
    GF8GenMult ARG2MULT8(
      .mult_i1(sigma_2L[71:64]), // Generic Multiplier input 1
      .mult_i2(delta_i), // Generic Multiplier input 2
      .mult_o(arg2[71:64])); // Generic Multiplier output
 
 
 ////////// SIGMA ADDER////////// 
    GF8SigmaAdder8t ARG1CT(
      .arg_i1(arg1),
      .arg_i2(arg2),
      .NewSigma(newSigma)
    );
 
endmodule
