proc init_gui {IPINST} {
 ipgui::add_param $IPINST -name Component_Name
 set page [ipgui::add_page $IPINST -name {Memory (100 MHz, unified control)}]
 set size [ipgui::add_param $IPINST -parent $page -name C_MEMORY_BYTES]
 set_property enabled false $size
 ipgui::add_param $IPINST -parent $page -name C_ADVANCED_SETTINGS
 foreach name {C_BASE_ADDR C_POWER_BEATS C_TIMEOUT_CYCLES C_METER_WINDOW} {ipgui::add_param $IPINST -parent $page -name $name}
 set board [ipgui::add_page $IPINST -name {Board interfaces}]
 ipgui::add_param $IPINST -parent $board -name USE_BOARD_FLOW
 ipgui::add_param $IPINST -parent $board -name SDRAM_BOARD_INTERFACE
}
proc validate_PARAM_VALUE.C_ADVANCED_SETTINGS {PARAM_VALUE.C_ADVANCED_SETTINGS} {return true}
foreach {name min max} {C_BASE_ADDR 0 4227858432 C_POWER_BEATS 15625 1048576 C_TIMEOUT_CYCLES 1024 16777216 C_METER_WINDOW 50000 200000 C_DEFAULT_TEST_WORDS 1 262144} {
 proc update_PARAM_VALUE.$name [list PARAM_VALUE.$name PARAM_VALUE.C_ADVANCED_SETTINGS] [string map [list @NAME@ $name] {
  set enabled [get_property value ${PARAM_VALUE.C_ADVANCED_SETTINGS}]
  set_property visible [expr {$enabled in {1 true}}] ${PARAM_VALUE.@NAME@}
 }]
 proc validate_PARAM_VALUE.$name [list PARAM_VALUE.$name] [string map [list @NAME@ $name @MIN@ $min @MAX@ $max] {
  set value [get_property value ${PARAM_VALUE.@NAME@}]
  if {![string is wideinteger -strict $value] || $value<@MIN@ || $value>@MAX@} {return false}
  if {"@NAME@" eq "C_BASE_ADDR" && $value%67108864!=0} {return false}
  if {"@NAME@" eq "C_METER_WINDOW" && $value ni {50000 100000 200000}} {return false}
  return true
 }]
 proc update_MODELPARAM_VALUE.$name [list MODELPARAM_VALUE.$name PARAM_VALUE.$name] [string map [list @NAME@ $name] {
  set_property value [get_property value ${PARAM_VALUE.@NAME@}] ${MODELPARAM_VALUE.@NAME@}
 }]
}
