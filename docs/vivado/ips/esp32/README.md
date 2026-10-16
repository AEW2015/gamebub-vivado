# ESP32 communications

`gamebub.org:ip:gamebub_esp32_v102:1.14`, driver `GBEsp32`.

This is an **active QSPI slave endpoint**, IRQ gate and optional overlay generator. It is not a passive logic analyzer, a CPU-driven SPI controller, or an SD-card filesystem interface.

- [Product guide](product-guide.md): integration, clocks, IRQs, overlay and limitations.
- [Registers](registers.md): CPU AXI map and endpoint diagnostics.
- [Catalog reference](catalog.md): complete packaged ports, parameters and interface metadata.
- [Software](software.md): configuration, examples and interrupt sequence.
- [Verification](verification.md): actual checks versus pending hardware qualification.
- [Public API](../../../../fpga/sw_repo/drivers/gbesp32/src/gbesp32.h).

The normal ESP32 firmware is not changed by this software package. Do not launch a game from its main menu during a JTAG-loaded diagnostic: that can intentionally replace the FPGA image.
