///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - DASE Detection Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests double adjacent symbol errors (uncorrectable, detection only)
///////////////////////////////////////////////////////////////////////////

class ecc_dase_detection_test extends ecc_base_test;

    `uvm_component_utils(ecc_dase_detection_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_dase_detection_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting DASE Detection Test (Uncorrectable Errors)", UVM_NONE)
    endtask : run_phase

endclass : ecc_dase_detection_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_dase_detection_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_dase_detection_seq)

    function new(string name = "ecc_dase_detection_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing 100 DASE transactions (adjacent symbol pairs)", UVM_MEDIUM)

        // Test adjacent symbol pairs (i, i+1) for i = 0..17
        for (int i = 0; i < 18; i++) begin
            repeat(5) begin
                `uvm_do_with(req, {
                    error_type == DASE;
                    error_symbol_0 == i;
                    error_symbol_1 == i + 1;
                    $countones(error_pattern_0) >= 1;
                    $countones(error_pattern_1) >= 1;
                })
            end
        end

        `uvm_info(get_type_name(), "DASE Detection test complete - all adjacent pairs tested", UVM_MEDIUM)
    endtask : body

endclass : ecc_dase_detection_seq
