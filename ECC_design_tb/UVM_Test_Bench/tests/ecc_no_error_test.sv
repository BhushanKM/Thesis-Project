///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - No Error Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests basic encode/decode without error injection
///////////////////////////////////////////////////////////////////////////

class ecc_no_error_test extends ecc_base_test;

    `uvm_component_utils(ecc_no_error_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_no_error_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting No Error Baseline Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_no_error_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_no_error_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_no_error_seq)

    function new(string name = "ecc_no_error_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing 100 no-error transactions", UVM_MEDIUM)

        repeat(100) begin
            `uvm_do_with(req, {
                error_type == NO_ERROR;
            })
        end

        `uvm_info(get_type_name(), "No Error baseline test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_no_error_seq
