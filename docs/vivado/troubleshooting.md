# Troubleshooting the IPI demo

| Symptom | Check |
| --- | --- |
| Board 2.0 is absent under Latest | Restart after installing new board folders; register at the welcome screen before creating the project. Board 1.9/1.10 and hardware Rev4 are separate concepts. |
| Custom Board interface automation reports no option | Select the core's Board tab or use `apply_board_connection`; generic AMD board-rule support is limited to selected interface types. |
| AXI FREQ_HZ validation mismatch | Check the real clock connection and AXI conversion. Audio AXI uses audio clock, ESP32 AXI uses 200 MHz service clock, memory AXI uses host clock. |
| Pixel frequency differs slightly | Feed the second wizard from 50 MHz and use actual propagated frequency metadata, not a 29.362 MHz label copied from another input solution. |
| All software is held in reset | Inspect resolved reset polarity and clock lock. Active-low unused reset inputs must not be tied low. |
| Audio registers respond but no tone | Check `stop_n` high after reset, heartbeat and duration, ESP32 DAC initialization/routing, and analog volume. Digital amplitude is not analog gain. |
| Buttons poll but interrupt never arrives | Check device enable/pending, Concat bit, INTC source/vector, processor interrupt enable and device acknowledgement. Level source must be cleared at the device. |
| Hardware is missing from BSP | Inspect SDT compatible/reg properties and YAML matching, then rebuild the platform after adding the local software repository. |
| RAM missing from linker | Use exact XSA-derived RAM registration; driver CSR discovery is not native RAM linker discovery. |
| SRAM works but SDRAM is unreachable | Check both cache windows, actual SmartConnect routes, memory grant/readiness and XSA memory range. Do not guess from the base parameter alone. |
| Memory test passes suspiciously | Ensure it writes/reads external memory, handles caches, uses independent expected data and includes an expected-failure control. Never certify margins from a counter alone. |
| Color channels swapped or image rotated | TPG sends native 480x800 portrait; default LCD packing converts AMD `{R,B,G}`. CPU overlay has a separate landscape coordinate transform. |
| LCD goes black on a source pause | Physical scanout cannot pause. Maintain FIFO supply; the sink discards a damaged frame and reacquires SOF. |
| ESP32 menu replaces or reloads the custom image | Firmware lifecycle/state, not a CPU bitmap-clear bug. Do not add overlay timeout erasure to hide the root cause. Avoid selecting a game during a JTAG demo. |

Record the exact board-file/IP/firmware versions, XSA/ELF/bitstream hashes, register values and reproduction steps before making a repair. A validation PASS does not establish routed timing or electrical margins.
