module Memmory
(
	input [7:0] data,
	input [7:0] addr,
	input we, clk,
	output reg [7:0] q
);

	// Declare the RAM variable
	parameter WIDTH = 256; 
  reg [7:0] ram[WIDTH-1:0];
  
  //if remove clear function, the dpram can be synthesized to ram block 
  //always @(posedge clk ) begin:clear 
  //  if (clear_i) begin
  //    for(i=0; i<WIDTH; i = i+1)
  //      ram[i] <= 0;
  //  end
  //end 

	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[addr] = data;

		// Read (if read_addr == write_addr, return OLD data).	To return
		// NEW data, use = (blocking write) rather than <= (non-blocking write)
		// in the write assignment.	 NOTE: NEW data may require extra bypass
		// logic around the RAM.
		q = ram[addr];
	end

endmodule
