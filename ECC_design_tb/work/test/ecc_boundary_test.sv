///////////////////////////////////////////////////////////////////////////
// ECC UVM Testbench - Boundary Test
// RS16(19,17) ECC Engine for HBM3/HBM4
// Tests edge cases: all-zeros, all-ones, alternating patterns
///////////////////////////////////////////////////////////////////////////

class ecc_boundary_test extends ecc_base_test;

    `uvm_component_utils(ecc_boundary_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        uvm_config_wrapper::set(this, "tb.agent.sequencer.run_phase", "default_sequence", ecc_boundary_seq::type_id::get());
        super.build_phase(phase);
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info(get_type_name(), "Starting Boundary Pattern Test", UVM_NONE)
    endtask : run_phase

endclass : ecc_boundary_test


///////////////////////////// SEQUENCE ///////////////////////////

class ecc_boundary_seq extends ecc_base_seq;

    `uvm_object_utils(ecc_boundary_seq)

    function new(string name = "ecc_boundary_seq");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info(get_type_name(), "Testing boundary patterns", UVM_MEDIUM)

        // All zeros - no error
        `uvm_info(get_type_name(), "Testing all-zeros pattern", UVM_MEDIUM)
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == '0;
        })

        // All ones - no error
        `uvm_info(get_type_name(), "Testing all-ones pattern", UVM_MEDIUM)
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == '1;
        })

        // Alternating 0x5555 - no error
        `uvm_info(get_type_name(), "Testing alternating 0x5555 pattern", UVM_MEDIUM)
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == {17{16'h5555}};
        })

        // Alternating 0xAAAA - no error
        `uvm_info(get_type_name(), "Testing alternating 0xAAAA pattern", UVM_MEDIUM)
        `uvm_do_with(req, {
            error_type == NO_ERROR;
            data == {17{16'hAAAA}};
        })

        // All zeros with SBE in each symbol
        `uvm_info(get_type_name(), "Testing SBE in all-zeros data", UVM_MEDIUM)
        for (int sym = 0; sym < 17; sym++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                data == '0;
                error_symbol_0 == sym;
                error_pattern_0 == 16'h0001;
            })
        end

        // All ones with SBE in each symbol
        `uvm_info(get_type_name(), "Testing SBE in all-ones data", UVM_MEDIUM)
        for (int sym = 0; sym < 17; sym++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                data == '1;
                error_symbol_0 == sym;
                error_pattern_0 == 16'h0001;
            })
        end

        // Walking ones pattern with errors
        `uvm_info(get_type_name(), "Testing walking ones with SBE", UVM_MEDIUM)
        for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                error_symbol_0 == 0;
                error_pattern_0 == (16'h1 << bit_pos);
            })
        end

        // Walking zeros pattern with errors
        `uvm_info(get_type_name(), "Testing walking zeros with SBE", UVM_MEDIUM)
        for (int bit_pos = 0; bit_pos < 16; bit_pos++) begin
            `uvm_do_with(req, {
                error_type == SBE;
                data == '1;
                error_symbol_0 == 0;
                error_pattern_0 == (16'h1 << bit_pos);
            })
        end

        // First and last symbol boundaries
        `uvm_info(get_type_name(), "Testing first/last symbol boundaries", UVM_MEDIUM)
        `uvm_do_with(req, {
            error_type == DBE;
            error_symbol_0 == 0;
            error_symbol_1 == 16;
            $countones(error_pattern_0) == 1;
            $countones(error_pattern_1) == 1;
        })

        `uvm_info(get_type_name(), "Boundary test complete", UVM_MEDIUM)
    endtask : body

endclass : ecc_boundary_seq
