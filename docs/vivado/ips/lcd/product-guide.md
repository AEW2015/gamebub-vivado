# LCD display product guide

## IP facts

Version 1.5 is the packaged GUI revision of the v1.4 LCD datapath for Vivado 2025.2, XC7A100T and GameBub Rev4. The current physical-interface binding is `lcd_rgb888`. The core has no internal clock generator, framebuffer, processor dependency or software register bank. License follows the repository FPGA source policy. It is not AMD IP.

## Interfaces and architecture

| Port or interface | Direction and width | Contract |
| --- | --- | --- |
| `pixel_clk` | Clock input | Standard reference actual metadata 29,361,979 Hz |
| `pixel_resetn` | Active-low input | Synchronous state reset in pixel domain |
| `S_AXIS_VIDEO` | Slave, 24-bit TDATA | One RGB888 pixel per beat; TUSER=SOF, TLAST=EOL |
| `S_AXIS_OVERLAY` | Optional slave, 32-bit TDATA | Bit31 opaque, lower24 color; same frame/line geometry and clock |
| `LCD` | Physical outputs | Clock, HSYNC, VSYNC, DE and 8-bit R/G/B |
| `vblank` | One-bit output | Wired to raster VSYNC, not a software-accessible CSR |
| `stream_locked` | One-bit output | Raster stream alignment status |
| `underflow`, `framing_error` | One-bit outputs | Sticky diagnostics cleared by reset |
| `overlay_visible` | One-bit output | Current/previous-frame opaque activity; not a per-pixel alpha output |

With overlay enabled, a ready/valid compositor aligns both inputs, gives opaque overlay pixels priority, and holds output data under backpressure. Both streams must supply complete native frames, including transparent overlay pixels. A sparse stream of only menu pixels is not valid. Disable the overlay parameter when no overlay source is present; an enabled but disconnected input can prevent video progress.

The raster runs at a fixed physical rate. If an active pixel is missing, the remainder of that damaged frame is blacked and input is drained/reacquired at the next SOF; it does not silently shift subsequent pixels. Early SOF is held for the next physical frame start. TLAST must agree with pixel479. This is why a FIFO and sustained upstream service are necessary.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| `C_ENABLE_OVERLAY` | 0 | Enable overlay compositor/input |
| `C_RGB_PACKING` | 0 | 0: AMD `{R,B,G}` source packing; 1: conventional `{R,G,B}` source packing |
| `C_TIMING_PROFILE` | 1 | 1: official-derived fixed timing; 0: legacy comparison timing |

Profile1 uses HSTART123, VSTART6, HTOTAL605, VTOTAL809, HSYNC4 and VSYNC4. Profile0 uses HSTART14, VSTART24, HTOTAL541 and VTOTAL834 with the same sync widths. At the standard pixel clock, profile1 frame rate is approximately60 Hz; use the actual clock/(HTOTAL×VTOTAL) rather than a fixed software assumption. These profiles do not implement all upstream adaptive scheduling behavior.

Outputs are registered with IOB intent; dot clock is forwarded through ODDR. Read the packaged LCD constraints alongside board pin assignment. No application false path is needed merely because video is streaming. Clock crossing belongs in the asynchronous FIFO, not in the LCD input.

## Integration and limitations

Use AMD TPG with MAX_COLS480/MAX_ROWS800, one sample/pixel per clock and RGB8. Connect through a 24-bit AXIS FIFO with TUSER1/TLAST, asynchronous write100MHz/readpixelclock. Connect ESP32 `M_AXIS_OVERLAY` directly at the same pixel clock and reset. Do not use an unrelated AXIS switch as an alpha compositor.

The LCD does not expose status to CPU memory in this reference. Adding GPIO/status capture would be a separate hardware revision. No runtime resolution, porch, color matrix, framebuffer DMA, scaling, rotation or LCD-panel command interface is implemented here. Panel initialization and ESP32-owned menus remain firmware responsibilities.

## Maintenance and performance

See [verification](verification.md) for source-bound tests and physical acceptance. Resource counts must come from the selected synthesized/routed variant, with overlay parameter and report identity stated. The guide does not promise throughput from an unmeasured memory source or qualify external panel timing solely from internal setup/hold reports.
