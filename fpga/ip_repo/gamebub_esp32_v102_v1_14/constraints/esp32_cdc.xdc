# Scoped to gamebub_esp32_v102; this is a 200MHz oversampling endpoint, NOT
# a source-synchronous QSPI PHY. Do not create a clock on the external SCK.
# Only first-stage synchronizer data pins; subsequent stages remain timed.
set_false_path -to [get_pins {endpoint/sck_sync_reg[0]/D endpoint/cs_sync_reg[0]/D}]
set_false_path -to [get_pins -hier -filter {NAME =~ */dq_meta_reg*/D || NAME =~ */buttons_meta_reg*/D}]
# cpu_irq is now registered in service_clk. Destination-domain synchronization
# belongs to the receiving interrupt controller, not a blanket exception here.
# Optional CPU layer can be optimized away. Pure XDC only: Vivado rejects
# procedural 'if' here and previously skipped the synchronizer exception.
set_false_path -quiet -to [get_pins -quiet -of_objects [get_cells -quiet -hier -filter {NAME =~ */cpu_enable_sync_reg?0?}] -filter {REF_PIN_NAME == D}]
