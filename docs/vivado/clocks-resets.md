# Clocks resets and interrupts

## Clock domains

| Domain | Reference source | Consumers |
| --- | --- | --- |
| 50 MHz oscillator | Board `clk_50mhz` | System Clocking Wizard input |
| 100 MHz | System PLL output 1 | MicroBlaze V, LMB, main AXI, INTC, MDM, vibration GPIO, memory host interfaces, TPG, FIFO write side |
| 200 MHz | System PLL output 2 | ESP32 `service_clk`/S_AXI, SDRAM `refclk200` |
| 50 MHz buffered reference | System PLL output 3 | Pixel MMCM input, configured No buffer |
| 29,361,979 Hz metadata | Pixel MMCM, request 29.362 MHz from 50 MHz | LCD, ESP32 overlay, audio including its AXI port, FIFO read side |

System wizard: primitive PLL, single-ended clock-capable 50 MHz input, outputs 100/200/50 MHz, zero phase, reset disabled and locked enabled. Pixel wizard: primitive MMCM, 50 MHz No buffer input, request 29.362 MHz, zero phase, reset disabled and locked enabled. Do not change its input to 100 MHz while keeping the same expected actual frequency.

The SDRAM controller also contains a runtime-reconfigurable memory clock generator. SRAM contains its PHY clock generator. Their memory/serializer clocks are not CPU clocks; keeping the CPU alive while retiming memory is essential for recovery. Do not connect a changing SDRAM clock to the IDELAY calibration reference.

## Reset wiring

Use one Processor System Reset for each consuming clock domain. Connect `slowest_sync_clk` to that clock, `dcm_locked` to its Clocking Wizard locked output, `peripheral_aresetn` to active-low peripheral resets and `mb_reset` to the processor's active-high Reset.

The reference propagates `C_EXT_RESET_HIGH=0` and `C_AUX_RESET_HIGH=0`. Connecting `locked` to `ext_reset_in` therefore asserts reset until lock. Unused auxiliary reset defaults high in the installed AMD IP. Never assume every reset pin is active-high or tie an active-low unused reset to zero. Read resolved properties after validation:

```tcl
get_property CONFIG.C_EXT_RESET_HIGH [get_bd_cells rst_clk_wiz_1_100M]
get_property CONFIG.C_AUX_RESET_HIGH [get_bd_cells rst_clk_wiz_1_100M]
```

MDM debug reset feeds the processor-domain reset controller. Audio `stop_n` is active-low: tying it to pixel-domain `peripheral_aresetn` allows playback only after reset release. Unused SDRAM `reconfig_hold` is active-high and must be low for normal operation.

## Processor interrupt

ESP32 `cpu_irq` is a registered **level-high pending interrupt**, not the physical ESP32 IRQ gate. The reference connects it through Concat input 0 to AXI INTC and resolves input 0 to level-high. INTC status alone cannot identify which buttons are down: read the ESP32 button state, process it, then acknowledge the ESP32 pending latch and controller in the documented order. A simultaneous new event wins over the device acknowledgement in RTL.

Concat only assembles a vector; it does not synchronize the 200-to-100 MHz path. These PLL outputs are related clocks, so this can be a timed crossing, but it still needs routed timing review. Alternatively use the INTC's supported asynchronous input option or a verified level synchronizer, and update the reference accordingly. Do not add an asynchronous false path while leaving the signal unsynchronized.

ESP32 QSPI/IRQ servicing remains hardware-driven if the processor is halted. `cpu_irq` masking must not disable the physical service. AXI interconnect and peripherals must use compatible reset/clock crossings; adding a clock label does not implement a converter.
