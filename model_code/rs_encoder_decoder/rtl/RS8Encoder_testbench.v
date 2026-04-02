`timescale 1ns / 10 ps

module RS8Encoder_testbench;
 
  reg clk_i,rst_i;
  reg valid_i;
  reg  [7:0]  enc_data_i;
  wire [7:0] enc_data_o;
  wire parity_o;
  wire busy_o;
  reg [126*7:0]  path,input_file,output_file;
  integer   fd_in, fd_out;
  
  reg [8:0] wait_cntr;
 
RS8Encoder8t DUT(.clk_i(clk_i), .rst_i(rst_i), 
  .encoder_i(enc_data_i),  // Input to the encoder
  .valid_i(valid_i),       // set this when input is set
  .encoder_o(enc_data_o),  // output of the encoder
  .parity_o(parity_o),     // Valid signal is set when the output is available on the output line
  .busy_o(busy_o)            // Busy Signal When busy signal is high during the encoding process Please dont 
  );                       // give input to the incoder
  
  // This is an input counter the purpose of this is to set the input to zero in the start 
  // of the encoding process

  always @(posedge clk_i) begin
    if(rst_i)
      wait_cntr <= 0;
    else 
      wait_cntr <= wait_cntr + 1;
  end
  
always
#5 clk_i = !clk_i;
  initial begin
    path = "./";
    // These are the input files that can be used in the encoder
    // you can select any information bit generation 
    input_file = "input_file_RSEncodeData.dat";
    output_file = "output_file_RSVerilogEncodedData.dat";
    fd_in = $fopen(input_file,"r");
    fd_out = $fopen(output_file,"w");

    clk_i = 0;
    rst_i = 1;    
    #10 rst_i = 0;
    enc_data_i = 0;

   while(1)
     begin
       @(posedge clk_i);
           if(wait_cntr < 4) begin
             valid_i = 0;  
             enc_data_i = 0;
           end
           else if((wait_cntr >=4)&&(wait_cntr<=243)) begin // give the input to the encoder when the encoder is not busy
             valid_i = 1;
             $fscanf(fd_in,"%d\n",enc_data_i); // The input to the encoder should be given at continous clocks and atease 239 packets at a time
           end
           else if ((wait_cntr>243)&&(wait_cntr <= 259)) begin 
             valid_i =1;
             enc_data_i =0;
           end
           else if (wait_cntr > 259)  begin
             valid_i =0;
             enc_data_i =0;
           end
           if(parity_o)
             $fwrite(fd_out,"%d \n",enc_data_o); // Write the output of the encoded data
     end  
  end // initial begin

endmodule
