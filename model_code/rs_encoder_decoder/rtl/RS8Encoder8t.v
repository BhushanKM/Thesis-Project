// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Hardware DFT and IDFT

module RS8Encoder8t(clk_i, rst_i, 
  encoder_i, // Control Signal calculates dft if dft_idft = 0 else idft if dft_idft = 1
  valid_i, // Control Signal
  encoder_o,  // Gallios Field Register input 1
  parity_o,
  busy_o
  );
  // Inputs are declared here
  input clk_i,rst_i;			// Clock and Reset Declaration
  input valid_i; // Controll Signal That does All the Required Operations
  input [7:0] encoder_i;
  output reg [7:0] encoder_o;
  output reg parity_o;
  output reg busy_o;
  
  // Declaration of Wires And Register are here 
  reg [7:0] enc_reg;  // register inputs
  reg [7:0] reg_o [0:15];
  reg reg_o_o;
  reg [7:0] add_i;
  reg [8:0] input_counter;
  wire [7:0] mult_o[0:15];
  
    

  // Combinational Body 
  always @(input_counter or reg_o[0] or encoder_i) begin 
    if (input_counter < 241) begin
      encoder_o = enc_reg;
    end
    else begin
      encoder_o = reg_o[0];
    end
  end
  
  always @(input_counter) begin
    if(|input_counter)
      parity_o = 1;
    else 
      parity_o = 0;
  end
  
  always @(input_counter)begin
    if(input_counter>=239)
      busy_o = 1;
    else 
      busy_o = 0;
  end
  
  always @(input_counter or encoder_i or reg_o[0]) begin
    if(input_counter == 1)
      add_i = enc_reg;
    else if(input_counter <240)
      add_i = reg_o[0]^enc_reg;
    else 
      add_i = 8'b0;
  end

  // Sequential Circuit Starts from Here
  // input counter that counts no of inputs set
  always @(posedge clk_i) begin
    if(rst_i) 
      enc_reg <= 0;
    else 
      enc_reg <= encoder_i;
  end 
  
  always @(posedge clk_i) begin 
    if((rst_i) || (input_counter[8]))  begin
      input_counter <= 0;
    end
    else if (valid_i) begin
      input_counter <= input_counter + 1;
    end
  end
    
  always @(posedge clk_i) begin
    if (rst_i) begin
      reg_o[0]  <= 0;
      reg_o[1]  <= 0;
      reg_o[2]  <= 0;
      reg_o[3]  <= 0;
      reg_o[4]  <= 0;
      reg_o[5]  <= 0;
      reg_o[6]  <= 0;
      reg_o[7]  <= 0;
      reg_o[8]  <= 0;
      reg_o[9]  <= 0;
      reg_o[10] <= 0;
      reg_o[11] <= 0;
      reg_o[12] <= 0;
      reg_o[13] <= 0;
      reg_o[14] <= 0;
      reg_o[15] <= 0;
    end
    else if(input_counter == 1) begin
      reg_o[0] <= mult_o[0];
      reg_o[1] <= mult_o[1];
      reg_o[2] <= mult_o[2];
      reg_o[3] <= mult_o[3];
      reg_o[4] <= mult_o[4];
      reg_o[5] <= mult_o[5];
      reg_o[6] <= mult_o[6];
      reg_o[7] <= mult_o[7];
      reg_o[8] <= mult_o[8];
      reg_o[9] <= mult_o[9];
      reg_o[10] <= mult_o[10];
      reg_o[11] <= mult_o[11];
      reg_o[12] <= mult_o[12];
      reg_o[13] <= mult_o[13];
      reg_o[14] <= mult_o[14];
      reg_o[15] <= mult_o[15];    
    end
    else begin
      reg_o[0] <= reg_o[1]^mult_o[0];
      reg_o[1] <= reg_o[2]^mult_o[1];
      reg_o[2] <= reg_o[3]^mult_o[2];
      reg_o[3] <= reg_o[4]^mult_o[3];
      reg_o[4] <= reg_o[5]^mult_o[4];
      reg_o[5] <= reg_o[6]^mult_o[5];
      reg_o[6] <= reg_o[7]^mult_o[6];
      reg_o[7] <= reg_o[8]^mult_o[7];
      reg_o[8] <= reg_o[9]^mult_o[8];
      reg_o[9] <= reg_o[10]^mult_o[9];
      reg_o[10] <= reg_o[11]^mult_o[10];
      reg_o[11] <= reg_o[12]^mult_o[11];
      reg_o[12] <= reg_o[13]^mult_o[12];
      reg_o[13] <= reg_o[14]^mult_o[13];
      reg_o[14] <= reg_o[15]^mult_o[14];
      reg_o[15] <= mult_o[15];
    end
  end

///////////////// Structural Model ////////////////
 
  // Multipliers Depending on the Generator Polynomial
  GF8Mult121 MULT_0(
    .mult_i(add_i), 
    .mult_o(mult_o[0]) );
 
  GF8Mult106 MULT_1(
    .mult_i(add_i), 
    .mult_o(mult_o[1]) );
 
  GF8Mult110 MULT_2(
    .mult_i(add_i), 
    .mult_o(mult_o[2]) );
 
  GF8Mult113 MULT_3(
    .mult_i(add_i), 
    .mult_o(mult_o[3]) );
 
  GF8Mult107 MULT_4(
    .mult_i(add_i), 
    .mult_o(mult_o[4]) );
 
  GF8Mult167 MULT_5(
    .mult_i(add_i), 
    .mult_o(mult_o[5]) );
 
  GF8Mult83 MULT_6(
    .mult_i(add_i), 
    .mult_o(mult_o[6]) );
 
  GF8Mult11 MULT_7(
    .mult_i(add_i), 
    .mult_o(mult_o[7]) );
 
  GF8Mult100 MULT_8(
    .mult_i(add_i), 
    .mult_o(mult_o[8]) );
 
  GF8Mult201 MULT_9(
    .mult_i(add_i), 
    .mult_o(mult_o[9]) );
 
  GF8Mult158 MULT_10(
    .mult_i(add_i), 
    .mult_o(mult_o[10]) );
 
  GF8Mult181 MULT_11(
    .mult_i(add_i), 
    .mult_o(mult_o[11]) );
 
  GF8Mult195 MULT_12(
    .mult_i(add_i), 
    .mult_o(mult_o[12]) );
 
  GF8Mult208 MULT_13(
    .mult_i(add_i), 
    .mult_o(mult_o[13]) );
 
  GF8Mult240 MULT_14(
    .mult_i(add_i), 
    .mult_o(mult_o[14]) );
 
  GF8Mult136 MULT_15(
    .mult_i(add_i), 
    .mult_o(mult_o[15]) );
 

  ///////////INPUT ADDER///////// 
 
 
endmodule
