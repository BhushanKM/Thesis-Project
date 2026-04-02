`timescale 1ns / 10 ps

module RS8FreqDocode8t_testbench;
 
  reg clk_i,rst_i;
  reg valid_i;
  reg  [7:0]  enc_data_i;
  wire [7:0] dec_data_o;
  wire valid_o;
  reg [126*7:0]  path,input_file,output_file;
  reg [1:0] cntr;
  integer   fd_in, fd_out;
  wire busy;
  
RS8FreqDecode DUT(.clk_i(clk_i), .rst_i(rst_i), 
  .valid_i(valid_i),    // input valid signal
  .enc_data_i(enc_data_i), // encoded data
  .dec_data_o(dec_data_o),  // decoded output
  .valid_o(valid_o),      // decoded output
  .busy_o(busy)
  );
      
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
    input_file = "output_file_C_RSEncodedData.dat";// To Take Data From the Encoder Implemented in C
    //input_file = "output_file_RSVerilogEncodedData.dat";// To Take Data From the Encoder Implemented in  Verilog 
    output_file = $fopen("output_file_GF8Decoded.dat","w");
    fd_in = $fopen(input_file,"r");
    

    clk_i = 0;
    rst_i = 1;    
    #10 rst_i = 0;

   while(1)
     begin
       @(posedge clk_i);
         if((cntr == 1)&&(~busy)) begin
           valid_i = 1;
         end else begin 
           valid_i = 0;
         end
         if(valid_i)
           $fscanf(fd_in,"%d\n",enc_data_i);
         
         if(valid_o)
           $fwrite(output_file,"%d\n",dec_data_o);
				 
     end
  end // initial begin

endmodule



