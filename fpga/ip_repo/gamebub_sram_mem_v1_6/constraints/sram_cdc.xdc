# Scoped to gamebub_sram_mem. Never cut payload or related 100/400MHz clocks.
# Only the first heartbeat synchronizer D and dedicated reset synchronizer CLR.
set_false_path -to [get_pins {memory/memory/clocks/control/heart_sync_reg[0]/D}]
set_false_path -from [get_cells memory/memory/clocks/heart_local_reset_reg] -to [get_pins {memory/memory/clocks/heart_reset_sync_reg[0]/CLR memory/memory/clocks/heart_reset_sync_reg[1]/CLR memory/memory/clocks/heart_reset_sync_reg[2]/CLR}]
