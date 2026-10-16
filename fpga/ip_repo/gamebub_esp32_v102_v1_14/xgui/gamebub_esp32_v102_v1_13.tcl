# v1.13 per-pixel CPU alpha. Use Vivado's installed native board helper.
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
 set video [ipgui::add_page $IPINST -name {Overlay video}]
 set p [ipgui::add_param $IPINST -parent $video -name C_ENABLE_CPU_OVERLAY -widget checkBox]
 set_property tooltip {Requires AXIS overlay output. Adds a 384x240 processor bitmap with independent opacity and black/white for every pixel, beneath ESP32 menus. Packed 16 pixels/word or individual pixel writes. No hardware rectangle. Registers 0x200..0x230, COV2 format. CPU RAM adds 16 BRAM18 (8 BRAM36 equivalent).} $p
 set p [ipgui::add_param $IPINST -parent $video -name C_ENABLE_OVERLAY_AXIS -widget checkBox]
 set_property tooltip {Optional 480x800 AMD RGBA AXI4-Stream output. Black/white plus transparency uses 6 BRAM36; full color uses 48. Disabled by default; QSPI/IRQ never wait for video.} $p
 set p [ipgui::add_param $IPINST -parent $video -name C_OVERLAY_MONOCHROME -widget checkBox]
 set_property tooltip {Recommended ON: stores black/white plus transparency, 2 bits per pixel. OFF preserves full ARGB1555 color. Output AXIS format is unchanged.} $p
 set p [ipgui::add_param $IPINST -parent $video -name C_OVERLAY_CLK_HZ]
 set_property tooltip {Must match the clock connected to overlay_clk and the compositor/FIFO. Recommended 100000000 Hz. This is clock metadata, not an internal clock generator.} $p
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
proc update_PARAM_VALUE.C_ENABLE_OVERLAY_AXIS {PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {}
proc update_PARAM_VALUE.C_ENABLE_CPU_OVERLAY {PARAM_VALUE.C_ENABLE_CPU_OVERLAY} {}
proc validate_PARAM_VALUE.C_ENABLE_CPU_OVERLAY {PARAM_VALUE.C_ENABLE_CPU_OVERLAY} {return true}
proc update_MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY {MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY PARAM_VALUE.C_ENABLE_CPU_OVERLAY} {
 set_property value [expr {[get_property value ${PARAM_VALUE.C_ENABLE_CPU_OVERLAY}]?1:0}] ${MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY}
}
proc update_PARAM_VALUE.C_OVERLAY_MONOCHROME {PARAM_VALUE.C_OVERLAY_MONOCHROME} {}
proc validate_PARAM_VALUE.C_OVERLAY_MONOCHROME {PARAM_VALUE.C_OVERLAY_MONOCHROME} {return true}
proc update_MODELPARAM_VALUE.C_OVERLAY_MONOCHROME {MODELPARAM_VALUE.C_OVERLAY_MONOCHROME PARAM_VALUE.C_OVERLAY_MONOCHROME} {
 set_property value [expr {[get_property value ${PARAM_VALUE.C_OVERLAY_MONOCHROME}] ? 1 : 0}] ${MODELPARAM_VALUE.C_OVERLAY_MONOCHROME}
}
proc update_PARAM_VALUE.C_OVERLAY_CLK_HZ {PARAM_VALUE.C_OVERLAY_CLK_HZ} {}
proc validate_PARAM_VALUE.C_OVERLAY_CLK_HZ {PARAM_VALUE.C_OVERLAY_CLK_HZ} {
 return true
}
proc validate_PARAM_VALUE.C_ENABLE_OVERLAY_AXIS {PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {return true}
proc update_MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS {MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {
 set_property value [expr {[get_property value ${PARAM_VALUE.C_ENABLE_OVERLAY_AXIS}] ? 1 : 0}] ${MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS}
}
