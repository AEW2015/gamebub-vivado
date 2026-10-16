# GBEsp32 software

[Public API](../../../../fpga/sw_repo/drivers/gbesp32/src/gbesp32.h), [driver](../../../../fpga/sw_repo/drivers/gbesp32/src/gbesp32.c), [examples](../../../../fpga/sw_repo/drivers/gbesp32/examples).

The SDT configuration structure is `{Name,BaseAddress}` matching compatible/reg schema order. `LookupConfig(0)` selects the first generated instance; explicit base selects a renamed/multiple instance without hardcoded names. The checked-in `_g.c` is a safe empty fallback. SDT-generated platform configuration must replace it or an application must pass its own configuration. An empty table returns NULL instead of inventing a base.

```c
GBEsp32 dev;
GBEsp32_Config *cfg = GBEsp32_LookupConfig(platform_esp32_base);
if (!cfg || GBEsp32_CfgInitialize(&dev, cfg, cfg->BaseAddress) != XST_SUCCESS)
    return XST_FAILURE;
u32 buttons = GBEsp32_Buttons(&dev);
```

`CfgInitialize` and `SelfTest` only read ID/ABI/capabilities. They do not reset transport, acknowledge events, enable IRQ, or clear bitmaps. Strict ABI0x00010005 checking prevents accidentally using COV1 transparency assumptions. No API initialization starts motors/audio or mutates ESP32 firmware. Status/getter zero on an unready instance is a convenience, not hardware success; check initialization status first.

## Examples and interrupt ordering

- `esp32_poll.c`: bounded single poll returning the pressed bitmap; platform main controls reporting duration.
- `qspi_diagnostics.c`: read16 non-atomic diagnostics without changing selector/inject bit.
- `buttons_irq.c`: callable handler with foreground-owned context; no console output in ISR. Platform configures actual XIntc interrupt number, handler reference, CPU exception entry and level-high source synchronization.
- `cpu_overlay.c`: explicit COV2 clear and a small white cross on transparent background; absent capability returns failure before writes.

For interrupt setup, disable CPU source, connect XIntc using **generated** parent/ID, record initial button state, acknowledge stale CPU latch, then enable source/controller/CPU interrupts. On service, snapshot buttons then clear CPU source before controller acknowledge. A source still high must retrigger; do not use an edge-only configuration to hide it. Application event counters cannot recover button states missed between samples. ESP32 acknowledgement is independent from the CPU latch.

All APIs are bounded in iteration count; only clear writes5760words. MMIO can still stall/trap without a system bus timeout; a C loop bound cannot recover a hung AXI transaction. No heap or persistent framebuffer shadow is allocated. Callers protect packed-index/data sequences against concurrent use. Board-specific console and IRQ dispatch stay outside generic drivers.

The poll/diagnostics/overlay sources include default standalone mains. Define `TESTAPP_GEN` when using the callable functions with your own main. The IRQ handler intentionally has no fabricated generic main: platform routing is required. YAML uses the exact observed native SDT compatible `xlnx,gamebub-esp32-v102-1.14` and lists the three independently buildable examples. CMake handles Vitis-generated `Gbesp32Example.cmake` metadata or an explicit callable-library build. Native Vitis discovery/import remains a separate qualification result; manual compilation alone is not discovery proof.
