///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Simple Random Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Based on Texas A&M CSCE 616 test structure
///////////////////////////////////////////////////////////////////////////

class ecc_simple_random_test extends ecc_base_test;

    `uvm_component_utils(ecc_simple_random_test)

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Build Phase
    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_simple_random_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    // Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Simple Random Sequence Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_simple_random_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_simple_random_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_simple_random_seq)

    function new(string name = "ecc_simple_random_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing simple random sequence with 50 transactions", UVM_MEDIUM)
        repeat(50) begin
            `uvm_do(req)
        end
    endtask : body

endclass : ecc_simple_random_seq
