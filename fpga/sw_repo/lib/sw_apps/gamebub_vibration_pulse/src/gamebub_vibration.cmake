# SPDX-License-Identifier: CERN-OHL-S-2.0
# Validate the selected motor GPIO before generating an actuator application.
# License details: LICENSE.md at repository root.
# Required metadata is reg, GPIO width, all-outputs, in that order. A general
# GPIO/button block at another address is not a safe motor-control substitute.
list(LENGTH GPIO0_PROP_LIST gpio_properties)
if(NOT gpio_properties EQUAL 3)
  message(FATAL_ERROR "Vibration requires GPIO reg, width and all-outputs metadata")
endif()
list(GET GPIO0_PROP_LIST 1 gpio_width)
list(GET GPIO0_PROP_LIST 2 gpio_outputs)
if(NOT gpio_width EQUAL 2 OR NOT gpio_outputs EQUAL 1)
  message(FATAL_ERROR "Vibration requires the reference two-bit, all-output AXI GPIO; do not select a button/input GPIO")
endif()
