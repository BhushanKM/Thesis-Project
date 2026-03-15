///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - DBE Random Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests double bit errors in different symbols
///////////////////////////////////////////////////////////////////////////

class ecc_dbe_random_test extends ecc_base_test;

    `uvm_component_utils(ecc_dbe_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_dbe_random_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting DBE Random Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_dbe_random_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_dbe_random_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_dbe_random_seq)

    function new(string name = "ecc_dbe_random_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing 500 random DBE transactions", UVM_MEDIUM)

        repeat(500) begin
            `uvm_do_with(req, {
                error_type == DBE;
                $countones(error_pattern_0) == 1;
                $countones(error_pattern_1) == 1;
                error_symbol_0 != error_symbol_1;
            })
        end

        `uvm_info(get_type_name(), "DBE Random test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_dbe_random_seq
