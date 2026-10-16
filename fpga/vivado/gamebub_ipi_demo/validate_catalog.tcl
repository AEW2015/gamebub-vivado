# SPDX-License-Identifier: 0BSD
# Read-only package checks in an owned, in-memory project. No hardware.
if {[current_project -quiet] ne ""} {error {Run in a fresh Vivado batch session}}
set catalog_here [file dirname [file normalize [info script]]]
set catalog_fpga [file normalize $catalog_here/../..]
source $catalog_fpga/board_files/install_gamebub_current_repositories.tcl
create_project -in_memory -part xc7a100tcsg324-1
set_property board_part gamebub.org:gamebub_rev4:part0:2.0 [current_project]
source $catalog_fpga/board_files/install_gamebub_current_repositories.tcl
set catalog_count 0
foreach {catalog_name catalog_version} $gb_current_versions {
 set catalog_vlnv gamebub.org:ip:$catalog_name:$catalog_version
 if {[llength [get_ipdefs -all -quiet $catalog_vlnv]] != 1} {
  error "Missing or ambiguous catalog entry: $catalog_vlnv"
 }
 set catalog_folder ${catalog_name}_v[string map {. _} $catalog_version]
 set catalog_core [ipx::open_core $catalog_fpga/ip_repo/$catalog_folder/component.xml]
 set catalog_result [ipx::check_integrity $catalog_core]
 if {$catalog_result != 1} {error "IP integrity failed: $catalog_vlnv"}
 puts "GAMEBUB_CATALOG_IP_PASS $catalog_vlnv"
 ipx::unload_core $catalog_core
 incr catalog_count
}
puts "GAMEBUB_CATALOG_CHECK_PASS count=$catalog_count"
close_project
exit
