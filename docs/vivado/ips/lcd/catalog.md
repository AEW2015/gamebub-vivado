# gamebub_lcd_axis component catalog

Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.

- VLNV: `gamebub.org:ip:gamebub_lcd_axis:1.5`
- Component version: `1.5`
- Component metadata SHA-256: `b2353fdc58ded4a429ed569d0b3e8cac6607673fbc2c7e59660e2e8af9b810b8`
- Source: [`component.xml`](../../../../fpga/ip_repo/gamebub_lcd_axis_v1_5/component.xml)

## User parameters

Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve="user"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.

| Parameter | Default | Description |
| --- | --- | --- |
| `C_ENABLE_OVERLAY` | `0` | Enable ESP32 AXI4-Stream overlay |
| `C_RGB_PACKING` | `0` | TDATA packing: 0=AMD RBG, 1=RGB |
| `Component_Name` | `gamebub_lcd_axis_0` | No description supplied in component metadata. |
| `USE_BOARD_FLOW` | `false` | No description supplied in component metadata. |
| `LCD_BOARD_INTERFACE` | `Custom` | No description supplied in component metadata. |
| `C_TIMING_PROFILE` | `1` | Panel timing profile |

## Bus interfaces and clock/reset association

Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.

| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S_AXIS_VIDEO | xilinx.com:interface:axis:1.0 | xilinx.com:interface:axis_rtl:1.0 | slave | TDATA → S_AXIS_VIDEO_tdata<br>TVALID → S_AXIS_VIDEO_tvalid<br>TREADY → S_AXIS_VIDEO_tready<br>TUSER → S_AXIS_VIDEO_tuser<br>TLAST → S_AXIS_VIDEO_tlast | — | — | — |
| LCD | gamebub.org:interface:lcd_rgb888:1.0 | gamebub.org:interface:lcd_rgb888_rtl:1.0 | master | R → lcd_data_r<br>G → lcd_data_g<br>B → lcd_data_b<br>DOTCLK → lcd_dotclk<br>HSYNC → lcd_hsync<br>VSYNC → lcd_vsync<br>DE → lcd_data_en | — | — | — |
| pixel_clk | xilinx.com:signal:clock:1.0 | xilinx.com:signal:clock_rtl:1.0 | slave | CLK → pixel_clk | — | pixel_resetn | S_AXIS_VIDEO:S_AXIS_OVERLAY:LCD |
| pixel_resetn | xilinx.com:signal:reset:1.0 | xilinx.com:signal:reset_rtl:1.0 | slave | RST → pixel_resetn | — | — | — |
| S_AXIS_OVERLAY | xilinx.com:interface:axis:1.0 | xilinx.com:interface:axis_rtl:1.0 | slave | TDATA → S_AXIS_OVERLAY_tdata<br>TVALID → S_AXIS_OVERLAY_tvalid<br>TREADY → S_AXIS_OVERLAY_tready<br>TUSER → S_AXIS_OVERLAY_tuser<br>TLAST → S_AXIS_OVERLAY_tlast | — | — | — |

## Top-level HDL ports

Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.

| Port | Direction | Vector bounds |
| --- | --- | --- |
| `pixel_clk` | `in` | `scalar` |
| `pixel_resetn` | `in` | `scalar` |
| `S_AXIS_VIDEO_tdata` | `in` | `[23:0]` |
| `S_AXIS_VIDEO_tvalid` | `in` | `scalar` |
| `S_AXIS_VIDEO_tuser` | `in` | `scalar` |
| `S_AXIS_VIDEO_tlast` | `in` | `scalar` |
| `S_AXIS_VIDEO_tready` | `out` | `scalar` |
| `S_AXIS_OVERLAY_tdata` | `in` | `[31:0]` |
| `S_AXIS_OVERLAY_tvalid` | `in` | `scalar` |
| `S_AXIS_OVERLAY_tuser` | `in` | `scalar` |
| `S_AXIS_OVERLAY_tlast` | `in` | `scalar` |
| `S_AXIS_OVERLAY_tready` | `out` | `scalar` |
| `vblank` | `out` | `scalar` |
| `overlay_visible` | `out` | `scalar` |
| `stream_locked` | `out` | `scalar` |
| `underflow` | `out` | `scalar` |
| `framing_error` | `out` | `scalar` |
| `lcd_dotclk` | `out` | `scalar` |
| `lcd_hsync` | `out` | `scalar` |
| `lcd_vsync` | `out` | `scalar` |
| `lcd_data_en` | `out` | `scalar` |
| `lcd_data_r` | `out` | `[7:0]` |
| `lcd_data_g` | `out` | `[7:0]` |
| `lcd_data_b` | `out` | `[7:0]` |
