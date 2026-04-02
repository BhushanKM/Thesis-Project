`timescale 1ns / 10 ps

module GF8Mult5_testbench;
 
  reg  clk_i,rst_i;
  wire [7:0] mult_o;
  reg [7:0]  mult_i;
  reg [126*7:0]  path,input_file,output_file;
  integer    fd_in,fd_out;
 
GF8Mult5 DUT(.clk_i(clk_i),.rst_i(rst_i),
  .mult_i(mult_i),
  .mult_o(mult_o));
 
always
#5 clk_i = !clk_i;
  initial begin
    path = "./";
    input_file = "input_file_GF8Mult.dat";
    output_file = "output_file_GF8Mult.dat";
    fd_in = $fopen(input_file,"r");
    fd_out = $fopen(output_file,"w");

    clk_i = 0;
    rst_i = 1;    
    #10 rst_i = 0;

   while(!$feof(fd_in))
     begin
       @(negedge clk_i);
         $fscanf(fd_in,"%d\n",mult_i);
         $fwrite(fd_out,"%d\n",mult_o);
     end
  end // initial begin

endmodule
