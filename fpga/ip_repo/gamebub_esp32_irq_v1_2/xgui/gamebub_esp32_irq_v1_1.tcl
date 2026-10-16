proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 set page [ipgui::add_page $IPINST -name {Configuration}]
 set p [ipgui::add_param $IPINST -parent $page -name C_SYNC_STAGES]
 set_property tooltip {IRQ input synchronizer stages; permitted range 2..4} $p
 set p [ipgui::add_param $IPINST -parent $page -name C_MANUAL_OVERRIDE]
 set_property tooltip {Allow diagnostic manual IRQ assertion; permitted range 0..1} $p
 set board [ipgui::add_page $IPINST -name {Board interfaces}]
 ipgui::add_param $IPINST -parent $board -name USE_BOARD_FLOW
 ipgui::add_param $IPINST -parent $board -name IRQ_BOARD_INTERFACE
}
proc update_PARAM_VALUE.C_SYNC_STAGES {PARAM_VALUE.C_SYNC_STAGES} {}
proc validate_PARAM_VALUE.C_SYNC_STAGES {PARAM_VALUE.C_SYNC_STAGES} {
 set v [get_property value ${PARAM_VALUE.C_SYNC_STAGES}]
 if {[string is wideinteger -strict $v] && $v >= 2 && $v <= 4} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_SYNC_STAGES {MODELPARAM_VALUE.C_SYNC_STAGES PARAM_VALUE.C_SYNC_STAGES} {
 set_property value [get_property value ${PARAM_VALUE.C_SYNC_STAGES}] ${MODELPARAM_VALUE.C_SYNC_STAGES}
}
proc update_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {}
proc validate_PARAM_VALUE.C_MANUAL_OVERRIDE {PARAM_VALUE.C_MANUAL_OVERRIDE} {
 set v [get_property value ${PARAM_VALUE.C_MANUAL_OVERRIDE}]
 if {[string is wideinteger -strict $v] && $v >= 0 && $v <= 1} {return true}
 return false
}
proc update_MODELPARAM_VALUE.C_MANUAL_OVERRIDE {MODELPARAM_VALUE.C_MANUAL_OVERRIDE PARAM_VALUE.C_MANUAL_OVERRIDE} {
 set_property value [get_property value ${PARAM_VALUE.C_MANUAL_OVERRIDE}] ${MODELPARAM_VALUE.C_MANUAL_OVERRIDE}
}
