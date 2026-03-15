///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Stress Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Back-to-back transactions with no delay for throughput testing
///////////////////////////////////////////////////////////////////////////

class ecc_stress_test extends ecc_base_test;

    `uvm_component_utils(ecc_stress_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_stress_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Stress Test - Back-to-back transactions", UVM_NONE)
    endtask : run_phase

endclass : ecc_stress_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_stress_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_stress_seq)

    function new(string name = "ecc_stress_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Executing 2000 back-to-back transactions (no delay)", UVM_MEDIUM)

        repeat(2000) begin
            `uvm_do_with(req, {
                delay == 0;
                error_type dist {
                    NO_ERROR := 10,
                    SBE      := 40,
                    DBE      := 30,
                    SSE      := 20
                };
            })
        end

        `uvm_info(get_type_name(), "Stress test complete - 2000 transactions", UVM_MEDIUM)
    endtask : body

endclass : ecc_stress_seq
