dc_command = f"bash -c 'source /opt/coe/synopsys/syn/V-2023.12-SP1/setup.syn.sh && dc_shell -f {tcl_script_path}'"
subprocess.run(dc_command, shell=True)

source /opt/coe/synopsys/syn/V-2023.12-SP1/setup.syn.sh
dc_shell

command = f"source /opt/coe/cadence/DDI231/setup.DDI231.linux.bash && innovus -batch -file {tcl_path}"

source /opt/coe/cadence/DDI231/setup.DDI231.linux.bash
innovus

source /opt/coe/synopsys/prime/V-2023.12-SP5-4/setup.prime.sh

