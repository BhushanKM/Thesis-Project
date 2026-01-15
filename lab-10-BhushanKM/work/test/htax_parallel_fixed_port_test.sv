///////////////////////////////////////////////////////////////////////////
// Texas A&M University
// CSCE 616 Hardware Design Verification
// Created by  : Prof. Quinn and Saumil Gogri
///////////////////////////////////////////////////////////////////////////


class htax_parallel_fixed_port_test extends base_test;

	`uvm_component_utils(htax_parallel_fixed_port_test)

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		uvm_config_wrapper::set(this,"tb.vsequencer.run_phase", "default_sequence", parallel_fixed_port_vseq::type_id::get());
		super.build_phase(phase);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info(get_type_name(),"Starting multiport random test",UVM_NONE)
	endtask : run_phase

endclass : htax_parallel_fixed_port_test



///////////////////////////// VIRTUAL SEQUENCE ///////////////////////////


class parallel_fixed_port_vseq extends htax_base_vseq;

  `uvm_object_utils(parallel_fixed_port_vseq)

  rand int port;
  htax_packet_c req0;
  htax_packet_c req1;
  htax_packet_c req2;
  htax_packet_c req3;

  function new (string name = "parallel_fixed_port_vseq");
    super.new(name);
  endfunction : new

  task body();
    // Execute a loop to run this scenario multiple times within one test
    repeat(100) begin
      port = $urandom_range(0,3); 
      fork
        // Port 0: Send Short Packet to Port 0 (Loopback stress)
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], { 
            req0.dest_port == 0;      
            req0.length == 5; 
            req0.delay  == 1;
            req0.vc inside {[1:2]}; 
        })

        // Port 1: Send Short Packet to Port 1
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], { 
            req1.dest_port == 1;      
            req1.length == 5;
            req1.delay  == 1; 
            req1.vc inside {[1:2]};
        })

        // Port 2: Send Short Packet to Port 2
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], { 
            req2.dest_port == 2;      
            req2.length == 5;
            req2.delay  == 1; 
            req2.vc inside {[1:2]};
        })

        // Port 3: Send Short Packet to Port 3
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], { 
            req3.dest_port == 3;      
            req3.length == 5; 
            req3.delay  == 1;
            req3.vc inside {[1:2]};
        })

      join
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[port], {       
            req0.length inside {[10:50]}; 
            req0.delay  == 1;
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[port], {       
            req1.length inside {[10:50]};
            req1.delay  == 1;
        })

        `uvm_do_on_with(req2, p_sequencer.htax_seqr[port], {       
            req2.length inside {[10:50]};
            req2.delay  == 1;
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[port], {       
            req3.length inside {[10:50]}; 
            req3.delay  == 1;
        })

      fork
          repeat(100) 
          begin
            `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.length == 70; req0.dest_port == 0; req0.delay ==1; req0.vc == 1;})
          end
          repeat(100) 
          begin
            `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.length == 70; req1.dest_port == 1; req1.delay ==1; req1.vc == 1;})
          end
          repeat(100) 
          begin
            `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.length == 70; req2.dest_port == 2; req2.delay ==1; req2.vc == 1;})
          end
          repeat(100) 
          begin
            `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.length == 70; req3.dest_port == 3; req3.delay ==1; req3.vc == 1;})
          end
      join
    end
  endtask : body

endclass : parallel_fixed_port_vseq
