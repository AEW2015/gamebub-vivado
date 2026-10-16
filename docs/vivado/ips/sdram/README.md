# GameBub SDR SDRAM memory controller 1.6

32 MiB SDR SDRAM with a SERDES4 PHY, exclusive CPU/test ownership, an AXI4-Lite
RAM aperture and unified 8 KiB control/clock aperture. It is not AMD MIG and not
a DDR controller. SDRAM, SRAM and their timing qualifications are distinct.

- [Product guide](product-guide.md)
- [Registers](registers.md)
- [Catalog reference](catalog.md)
- [Software and safety](software.md)
- [Verification and limitations](verification.md)

Driver: [`GBSdram`](../../../../fpga/sw_repo/drivers/gbsdram/src/gbsdram.h).
