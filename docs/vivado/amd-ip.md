# AMD IP reference

This page inventories the AMD IP used by the GameBub Rev4 Vivado 2025.2 reference export. Versions and instance names come from the reviewed `review_bd.tcl` export (SHA-256 `89c22d93b446ea93eed8cffd29e13cc7a7b3ed5899ebbb5b94a2baa01445d80a`). AMD guide IDs were checked against the installed 2025.2 `component.xml` files. Follow the vendor guide for product behavior; this page records GameBub-specific integration and software ownership only.

| IP (VLNV) | Instances | Count | Guide | Software driver |
| --- | --- | ---: | --- | --- |
| MicroBlaze V (`xilinx.com:ip:microblaze_riscv:1.0`) | `microblaze_riscv_0` | 1 | [UG1629](https://docs.amd.com/r/2025.2-English/ug1629-microblaze-v-user-guide) | Yes. Use the standalone BSP, including its cache and exception APIs. The processor runs at 100 MHz with 4 KiB instruction and data caches; both cache address windows are `0x70000000..0x7FFFFFFF`. |
| SmartConnect (`xilinx.com:ip:smartconnect:1.0`) | `microblaze_riscv_0_axi_periph`, `axi_smc` | 2 | [PG247](https://docs.amd.com/r/en-US/pg247-smartconnect) | No application driver. Document and verify memory arbitration, peripheral clock domains, address routes, transaction splitting and reset behavior. |
| AXI Interrupt Controller (`xilinx.com:ip:axi_intc:4.1`) | `microblaze_riscv_0_axi_intc` | 1 | [PG099](https://docs.amd.com/r/en-US/pg099-axi-intc) | Yes. Use AMD `XIntc`; document generated interrupt IDs and level-high pending/acknowledgement order. |
| Inline Concat (`xilinx.com:inline_hdl:ilconcat:1.0`) | `microblaze_riscv_0_xlconcat` | 1 | Not applicable (inline HDL metadata) | No driver. The single input is the ESP32 CPU IRQ; Concat does not synchronize it. |
| MDM RISC-V (`xilinx.com:ip:mdm_riscv:1.0`) | `mdm_1` | 1 | [PG428](https://docs.amd.com/r/en-US/pg428-mdm-v) | Yes, use the existing `uartlite` binding and standalone console stack. The MDM provides debug/JTAG UART; do not create a separate UART driver. |
| Clocking Wizard (`xilinx.com:ip:clk_wiz:6.0`) | `clk_wiz_1`, `clk_wiz_0` | 2 | [PG065](https://docs.amd.com/r/en-US/pg065-clk-wiz) | No runtime driver in this design. Both wizards have `USE_RESET=false`; document their fixed connections, lock/reset use and generated frequencies. |
| Processor System Reset (`xilinx.com:ip:proc_sys_reset:5.0`) | `rst_clk_wiz_1_100M`, `rst_clk_wiz_1_200M`, `rst_clk_wiz_0_29M` | 3 | [PG164](https://docs.amd.com/r/en-US/pg164-proc-sys-reset) | No application driver. These provide domain-specific synchronized resets. |
| AXI GPIO (`xilinx.com:ip:axi_gpio:2.0`) | `axi_gpio_0` | 1 | [PG144](https://docs.amd.com/r/en-US/pg144-axi-gpio) | Yes. Use AMD `XGpio` for the two vibration outputs; examples must apply bounded pulses and turn outputs off on exit. |
| Video Test Pattern Generator (`xilinx.com:ip:v_tpg:8.2`) | `v_tpg_0` | 1 | [PG103](https://docs.amd.com/r/en-US/pg103-v-tpg) | Yes. Use AMD `XV_tpg` and `video_common`; configure for the native 480x800 video path. |
| AXI4-Stream Data FIFO (`xilinx.com:ip:axis_data_fifo:2.0`) | `axis_data_fifo_0` | 1 | [PG085](https://docs.amd.com/r/en-US/pg085-axi4stream-infrastructure) | No software driver. It is stream infrastructure (asynchronous, depth 4096 in this export); cover backpressure, clocking and reset in video tests. |
| LMB (`xilinx.com:ip:lmb_v10:3.0`) | `dlmb_v10`, `ilmb_v10` | 2 | [PG113](https://docs.amd.com/r/en-US/pg113-lmb-v10) | No peripheral driver. These form the processor's local data and instruction bus topology. |
| LMB BRAM Interface Controller (`xilinx.com:ip:lmb_bram_if_cntlr:4.0`) | `dlmb_bram_if_cntlr`, `ilmb_bram_if_cntlr` | 2 | [PG112](https://docs.amd.com/r/en-US/pg112-lmb-bram-if-cntlr) | No separate peripheral driver. Use applicable AMD BRAM support for memory operations; ECC is disabled in both instances. Do not destructively test boot memory. |
| Block Memory Generator (`xilinx.com:ip:blk_mem_gen:8.4`) | `lmb_bram` | 1 | [PG058](https://docs.amd.com/r/en-US/pg058-blk-mem-gen) | No peripheral driver; normal processor memory access uses its LMB controllers. The export maps 16 KiB local BRAM. |
| GameBub ESP32 (`gamebub.org:ip:gamebub_esp32_v102:1.14`) | `gamebub_esp32_v102_0` | 1 | GameBub IP; AMD guide not applicable | Yes. Implement the GameBub `GBEsp32` driver for its custom register interface. |
| GameBub SRAM (`gamebub.org:ip:gamebub_sram_mem:1.6`) | `gamebub_sram_mem_0` | 1 | GameBub IP; AMD guide not applicable | Yes. Implement `GBSram` for control registers; RAM itself is memory access, not a word-at-a-time peripheral API. |
| GameBub SDRAM (`gamebub.org:ip:gamebub_sdram_mem:1.6`) | `gamebub_sdram_mem_0` | 1 | GameBub IP; AMD guide not applicable | Yes. Implement `GBSdram` for control/reconfiguration registers; RAM itself is memory access. |
| GameBub DAC Audio (`gamebub.org:ip:gamebub_dac_audio:1.3`) | `gamebub_dac_audio_0` | 1 | GameBub IP; AMD guide not applicable | Yes. Implement `GBAudio` for the custom audio control interface. |
| GameBub LCD AXIS (`gamebub.org:ip:gamebub_lcd_axis:1.5`) | `gamebub_lcd_axis_0` | 1 | GameBub IP; AMD guide not applicable | No fabricated register driver. Document the AXI-Stream video/panel integration and provide software helpers only where needed. |

The inventory contains 24 instantiated cells across 18 distinct VLNVs. Clocks, resets, SmartConnect, Concat, LMB and AXI-Stream transport are hardware infrastructure; they do not need application drivers. AMD peripheral drivers are reused where the design exposes a corresponding software programming model. Custom GameBub register interfaces get GameBub drivers, not AMD driver attribution.

## Export-specific clock and memory facts

- The input is 50 MHz. `clk_wiz_1` produces 100 MHz for the processor and AXI host domain, 200 MHz for ESP32 service and the SDRAM reference clock, and 50 MHz as the input to the pixel wizard.
- `clk_wiz_0` requests 29.362 MHz using a 50 MHz input, feedback multiplier 56.375, input divider 3 and output divider 32. The corresponding calculated output is about 29,361,979 Hz; the export's request is rounded to 29.362 MHz.
- `axi_gpio_0` is at `0x40000000` (64 KiB). Other control windows are `mdm_1` `0x44A00000`, ESP32 `0x44A10000`, SRAM control `0x44A20000`, SDRAM control `0x44A30000`, audio `0x44A40000`, and TPG `0x44A50000` (each 64 KiB).
- SRAM is `0x76000000..0x7607FFFF` (512 KiB); SDRAM is `0x78000000..0x79FFFFFF` (32 MiB). Both instruction and data cache windows cover `0x70000000..0x7FFFFFFF`, while each cache is 4 KiB. Peripheral registers are outside that cached range.
- Audio `stop_n` is connected to the pixel-domain reset net `rst_clk_wiz_0_29M/peripheral_aresetn`, alongside audio `audio_resetn`. Treat this as a reset-derived stop signal; do not infer a separate audio-stop control.

See [`inventory.json`](../../fpga/vivado/gamebub_ipi_demo/inventory.json) for the per-instance machine-readable inventory and source hash. This page links to vendor guides instead of copying them.
