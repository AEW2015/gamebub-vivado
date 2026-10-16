# SPDX-License-Identifier: 0BSD
# Audit packaged constraints on a COPY-IN-MEMORY of a supplied routed DCP.
# Writes only to a new output folder. Does not alter/rebuild the input project.
set here [file dirname [file normalize [info script]]]
set fpga [file normalize $here/../..]
set input_dcp [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]
if {![file isfile $input_dcp] || [file exists $output_dir]} {
 error {Supply an existing routed DCP and a NEW output directory}
}
file mkdir $output_dir
set_param general.maxThreads 4
open_checkpoint $input_dcp
set esp [get_cells -hier -filter {REF_NAME == gamebub_esp32_v102 || ORIG_REF_NAME == gamebub_esp32_v102}]
set sdram [get_cells -hier -filter {REF_NAME == gamebub_sdram_mem || ORIG_REF_NAME == gamebub_sdram_mem}]
if {[llength $esp]!=1 || [llength $sdram]!=1} {error {Expected one ESP32 and SDRAM core}}
set esp [lindex $esp 0]
set sdram [lindex $sdram 0]
read_xdc -cells $esp $fpga/ip_repo/gamebub_esp32_v102_v1_14/constraints/esp32_cdc.xdc
read_xdc -cells $sdram $fpga/ip_repo/gamebub_sdram_mem_v1_6/constraints/sdram_cdc.xdc
set evidence [open $output_dir/endpoint_checks.txt w]
foreach {name src_pattern dst_pattern budget} {
 request memory/link/held_request_reg* memory/link/mem_data_reg* 16
 response memory/link/held_response_reg* memory/link/response_data_reg* 20
 cmd_meter clocks/cmd_meter/gray_count_reg* clocks/cmd_meter/gray_meta_reg* 16
 read_meter clocks/read_meter/gray_count_reg* clocks/read_meter/gray_meta_reg* 16
} {
 set src [get_cells -hier -filter "NAME =~ $sdram/$src_pattern && REF_NAME =~ FD*"]
 set dst [get_cells -hier -filter "NAME =~ $sdram/$dst_pattern && REF_NAME =~ FD*"]
 # NAME pattern above allows nested module names within the core.
 if {![llength $src] || ![llength $dst]} {error "Missing $name endpoints"}
 set path [get_timing_paths -from $src -to $dst -max_paths 1]
 if {[llength $path]!=1} {error "Payload $name became untimed"}
 set actual [get_property REQUIREMENT $path]
 if {abs($actual-$budget)>0.001} {error "Wrong $name budget $actual"}
 puts $evidence "$name sources=[llength $src] destinations=[llength $dst] requirement=$actual slack=[get_property SLACK $path]"
}
set first [get_pins -hier -regexp {.*cpu_enable_sync_reg\[0\]/D}]
puts "ESP32_FIRST_STAGE count=[llength $first] pins=$first"
report_exceptions -summary -file $output_dir/exceptions_before_checks.rpt
if {[llength $first]!=1} {error {CPU overlay first stage is missing}}
# Vivado can return false-path objects whose SLACK property does not match the
# printed infinity. Check the explicit exception in the native report instead.
set first_report [report_timing -to $first -return_string]
set first_file [open $output_dir/overlay_first_stage.rpt w]
puts $first_file $first_report
close $first_file
if {![regexp {Timing Exception:\s+False Path} $first_report]} {
 error {CPU overlay first stage is missing or still synchronously timed}
}
puts $evidence {ESP32 CPU overlay first-stage exception PASS}
close $evidence
report_timing_summary -max_paths 2 -file $output_dir/timing_summary.rpt
report_bus_skew -file $output_dir/bus_skew.rpt
report_exceptions -summary -file $output_dir/exceptions.rpt
report_route_status -file $output_dir/route_status.rpt
write_checkpoint $output_dir/constraints_applied.dcp
puts GAMEBUB_PACKAGED_CDC_ENDPOINT_AUDIT_PASS
close_design
exit
