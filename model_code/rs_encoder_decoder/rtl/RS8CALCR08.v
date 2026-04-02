// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Hardware Register

module RS8CALCR08(clk_i, rst_i, 
  en_i,        // Enable Signal
  sigma_i,     // sigma value in to calculate R0
  syndrom_i,   // Syndrom value from the memory
  loc_o,       // mem_address
  R_0_o,       // Valid R_o when valid_o == 1
  valid_o,     // When processing done
  done_dec_i   // input to clear all the registers
  );
  // Inputs are declared here
  input clk_i,rst_i,en_i;			// Clock and Reset Declaration
  input [71:0] sigma_i;
  input [7:0] syndrom_i;
  input done_dec_i;
  output reg valid_o;
  output reg [7:0] R_0_o;
  output reg [7:0] loc_o;

  // Declaration of Wires And Register are here 
  wire [7:0] add_i1;
  wire [7:0] add_o;
  reg acc;
  reg [7:0] add_acc;
  reg [7:0] mult_i2;
  reg [7:0] mult_i1;
  reg [71:0] sigma_t;
  
  always@(posedge clk_i) begin
    if(rst_i) begin
      add_acc = 0;
    end
    else if(acc) begin 
      add_acc = add_o;
    end
  end
  
  GF8GenMult MULT(
    .mult_i1(mult_i1), // Generic Multiplier input 1
    .mult_i2(mult_i2), // Generic Multiplier input 2
    .mult_o(add_i1)); // Generic Multiplier output
    
  GF8Add Add_ACC(  
    .add_i1(add_i1),
    .add_i2(add_acc),
    .add_o(add_o));
 
  
  // Declaration of Register are here 
  reg [2:0] state;

  parameter INIT       = 3'b000;
  parameter WAIT       = 3'b001;
  parameter CALC_ACC   = 3'b010;
  parameter INVERS     = 3'b011;
  parameter MULT_LAST  = 3'b100;
  parameter DONE       = 3'b101;
  

  always @(posedge clk_i) begin
	  if(rst_i) begin
      state <= INIT;
      loc_o <= 0;
      mult_i2 <= 0;
      mult_i1 <= 0;
      sigma_t <= 0;
      acc <= 0;
      valid_o <= 0;
      R_0_o   <= 0;
    end
    else begin
      case(state)
        INIT: begin
          state <= WAIT;
          loc_o <= 8;
          mult_i2 <= 0;
          mult_i1 <= 0;
          sigma_t <= 0;
          acc <= 0;
          valid_o <= 0;
          R_0_o   <= 0;
        end
        WAIT: begin
          if (en_i) begin
            state <= CALC_ACC;
          end
          else begin
            state <= WAIT;
          end
          loc_o <= 8;
          mult_i2 <= 0;
          mult_i1 <= 0;
          sigma_t <= sigma_i;
          acc <= 0;
          valid_o <= 0;
          R_0_o   <= R_0_o;
        end
        CALC_ACC: begin
          if (loc_o < 15) begin
            state <= CALC_ACC;
          end
          else begin
            state <= MULT_LAST;
          end
          loc_o <= loc_o + 1;
          mult_i1 <= syndrom_i;
          mult_i2 <= sigma_t[71:64];
          sigma_t <= sigma_t<<8;
          acc <= 1;
          valid_o <= 0;
          R_0_o   <= R_0_o;
        end
        MULT_LAST: begin
          state <= DONE;
          loc_o <= 0;
          mult_i1 <= add_acc;
          mult_i2 <= sigma_t[71:64];
          sigma_t <= sigma_t;
          acc <= 0;
          valid_o <= 1;
          R_0_o   <= add_i1;
        end
        DONE: begin
          if (done_dec_i)
            state <= INIT;
          else
            state <= DONE;
          loc_o <= 0;
          mult_i2 <= add_acc;
          mult_i1 <= sigma_t[71:64];
          sigma_t <= sigma_t;
          acc <= 0;
          valid_o <= 1;
          R_0_o   <= add_i1;
        end
        default: begin
          state <= INIT;
          loc_o <= 0;
          mult_i2 <= add_acc;
          mult_i1 <= sigma_t[71:64];
          sigma_t <= sigma_t;
          acc <= 0;
          valid_o <= 0;
          R_0_o   <= R_0_o;
        end
      endcase
    end
  end
  
endmodule
