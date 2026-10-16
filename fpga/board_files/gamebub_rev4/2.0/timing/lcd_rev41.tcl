# Board-owned ILI9806E RGB interface budget from the tested b_009 integration.
# Explicit opt-in: names follow the user's BD external interface, not fixed
# top_i hierarchy. The LCD IP1.2 supplies the generated forwarded clock.
# Panel samples falling DOTCLK; outputs are launched on rising pixel clock.
# max4ns/min-1ns retain existing bring-up assumptions, NOT new panel AC proof.
namespace eval gamebub_rev41 {
 proc constrain_lcd {clock_port data_ports} {
  set clkport [get_ports $clock_port]
  set data [get_ports $data_ports]
  if {[llength $clkport]!=1 || [llength $data]!=27} {
   error "LCD timing requires one DOTCLK and exactly27 RGB/sync/DE ports"
  }
  set clocks [get_clocks -of_objects $clkport]
  if {[llength $clocks]!=1} {
   error "Expected one forwarded clock from LCD IP1.2; remove old project clock definitions"
  }
  set_output_delay -clock $clocks -clock_fall -max 4 $data
  set_output_delay -clock $clocks -clock_fall -min -1 $data
 }
}
