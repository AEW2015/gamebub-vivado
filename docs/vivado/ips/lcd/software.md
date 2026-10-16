# LCD software integration

Use AMD `XV_tpg` from the BSP; initialize from its generated configuration, select native height800/width480, RGB output, requested pattern and auto-restart, then start. Default data packing follows AMD RGB8 `{R,B,G}` on TDATA. FIFO and LCD require no software register initialization.

CPU graphics go through `GBEsp32`, not the LCD. Enable the optional CPU overlay in the hardware, clear/write the separate COV2 bitmap and enable that layer. ESP32 graphics retain priority. Transparent CPU pixels preserve the TPG underneath; opaque black pixels form a panel. There is no framebuffer readback, so software cannot read-modify-write arbitrary pixels unless it maintains a shadow or uses the individual-pixel writer.

See the [Vitis workflow](../../vitis-workflow.md) and [reference examples](../../../../fpga/sw_repo/README.md). The latter link is relative to the repository and should resolve in GitHub; use the documentation link checker after rearranging directories.

Do not wait forever for a hardware status pin via a nonexistent MMIO register. Software cannot observe LCD underflow in this exact BD. Use simulation/physical inspection or a separately instrumented design. Do not start software before the processor is released from reset and upstream AXI clocks are available.
