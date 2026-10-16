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
 add_board_tab $IPINST -display_name {LCD_BOARD_INTERFACE {LCD RGB888}}
 set page [ipgui::add_page $IPINST -name {IP Configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $page overview {Native GameBub RGB888 scanout: 480 x 800, viewed as 800 x 480 landscape.
Connect pixel_clk to approximately 29.361979 MHz and use active-low pixel_resetn.}
 set group [ipgui::add_group $IPINST -parent $page -name {Video input} -layout vertical]
 set p [::gamebub_gui::parameter $IPINST $group C_RGB_PACKING {RGB byte order} {0: AMD TPG/VDMA RGB packing. 1: alternate packing retained for existing custom sources.} {comboBox}]
 set group [ipgui::add_group $IPINST -parent $page -name {ESP32 / CPU overlay} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_1 {Connect M_AXIS_OVERLAY directly to S_AXIS_OVERLAY at the same pixel clock.
When overlay is disabled, no overlay stream is required.}
 set p [::gamebub_gui::parameter $IPINST $group C_ENABLE_OVERLAY {Enable AXI4-Stream overlay input} {Overlay pixels use binary alpha. Disable for a video-only test-pattern design.} {comboBox}]
 set group [ipgui::add_group $IPINST -parent $page -name {Panel timing} -layout vertical]
 set p [::gamebub_gui::parameter $IPINST $group C_TIMING_PROFILE {Panel timing profile} {1: official-derived fixed timing (recommended for new designs). 0: preserve legacy porch timing for controlled comparisons. Neither changes pixel-clock frequency.} {comboBox}]
}
proc update_PARAM_VALUE.LCD_BOARD_INTERFACE {IPINST PARAM_VALUE.LCD_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices gamebub.org:interface:lcd_rgb888_rtl:1.0 master {R 8 out G 8 out B 8 out DOTCLK 1 out HSYNC 1 out VSYNC 1 out DE 1 out}] ${PARAM_VALUE.LCD_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.LCD_BOARD_INTERFACE {PARAM_VALUE.LCD_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices gamebub.org:interface:lcd_rgb888_rtl:1.0 master {R 8 out G 8 out B 8 out DOTCLK 1 out HSYNC 1 out VSYNC 1 out DE 1 out}] ,]
 if {[get_property value ${PARAM_VALUE.LCD_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.LCD_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.C_ENABLE_OVERLAY {PARAM_VALUE.C_ENABLE_OVERLAY} {
 
}
proc validate_PARAM_VALUE.C_ENABLE_OVERLAY {PARAM_VALUE.C_ENABLE_OVERLAY} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_ENABLE_OVERLAY} 0 1]}
proc update_MODELPARAM_VALUE.C_ENABLE_OVERLAY {MODELPARAM_VALUE.C_ENABLE_OVERLAY PARAM_VALUE.C_ENABLE_OVERLAY} {set_property value [get_property value ${PARAM_VALUE.C_ENABLE_OVERLAY}] ${MODELPARAM_VALUE.C_ENABLE_OVERLAY}}
proc update_PARAM_VALUE.C_RGB_PACKING {PARAM_VALUE.C_RGB_PACKING} {
 
}
proc validate_PARAM_VALUE.C_RGB_PACKING {PARAM_VALUE.C_RGB_PACKING} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_RGB_PACKING} 0 1]}
proc update_MODELPARAM_VALUE.C_RGB_PACKING {MODELPARAM_VALUE.C_RGB_PACKING PARAM_VALUE.C_RGB_PACKING} {set_property value [get_property value ${PARAM_VALUE.C_RGB_PACKING}] ${MODELPARAM_VALUE.C_RGB_PACKING}}
proc update_PARAM_VALUE.C_TIMING_PROFILE {PARAM_VALUE.C_TIMING_PROFILE} {
 
}
proc validate_PARAM_VALUE.C_TIMING_PROFILE {PARAM_VALUE.C_TIMING_PROFILE} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_TIMING_PROFILE} 0 1]}
proc update_MODELPARAM_VALUE.C_TIMING_PROFILE {MODELPARAM_VALUE.C_TIMING_PROFILE PARAM_VALUE.C_TIMING_PROFILE} {set_property value [get_property value ${PARAM_VALUE.C_TIMING_PROFILE}] ${MODELPARAM_VALUE.C_TIMING_PROFILE}}
