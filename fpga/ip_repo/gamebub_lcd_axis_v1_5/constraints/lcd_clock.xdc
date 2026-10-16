# Scoped to gamebub_lcd_axis. No board pin names or output-delay assumptions.
# No explicit clock name: Vivado derives an instance-unique clock name.
create_generated_clock -source [get_pins dotclock/C] -divide_by 1 [get_pins dotclock/Q]
