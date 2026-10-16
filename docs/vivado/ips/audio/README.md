# DAC audio tone generator

`gamebub.org:ip:gamebub_dac_audio:1.3`, driver `GBAudio`.

Generate bounded sine/square/triangle tones through the board's external DAC. This is **not PCM DMA, an AXI4-Stream audio player, or standard I2S**. The ESP32 still owns DAC configuration, analog volume and speaker/headphone routing.

- [Product guide](product-guide.md).
- [Registers](registers.md).
- [Catalog reference](catalog.md): packaged ports, parameters and interfaces.
- [Software and examples](software.md).
- [Verification and safety gates](verification.md).
- [Public C API](../../../../fpga/sw_repo/drivers/gbaudio/src/gbaudio.h).
