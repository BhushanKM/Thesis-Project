///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Base Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Based on Texas A&M CSCE 616 test structure
///////////////////////////////////////////////////////////////////////////

class ecc_base_test extends uvm_test;

    uvm_cmdline_processor clp;

    `uvm_component_utils(ecc_base_test)

    // Environment
    ecc_env tb;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        clp = uvm_cmdline_processor::get_inst();
    endfunction : new

    // Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tb = ecc_env::type_id::create("tb", this);
    endfunction : build_phase

    // End of Elaboration Phase - Print topology
    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    // Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    // Run Phase - Set drain time
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.phase_done.set_drain_time(this, 100ns);
    endtask : run_phase

    // Report Phase - Print test status
    function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        svr = uvm_report_server::get_server();

        `uvm_info(get_type_name(), "============================================", UVM_NONE)
        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info(get_type_name(), "********** TEST FAILED **********", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), "********** TEST PASSED **********", UVM_NONE)
        end
        `uvm_info(get_type_name(), "============================================", UVM_NONE)
    endfunction : report_phase

endclass : ecc_base_test
