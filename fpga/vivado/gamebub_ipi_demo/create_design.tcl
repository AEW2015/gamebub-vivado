# Recreate the documentation reference in a fresh, private project. No hardware.
set here [file dirname [file normalize [info script]]]
set fpga [file normalize $here/../..]
set out [file normalize [lindex $argv 0]]
if {$out eq "" || [file exists $out]} {error {Supply a new output directory}}
source $fpga/board_files/install_gamebub_current_repositories.tcl
create_project gamebub_demo $out -part xc7a100tcsg324-1
set_property board_part gamebub.org:gamebub_rev4:part0:2.0 [current_project]
source $fpga/board_files/install_gamebub_current_repositories.tcl
source $here/reference_bd.tcl
# Explicit unused hold tie-off; the original export relied on default zero.
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 memory_run
set_property -dict {CONFIG.CONST_WIDTH 1 CONFIG.CONST_VAL 0} [get_bd_cells memory_run]
connect_bd_net [get_bd_pins memory_run/dout] [get_bd_pins gamebub_sdram_mem_0/reconfig_hold]
source $here/validate_design.tcl
validate_bd_design
save_bd_design
generate_target all [get_files */top.bd]
set wrapper [make_wrapper -files [get_files */top.bd] -top]
add_files -norecurse $wrapper
set_property top top_wrapper [current_fileset]
update_compile_order -fileset sources_1
write_hw_platform -fixed -force -file $out/gamebub_demo.xsa
puts GAMEBUB_DOCUMENTED_REFERENCE_XSA_PASS
close_project
exit
