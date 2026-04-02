// THIS IS A SYNDROME BUFFER THAT PUTS DATA IN FIFO 
// AND DATA CAN BE PICKED FROM THE LAST OF THE FIFO 
// OR FROM LOCATION SPECIFIED BY loc_i 
module GF8SyndromBuffer(clk_i, rst_i, 
  push_i,          // push data
  sel_i,           // Enable Signal
  loc_i,           // Enable Signal
  syndrom_i,       // input syndrom
  syndrom_o       // data from loc
  );
  // Inputs are declared here
  input clk_i,rst_i,push_i;			// Clock and Reset Declaration
  input sel_i;
  input [4:0] loc_i;
  input [7:0] syndrom_i;
  output wire [7:0] syndrom_o;
 // This is first 2*t syndrome buffer 
  reg [7:0] shift_reg[0:16];

  assign syndrom_o = sel_i?shift_reg[loc_i]:shift_reg[16];

  // Sequential Body
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      shift_reg[0] <= 0;
      shift_reg[1] <= 0;
      shift_reg[2] <= 0;
      shift_reg[3] <= 0;
      shift_reg[4] <= 0;
      shift_reg[5] <= 0;
      shift_reg[6] <= 0;
      shift_reg[7] <= 0;
      shift_reg[8] <= 0;
      shift_reg[9] <= 0;
      shift_reg[10] <= 0;
      shift_reg[11] <= 0;
      shift_reg[12] <= 0;
      shift_reg[13] <= 0;
      shift_reg[14] <= 0;
      shift_reg[15] <= 0;
      shift_reg[16] <= 0;
    end
    else if(push_i) begin
      shift_reg[0] <= syndrom_i;
      shift_reg[1] <= shift_reg[0];
      shift_reg[2] <= shift_reg[1];
      shift_reg[3] <= shift_reg[2];
      shift_reg[4] <= shift_reg[3];
      shift_reg[5] <= shift_reg[4];
      shift_reg[6] <= shift_reg[5];
      shift_reg[7] <= shift_reg[6];
      shift_reg[8] <= shift_reg[7];
      shift_reg[9] <= shift_reg[8];
      shift_reg[10] <= shift_reg[9];
      shift_reg[11] <= shift_reg[10];
      shift_reg[12] <= shift_reg[11];
      shift_reg[13] <= shift_reg[12];
      shift_reg[14] <= shift_reg[13];
      shift_reg[15] <= shift_reg[14];
      shift_reg[16] <= shift_reg[15];
    end
  end
  
endmodule
