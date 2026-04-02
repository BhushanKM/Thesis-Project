// This is a verilog File Generated
// By The C++ program That Generates
// Reed Solomon Controller  
// Barlekamp Messay Controller 

module RS8FreqDecode(clk_i, rst_i, 
  valid_i,     // input valid signal
  enc_data_i,  // encoded data
  dec_data_o,  // decoded output
  valid_o,      // decoded output
  busy_o
  );
  // Declaration of the inputs
  input clk_i, rst_i;
  input valid_i;
  input [7:0] enc_data_i;
  output wire [7:0] dec_data_o;
  output wire valid_o;
  output wire busy_o;

  
  // Declaration of Wires And Register are here 
  // Control Signal To Calculate S_0
  wire calc_S_0;
  
  // Control signals To Calculate fourier transforms 
  wire [1:0] dft_sel;  // select signal tells to calculate DFT or IDFT
  wire dft_calc;  // enable signal

  // Control Signal to Calculate DELTA;
  wire en_fir;
  wire fir_sel;

  // Control Signal for errolocpoly;
  wire calc_bm_step;
  wire [7:0] step;
  wire done_bm_step;
    
  wire push_zero;  
  
  // MEMORY CONTROL SIGNAL
  wire wren;
  wire [7:0] mem_address;
  wire busy;
  
  // MEMORY DATA SIGNAL
  wire [7:0] mem_data;
  
  // IDFT Zero Value CONTROL SIGNALS
  wire load_last;
  wire load_sel_out;
  wire done_dec;
  
  // Data Signal  
  wire [71:0] sigma;        // original error loc poly
  wire [71:0] sigma_0;      // error loc poly with shifted right 8 bit and inv(sigma(0)) in the end
  wire [71:0] sigma_last;   // error loc poly with sigma(0) inversed
  
  wire [71:0] fir_i_sigma;
  wire [7:0] synd;
  wire [7:0] fir_o;
  wire [7:0] add_res;
  wire [7:0] dft_all_in;
  wire [7:0] dft_in;  
  wire [7:0] mem_data_o;
  
  // R 0 Calculator Signals
  wire [7:0] mem_loc; // mem address from the R_0 module is enabled when r_calc_sel is set to high
  wire r_calc_sel;    // R_0_calculate Control signal from the controller to select R0 memmory address
  wire r_calc_done;   // R_0_calculate control signal to the controller
  wire r_calc;        // enable signal to calculate R0
  // R 0 Data signals
  wire [7:0] R_0; 
  
  // Registers
  reg [7:0] delta;
  reg [7:0] last_in;
  reg [7:0] S_0;
 
  // mem address and control signal from the controler 
  wire [7:0] mem_addr;
  wire mem_in;
 
  assign busy_o = busy;
  assign add_res =   delta^synd;
  
  // Decoder output
  assign dec_data_o = load_sel_out?last_in:synd;
  // MUX TO INPUT SIGMA OR SIGMA_O DEPENDING ON OPERATION
  assign fir_i_sigma = fir_sel ? sigma_0: sigma;
  // MUX FOR THE INPUT OF DFT_IDFT BLOCK
  assign dft_in = dft_sel[1] ? mem_data_o:enc_data_i;
  assign dft_all_in = push_zero ? 8'b00000000:dft_in;
  	
  // MEMORY MUXES 
  assign mem_address = r_calc_sel ? mem_loc:mem_addr;
  assign mem_data = mem_in ? synd:add_res; //input first 16 syndrom of add_res


  // SEQUENTIAL BODY 
  always @(posedge clk_i) begin
    if((rst_i)||(done_dec))begin
      S_0 <= 0;
    end
    else if (calc_S_0) begin
      S_0 <= S_0^enc_data_i;
    end
  end
  
  always @(posedge clk_i) begin
    if((rst_i)||(done_dec))begin
      last_in <= 0;
    end
    else if (load_last) begin
      last_in <= last_in^add_res;
    end
  end

  always @(posedge clk_i) begin
    if ((rst_i)||(done_dec))
      delta <= 0;
    else
      delta <= fir_o;
  end

  
  // STRUCTURAL MODEL OF RS DECODER
  //    MEMORY EVALUALTOR
  Memmory	EVALMEM(
   .clk (clk_i),
	 .addr (mem_address),
	 .data (mem_data),
	 .we (wren),
   .q ( mem_data_o )
	);

  GF8Dft_Idft DFTIDFT(.clk_i(clk_i), .rst_i(rst_i), 
    .dft_sel_i(dft_sel[0]), // Control Signal calculates dft if dft_idft = 0 else idft if dft_idft = 1
    .en_i(dft_calc),               // Control Signal
    .dft_i(dft_all_in),            // Gallios Field Register input 1
    .dft_o(synd)                   // Gallios Field Register output
  );

  RS8Controller CNTRLER(.clk_i(clk_i),.rst_i(rst_i), 
    .valid_i(valid_i),             // Controller input valid
    .calc_S_0_o(calc_S_0),         // Control Signal to Calculate S_0
    .dft_sel_o(dft_sel),           // select FFT or IFFT
    .dft_calc_o(dft_calc),         // calculate fourier transform
    .mem_in_o(mem_in),             // memory data selection control signal
    .en_fir_o(en_fir),             // calculate new delta
    .fir_sel_o(fir_sel),           // calculate new delta
    .calc_bm_step_o(calc_bm_step), // Calculate BM Step
    .step_o(step),                 // current_step
    .done_bm_step_i(done_bm_step), // update from BM circuit
    .elp_busy_i(elp_busy),         // Controller input busy signal from error loc poly
    .r_calc_o(r_calc),             // TO Enable R0 calculator 
    .r_calc_sel_o(r_calc_sel),     // To selsect R0 MEMORY ADDRESS
    .r_calc_done_i(r_calc_done),   // When R0 has completed the operation
    .push_o(push_zero),            // push data in syndrom
    .mem_addr_o(mem_addr),         // Memmory Address
    .wren_o(wren),                 // Write Data IN memmory
    .load_last_o(load_last),       // Load Last  
    .last_in_sel_o(load_sel_out),  // ouput data 0
    .valid_o_o(valid_o),           // Output from the Decode         
    .busy_o(busy),                 // Output from the Decoder   
    .done_dec_o(done_dec)          // When The Complete Decoding is done
  );
    
  RS8ErrLocPoly8t CALCERRLOCPOLY(.clk_i(clk_i),.rst_i(rst_i), 
    .valid_i(calc_bm_step),    // input 1
    .delta_i(delta),           // input 1
    .step_i(step),             // input 1
    .done_dec_i(done_dec),     // input 1
    .valid_o(done_bm_step),    // output 
    .sigma_0_o(sigma_0),       // output 
    .sigma_o(sigma),           // output 
    .sigma_last_o(sigma_last), // output 
    .busy_o(elp_busy)          // Busy signal indication for processing 
  );
 
  GF8Fir8t CALCDELTARE(
    .clk_i(clk_i),.rst_i(rst_i),
    .en_i(en_fir),             // Gallios Field FIR Filter enable 1
    .fir_i(synd),              // Gallios Field FIR Filter input 1
    .sel_i(fir_sel),           // Gallios Field FIR Filter input 1
    .coeff_i(fir_i_sigma),     // Gallios Field FIR Coefficient input 1
    .fir_o(fir_o),             // Gallios Field FIR out
    .done_dec_i(done_dec)      // This is to clear every thing in this module
  );
    
  RS8CALCR08 R0CALC(.clk_i(clk_i), .rst_i(rst_i), 
    .en_i(r_calc),             // Enable Signal
    .sigma_i(sigma_last),      // sigma value in to calculate R0
    .syndrom_i(mem_data_o),    // Syndrom value from the memory
    .loc_o(mem_loc),           // mem_address
    .R_0_o(R_0),               // Valid R_o when valid_o == 1
    .valid_o(r_calc_done),     // When processing done
    .done_dec_i(done_dec)      // input to clear all the registers
  );  


endmodule
