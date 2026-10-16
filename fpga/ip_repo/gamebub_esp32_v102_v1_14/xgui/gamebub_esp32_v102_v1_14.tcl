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
 add_board_tab $IPINST -display_name {QSPI_BOARD_INTERFACE {QSPI} BUTTONS_BOARD_INTERFACE {Buttons} IRQ_BOARD_INTERFACE {ESP32 IRQ gate}}
 set page [ipgui::add_page $IPINST -name {IP Configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $page overview {Always-on ESP32 QSPI, active-high IRQ gate and twelve-button service.
Use 200 MHz service_clk; use an AXI Clock Converter for a different CPU clock.}
 set group [ipgui::add_group $IPINST -parent $page -name {Overlay video} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_0 {Optional native 480 x 800 AXI4-Stream, one RGBA pixel per beat.
ESP32 pixels have priority above the separate CPU bitmap.
Disabling removes overlay connections; reconnect clock, reset and AXIS when re-enabled.}
 set p [::gamebub_gui::parameter $IPINST $group C_ENABLE_OVERLAY_AXIS {Enable AXI4-Stream overlay output} {When disabled, no video RAM is generated and QSPI/IRQ still run independently. Vivado removes disabled clock/reset/interface connections; reconnect them after re-enabling this option.} {checkBox}]
 set p [::gamebub_gui::parameter $IPINST $group C_OVERLAY_MONOCHROME {Use black/white ESP32 overlay} {On: 6 BRAM36 with independent opacity. Off: full ARGB1555 storage uses 48 BRAM36.} {checkBox}]
 set p [::gamebub_gui::parameter $IPINST $group C_ENABLE_CPU_OVERLAY {Enable CPU pixel writer} {COV2: 384 x 240, independent opacity and black/white per pixel. Adds 16 RAMB18 (8 BRAM36 equivalent); CPU index/data registers start at +0x200.} {checkBox}]
 set p [::gamebub_gui::parameter $IPINST $group C_OVERLAY_CLK_HZ {Overlay stream clock (Hz)} {Clock metadata only, not a clock generator. Match overlay_clk and the receiving LCD/FIFO; for the standard pixel clock use the Clocking Wizard's actual integer frequency.} {}]
 set group [ipgui::add_group $IPINST -parent $page -name {Diagnostics} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_1 {Manual IRQ forcing is for controlled debugging only; normal ESP32 handshaking does not need it.}
 set p [::gamebub_gui::parameter $IPINST $group C_MANUAL_OVERRIDE {Allow manual IRQ assertion} {0: normal automatic IRQ only (recommended). 1: also permit the diagnostic manual gate register.} {comboBox}]
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
proc update_PARAM_VALUE.IRQ_BOARD_INTERFACE {IPINST PARAM_VALUE.IRQ_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices gamebub.org:interface:esp32_irq_rtl:1.0 master {GATE 1 out}] ${PARAM_VALUE.IRQ_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.IRQ_BOARD_INTERFACE {PARAM_VALUE.IRQ_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices gamebub.org:interface:esp32_irq_rtl:1.0 master {GATE 1 out}] ,]
 if {[get_property value ${PARAM_VALUE.IRQ_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.IRQ_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {
 
}
proc validate_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_MANUAL_OVERRIDE} 0 1]}
proc update_MODELPARAM_VALUE.C_MANUAL_OVERRIDE {MODELPARAM_VALUE.C_MANUAL_OVERRIDE PARAM_VALUE.C_MANUAL_OVERRIDE} {set_property value [get_property value ${PARAM_VALUE.C_MANUAL_OVERRIDE}] ${MODELPARAM_VALUE.C_MANUAL_OVERRIDE}}
proc update_PARAM_VALUE.C_ENABLE_OVERLAY_AXIS {PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {
 
}
proc validate_PARAM_VALUE.C_ENABLE_OVERLAY_AXIS {PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {return true}
proc update_MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS {MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {set_property value [::gamebub_gui::bool_value ${PARAM_VALUE.C_ENABLE_OVERLAY_AXIS}] ${MODELPARAM_VALUE.C_ENABLE_OVERLAY_AXIS}}
proc update_PARAM_VALUE.C_OVERLAY_MONOCHROME {PARAM_VALUE.C_OVERLAY_MONOCHROME PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {
 set axis [::gamebub_gui::bool_text ${PARAM_VALUE.C_ENABLE_OVERLAY_AXIS}]
 set_property enabled $axis ${PARAM_VALUE.C_OVERLAY_MONOCHROME}
}
proc validate_PARAM_VALUE.C_OVERLAY_MONOCHROME {PARAM_VALUE.C_OVERLAY_MONOCHROME} {return true}
proc update_MODELPARAM_VALUE.C_OVERLAY_MONOCHROME {MODELPARAM_VALUE.C_OVERLAY_MONOCHROME PARAM_VALUE.C_OVERLAY_MONOCHROME} {set_property value [::gamebub_gui::bool_value ${PARAM_VALUE.C_OVERLAY_MONOCHROME}] ${MODELPARAM_VALUE.C_OVERLAY_MONOCHROME}}
proc update_PARAM_VALUE.C_OVERLAY_CLK_HZ {PARAM_VALUE.C_OVERLAY_CLK_HZ PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {
 set axis [::gamebub_gui::bool_text ${PARAM_VALUE.C_ENABLE_OVERLAY_AXIS}]
 set_property enabled $axis ${PARAM_VALUE.C_OVERLAY_CLK_HZ}
}
proc validate_PARAM_VALUE.C_OVERLAY_CLK_HZ {PARAM_VALUE.C_OVERLAY_CLK_HZ} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_OVERLAY_CLK_HZ} 1000000 200000000 1]}
proc update_PARAM_VALUE.C_ENABLE_CPU_OVERLAY {PARAM_VALUE.C_ENABLE_CPU_OVERLAY PARAM_VALUE.C_ENABLE_OVERLAY_AXIS} {
 set axis [::gamebub_gui::bool_text ${PARAM_VALUE.C_ENABLE_OVERLAY_AXIS}]
 set_property enabled $axis ${PARAM_VALUE.C_ENABLE_CPU_OVERLAY}
 if {!$axis} {set_property value false ${PARAM_VALUE.C_ENABLE_CPU_OVERLAY}}
}
proc validate_PARAM_VALUE.C_ENABLE_CPU_OVERLAY {PARAM_VALUE.C_ENABLE_CPU_OVERLAY} {return true}
proc update_MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY {MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY PARAM_VALUE.C_ENABLE_CPU_OVERLAY} {set_property value [::gamebub_gui::bool_value ${PARAM_VALUE.C_ENABLE_CPU_OVERLAY}] ${MODELPARAM_VALUE.C_ENABLE_CPU_OVERLAY}}
