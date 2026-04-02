`timescale 1ns / 10 ps

module GF8GenMultBitSer_testbench;
 
  reg  clk_i,rst_i;
  wire [7:0] mult_o;
  wire valid_o;
  reg [7:0]  mult_i1,mult_i2;
  reg valid_i;
  reg [126*7:0]  path,input_file,output_file;
  reg [4:0] cntr;
  integer    fd_in,fd_out;
 
GF8GenMultBitSer DUT(.clk_i(clk_i),.rst_i(rst_i),
  .valid_i(valid_i),
  .mult_i1(mult_i1),
  .mult_i2(mult_i2),
  .valid_o(valid_o),
  .mult_o(mult_o));
 
   always @(posedge clk_i) begin
     if (rst_i) begin
       cntr <= 0;
     end else if (valid_o) begin
       cntr <= 0; 
     end else begin
       cntr <= cntr+1;
     end
  end     
      
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
         if(cntr == 1) begin
           valid_i = 1;
         end else begin 
           valid_i = 0;
         end
         if(valid_i) begin
           $fscanf(fd_in,"%d %d\n",mult_i1,mult_i2);
           $fwrite(fd_out,"%d\n",mult_o);
					end
     end
  end // initial begin

endmodule
