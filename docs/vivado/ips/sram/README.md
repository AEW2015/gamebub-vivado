# GameBub SRAM memory controller 1.6

512 KiB asynchronous SRAM, accessed through a 32-bit AXI4-Lite RAM aperture and
a separate AXI4-Lite control/test aperture. This core supports normal processor
data/instructions and an exclusive destructive hardware tester, not both at once.

- [Product guide](product-guide.md): clocks, ownership, connections and limitations.
- [Registers](registers.md): reviewed schema bound to current RTL.
- [Catalog reference](catalog.md): complete packaged ports, parameters and interfaces.
- [Software](software.md): driver, cache policy and examples.
- [Verification](verification.md): tested scope and release gates.

Driver: [`GBSram`](../../../../fpga/sw_repo/drivers/gbsram/src/gbsram.h).
Do not interpret an old tester's successful 250 MHz **SDRAM** result as SRAM
qualification. SRAM uses its own fixed internal 100/400 MHz PHY clocks.
