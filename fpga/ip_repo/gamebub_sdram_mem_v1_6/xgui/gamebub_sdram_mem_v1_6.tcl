# GameBub GUI-only common template; bundled into each versioned IP.
# Uses the same native board helper as AMD AXI GPIO / Clocking Wizard 2025.2.
package require xilinx::board 1.0
namespace import ::xilinx::board::*
namespace eval ::gamebub_gui {}
proc ::gamebub_gui::board_choices {vlnv mode ports} {
 if {[::ipxit::get_project_property BOARD] eq ""} {return Custom}
 set result [list Custom]
 foreach intf [get_board_part_interfaces -filter "VLNV == $vlnv && MODE == $mode"] {
  set compatible 1
  foreach {name width direction} $ports {
   if {[llength [get_board_interface_ports -of_objects $intf -filter "LOGICAL_NAME == $name && WIDTH == $width && DIRECTION == $direction"]]!=1} {set compatible 0;break}
  }
  if {$compatible} {lappend result [get_property NAME $intf]}
 }
 return [join [lsort -unique $result] ,]
}
proc ::gamebub_gui::note {inst parent name text} {
 return [ipgui::add_static_text $inst -parent $parent -name $name -text $text]
}
proc ::gamebub_gui::parameter {inst parent name label tip {widget {}}} {
 if {$widget eq ""} {set p [ipgui::add_param $inst -parent $parent -name $name]} else {set p [ipgui::add_param $inst -parent $parent -name $name -widget $widget]}
 set_property display_name $label $p
 set_property tooltip $tip $p
 return $p
}
proc ::gamebub_gui::integer_ok {object lo hi {align 1}} {
 set v [get_property value $object]
 if {![string is wideinteger -strict $v] || $v<$lo || $v>$hi || $v%$align!=0} {
  set_property errmsg "Enter an integer from $lo to $hi, aligned to $align." $object
  return false
 }
 return true
}
proc ::gamebub_gui::bool_value {object} {
 # Vivado GUI paramvalues may be TRUE/FALSE, whereas XCI uses true/false.
 # Use Tcl boolean conversion, not a case-sensitive string membership test.
 set v [get_property value $object]
 if {[info exists ::env(GAMEBUB_GUI_TRACE)]} {puts "GAMEBUB_GUI_BOOL object=$object value=<$v>"}
 return [expr {$v ? 1 : 0}]
}
proc ::gamebub_gui::bool_text {object} {
 # XGUI enum-valued enabled/visible properties require literal true/false.
 return [expr {[::gamebub_gui::bool_value $object] ? "true" : "false"}]
}

proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 add_board_tab $IPINST -display_name {SDRAM_BOARD_INTERFACE {SDR SDRAM}}
 set page [ipgui::add_page $IPINST -name {IP Configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $page overview {32 MiB SDR SDRAM with 100 MHz MEM_AXI and unified CTRL_AXI.
Use a separate stable 200 MHz refclk200 for IDELAY calibration.}
 set group [ipgui::add_group $IPINST -parent $page -name {Memory interface} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_0 {CTRL_AXI occupies 8 KiB: memory/test registers at +0x0000 and MMCM registers at +0x1000.
The controller contains its own runtime-reconfigurable memory MMCM.}
 set p [::gamebub_gui::parameter $IPINST $group C_MEMORY_BYTES {Installed SDRAM capacity (bytes)} {Fixed board memory capacity: 33554432 bytes (32 MiB).} {}]
 set_property enabled false $p
 set group [ipgui::add_group $IPINST -parent $page -name {Advanced configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_1 {Keep boot code and stack in BRAM until external memory has been qualified.
Park all memory clients before changing memory clocks or ownership.}
 set p [::gamebub_gui::parameter $IPINST $group C_ADVANCED_SETTINGS {Edit advanced controller defaults} {Enables the settings below, which propagate into the implemented controller. These are not a frequency/phase qualification claim.} {checkBox}]
 set p [::gamebub_gui::parameter $IPINST $group C_BASE_ADDR {Processor memory base address} {Must match Address Editor's MEM_AXI base and be 64 MiB aligned; defaults to 0x60000000. The physical memory aperture is only 32 MiB.} {}]
 set p [::gamebub_gui::parameter $IPINST $group C_POWER_BEATS {Power-up wait (command-clock cycles)} {15625..65535 cycles, matching the RTL's 16-bit wait counter; default retained. This setting does not certify memory electrical timing.} {}]
 set p [::gamebub_gui::parameter $IPINST $group C_TIMEOUT_CYCLES {Mailbox timeout (100 MHz host cycles)} {1024..16777216 host cycles; preserve the default unless implementing a known ownership/clock configuration.} {}]
 set p [::gamebub_gui::parameter $IPINST $group C_METER_WINDOW {Frequency-meter window (reference cycles)} {Choose 50000, 100000 or 200000 cycles. Larger windows trade update speed for measurement granularity.} {comboBox}]
}
proc update_PARAM_VALUE.SDRAM_BOARD_INTERFACE {IPINST PARAM_VALUE.SDRAM_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices gamebub.org:interface:sdram_rtl:1.0 master {A 13 out BS 2 out DQ 16 inout CLK 1 out WE_N 1 out LDQM 1 out UDQM 1 out CAS_N 1 out RAS_N 1 out CKE 2 out CS_N 2 out}] ${PARAM_VALUE.SDRAM_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.SDRAM_BOARD_INTERFACE {PARAM_VALUE.SDRAM_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices gamebub.org:interface:sdram_rtl:1.0 master {A 13 out BS 2 out DQ 16 inout CLK 1 out WE_N 1 out LDQM 1 out UDQM 1 out CAS_N 1 out RAS_N 1 out CKE 2 out CS_N 2 out}] ,]
 if {[get_property value ${PARAM_VALUE.SDRAM_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.SDRAM_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.C_BASE_ADDR {PARAM_VALUE.C_BASE_ADDR PARAM_VALUE.C_ADVANCED_SETTINGS} {
 set_property enabled [::gamebub_gui::bool_text ${PARAM_VALUE.C_ADVANCED_SETTINGS}] ${PARAM_VALUE.C_BASE_ADDR}
}
proc validate_PARAM_VALUE.C_BASE_ADDR {PARAM_VALUE.C_BASE_ADDR} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_BASE_ADDR} 0 4227858432 67108864]}
proc update_MODELPARAM_VALUE.C_BASE_ADDR {MODELPARAM_VALUE.C_BASE_ADDR PARAM_VALUE.C_BASE_ADDR} {set_property value [get_property value ${PARAM_VALUE.C_BASE_ADDR}] ${MODELPARAM_VALUE.C_BASE_ADDR}}
proc update_PARAM_VALUE.C_POWER_BEATS {PARAM_VALUE.C_POWER_BEATS PARAM_VALUE.C_ADVANCED_SETTINGS} {
 set_property enabled [::gamebub_gui::bool_text ${PARAM_VALUE.C_ADVANCED_SETTINGS}] ${PARAM_VALUE.C_POWER_BEATS}
}
proc validate_PARAM_VALUE.C_POWER_BEATS {PARAM_VALUE.C_POWER_BEATS} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_POWER_BEATS} 15625 65535 1]}
proc update_MODELPARAM_VALUE.C_POWER_BEATS {MODELPARAM_VALUE.C_POWER_BEATS PARAM_VALUE.C_POWER_BEATS} {set_property value [get_property value ${PARAM_VALUE.C_POWER_BEATS}] ${MODELPARAM_VALUE.C_POWER_BEATS}}
proc update_PARAM_VALUE.C_TIMEOUT_CYCLES {PARAM_VALUE.C_TIMEOUT_CYCLES PARAM_VALUE.C_ADVANCED_SETTINGS} {
 set_property enabled [::gamebub_gui::bool_text ${PARAM_VALUE.C_ADVANCED_SETTINGS}] ${PARAM_VALUE.C_TIMEOUT_CYCLES}
}
proc validate_PARAM_VALUE.C_TIMEOUT_CYCLES {PARAM_VALUE.C_TIMEOUT_CYCLES} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_TIMEOUT_CYCLES} 1024 16777216 1]}
proc update_MODELPARAM_VALUE.C_TIMEOUT_CYCLES {MODELPARAM_VALUE.C_TIMEOUT_CYCLES PARAM_VALUE.C_TIMEOUT_CYCLES} {set_property value [get_property value ${PARAM_VALUE.C_TIMEOUT_CYCLES}] ${MODELPARAM_VALUE.C_TIMEOUT_CYCLES}}
proc update_PARAM_VALUE.C_METER_WINDOW {PARAM_VALUE.C_METER_WINDOW PARAM_VALUE.C_ADVANCED_SETTINGS} {
 set_property enabled [::gamebub_gui::bool_text ${PARAM_VALUE.C_ADVANCED_SETTINGS}] ${PARAM_VALUE.C_METER_WINDOW}
}
proc validate_PARAM_VALUE.C_METER_WINDOW {PARAM_VALUE.C_METER_WINDOW} {if {[get_property value ${PARAM_VALUE.C_METER_WINDOW}] ni {50000 100000 200000}} {set_property errmsg {Choose 50000, 100000 or 200000 cycles.} ${PARAM_VALUE.C_METER_WINDOW};return false};return true}
proc update_MODELPARAM_VALUE.C_METER_WINDOW {MODELPARAM_VALUE.C_METER_WINDOW PARAM_VALUE.C_METER_WINDOW} {set_property value [get_property value ${PARAM_VALUE.C_METER_WINDOW}] ${MODELPARAM_VALUE.C_METER_WINDOW}}
proc update_PARAM_VALUE.C_MEMORY_BYTES {PARAM_VALUE.C_MEMORY_BYTES} {set_property enabled false ${PARAM_VALUE.C_MEMORY_BYTES}}
proc validate_PARAM_VALUE.C_MEMORY_BYTES {PARAM_VALUE.C_MEMORY_BYTES} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_MEMORY_BYTES} 33554432 33554432]}
proc update_PARAM_VALUE.C_ADVANCED_SETTINGS {PARAM_VALUE.C_ADVANCED_SETTINGS} {
 
}
proc validate_PARAM_VALUE.C_ADVANCED_SETTINGS {PARAM_VALUE.C_ADVANCED_SETTINGS} {return true}
