proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 set page [ipgui::add_page $IPINST -name {Configuration}]
 set p [ipgui::add_param $IPINST -parent $page -name C_ENABLE_SNIFFER]
 set_property tooltip {Include passive transaction capture; permitted range 0..1} $p
 set board [ipgui::add_page $IPINST -name {Board interfaces}]
 ipgui::add_param $IPINST -parent $board -name USE_BOARD_FLOW
 ipgui::add_param $IPINST -parent $board -name QSPI_BOARD_INTERFACE
 ipgui::add_param $IPINST -parent $board -name BUTTONS_BOARD_INTERFACE
}
proc update_PARAM_VALUE.C_ENABLE_SNIFFER {PARAM_VALUE.C_ENABLE_SNIFFER} {}
proc validate_PARAM_VALUE.C_ENABLE_SNIFFER {PARAM_VALUE.C_ENABLE_SNIFFER} {
 set v [get_property value ${PARAM_VALUE.C_ENABLE_SNIFFER}]
 if {[string is wideinteger -strict $v] && $v >= 0 && $v <= 1} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_ENABLE_SNIFFER {MODELPARAM_VALUE.C_ENABLE_SNIFFER PARAM_VALUE.C_ENABLE_SNIFFER} {
 set_property value [get_property value ${PARAM_VALUE.C_ENABLE_SNIFFER}] ${MODELPARAM_VALUE.C_ENABLE_SNIFFER}
}
