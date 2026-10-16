# Use Vivado's installed native helper, as Clocking Wizard/AXI GPIO do.
# Native tab layout, plus discovery through Vivado's board-interface API.
# Native get_board_interface_param_range returned Custom only for this
# custom IP in 2025.2. Filter by our typed interface contracts instead.
# No board names are hardcoded; a project with no board stays Custom.
package require xilinx::board 1.0
namespace import ::xilinx::board::*
proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 add_board_tab $IPINST -display_name {
  QSPI_BOARD_INTERFACE QSPI
  BUTTONS_BOARD_INTERFACE Buttons
  IRQ_BOARD_INTERFACE {ESP32 IRQ gate}
 }
 set page [ipgui::add_page $IPINST -name {Diagnostics}]
 set p [ipgui::add_param $IPINST -parent $page -name C_MANUAL_OVERRIDE -widget comboBox]
 set_property tooltip {Default 0. Enable only for deliberate diagnostic forcing of the ESP32 IRQ gate. Normal QSPI IRQ handling always works.} $p
}
proc gamebub_board_choices {vlnv mode ports} {
 if {[::ipxit::get_project_property BOARD] eq ""} {return Custom}
 set choices [list Custom]
 foreach interface [get_board_part_interfaces -filter "VLNV == $vlnv && MODE == $mode"] {
  set compatible 1
  foreach {logical width direction} $ports {
   set matches [get_board_interface_ports -of_objects $interface -filter "LOGICAL_NAME == $logical && WIDTH == $width && DIRECTION == $direction"]
   if {[llength $matches]!=1} {set compatible 0;break}
  }
  if {!$compatible} {continue}
  lappend choices [get_property NAME $interface]
 }
 # GUI parameter 'range' is a comma-separated enumeration, not a Tcl list.
 return [join [lsort -unique $choices] ,]
}
proc update_PARAM_VALUE.QSPI_BOARD_INTERFACE {IPINST PARAM_VALUE.QSPI_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [gamebub_board_choices gamebub.org:interface:esp32_qspi_rtl:1.0 slave {SCK 1 in CS_N 1 in DQ 4 inout}]
 puts "GAMEBUB_BOARD_CHOICES QSPI=$choices"
 set_property range $choices ${PARAM_VALUE.QSPI_BOARD_INTERFACE}
}
proc update_PARAM_VALUE.BUTTONS_BOARD_INTERFACE {IPINST PARAM_VALUE.BUTTONS_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [gamebub_board_choices xilinx.com:interface:gpio_rtl:1.0 master {TRI_I 12 in}]
 puts "GAMEBUB_BOARD_CHOICES BUTTONS=$choices"
 set_property range $choices ${PARAM_VALUE.BUTTONS_BOARD_INTERFACE}
}
proc update_PARAM_VALUE.IRQ_BOARD_INTERFACE {IPINST PARAM_VALUE.IRQ_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [gamebub_board_choices gamebub.org:interface:esp32_irq_rtl:1.0 master {GATE 1 out}]
 puts "GAMEBUB_BOARD_CHOICES IRQ_GATE=$choices"
 set_property range $choices ${PARAM_VALUE.IRQ_BOARD_INTERFACE}
}
proc update_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {}
proc validate_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {
 return true
}
proc update_MODELPARAM_VALUE.C_MANUAL_OVERRIDE {MODELPARAM_VALUE.C_MANUAL_OVERRIDE PARAM_VALUE.C_MANUAL_OVERRIDE} {
 set_property value [get_property value ${PARAM_VALUE.C_MANUAL_OVERRIDE}] ${MODELPARAM_VALUE.C_MANUAL_OVERRIDE}
}
