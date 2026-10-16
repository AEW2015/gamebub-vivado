proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 set page [ipgui::add_page $IPINST -name {Video configuration}]
 foreach name {C_ENABLE_OVERLAY C_RGB_PACKING} {ipgui::add_param $IPINST -parent $page -name $name}
 set board [ipgui::add_page $IPINST -name {Board interfaces}]
 foreach name {USE_BOARD_FLOW LCD_BOARD_INTERFACE} {ipgui::add_param $IPINST -parent $board -name $name}
}
foreach name {C_ENABLE_OVERLAY C_RGB_PACKING} {
 proc update_PARAM_VALUE.$name [list PARAM_VALUE.$name] {}
 proc validate_PARAM_VALUE.$name [list PARAM_VALUE.$name] [string map [list @NAME@ $name] {
  set v [get_property value ${PARAM_VALUE.@NAME@}]
  if {[string is integer -strict $v] && $v in {0 1}} {return true}
  return false
 }]
 proc update_MODELPARAM_VALUE.$name [list MODELPARAM_VALUE.$name PARAM_VALUE.$name] [string map [list @NAME@ $name] {
  set_property value [get_property value ${PARAM_VALUE.@NAME@}] ${MODELPARAM_VALUE.@NAME@}
 }]
}
