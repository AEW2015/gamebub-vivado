# Current GUI-polished IP set for NEW Vivado 2025.2 IPI projects.
# This curated distribution does not include historical packages/installers.
# Keep historical projects with their original repository and upgrade privately.
set gb_current_board_dir [file dirname [file normalize [info script]]]
set gb_current_constraint_release 20261016_cdc2
puts "GAMEBUB_CONSTRAINT_RELEASE=$gb_current_constraint_release"
if {[regexp {\s} $gb_current_board_dir]} {
 puts {WARNING: Vivado 2025.2 child synthesis runs flatten board repository paths containing whitespace. GUI generation may work while launch_runs later cannot find the board. Install this source bundle in a path without spaces; do not patch generated AMD run scripts.}
}
set gb_current_versions {
 gamebub_esp32_v102 1.14 gamebub_lcd_axis 1.5 gamebub_sram_mem 1.6
 gamebub_sdram_mem 1.6 gamebub_dac_audio 1.3 gamebub_esp32_irq 1.2
 gamebub_esp32_qspi 1.2 gamebub_video_status 1.1
}
set gb_current_paths [list $gb_current_board_dir/interfaces]
set gb_current_vlnvs {}
foreach {name ver} $gb_current_versions {
 lappend gb_current_paths [file normalize $gb_current_board_dir/../ip_repo/${name}_v[string map {. _} $ver]]
 lappend gb_current_vlnvs gamebub.org:ip:$name:$ver
}
if {[current_project -quiet] ne ""} {
 # Refuse to make historical instantiated IP disappear from an existing project.
 foreach ip [get_ips -quiet] {
  set def [get_property IPDEF $ip]
  if {[string match gamebub.org:* $def] && $def ni $gb_current_vlnvs} {
   error "Current-only setup would hide instantiated $def ($ip). Keep this historical project with its original repository, or upgrade a private copy first."
  }
 }
}
set gb_current_boards [get_param board.repoPaths]
if {$gb_current_board_dir ni $gb_current_boards} {lappend gb_current_boards $gb_current_board_dir}
set_param board.repoPaths $gb_current_boards
# File1.10 is not the Latest winner when1.9 is present in Vivado2025.2.
# Board2.0 preserves1.10's hardware contract and is the new-project GUI choice.
# This only inspects discovery; never change an existing project's BOARD_PART.
set gb_current_recommended_board gamebub.org:gamebub_rev4:part0:2.0
set gb_current_latest_board [get_board_parts -quiet -latest_file_version gamebub.org:gamebub_rev4:part0:*]
puts "GAMEBUB_RECOMMENDED_BOARD=$gb_current_recommended_board"
puts "GAMEBUB_GUI_LATEST_BOARD=$gb_current_latest_board"
if {$gb_current_latest_board ne $gb_current_recommended_board} {
 puts {WARNING: GameBub board2.0 is not the discovered Latest board in this Vivado session. Save your work, restart Vivado, source this helper before opening New Project, then select GameBub Rev4 file version2.0 in the GUI. Re-sourcing an already cached repository may not rescan added board versions. Existing projects have not been upgraded.}
}
if {[current_project -quiet] ne ""} {
 set gb_existing_paths [get_property IP_REPO_PATHS [current_project]]
 set gb_historical_root [file normalize $gb_current_board_dir/../ip_repo]
 foreach path $gb_existing_paths {
  if {[string equal -nocase [file normalize $path] $gb_historical_root]} {continue}
  if {$path ni $gb_current_paths} {lappend gb_current_paths $path}
 }
 foreach path $gb_current_paths {if {![file isdirectory $path]} {error "Missing current IP repository $path"}}
 set_property IP_REPO_PATHS $gb_current_paths [current_project]
 update_ip_catalog -rebuild
 puts "GAMEBUB_CURRENT_IP_VERSIONS=$gb_current_versions"
}
puts "GAMEBUB_CURRENT_BOARD_REPOSITORY=$gb_current_board_dir"
