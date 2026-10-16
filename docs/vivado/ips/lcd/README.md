# LCD AXI4 Stream display

`gamebub.org:ip:gamebub_lcd_axis:1.5` consumes native 480x800 RGB video and an optional full-panel overlay. It generates the GameBub panel signals; viewed physically, the display is 800x480 landscape.

- [Product guide](product-guide.md)
- [Catalog ports and parameters](catalog.md)
- [Software integration](software.md)
- [Verification](verification.md)
- [Shared clock/reset requirements](../../clocks-resets.md)

The core has **no AXI register bank**. Use AMD TPG software for test video and GBEsp32 for CPU overlay pixels. Do not look for LCD control offsets that do not exist.
