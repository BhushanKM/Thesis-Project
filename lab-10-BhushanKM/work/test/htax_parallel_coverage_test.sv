///////////////////////////////////////////////////////////////////////////
// Texas A&M University
// CSCE 616 Hardware Design Verification
// Created by  : Prof. Quinn and Saumil Gogri
///////////////////////////////////////////////////////////////////////////


class htax_parallel_coverage_test extends base_test;

	`uvm_component_utils(htax_parallel_coverage_test)

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		uvm_config_wrapper::set(this,"tb.vsequencer.run_phase", "default_sequence", parallel_coverage_vseq::type_id::get());
		super.build_phase(phase);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info(get_type_name(),"Starting multiport random test",UVM_NONE)
	endtask : run_phase

endclass : htax_parallel_coverage_test



///////////////////////////// VIRTUAL SEQUENCE ///////////////////////////


class parallel_coverage_vseq extends htax_base_vseq;

  `uvm_object_utils(parallel_coverage_vseq)

  rand int port;
  htax_packet_c req0;
  htax_packet_c req1;
  htax_packet_c req2;
  htax_packet_c req3;

  function new (string name = "parallel_coverage_vseq");
    super.new(name);
  endfunction : new

  task body();
    // Execute a loop to run this scenario multiple times within one test
        //for long packet sequences
        port = $urandom_range(0,3);
        `uvm_do_on_with(req, p_sequencer.htax_seqr[port], {req.length > 40;})
        
        //for mixed multiport sequence
        fork
          repeat(100) 
          begin
            req0 = htax_packet_c::type_id::create("req0");
            `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.length inside {[3:80]};})
          end
          repeat(100) 
          begin
            req1 = htax_packet_c::type_id::create("req1");
            `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.length inside {[3:80]};})
          end
          repeat(100) 
          begin
            req2 = htax_packet_c::type_id::create("req2");
            `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.length inside {[3:80]};})
          end
          repeat(100) 
          begin
            req3 = htax_packet_c::type_id::create("req3");
            `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.length inside {[3:80]};})
          end
        join
      
        // Running traffic on port 0 by fixing dest port and VC to check for consistency (RUnning the set of sequences on all 4 ports)
        repeat(10)begin
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.dest_port == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.dest_port == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.length inside {[3:80]}; req0.vc == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], {req0.length inside {[3:80]}; req0.vc == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.dest_port == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.dest_port == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.length inside {[3:80]}; req1.vc == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], {req1.length inside {[3:80]}; req1.vc == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.dest_port == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.dest_port == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.length inside {[3:80]}; req2.vc == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], {req2.length inside {[3:80]}; req2.vc == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.dest_port == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.dest_port == 2;})
        end
        repeat(10)begin
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.length inside {[3:80]}; req3.vc == 1;})
        end
        repeat(10)begin
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], {req3.length inside {[3:80]}; req3.vc == 2;})
        end

        //for random short packet sequences
        port = $urandom_range(0,3);
        `uvm_do_on_with(req, p_sequencer.htax_seqr[port], {req.length < 11;})

    repeat(50) begin 
        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], { 
            req0.dest_port == 0;
            req0.length inside {[3:10]};  
            req0.vc inside {[1:2]};
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[0], { 
            req1.dest_port == 0;
            req1.length inside {[3:10]}; 
            req1.vc inside {[1:2]};
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[0], { 
            req2.dest_port == 1;
            req2.length inside {[3:10]}; 
            req2.vc inside {[1:2]}; 
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[0], { 
            req3.dest_port == 1;
            req3.length inside {[3:10]};
            req3.vc inside {[1:2]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], { 
            req0.dest_port == 2;
            req0.length inside {[3:10]};  
            req0.vc inside {[1:2]};
        })
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[0], { 
            req1.dest_port == 2;
            req1.length inside {[3:10]}; 
            req1.vc inside {[1:2]}; 
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[0], { 
            req2.dest_port == 3;
            req2.length inside {[3:10]};
            req2.vc inside {[1:2]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[0], { 
            req3.dest_port == 3;
            req3.length inside {[3:10]};  
            req3.vc inside {[1:2]};
        })

        `uvm_do_on_with(req2, p_sequencer.htax_seqr[0], { 
            req2.dest_port == 0;
            req2.length inside {[50:63]}; 
            req2.vc inside {[1:2]};
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[0], { 
            req3.dest_port == 0;
            req3.length inside {[50:63]}; 
            req3.vc inside {[1:2]};
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], { 
            req0.dest_port == 1;
            req0.length inside {[50:63]}; 
            req0.vc inside {[1:2]}; 
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[0], { 
            req1.dest_port == 1;
            req1.length inside {[50:63]};
            req1.vc inside {[1:2]};  
        })
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[0], { 
            req2.dest_port == 2;
            req2.length inside {[50:63]}; 
            req2.vc inside {[1:2]}; 
        })
        
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[0], { 
            req3.dest_port == 2;
            req3.length inside {[50:63]};  
            req3.vc inside {[1:2]};
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[0], { 
            req0.dest_port == 3;
            req0.length inside {[50:63]};  
            req0.vc inside {[1:2]};
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[0], { 
            req1.dest_port == 3;
            req1.length inside {[50:63]};
            req1.vc inside {[1:2]};  
        })














        `uvm_do_on_with(req0, p_sequencer.htax_seqr[1], { 
            req0.dest_port == 0;
            req0.length inside {[50:63]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], { 
            req1.dest_port == 0;
            req1.length inside {[50:63]}; 
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[1], { 
            req2.dest_port == 1;
            req2.length inside {[50:63]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[1], { 
            req3.dest_port == 1;
            req3.length inside {[50:63]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[1], { 
            req0.dest_port == 2;
            req0.length inside {[50:63]};  
        })
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], { 
            req1.dest_port == 2;
            req1.length inside {[50:63]};  
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[1], { 
            req2.dest_port == 3;
            req2.length inside {[50:63]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[1], { 
            req3.dest_port == 3;
            req3.length inside {[50:63]};  
        })

        `uvm_do_on_with(req2, p_sequencer.htax_seqr[1], { 
            req2.dest_port == 0;
            req2.length inside {[3:10]}; 
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[1], { 
            req3.dest_port == 0;
            req3.length inside {[3:10]}; 
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[1], { 
            req0.dest_port == 1;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], { 
            req1.dest_port == 1;
            req0.length inside {[3:10]};  
        })
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[1], { 
            req2.dest_port == 2;
            req2.length inside {[3:10]};  
        })
        
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[1], { 
            req3.dest_port == 2;
            req3.length inside {[3:10]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[1], { 
            req0.dest_port == 3;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[1], { 
            req1.dest_port == 3;
            req1.length inside {[3:10]};  
        })

















        `uvm_do_on_with(req0, p_sequencer.htax_seqr[2], { 
            req0.dest_port == 0;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[2], { 
            req1.dest_port == 0;
            req1.length inside {[3:10]}; 
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], { 
            req2.dest_port == 1;
            req2.length inside {[3:10]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[2], { 
            req3.dest_port == 1;
            req3.length inside {[3:10]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[2], { 
            req0.dest_port == 2;
            req0.length inside {[3:10]};  
        })
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[2], { 
            req1.dest_port == 2;
            req1.length inside {[3:10]};  
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], { 
            req2.dest_port == 3;
            req2.length inside {[3:10]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[2], { 
            req3.dest_port == 3;
            req3.length inside {[3:10]};  
        })

        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], { 
            req2.dest_port == 0;
            req2.length inside {[50:63]}; 
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[2], { 
            req3.dest_port == 0;
            req3.length inside {[50:63]}; 
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[2], { 
            req0.dest_port == 1;
            req0.length inside {[50:63]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[2], { 
            req1.dest_port == 1;
            req0.length inside {[50:63]};  
        })
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[2], { 
            req2.dest_port == 2;
            req2.length inside {[50:63]};  
        })
        
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[2], { 
            req3.dest_port == 2;
            req3.length inside {[50:63]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[2], { 
            req0.dest_port == 3;
            req0.length inside {[50:63]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[2], { 
            req1.dest_port == 3;
            req1.length inside {[50:63]};  
        })


















        `uvm_do_on_with(req0, p_sequencer.htax_seqr[3], { 
            req0.dest_port == 0;
            req0.length inside {[50:63]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[3], { 
            req1.dest_port == 0;
            req1.length inside {[50:63]}; 
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[3], { 
            req2.dest_port == 1;
            req2.length inside {[50:63]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], { 
            req3.dest_port == 1;
            req3.length inside {[50:63]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[3], { 
            req0.dest_port == 2;
            req0.length inside {[50:63]};  
        })
        `uvm_do_on_with(req1, p_sequencer.htax_seqr[3], { 
            req1.dest_port == 2;
            req1.length inside {[50:63]};  
        })


        `uvm_do_on_with(req2, p_sequencer.htax_seqr[3], { 
            req2.dest_port == 3;
            req2.length inside {[50:63]};  
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], { 
            req3.dest_port == 3;
            req3.length inside {[50:63]};  
        })
    
        `uvm_do_on_with(req2, p_sequencer.htax_seqr[3], { 
            req2.dest_port == 0;
            req2.length inside {[3:10]}; 
        })

        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], { 
            req3.dest_port == 0;
            req3.length inside {[3:10]}; 
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[3], { 
            req0.dest_port == 1;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[3], { 
            req1.dest_port == 1;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req2, p_sequencer.htax_seqr[3], { 
            req2.dest_port == 2;
            req2.length inside {[3:10]};  
        })
        
        `uvm_do_on_with(req3, p_sequencer.htax_seqr[3], { 
            req3.dest_port == 2;
            req3.length inside {[3:10]};  
        })

        `uvm_do_on_with(req0, p_sequencer.htax_seqr[3], { 
            req0.dest_port == 3;
            req0.length inside {[3:10]};  
        })

        `uvm_do_on_with(req1, p_sequencer.htax_seqr[3], { 
            req1.dest_port == 3;
            req1.length inside {[3:10]};  
        })
    end
  endtask : body

endclass : parallel_coverage_vseq
