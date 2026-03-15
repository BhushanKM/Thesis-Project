///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - SSE Random Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests single symbol errors (multi-bit within one symbol)
///////////////////////////////////////////////////////////////////////////

class ecc_sse_random_test extends ecc_base_test;

    `uvm_component_utils(ecc_sse_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_sse_random_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting SSE Random Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_sse_random_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_sse_random_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_sse_random_seq)

    function new(string name = "ecc_sse_random_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing 500 random SSE transactions (2-16 bits per symbol)", UVM_MEDIUM)

        repeat(500) begin
            `uvm_do_with(req, {
                error_type == SSE;
                $countones(error_pattern_0) inside {[2:16]};
                error_pattern_1 == 0;
            })
        end

        `uvm_info(get_type_name(), "SSE Random test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_sse_random_seq
