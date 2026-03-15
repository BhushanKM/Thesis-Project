//////////////////////////////////////////////////////////////////////////////////
// ECC Agent - Agent Packaging Driver, Monitor, Sequencer
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_agent_c extends uvm_agent;

    `uvm_component_utils(ecc_agent_c)

    // Agent components
    ecc_driver_c    driver;
    ecc_monitor_c   monitor;
    ecc_sequencer_c sequencer;

    // Analysis port (passthrough from monitor)
    uvm_analysis_port #(ecc_transaction) dec_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Always create monitor
        monitor = ecc_monitor_c::type_id::create("monitor", this);

        // Create driver and sequencer only for active agent
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = ecc_driver_c::type_id::create("driver", this);
            sequencer = ecc_sequencer_c::type_id::create("sequencer", this);
        end

        dec_ap = new("dec_ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect driver to sequencer
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end

        // Connect monitor analysis port
        monitor.dec_ap.connect(dec_ap);
    endfunction

endclass
