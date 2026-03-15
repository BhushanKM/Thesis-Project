//////////////////////////////////////////////////////////////////////////////////
// ECC Environment - UVM Environment
// RS16(19,17) ECC Engine for HBM3/HBM4
//////////////////////////////////////////////////////////////////////////////////

class ecc_env extends uvm_env;

    `uvm_component_utils(ecc_env)

    // Environment components
    ecc_agent_c       agent;
    ecc_scoreboard_c  scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = ecc_agent_c::type_id::create("agent", this);
        scoreboard = ecc_scoreboard_c::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor to scoreboard
        agent.monitor.dec_ap.connect(scoreboard.dec_export);
    endfunction

endclass
