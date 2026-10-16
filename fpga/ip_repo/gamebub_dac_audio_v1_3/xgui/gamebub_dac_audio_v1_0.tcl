proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 set page [ipgui::add_page $IPINST -name {Configuration}]
 set p [ipgui::add_param $IPINST -parent $page -name C_DEFAULT_FREQUENCY]
 set_property tooltip {Initial tone frequency (Hz); permitted range 20..12000} $p
 set p [ipgui::add_param $IPINST -parent $page -name C_DEFAULT_LEVEL]
 set_property tooltip {Initial digital level (percent); permitted range 0..100} $p
 set p [ipgui::add_param $IPINST -parent $page -name C_DEFAULT_LIMIT_MS]
 set_property tooltip {Initial playback session limit (ms); permitted range 100..30000} $p
 set board [ipgui::add_page $IPINST -name {Board interfaces}]
 ipgui::add_param $IPINST -parent $board -name USE_BOARD_FLOW
 ipgui::add_param $IPINST -parent $board -name AUDIO_BOARD_INTERFACE
}
proc update_PARAM_VALUE.C_DEFAULT_FREQUENCY {PARAM_VALUE.C_DEFAULT_FREQUENCY} {}
proc validate_PARAM_VALUE.C_DEFAULT_FREQUENCY {PARAM_VALUE.C_DEFAULT_FREQUENCY} {
 set v [get_property value ${PARAM_VALUE.C_DEFAULT_FREQUENCY}]
 if {[string is wideinteger -strict $v] && $v >= 20 && $v <= 12000} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_DEFAULT_FREQUENCY {MODELPARAM_VALUE.C_DEFAULT_FREQUENCY PARAM_VALUE.C_DEFAULT_FREQUENCY} {
 set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_FREQUENCY}] ${MODELPARAM_VALUE.C_DEFAULT_FREQUENCY}
}
proc update_PARAM_VALUE.C_DEFAULT_LEVEL {PARAM_VALUE.C_DEFAULT_LEVEL} {}
proc validate_PARAM_VALUE.C_DEFAULT_LEVEL {PARAM_VALUE.C_DEFAULT_LEVEL} {
 set v [get_property value ${PARAM_VALUE.C_DEFAULT_LEVEL}]
 if {[string is wideinteger -strict $v] && $v >= 0 && $v <= 100} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_DEFAULT_LEVEL {MODELPARAM_VALUE.C_DEFAULT_LEVEL PARAM_VALUE.C_DEFAULT_LEVEL} {
 set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_LEVEL}] ${MODELPARAM_VALUE.C_DEFAULT_LEVEL}
}
proc update_PARAM_VALUE.C_DEFAULT_LIMIT_MS {PARAM_VALUE.C_DEFAULT_LIMIT_MS} {}
proc validate_PARAM_VALUE.C_DEFAULT_LIMIT_MS {PARAM_VALUE.C_DEFAULT_LIMIT_MS} {
 set v [get_property value ${PARAM_VALUE.C_DEFAULT_LIMIT_MS}]
 if {[string is wideinteger -strict $v] && $v >= 100 && $v <= 30000} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS {MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS PARAM_VALUE.C_DEFAULT_LIMIT_MS} {
 set_property value [get_property value ${PARAM_VALUE.C_DEFAULT_LIMIT_MS}] ${MODELPARAM_VALUE.C_DEFAULT_LIMIT_MS}
}
