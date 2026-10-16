# SPDX-License-Identifier: CERN-OHL-S-2.0
# Scoped to gamebub_sdram_mem; loaded LATE in implementation only.
# Four-phase bundled-data mailbox: source payload remains frozen until RTZ.
# Established request/response flight-time budgets are 16/20 ns, NOT false
# paths. Handshake traverses three destination synchronizer stages before
# capture. Keep every intra-domain and command/serializer/read PHY path timed.
set_max_delay -datapath_only 16.000 -from [get_cells -hier -filter {NAME =~ */memory/link/held_request_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */memory/link/mem_data_reg* && REF_NAME =~ FD*}]
set_max_delay -datapath_only 20.000 -from [get_cells -hier -filter {NAME =~ */memory/link/held_response_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */memory/link/response_data_reg* && REF_NAME =~ FD*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ */memory/link/held_request_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */memory/link/mem_data_reg* && REF_NAME =~ FD*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ */memory/link/held_response_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */memory/link/response_data_reg* && REF_NAME =~ FD*}]
# Only first-stage data pins. Optional PARK observer may be optimized out.
set_false_path -quiet -to [get_pins -hier -quiet -regexp {.*memory/link/(req_sync_reg\[0\]|ack_sync_reg\[0\])/D}]
set_false_path -quiet -to [get_pins -hier -quiet -regexp {.*memory/park_sync_reg\[0\]/D}]
set_false_path -quiet -to [get_pins -hier -quiet -regexp {.*memory/stack/controller/fault_meta_reg/D}]
set_false_path -quiet -to [get_pins -hier -quiet -regexp {.*clocks/sequencer/lock_sync_reg\[0\]/D}]
set_false_path -quiet -to [get_pins -hier -quiet -regexp {.*memory/reset_pipe_reg\[0\]/D}]
# Asynchronous assertion into dedicated reset-release synchronizer pipes only.
# Do NOT blanket-cut all asynchronous reset pins in the memory controller.
set_false_path -to [get_pins -of_objects [get_cells -hier -filter {NAME =~ */memory/link/mem_reset_pipe_reg* || NAME =~ */memory/reset_pipe_reg* || NAME =~ */clocks/cmd_meter/reset_pipe_reg* || NAME =~ */clocks/read_meter/reset_pipe_reg*}] -filter {REF_PIN_NAME == PRE || REF_PIN_NAME == CLR}]
# Gray rate meters: source CLKDIV is at most 62.5 MHz (16 ns) at the 250-MHz
# profile. Preserve the established one-source-period delay / half-period skew.
set_max_delay -datapath_only 16.000 -from [get_cells -hier -filter {NAME =~ */clocks/cmd_meter/gray_count_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */clocks/cmd_meter/gray_meta_reg* && REF_NAME =~ FD*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ */clocks/cmd_meter/gray_count_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */clocks/cmd_meter/gray_meta_reg* && REF_NAME =~ FD*}]
set_max_delay -datapath_only 16.000 -from [get_cells -hier -filter {NAME =~ */clocks/read_meter/gray_count_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */clocks/read_meter/gray_meta_reg* && REF_NAME =~ FD*}]
set_bus_skew 8.000 -from [get_cells -hier -filter {NAME =~ */clocks/read_meter/gray_count_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */clocks/read_meter/gray_meta_reg* && REF_NAME =~ FD*}]
# Preserve the existing SERDES PHY margins from the endpoint-checked design.
set_clock_uncertainty -hold 0.250 -from [get_clocks -of_objects [get_pins -of_objects [get_cells -hier -filter {REF_NAME == MMCME2_ADV}] -filter {REF_PIN_NAME == CLKOUT1}]] -to [get_clocks -of_objects [get_pins -of_objects [get_cells -hier -filter {REF_NAME == MMCME2_ADV}] -filter {REF_PIN_NAME == CLKOUT0}]]
set_clock_uncertainty -setup 1.350 -from [get_clocks -of_objects [get_pins -of_objects [get_cells -hier -filter {REF_NAME == MMCME2_ADV}] -filter {REF_PIN_NAME == CLKOUT1}]] -to [get_clocks -of_objects [get_pins -of_objects [get_cells -hier -filter {REF_NAME == MMCME2_ADV}] -filter {REF_PIN_NAME == CLKOUT3}]]
