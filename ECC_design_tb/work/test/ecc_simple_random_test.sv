///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Simple Random Test
// RS16(19,17) ECC Engine for HBM3/HBM4
///////////////////////////////////////////////////////////////////////////

class ecc_simple_random_test extends ecc_base_test;

    `uvm_component_utils(ecc_simple_random_test)

    function new(string name = "ecc_simple_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        mixed_error_seq seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting Simple Random Test with 50 mixed transactions", UVM_LOW)

        seq = mixed_error_seq::type_id::create("seq");
        seq.num_transactions = 50;
        seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass
