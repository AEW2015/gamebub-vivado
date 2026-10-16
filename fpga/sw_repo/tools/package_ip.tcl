# Output-only SDK packaging. Inputs are prepared by package_inputs.py.
if {[llength $argv] < 1} {error "Usage: package_ip.tcl probe | OUTPUT"}
if {[lindex $argv 0] eq "probe"} {
 load_features ipservices
 foreach cmd {ipx::add_file_group ipx::add_file ipx::get_file_group_types ipx::create_xgui_files ipx::check_integrity ipx::open_core ipx::unload_core ipx::save_core} {
  if {[catch {help $cmd} result]} {puts "PROBE $cmd $result"} else {puts $result}
 }
 set probe [ipx::create_core gamebub.org user sdk_type_probe 0.0]
 foreach type {product_guide datasheet getting_started_guide software_driver softwareDrivers example_design example} {
  if {[catch {set group [ipx::add_file_group -type $type probe_$type $probe]} result]} {puts "TYPE_REJECT $type $result"} else {puts "TYPE_ACCEPT $type";report_property $group}
 }
 exit
}
set output [file normalize [lindex $argv 0]]
source [file join $output inputs.tcl]
create_project -in_memory sdk_ip_catalog -part xc7a100tcsg324-1
set_property ip_repo_paths [list [file join $output ip_repo interfaces]] [current_project]
update_ip_catalog -rebuild
foreach entry $packages {
 lassign $entry folder version title driver doc
 set core_dir [file join $output ip_repo $folder]
 ipx::open_core [file join $core_dir component.xml]
 set core [ipx::current_core]
 set_property version $version $core
 set_property core_revision 1 $core
 set_property display_name "$title (SDK documentation candidate)" $core
 # Replace the old standalone integration-guide entry with canonical generated
 # docs. Keep the original HTML payload untouched for source identity auditing.
 foreach fg [ipx::get_file_groups -of_objects $core] {
  if {[get_property type $fg] eq "product_guide"} {ipx::remove_file_group [get_property name $fg] $core}
 }
 # Retain every original source/GUI file; use a byte-identical new-version GUI
 # filename so the candidate version does not produce a basename warning.
 set name [get_property name $core]
 foreach fg [ipx::get_file_groups -of_objects $core] {
  foreach f [ipx::get_files -of_objects $fg] {
   set old [get_property name $f]
   if {[string match "xgui/${name}_v*.tcl" $old]} {
    set new "xgui/${name}_v[string map {. _} $version].tcl"
    if {[file isfile [file join $core_dir $new]]} {set_property name $new $f}
   }
  }
 }
 # Real IPX type names probed against installed Vivado2025.2; do not use GUI
 # label strings such as softwareDrivers/example_design as type enums.
 foreach {type suffix name} {
  product_guide product-guide.html {Product Guide}
  datasheet README.html {Data Sheet}
  getting_started_guide software.html {Getting Started}
 } {
  set fg [ipx::add_file_group -type $type sdk_$type $core]
  set_property display_name "$title $name" $fg
  set f [ipx::add_file "doc/sdk/docs/vivado/ips/$doc/$suffix" $fg]
  set_property type html $f
 }
 if {$driver ne ""} {
  set fg [ipx::add_file_group -type software_driver sdk_software_driver $core]
  foreach name $sdk_software($folder) {ipx::add_file $name $fg}
 }
 set fg [ipx::add_file_group -type example sdk_example $core]
 set f [ipx::add_file examples/sdk_example.tcl $fg]
 set_property type tclSource $f
 # Source the portable hook to validate relocation/path calculation without
 # creating or mutating a project. Full GUI example generation is separate.
 source [file join $core_dir examples/sdk_example.tcl]
 if {![file isfile $gamebub_sdk/fpga/vivado/gamebub_ipi_demo/create_design.tcl]} {error {Portable SDK hook resolved an invalid path}}
 ipx::update_checksums $core
 ipx::save_core $core
 set report [ipx::check_integrity $core]
 if {$report != 1} {error "Native integrity failed for $folder"}
 puts "SDK_IP_INTEGRITY_PASS $folder result=$report"
 ipx::unload_core $core
}
puts SDK_IP_PACKAGING_DONE
exit
