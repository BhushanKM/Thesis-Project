`timescale 1ns / 10 ps

module CompleteChain_testBench;
 
  reg clk_i,rst_i;
  reg valid_i;
  reg gen_i;
  wire [7:0] enc_data_i;
  wire [7:0] enc_data_o;
  wire [7:0] dec_data_o;
  wire parity_o;
  wire busy_o;
  reg [126*7:0]  path,output_file,output_fileDec,output_fileRND;
  integer   fd_in, fd_out,fd_out1,fd_out2;
  

 
GF8lfsr RNDMIZER(.clk_i(clk_i), .rst_i(rst_i), 
  .en_i(gen_i), // Valid Input Set it to High When giving the input
  .lfsr_o(enc_data_i)   // Gallios Field Generic Bit Serial Multiplier output
  ); 
 
RS8Encoder8t ENC(.clk_i(clk_i), .rst_i(rst_i), 
  .encoder_i(enc_data_i),  // Input to the encoder
  .valid_i(valid_i),       // set this when input is set
  .encoder_o(enc_data_o),  // output of the encoder
  .parity_o(parity_o),     // Valid signal is set when the output is available on the output line
  .busy_o(enc_busy_o)            // Busy Signal When busy signal is high during the encoding process Please dont 
  );                       // give input to the incoder
  
  
RS8FreqDecode DEC(.clk_i(clk_i), .rst_i(rst_i), 
  .valid_i(parity_o),    // input valid signal
  .enc_data_i(enc_data_o), // encoded data
  .dec_data_o(dec_data_o),  // decoded output
  .valid_o(valid_o),      // decoded output
  .busy_o(dec_busy_o)
  );
     
  
  // This is an input counter the purpose of this is to set the input to zero in the start 
  // of the encoding process
  reg [10:0] wait_cntr;
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
 
    output_file = "output_file_RSVerilogEncodedData.dat";
    output_fileDec = "output_file_RSVerilogDecodedData.dat";
    output_fileRND = "output_file_RSVerilogRNDData.data";
 
    fd_out = $fopen(output_file,"w");
    fd_out1 = $fopen(output_fileDec,"w");
    fd_out2 = $fopen(output_fileRND,"w");

    clk_i = 0;
    rst_i = 1;    
    #10 rst_i = 0;

   while(1)
     begin
       @(posedge clk_i);
           if(wait_cntr < 4) begin
             valid_i = 0;  
             gen_i = 1;
           end
           else if((wait_cntr >=4)&&(wait_cntr<=243)) begin // give the input to the encoder when the encoder is not busy
             valid_i = 1;
             gen_i = 1;
           end
           else if ((wait_cntr>243)&&(wait_cntr <= 259)) begin 
             valid_i =1;
             gen_i = 0;
           end
           else if (wait_cntr > 259)  begin
             valid_i =0;
             gen_i = 0;
           end
           if(parity_o)
             $fwrite(fd_out,"%d \n",enc_data_o); // Write the output of the encoded data
           if(valid_o)
            $fwrite(fd_out1,"%d \n",dec_data_o); // Write the output of the encoded data
           if(gen_i)  
            $fwrite(fd_out2,"%d \n",enc_data_i); // RandomLy Generated Data
             
     end  
  end // initial begin

endmodule