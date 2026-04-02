`timescale 1ns / 10 ps

module GF8Fir8t_testbench;
 
  reg clk_i,rst_i;
  reg en_i;
  reg [7:0]  fir_i;
  reg sel_i;
  wire [7:0]  fir_o;
  reg [71:0] coeff_i,shift_reg_i;
  reg [126*7:0]  path,input_file,output_file;
  integer   fd_in, fd_out;
 
GF8Fir8t DUT(
  .clk_i(clk_i),.rst_i(rst_i),
  .en_i(en_i), // Gallios Field FIR Filter enable 1
  .fir_i(fir_i), // Gallios Field FIR Filter input 1
  .sel_i(sel_i), // Gallios Field FIR Filter input 1
  .shift_reg_i(shift_reg_i), // Gallios Field FIR Coefficient input 1
  .coeff_i(coeff_i), // Gallios Field FIR Coefficient input 1
  .fir_o(fir_o)   // Gallios Field FIR out
  );
 
      
always
#5 clk_i = !clk_i;
  initial begin
    path = "./";
    input_file = "input_file_GF8Fir.dat";
    output_file = "output_file_GF8Fir.dat";
    fd_in = $fopen(input_file,"r");
    fd_out = $fopen(output_file,"w");
    coeff_i[7:0] = 8'h0;
    shift_reg_i[7:0] = 8'h8;
    coeff_i[15:8] = 8'h1;
    shift_reg_i[15:8] = 8'h7;
    coeff_i[23:16] = 8'h2;
    shift_reg_i[23:16] = 8'h6;
    coeff_i[31:24] = 8'h3;
    shift_reg_i[31:24] = 8'h5;
    coeff_i[39:32] = 8'h4;
    shift_reg_i[39:32] = 8'h4;
    coeff_i[47:40] = 8'h5;
    shift_reg_i[47:40] = 8'h3;
    coeff_i[55:48] = 8'h6;
    shift_reg_i[55:48] = 8'h2;
    coeff_i[63:56] = 8'h7;
    shift_reg_i[63:56] = 8'h1;
    coeff_i[71:64] = 8'h8;
    shift_reg_i[71:64] = 8'h0;

    clk_i = 0;
    rst_i = 1;    
    en_i = 0; 
    sel_i = 0; 
    #10 rst_i = 0;

   while(!$feof(fd_in))
     begin
       @(negedge clk_i);
         $fscanf(fd_in,"%d\n",fir_i);
         $fwrite(fd_out,"%d\n",fir_o);
         en_i = 1; 
     end
  end // initial begin

endmodule
