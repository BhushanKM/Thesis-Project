// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Parallel Hardware Multiplier

// THIS BLOCK IS THE IMPLEMENTATION OF MODULE A 
module GF8GenMultModA(
  modA_i1, // Generic Multiplier Mod A input 1
  modA_i2, // Generic Multiplier Mod A input 2
  modA_o   // Generic Multiplier Mod A output
  );
  // Inputs are declared here
  input [7:0] modA_i1, modA_i2;
  output wire modA_o;

  // Declaration of Wires And Register are here 
  wire xor0_w0, xor0_w1, xor0_w2, xor0_w3;
  wire xor1_w0, xor1_w1;
  wire and_w0, and_w1, and_w2, and_w3, and_w4, and_w5, and_w6, and_w7;

  //LOGIC STARTS FROM HERE

  assign and_w0 = modA_i1[0] & modA_i2[0];
  assign and_w1 = modA_i1[1] & modA_i2[1];
  assign and_w2 = modA_i1[2] & modA_i2[2];
  assign and_w3 = modA_i1[3] & modA_i2[3];
  assign and_w4 = modA_i1[4] & modA_i2[4];
  assign and_w5 = modA_i1[5] & modA_i2[5];
  assign and_w6 = modA_i1[6] & modA_i2[6];
  assign and_w7 = modA_i1[7] & modA_i2[7];

  assign xor0_w0 = and_w0^and_w1; 
  assign xor0_w1 = and_w2^and_w3; 
  assign xor0_w2 = and_w4^and_w5; 
  assign xor0_w3 = and_w6^and_w7; 

  assign xor1_w0 = xor0_w0^xor0_w1; 
  assign xor1_w1 = xor0_w2^xor0_w3; 

  assign modA_o = xor1_w0^xor1_w1; 

endmodule



// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Parallel Hardware Multiplier

// THIS BLOCK IS THE IMPLEMENTATION OF MODULE B 
module GF8GenMultModB(
  modB_i, // Generic Multiplier Mod B input 1
  modB_o   // Generic Multiplier Mod B output
  );
  // Inputs are declared here
  input [7:0] modB_i;
  output wire [6:0] modB_o;

  assign modB_o[0] = modB_i[0]^modB_i[2]^modB_i[3]^modB_i[4];
  assign modB_o[1] = modB_i[1]^modB_i[3]^modB_i[4]^modB_i[5];
  assign modB_o[2] = modB_i[2]^modB_i[4]^modB_i[5]^modB_i[6];
  assign modB_o[3] = modB_i[3]^modB_i[5]^modB_i[6]^modB_i[7];
  assign modB_o[4] = modB_i[0]^modB_i[2]^modB_i[3]^modB_i[6]^modB_i[7];
  assign modB_o[5] = modB_i[0]^modB_i[1]^modB_i[2]^modB_i[7];
  assign modB_o[6] = modB_i[0]^modB_i[1]^modB_i[4];

endmodule



// This is a verilog File Generated
// By The C++ program That Generates
// An Gallios Field Generic 
// Bit Parallel Hardware Multiplier

module GF8GenMult(
  mult_i1, // Gallios Field Generic Multiplier input 1
  mult_i2, // Gallios Field Generic Multiplier input 2
  mult_o   // Gallios Field Generic Multiplier output
  );
  // Inputs are declared here
  input [7:0] mult_i1, mult_i2;
  output wire [7:0] mult_o;
  // Declaration of Wires And Register are here 
  wire [6:0] modB_o;
  wire [7:0] dual_o, dual_i;
  wire [7:0] modA_w [0:6];
  assign dual_i[0] = mult_i1[1]; 
  assign dual_i[1] = mult_i1[0]; 
  assign dual_i[2] = mult_i1[7]; 
  assign dual_i[3] = mult_i1[6]; 
  assign dual_i[4] = mult_i1[5]; 
  assign dual_i[5] = mult_i1[4]; 
  assign dual_i[6] = mult_i1[3]^mult_i1[7]; 
  assign dual_i[7] = mult_i1[2]^mult_i1[7]^mult_i1[6];
 
  GF8GenMultModB MODB(
    .modB_i(dual_i),
    .modB_o(modB_o)); 
 
 
  assign modA_w[0] =  {modB_o[0],dual_i[7:1]};
  assign modA_w[1] =  {modB_o[1],modB_o[0],dual_i[7:2]};
  assign modA_w[2] =  {modB_o[2],modB_o[1],modB_o[0],dual_i[7:3]};
  assign modA_w[3] =  {modB_o[3],modB_o[2],modB_o[1],modB_o[0],dual_i[7:4]};
  assign modA_w[4] =  {modB_o[4],modB_o[3],modB_o[2],modB_o[1],modB_o[0],dual_i[7:5]};
  assign modA_w[5] =  {modB_o[5],modB_o[4],modB_o[3],modB_o[2],modB_o[1],modB_o[0],dual_i[7:6]};
  assign modA_w[6] =  {modB_o[6],modB_o[5],modB_o[4],modB_o[3],modB_o[2],modB_o[1],modB_o[0],dual_i[7:7]};

  GF8GenMultModA MODA0(
    .modA_i1(dual_i), // Generic Multiplier Mod A input 1
    .modA_i2(mult_i2), // Generic Multiplier Mod A input 2
    .modA_o(dual_o[0]));   // Generic Multiplier Mod A output
 
  genvar j;
  generate
    for (j=1; j < 8; j = j+1) begin:MODABLOCKS
      GF8GenMultModA MODA(
        .modA_i1(modA_w[j-1]), // Generic Multiplier Mod A input 1
        .modA_i2(mult_i2), // Generic Multiplier Mod A input 2
        .modA_o(dual_o[j]));   // Generic Multiplier Mod A output
    end
  endgenerate
 
  assign mult_o[0] = dual_o[1]; 
  assign mult_o[1] = dual_o[0]; 
  assign mult_o[2] = dual_o[7]^dual_o[2]^dual_o[3]; 
  assign mult_o[3] = dual_o[6]^dual_o[2]; 
  assign mult_o[4] = dual_o[5]; 
  assign mult_o[5] = dual_o[4]; 
  assign mult_o[6] = dual_o[3];
  assign mult_o[7] = dual_o[2];
endmodule
