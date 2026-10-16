# Create a GameBub Vivado project

## Requirements

Use Vivado/Vitis 2025.2 with Artix-7 support, part `xc7a100tcsg324-1`, and the checked-out GameBub repository. Install into a path without spaces: Vivado 2025.2 child runs can mishandle board repository paths containing whitespace. No FuseSoC is used in this flow.

## Manual GUI workflow

At the Vivado welcome screen, register the board repository. Replace `/path/to/gamebub-vivado` with your own checkout using forward slashes:

```tcl
source /path/to/gamebub-vivado/fpga/board_files/install_gamebub_current_repositories.tcl
```

Create a new RTL project. On Boards, search **GameBub**, keep Board Rev **Latest**, and choose **GameBub Rev4**, file version **2.0**. If an older version is cached, save existing work and restart Vivado once, then register the repository before opening the project wizard. Do not relabel the hardware as Rev2.

After creating the project, source the same helper again to register the current IP catalog. Add a block design, MicroBlaze V and ordinary AMD Clocking Wizard/Processor System Reset IP. Use the [clock/reset table](clocks-resets.md); then add the peripherals one at a time, validating after each addition.

Custom physical interfaces bind through the core's Board tab and Make External, or explicit board connection:

```tcl
apply_board_connection -board_interface mcu_qspi \
  -ip_intf gamebub_esp32_v102_0/QSPI -diagram [current_bd_design]
apply_board_connection -board_interface buttons_12bits \
  -ip_intf gamebub_esp32_v102_0/BUTTONS -diagram [current_bd_design]
apply_board_connection -board_interface mcu_irq_gate \
  -ip_intf gamebub_esp32_v102_0/IRQ_GATE -diagram [current_bd_design]
```

Use the same operation for `sram`→`SRAM`, `sdram`→`SDRAM`, `dac_dsp`→`AUDIO` and `lcd_rgb888`→`LCD`. Instance names above are examples. Native AMD board automation does not support every custom interface VLNV; a generic automation-rule rejection does not mean the physical interface cannot be connected.

Connect AXI interfaces through SmartConnect with all participating clocks, or explicit AXI clock converters. Assign nonoverlapping addresses. The [reference inventory](amd-ip.md) is one map, not an address requirement in reusable drivers. GPIO vibration has two output bits; configure its reset output to zero.

## Reproducible reference

Run the following from a shell with Vivado available; use a new output directory:

```powershell
vivado -mode batch -source fpga/vivado/gamebub_ipi_demo/create_design.tcl -tclargs D:/builds/gamebub-sdk-001
```

This recreates the source diagram, explicitly ties unused SDRAM hold low, validates cache/audio/reset contracts, generates IP output products and exports an XSA **without a bitstream**. It does not program the board, route the design or establish timing closure.

For your own design, validate and export for review:

```tcl
validate_bd_design
save_bd_design
write_bd_tcl -force review_bd.tcl
```

Before hardware, generate a wrapper and build your own timing-clean bitstream. Board-interface XDC supplies pin assignments; also audit configuration voltage, external timing and the applicable packaged/project CDC constraints. Do not solve warnings by marking unrelated clocks false-path without examining the actual crossing.
