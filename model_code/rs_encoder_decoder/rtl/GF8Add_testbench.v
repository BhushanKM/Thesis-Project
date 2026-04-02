`timescale 1ns / 10 ps

module GF8Add_testbench;
 
  reg clk_i,rst_i;
  wire [7:0] add_o;
  reg [7:0]  add_i1,add_i2;
  reg [126*7:0]  path,input_file,output_file;
  integer    fd_in,fd_out;
 
GF8Add DUT(.clk_i(clk_i),.rst_i(rst_i),
  .add_i1(add_i1),
  .add_i2(add_i2),
  .add_o(add_o));
 
always
#5 clk_i = !clk_i;
  initial begin
    path = "./";
    input_file = "input_file_GF8Add.dat";
    output_file = "output_file_GF8Add.dat";
    fd_in = $fopen(input_file,"r");
    fd_out = $fopen(output_file,"w");

    clk_i = 0;
    rst_i = 1;    
    #10 rst_i = 0;

   while(!$feof(fd_in))
     begin
       @(negedge clk_i);
         $fscanf(fd_in,"%d %d\n ",add_i1,add_i2);
         $fwrite(fd_out,"%d\n ",add_o);
     end
  end // initial begin

endmodule
