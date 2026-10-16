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
 add_board_tab $IPINST -display_name {AUDIO_BOARD_INTERFACE {DAC audio}}
 set page [ipgui::add_page $IPINST -name {IP Configuration} -layout vertical]
 ::gamebub_gui::note $IPINST $page overview {Signed 16-bit stereo DAC DSP-format test-tone generator, not standard I2S.
S_AXI and audio_clk share the same domain; use AXI Clock Converter from a 100 MHz CPU.}
 set group [ipgui::add_group $IPINST -parent $page -name {Power-on tone defaults} -layout vertical]
 ::gamebub_gui::note $IPINST $group note_0 {Keep stop_n high to permit playback. Reset starts stopped; software must start and service the heartbeat.
ESP32 retains DAC setup and volume control.}
 set p [::gamebub_gui::parameter $IPINST $group C_DEFAULT_FREQUENCY {Tone frequency (Hz)} {20..12000 Hz. Initial setting only; playback still requires an explicit start command.} {}]
 set p [::gamebub_gui::parameter $IPINST $group C_DEFAULT_LEVEL {Digital amplitude (%)} {0..100 percent linear PCM amplitude, not analog DAC volume. ESP32 retains DAC setup and volume control.} {}]
 set p [::gamebub_gui::parameter $IPINST $group C_DEFAULT_LIMIT_MS {Playback limit (ms)} {100..30000 ms. Keep bounded playback and heartbeat servicing; reset/stop defaults remain unchanged.} {}]
}
proc update_PARAM_VALUE.AUDIO_BOARD_INTERFACE {IPINST PARAM_VALUE.AUDIO_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set_property range [::gamebub_gui::board_choices gamebub.org:interface:dac_dsp_rtl:1.0 master {MCLK 1 out WCLK 1 out BCLK 1 out DIN 1 out}] ${PARAM_VALUE.AUDIO_BOARD_INTERFACE}
}
proc validate_PARAM_VALUE.AUDIO_BOARD_INTERFACE {PARAM_VALUE.AUDIO_BOARD_INTERFACE PROJECT_PARAM.BOARD} {
 set choices [split [::gamebub_gui::board_choices gamebub.org:interface:dac_dsp_rtl:1.0 master {MCLK 1 out WCLK 1 out BCLK 1 out DIN 1 out}] ,]
 if {[get_property value ${PARAM_VALUE.AUDIO_BOARD_INTERFACE}] ni $choices} {
  set_property errmsg {Choose Custom or a compatible interface on the selected board.} ${PARAM_VALUE.AUDIO_BOARD_INTERFACE}
  return false
 }
 return true
}
proc update_PARAM_VALUE.C_DEFAULT_FREQUENCY {PARAM_VALUE.C_DEFAULT_FREQUENCY} {
 
}
proc validate_PARAM_VALUE.C_DEFAULT_FREQUENCY {PARAM_VALUE.C_DEFAULT_FREQUENCY} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_DEFAULT_FREQUENCY} 20 12000 1]}
proc update_MODELPARAM_VALUE.C_DEFAULT_FREQUENCY {MODELPARAM_VALUE.C_DEFAULT_FREQUENCY PARAM_VALUE.C_DEFAULT_FREQUENCY} {set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_FREQUENCY}] ${MODELPARAM_VALUE.C_DEFAULT_FREQUENCY}}
proc update_PARAM_VALUE.C_DEFAULT_LEVEL {PARAM_VALUE.C_DEFAULT_LEVEL} {
 
}
proc validate_PARAM_VALUE.C_DEFAULT_LEVEL {PARAM_VALUE.C_DEFAULT_LEVEL} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_DEFAULT_LEVEL} 0 100 1]}
proc update_MODELPARAM_VALUE.C_DEFAULT_LEVEL {MODELPARAM_VALUE.C_DEFAULT_LEVEL PARAM_VALUE.C_DEFAULT_LEVEL} {set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_LEVEL}] ${MODELPARAM_VALUE.C_DEFAULT_LEVEL}}
proc update_PARAM_VALUE.C_DEFAULT_LIMIT_MS {PARAM_VALUE.C_DEFAULT_LIMIT_MS} {
 
}
proc validate_PARAM_VALUE.C_DEFAULT_LIMIT_MS {PARAM_VALUE.C_DEFAULT_LIMIT_MS} {return [::gamebub_gui::integer_ok ${PARAM_VALUE.C_DEFAULT_LIMIT_MS} 100 30000 1]}
proc update_MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS {MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS PARAM_VALUE.C_DEFAULT_LIMIT_MS} {set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_LIMIT_MS}] ${MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS}}
