# Scoped to gamebub_video_status. Bounds preserve Gray-bus coherency. Do not
# combine with set_clock_groups or false paths across the Gray bus.
set_max_delay -datapath_only 16 -from [get_cells -hier -filter {NAME =~ */gray_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */gray_meta_reg* && REF_NAME =~ FD*}]
set_bus_skew 8 -from [get_cells -hier -filter {NAME =~ */gray_reg* && REF_NAME =~ FD*}] -to [get_cells -hier -filter {NAME =~ */gray_meta_reg* && REF_NAME =~ FD*}]
set_false_path -to [get_pins -hier -filter {NAME =~ */flag_meta_reg*/D}]
