// This is a verilog File Generated
// By The C++ program That Generates
// Reed Solomon Controller  
// Barlekamp Messay Controller 

module RS8Controller(clk_i, rst_i, 
  valid_i,                   // Controller input valid
  calc_S_0_o,                // Control Signal to Calculate S_0
  dft_sel_o,                 // select FFT or IFFT
  dft_calc_o,                // calculate fourier transform
  mem_in_o,                  // memory control signal to input what in the memory
  en_fir_o,                  // calculate new delta
  fir_sel_o,                 // calculate new delta
  calc_bm_step_o,            // Calculate BM Step
  step_o,                    // current_step
  done_bm_step_i,            // update from BM circuit
  elp_busy_i,                // Controller input busy signal from error loc poly
  r_calc_o,                  // To enable R0 to calculate
  r_calc_sel_o,              // To enable R0 to select memmory address
  r_calc_done_i,             // When R0 has completed the operation
  push_o,                    // push data in syndrom
  mem_addr_o,                // Memmory Address
  load_last_o,               // This is the first DFT calculation control signal 
  wren_o,                    // Write Data IN memmory
  done_dec_o,                // done BM decoding 
  last_in_sel_o,             // ouput data 0
  valid_o_o,                 // Asserted when data is being outputed from the RS decoder
  busy_o                     // States the Status of the RS decoder
  );
  
  // Declaration of the inputs
  input clk_i, rst_i;
  input valid_i;
  output reg dft_calc_o;
  output reg [1:0] dft_sel_o;
  output reg busy_o; 
  output reg en_fir_o;
  output reg fir_sel_o;
  output reg valid_o_o;
  
  // Control Signals associated 
  output reg calc_S_0_o;
  
  // with Error Loc Poly calculator
  output reg calc_bm_step_o;
  output wire [7:0] step_o;
  input done_bm_step_i;
  input elp_busy_i;
  
  // R 0 calculator control signals
  input r_calc_done_i;   // When R0 has completed the operation
  output reg r_calc_sel_o;     // R0 memory address select
  output reg r_calc_o;       // to enable R0 to calculate

  output reg push_o;
  output reg done_dec_o;
  
  // MEMORY ADDRESS AND MEMORY CONTROL SIGNALS
  output wire [7:0] mem_addr_o;
  output reg mem_in_o;
  output reg wren_o;
  
  
  output reg load_last_o;
  output reg last_in_sel_o;

  // Declaration of Wires And Register are here 
  // Control Registers
  // INPUT COUNTER HANDLER
  reg [8:0] input_cntr;
  reg clr_input_cntr;
  always @ (posedge clk_i) begin
    if ((rst_i)||(clr_input_cntr)) begin
      input_cntr  = 0;
    end
    else if ((valid_i)&& (~(busy_o))) begin
      input_cntr = input_cntr + 1;
    end
  end
  
  // ErrorPolyCalcStep
  reg [7:0] step;
  always @ (posedge clk_i) begin
    if ((rst_i)||(done_dec_o)) begin
      step  = 0;
    end
    else if (done_bm_step_i) begin
      step = step + 1;
    end
  end
    
  reg clr_mem_addr;
  reg inc_mem_addr;
  reg [7:0] mem_addr;  
  always @(posedge clk_i) begin
    if((rst_i)||(clr_mem_addr)) begin  
      mem_addr = 0;
    end
    else if(inc_mem_addr) begin
      mem_addr = mem_addr +1;
    end
  end
  
  reg inc_idft_cntr;
  reg clr_idft_cntr;
  reg [7:0] idft_cntr;
  always @(posedge clk_i) begin
    if((rst_i)||(clr_idft_cntr)) begin  
      idft_cntr = 0;
    end
    else if(inc_idft_cntr) begin
      idft_cntr = idft_cntr +1;
    end
  end
  
  assign step_o = step;
  assign mem_addr_o = mem_addr;
   
  // Controller State Machine  
  parameter INIT        = 5'b00000;
  parameter INPUT       = 5'b00001;
  parameter CALCSYND    = 5'b00010;
  parameter CALCDELTA1  = 5'b00011;
  parameter CALCDELTA2  = 5'b00100;
  parameter CALCBMSTEP1 = 5'b00101;
  parameter CALCBMSTEP2 = 5'b00110;
  parameter DONEBM      = 5'b00111;
  parameter CALCR0      = 5'b01000;
  parameter PUTZEROIDFT = 5'b01001;
  parameter MEMORY      = 5'b01010;
  parameter CALCRE      = 5'b01011;
  parameter LOADIDFT    = 5'b01100;
  parameter DATA0OUT    = 5'b01101;
  parameter CALCIDFT    = 5'b01110;
  parameter DONE        = 5'b01111;
 
  reg [4:0] cs,ns;
  
  // STATE TRANSITION BODY
  always @ (posedge clk_i) begin
    if (rst_i) begin
      cs <= INIT;
    end 
    else begin 
      cs <= ns;
    end 
  end 

  // Combination Body
  always @(*) begin
  case (cs)
    INIT: begin
      ns = INPUT;

      // output
      calc_S_0_o         = 0;
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_mem_addr       = 0;
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      done_dec_o         = 0;
      valid_o_o          = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      clr_input_cntr     = 1;
      clr_mem_addr       = 0;
      push_o             = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      r_calc_sel_o       = 0;
      r_calc_o           = 0;
      busy_o             = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;
      
    end
    INPUT: begin
      // At this state All the data is inputed
      if(input_cntr < 255) begin
        ns = INPUT;
      end
      else begin 
        ns = CALCDELTA1;
      end
      
      // output
      if (valid_i) begin
        dft_calc_o       = 1;
        calc_S_0_o       = 1;
        dft_sel_o        = 2'b01;
      end
      else begin
        dft_calc_o       = 0;
        calc_S_0_o       = 0;
        dft_sel_o        = 2'b00;
      end
      inc_mem_addr       = 0;
            
      //used Not used 
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      done_dec_o         = 0;
      clr_input_cntr     = 0;
      clr_mem_addr       = 1;
      push_o             = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      busy_o             = 0;
      load_last_o        = 0;
      
      
      //un used
      valid_o_o          = 0; 
      last_in_sel_o      = 0;

    end
    CALCSYND: begin
      ns = CALCDELTA1;
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 1;
      inc_mem_addr       = 1;
      wren_o             = 0;
      mem_in_o           = 1;

      // need to be trimmed 
      push_o             = 0;      
      
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      done_dec_o         = 0;
      calc_S_0_o         = 0;
      valid_o_o          = 0; 
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      clr_mem_addr       = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;

      clr_input_cntr     = 1;
      // important signal 
      busy_o             = 1;

    end
    CALCDELTA1: begin
      ns = CALCDELTA2;
           // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_mem_addr       = 0;
      en_fir_o           = 1;
      
      // The memory is written with first 16 syndroms
      wren_o             = 1;
      mem_in_o           = 1;
      push_o             = 0;      
     
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      calc_S_0_o         = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      clr_mem_addr       = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;
      
      clr_input_cntr     = 0;
      busy_o             = 1;
    end
    CALCDELTA2: begin
      ns = CALCBMSTEP1;
      
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_mem_addr       = 0;
      en_fir_o           = 0;
      
      // why memmory is being written here
      wren_o             = 0;
      mem_in_o           = 0;
      push_o             = 0;      
     
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      calc_S_0_o         = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_mem_addr       = 0;
      load_last_o        = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      last_in_sel_o      = 0;
      
      clr_input_cntr     = 0;
      busy_o             = 1;
    end

    CALCBMSTEP1: begin
      ns = CALCBMSTEP2;
      // output
      calc_bm_step_o     = 1;

      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      en_fir_o           = 0;
      inc_mem_addr       = 0;
      fir_sel_o          = 0;
      calc_S_0_o         = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_mem_addr       = 0;
      push_o             = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      mem_in_o           = 0;
      wren_o             = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;
 
      clr_input_cntr     = 0;
      busy_o             = 1;

    end
    CALCBMSTEP2: begin
      if (done_bm_step_i) begin
        if(step_o < 15) // 2*t-1
          ns = CALCSYND;
        else 
          ns = DONEBM;
      end
      else begin
        ns = CALCBMSTEP2;
      end
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_mem_addr       = 0;
      calc_S_0_o         = 0;
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_mem_addr       = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      push_o             = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      mem_in_o           = 0;
      wren_o             = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;

      clr_input_cntr     = 1;
      busy_o             = 1;
    end
    DONEBM: begin
      // important wait for the elp to complete inversion aswell
      if(elp_busy_i) begin
        ns = DONEBM;
        r_calc_o = 0;
        r_calc_sel_o= 0;
      end
      else begin
        ns = CALCR0;
        r_calc_o = 1;
        r_calc_sel_o= 1;
      end

      // output
      clr_mem_addr       = 0;
     
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      en_fir_o           = 0;
      calc_S_0_o         = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      
      done_dec_o         = 0;
      valid_o_o          = 0; 
      push_o             = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      inc_mem_addr       = 0;
      mem_in_o           = 0;
      wren_o             = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;

      clr_input_cntr     = 1;
      busy_o             = 1;
    end
    CALCR0: begin
      if(r_calc_done_i) begin
        ns = MEMORY;
      end
      else begin
        ns = CALCR0;
      end
      // output
      r_calc_sel_o       = 1;
      r_calc_o           = 0;

      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      en_fir_o           = 0;
      calc_S_0_o         = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      
      done_dec_o         = 0;
      valid_o_o          = 0; 
      push_o             = 0;
      inc_idft_cntr      = 0;
      clr_mem_addr       = 0;
      clr_idft_cntr      = 0;
      inc_mem_addr       = 0;
      mem_in_o           = 0;
      wren_o             = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;

      clr_input_cntr     = 1;
      busy_o             = 1;
    end
    MEMORY: begin
      ns = CALCRE;
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 1; // calc_first DFT0
      fir_sel_o          = 1; // calc_first RE
      en_fir_o           = 1; // dont calc first RE
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      calc_bm_step_o     = 0;
      
      // Put data in Memmory
      clr_mem_addr       = 0;
      inc_mem_addr       = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      
      done_dec_o         = 0;
      
      valid_o_o          = 0; 
      push_o             = 0;
      load_last_o        = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 0;

      busy_o             = 1;
      clr_input_cntr     = 1;

    end
    CALCRE: begin
      if(mem_addr<255) begin
        ns = CALCRE;
        clr_mem_addr = 0;
      end      
      else begin
        ns = PUTZEROIDFT;
        clr_mem_addr = 1;
      end
      // output
      // calculate remaining syndrome
      dft_sel_o          = 2'b00;
      dft_calc_o         = 1;
      // calculate r0 
      en_fir_o           = 1;
      fir_sel_o          = 1;
      inc_mem_addr       = 1;
      calc_S_0_o         = 0;
      load_last_o        = 1;
      wren_o             = 1;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      mem_in_o           = 0;
 
      // add syndrome and ro and put it in memmory
      //////////////////////
      inc_idft_cntr      = 0;
      push_o             = 0;
      clr_idft_cntr      = 0;
      calc_bm_step_o     = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_input_cntr     = 0;
      last_in_sel_o      = 0;
      busy_o             = 1;
    end
    
    PUTZEROIDFT:begin
      if(mem_addr<15) begin
        ns = PUTZEROIDFT;
      end
      else begin
        ns = LOADIDFT;
      end
      // output
      dft_sel_o          = 2'b11;
      dft_calc_o         = 1;
      inc_mem_addr       = 1;
      // This signal is used to push zero in IDFT
      push_o             = 1;
      
      en_fir_o           = 0;
      inc_idft_cntr      = 0;
      clr_idft_cntr      = 0;
      calc_bm_step_o     = 0;
      
      wren_o             = 0;
      mem_in_o           = 0;
      clr_mem_addr       = 0;
      fir_sel_o          = 0;
      
      done_dec_o         = 0;
      
      valid_o_o          = 0; 
      load_last_o        = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 0;

      busy_o             = 1;    
      clr_input_cntr     = 1;
  
    end
    LOADIDFT: begin
      if(mem_addr<254) begin
        ns = LOADIDFT;
      end
      else begin
        ns = DATA0OUT;
      end
      // output
      dft_sel_o          = 2'b11;
      dft_calc_o         = 1;
      inc_mem_addr       = 1;
      clr_mem_addr       = 0;
      load_last_o        = 0;
      clr_idft_cntr      = 1;
 
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      inc_idft_cntr      = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_input_cntr     = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      push_o             = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 0;

      busy_o             = 1;
    end
    DATA0OUT: begin
      ns = CALCIDFT;
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      inc_mem_addr       = 0;
      clr_mem_addr       = 0;
      load_last_o        = 0;
      clr_idft_cntr      = 1;
 
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      inc_idft_cntr      = 0;
      done_dec_o         = 0;
      valid_o_o          = 1; 
      clr_input_cntr     = 0;
      push_o             = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 1;

      busy_o             = 1;    
    end
    CALCIDFT: begin
      if(idft_cntr<253) begin
        ns = CALCIDFT;
      end
      else begin
        ns = DONE;
      end
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 1;
      inc_mem_addr       = 0;
      clr_mem_addr       = 1;
      inc_idft_cntr      = 1;
      clr_idft_cntr      = 0;
      valid_o_o          = 1;
      
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      done_dec_o         = 0;
      clr_input_cntr     = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      push_o             = 0;
      wren_o             = 0;
      mem_in_o           = 0;
      load_last_o        = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 0;

      busy_o             = 1;
    end
    DONE: begin
      ns = INIT;
      // output
      done_dec_o         = 1;
      clr_input_cntr     = 1;
      clr_mem_addr       = 1;
      clr_idft_cntr      = 1;
      busy_o             = 1;

      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      inc_idft_cntr      = 0;
      valid_o_o          = 0; 
      mem_in_o           = 0;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      push_o             = 0;
      wren_o             = 0;
      inc_mem_addr       = 0;
      load_last_o        = 0;
      calc_S_0_o         = 0;
      last_in_sel_o      = 0;
    end
    default: begin
      ns = INIT;
      // output
      dft_sel_o          = 2'b00;
      dft_calc_o         = 0;
      en_fir_o           = 0;
      fir_sel_o          = 0;
      calc_bm_step_o     = 0;
      inc_idft_cntr      = 0;
      done_dec_o         = 0;
      valid_o_o          = 0; 
      clr_input_cntr     = 1;
      clr_mem_addr       = 1;
      clr_idft_cntr      = 1;
      r_calc_o           = 0;
      r_calc_sel_o       = 0;
      mem_in_o           = 0;
      push_o             = 0;
      wren_o             = 0;
      inc_mem_addr       = 0;
      load_last_o        = 0;
      last_in_sel_o      = 0;
      calc_S_0_o         = 0;
      busy_o             = 1;

    end
  endcase
  end
endmodule
