//////////////////////////////////////////////////////////////////////////////////
// ECC Tests - Test Scenarios
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Base Test
//==============================================================================
class ecc_base_test extends uvm_test;

    `uvm_component_utils(ecc_base_test)

    ecc_env env;

    function new(string name = "ecc_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ecc_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting base test", UVM_LOW)
        #100ns;
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        svr = uvm_report_server::get_server();

        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info(get_type_name(), "********** TEST FAILED **********", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), "********** TEST PASSED **********", UVM_NONE)
        end
    endfunction

endclass

//==============================================================================
// Sanity Test - Quick functionality check
//==============================================================================
class ecc_sanity_test extends ecc_base_test;

    `uvm_component_utils(ecc_sanity_test)

    function new(string name = "ecc_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        no_error_seq no_err_seq;
        sbe_seq sbe_sequence;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting sanity test", UVM_LOW)

        // Run no-error sequence
        no_err_seq = no_error_seq::type_id::create("no_err_seq");
        no_err_seq.num_transactions = 10;
        no_err_seq.start(env.agent.sequencer);

        // Run a few SBE tests
        sbe_sequence = sbe_seq::type_id::create("sbe_sequence");
        sbe_sequence.num_transactions = 20;
        sbe_sequence.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// SBE Test - Single Bit Error correction
//==============================================================================
class ecc_sbe_test extends ecc_base_test;

    `uvm_component_utils(ecc_sbe_test)

    function new(string name = "ecc_sbe_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sbe_exhaustive_seq sbe_exh_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting SBE exhaustive test", UVM_LOW)

        // Run exhaustive SBE test (all 304 bit positions)
        sbe_exh_seq = sbe_exhaustive_seq::type_id::create("sbe_exh_seq");
        sbe_exh_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// DBE Test - Double Bit Error correction
//==============================================================================
class ecc_dbe_test extends ecc_base_test;

    `uvm_component_utils(ecc_dbe_test)

    function new(string name = "ecc_dbe_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        dbe_seq dbe_sequence;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting DBE test", UVM_LOW)

        dbe_sequence = dbe_seq::type_id::create("dbe_sequence");
        dbe_sequence.num_transactions = 500;
        dbe_sequence.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// SSE Test - Single Symbol Error correction
//==============================================================================
class ecc_sse_test extends ecc_base_test;

    `uvm_component_utils(ecc_sse_test)

    function new(string name = "ecc_sse_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sse_seq sse_sequence;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting SSE test", UVM_LOW)

        sse_sequence = sse_seq::type_id::create("sse_sequence");
        sse_sequence.num_transactions = 500;
        sse_sequence.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// DASE Test - Double Adjacent Symbol Error detection
//==============================================================================
class ecc_dase_test extends ecc_base_test;

    `uvm_component_utils(ecc_dase_test)

    function new(string name = "ecc_dase_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        dase_seq dase_sequence;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting DASE test (uncorrectable errors)", UVM_LOW)

        dase_sequence = dase_seq::type_id::create("dase_sequence");
        dase_sequence.num_transactions = 50;
        dase_sequence.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Boundary Test - Edge cases and special patterns
//==============================================================================
class ecc_boundary_test extends ecc_base_test;

    `uvm_component_utils(ecc_boundary_test)

    function new(string name = "ecc_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        boundary_seq bound_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting boundary test", UVM_LOW)

        bound_seq = boundary_seq::type_id::create("bound_seq");
        bound_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Comprehensive Test - All error types
//==============================================================================
class ecc_comprehensive_test extends ecc_base_test;

    `uvm_component_utils(ecc_comprehensive_test)

    function new(string name = "ecc_comprehensive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        no_error_seq   no_err_seq;
        sbe_seq        sbe_sequence;
        dbe_seq        dbe_sequence;
        sse_seq        sse_sequence;
        dase_seq       dase_sequence;
        boundary_seq   bound_seq;
        mixed_error_seq mixed_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting comprehensive test", UVM_LOW)

        // Phase 1: No error baseline
        `uvm_info(get_type_name(), "Phase 1: No-error baseline", UVM_MEDIUM)
        no_err_seq = no_error_seq::type_id::create("no_err_seq");
        no_err_seq.num_transactions = 50;
        no_err_seq.start(env.agent.sequencer);

        // Phase 2: SBE tests
        `uvm_info(get_type_name(), "Phase 2: SBE tests", UVM_MEDIUM)
        sbe_sequence = sbe_seq::type_id::create("sbe_sequence");
        sbe_sequence.num_transactions = 200;
        sbe_sequence.start(env.agent.sequencer);

        // Phase 3: DBE tests
        `uvm_info(get_type_name(), "Phase 3: DBE tests", UVM_MEDIUM)
        dbe_sequence = dbe_seq::type_id::create("dbe_sequence");
        dbe_sequence.num_transactions = 200;
        dbe_sequence.start(env.agent.sequencer);

        // Phase 4: SSE tests
        `uvm_info(get_type_name(), "Phase 4: SSE tests", UVM_MEDIUM)
        sse_sequence = sse_seq::type_id::create("sse_sequence");
        sse_sequence.num_transactions = 200;
        sse_sequence.start(env.agent.sequencer);

        // Phase 5: DASE tests
        `uvm_info(get_type_name(), "Phase 5: DASE tests", UVM_MEDIUM)
        dase_sequence = dase_seq::type_id::create("dase_sequence");
        dase_sequence.num_transactions = 50;
        dase_sequence.start(env.agent.sequencer);

        // Phase 6: Boundary tests
        `uvm_info(get_type_name(), "Phase 6: Boundary tests", UVM_MEDIUM)
        bound_seq = boundary_seq::type_id::create("bound_seq");
        bound_seq.start(env.agent.sequencer);

        // Phase 7: Mixed random tests
        `uvm_info(get_type_name(), "Phase 7: Mixed random tests", UVM_MEDIUM)
        mixed_seq = mixed_error_seq::type_id::create("mixed_seq");
        mixed_seq.num_transactions = 500;
        mixed_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Stress Test - Back-to-back high throughput
//==============================================================================
class ecc_stress_test extends ecc_base_test;

    `uvm_component_utils(ecc_stress_test)

    function new(string name = "ecc_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        stress_seq str_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting stress test", UVM_LOW)

        str_seq = stress_seq::type_id::create("str_seq");
        str_seq.num_transactions = 2000;
        str_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Test Mode Test - JEDEC HBM4 test mode
//==============================================================================
class ecc_test_mode_test extends ecc_base_test;

    `uvm_component_utils(ecc_test_mode_test)

    function new(string name = "ecc_test_mode_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        test_mode_seq tm_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting test mode test", UVM_LOW)

        tm_seq = test_mode_seq::type_id::create("tm_seq");
        tm_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass

//==============================================================================
// Regression Test - Full regression suite
//==============================================================================
class ecc_regression_test extends ecc_base_test;

    `uvm_component_utils(ecc_regression_test)

    function new(string name = "ecc_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        sbe_exhaustive_seq sbe_exh_seq;
        dbe_seq            dbe_sequence;
        sse_seq            sse_sequence;
        dase_seq           dase_sequence;
        boundary_seq       bound_seq;
        stress_seq         str_seq;
        test_mode_seq      tm_seq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting full regression test", UVM_LOW)

        // Exhaustive SBE
        `uvm_info(get_type_name(), "Regression: Exhaustive SBE (304 positions)", UVM_MEDIUM)
        sbe_exh_seq = sbe_exhaustive_seq::type_id::create("sbe_exh_seq");
        sbe_exh_seq.start(env.agent.sequencer);

        // Extended DBE
        `uvm_info(get_type_name(), "Regression: Extended DBE", UVM_MEDIUM)
        dbe_sequence = dbe_seq::type_id::create("dbe_sequence");
        dbe_sequence.num_transactions = 1000;
        dbe_sequence.start(env.agent.sequencer);

        // Extended SSE
        `uvm_info(get_type_name(), "Regression: Extended SSE", UVM_MEDIUM)
        sse_sequence = sse_seq::type_id::create("sse_sequence");
        sse_sequence.num_transactions = 1000;
        sse_sequence.start(env.agent.sequencer);

        // DASE detection
        `uvm_info(get_type_name(), "Regression: DASE detection", UVM_MEDIUM)
        dase_sequence = dase_seq::type_id::create("dase_sequence");
        dase_sequence.num_transactions = 100;
        dase_sequence.start(env.agent.sequencer);

        // Boundary patterns
        `uvm_info(get_type_name(), "Regression: Boundary patterns", UVM_MEDIUM)
        bound_seq = boundary_seq::type_id::create("bound_seq");
        bound_seq.start(env.agent.sequencer);

        // Stress test
        `uvm_info(get_type_name(), "Regression: Stress test", UVM_MEDIUM)
        str_seq = stress_seq::type_id::create("str_seq");
        str_seq.num_transactions = 5000;
        str_seq.start(env.agent.sequencer);

        // Test mode
        `uvm_info(get_type_name(), "Regression: Test mode", UVM_MEDIUM)
        tm_seq = test_mode_seq::type_id::create("tm_seq");
        tm_seq.start(env.agent.sequencer);

        #100ns;
        phase.drop_objection(this);
    endtask

endclass
