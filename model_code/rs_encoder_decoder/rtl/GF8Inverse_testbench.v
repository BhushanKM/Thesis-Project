`timescale 1ns / 10 ps

module GF8GenInverse_testbench;
 
  reg  clk_i,rst_i;
  wire [7:0] inv_o;
  wire valid_o;
  reg [7:0]  inv_i;
  reg valid_i;
  reg [126*7:0]  path,input_file,output_file;
  reg [7:0] cntr;
  integer    fd_in,fd_out;
 
GF8Inverse DUT(.clk_i(clk_i),.rst_i(rst_i),
  .valid_i(valid_i),
  .inv_i(inv_i),
  .valid_o(valid_o),
  .inv_o(inv_o));
 
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
    input_file = "input_file_GF8Inverse.dat";
    output_file = "output_file_GF8Inverse.dat";
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
           $fscanf(fd_in,"%d\n",inv_i);
           $fwrite(fd_out,"%d\n",inv_o);
					end
     end
  end // initial begin

endmodule
