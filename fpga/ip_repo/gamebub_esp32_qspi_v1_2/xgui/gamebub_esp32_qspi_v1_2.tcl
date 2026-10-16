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
 add_board_tab $IPINST -display_name {QSPI_BOARD_INTERFACE {QSPI} BUTTONS_BOARD_INTERFACE {Buttons}}
 set page [ipgui::add_page $IPINST -name {IP Configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $page overview {Standalone ESP32 QSPI service and optional passive sniffer.
Use 50 MHz host_clk for MAILBOX_AXI/SNIFF_AXI, and 200 MHz service_clk.
For a new complete design, prefer the combined ESP32 Communications IP with integrated IRQ gate.}
 set group [ipgui::add_group $IPINST -parent $page -name {Transaction capture} -layout vertical]
 set p [::gamebub_gui::parameter $IPINST $group C_ENABLE_SNIFFER {Include passive QSPI transaction capture} {0: service endpoint only. 1: also include the implemented capture path; does not make a second QSPI responder.} {comboBox}]
}
proc update_PARAM_VALUE.QSPI_BOARD_INTERFACE {IPINST PARAM_VALUE.QSPI_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices gamebub.org:interface:esp32_qspi_rtl:1.0 slave {SCK 1 in CS_N 1 in DQ 4 inout}] ${PARAM_VALUE.QSPI_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.QSPI_BOARD_INTERFACE {PARAM_VALUE.QSPI_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices gamebub.org:interface:esp32_qspi_rtl:1.0 slave {SCK 1 in CS_N 1 in DQ 4 inout}] ,]
 if {[get_property value ${PARAM_VALUE.QSPI_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.QSPI_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.BUTTONS_BOARD_INTERFACE {IPINST PARAM_VALUE.BUTTONS_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices xilinx.com:interface:gpio_rtl:1.0 master {TRI_I 12 in}] ${PARAM_VALUE.BUTTONS_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.BUTTONS_BOARD_INTERFACE {PARAM_VALUE.BUTTONS_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices xilinx.com:interface:gpio_rtl:1.0 master {TRI_I 12 in}] ,]
 if {[get_property value ${PARAM_VALUE.BUTTONS_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.BUTTONS_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.C_ENABLE_SNIFFER {PARAM_VALUE.C_ENABLE_SNIFFER} {
 
}
proc validate_PARAM_VALUE.C_ENABLE_SNIFFER {PARAM_VALUE.C_ENABLE_SNIFFER} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_ENABLE_SNIFFER} 0 1]}
proc update_MODELPARAM_VALUE.C_ENABLE_SNIFFER {MODELPARAM_VALUE.C_ENABLE_SNIFFER PARAM_VALUE.C_ENABLE_SNIFFER} {set_property value [get_property value ${PARAM_VALUE.C_ENABLE_SNIFFER}] ${MODELPARAM_VALUE.C_ENABLE_SNIFFER}}
