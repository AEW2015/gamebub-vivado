# Check the reference's essential resolved contracts after native propagation.
validate_bd_design
foreach p {C_ICACHE_BASEADDR C_DCACHE_BASEADDR} {
 if {[get_property CONFIG.$p [get_bd_cells microblaze_riscv_0]] != 0x70000000} {error "Wrong cache base $p"}
}
foreach p {C_ICACHE_HIGHADDR C_DCACHE_HIGHADDR} {
 if {[get_property CONFIG.$p [get_bd_cells microblaze_riscv_0]] != 0x7fffffff} {error "Wrong cache high $p"}
}
set audio_net [get_bd_nets -of_objects [get_bd_pins gamebub_dac_audio_0/stop_n]]
if {$audio_net ne [get_bd_nets -of_objects [get_bd_pins rst_clk_wiz_0_29M/peripheral_aresetn]]} {error {Audio held stopped}}
if {[get_property CONFIG.PRIM_IN_FREQ [get_bd_cells clk_wiz_0]]!=50} {error {Pixel wizard reference must be 50 MHz}}
foreach name {100M 200M} {
 if {[get_property CONFIG.C_EXT_RESET_HIGH [get_bd_cells rst_clk_wiz_1_$name]]!=0} {error {Unexpected ext reset polarity}}
}
if {([get_property CONFIG.C_KIND_OF_INTR [get_bd_cells microblaze_riscv_0_axi_intc]] & 1)!=0} {error {ESP32 interrupt must be level}}
puts GAMEBUB_DOCUMENTED_REFERENCE_CONTRACT_PASS
