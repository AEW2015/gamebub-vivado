# ESP32 communications product guide

## Scope and features

The core services installed official-firmware QSPI accesses independently of the MicroBlaze V. Twelve pressed/released buttons feed an ESP32 event path and an independently acknowledged CPU event latch. The FPGA drives the Rev4 IRQ nFET gate: **gate high asserts the ESP32's active-low IRQ**, not a push-pull shared interrupt pin.

The endpoint includes diagnostic counters and optional AXI4-Stream overlay generation. CPU COV2 overlay requires both `C_ENABLE_OVERLAY_AXIS=1` and `C_ENABLE_CPU_OVERLAY=1`; check runtime identity and capabilities before writes. `C_OVERLAY_MONOCHROME` controls the ESP32 image representation. Leave `C_MANUAL_OVERRIDE=0` for normal use; holding the manual gate high can prevent normal IRQ recovery.

## Interfaces and integration

| Interface | Role |
| --- | --- |
| QSPI | ESP32-master SCK, CS_n and four bidirectional data pins; FPGA is the slave |
| BUTTONS | Twelve active-low physical inputs, synchronized internally |
| IRQ gate | Rev4 nFET gate output; high asserts shared ESP interrupt |
| S_AXI | 32-bit AXI4-Lite diagnostics, CPU events and optional COV2 writes; 4KiB aperture |
| cpu_irq | Registered service-domain **level**, pending AND enable |
| M_AXIS_OVERLAY | Optional 32-bit alpha/RGB stream, native480x800, SOF/EOL sidebands |

Use board automation for pin assignment; never infer package pins from an example instance name. Use a normal Clocking Wizard and Processor System Reset. Connect service clock/reset to the **always-running200MHz** domain. A100MHz CPU requires a clock-converting AXI interconnect. Concat does not synchronize levels. The reference's related PLL clocks allow a timed synchronous interrupt crossing, which still requires routed setup/hold review; otherwise add supported destination synchronization (for example INTC asynchronous-input mode). Do not false-path an unsynchronized crossing. Do not gate QSPI service on application pause or processor initialization.

Overlay clock/reset belong to the pixel domain, nominal29,361,979Hz in the reference. Reset deassertion must be synchronized in each domain. Streaming backpressure must not stall ESP32 QSPI service. `M_AXIS_OVERLAY` data packs alpha[31:24], R[23:16], B[15:8], G[7:0], matching this core's downstream integration rather than assuming conventional RGBA byte order.

AXI supports one outstanding write and one outstanding read. AW/W are captured separately; reads are pipelined and sample changing data at the data stage, not atomically at AR handshake. Aligned32-bit accesses are recommended. Reserved and read-only writes return SLVERR; reads of reserved/misaligned addresses return SLVERR and zero. CPU software MMIO primitives do not report AXI responses: missing slaves or SLVERR may trap. Hardware bus timeouts and an exception handler are separate system responsibilities.

## CPU overlay ownership and pixels

COV2 stores384x240 logical pixels as two bits `{opaque,white}`: `0` transparent black, `1` transparent white, `2` opaque black, `3` opaque white. It is independent of the ESP32 buffer and is **under** opaque ESP32 graphics. The CPU cannot erase the ESP32 menu through COV2 writes.

Logical row-major index is `y*384+x`. Sixteen pixels occupy each32-bit word, first pixel in bits1:0. Packed word writes auto-increment modulo5760; pixel writes auto-increment modulo92160. The driver rejects range crossings instead of silently wrapping. Whole-byte AXI strobes on a packed write enable four pixels each. Single-pixel writes require byte0 strobe. Access to index+data pairs is not reentrant: serialize task/ISR/DMA writers externally.

Native panel placement uses physical `x=2*logical_y` and `y=16+2*logical_x` with2x replication. This is the landscape bitmap rotated into the480x800 portrait scanout. The ESP32 buffer uses its own360x240 placement and offset; do not conflate those dimensions.

The bitmap is configured transparent at FPGA configuration. Soft resets reset enable/index/counters and pipelines **without clearing bitmap RAM**. Explicit clear costs5760 full packed writes plus setup; no hardware clear, framebuffer readback, double buffering or frame-atomic swap exists. Live writes can tear. Read of WORD_DATA is last bus word only. Optional software shadowing costs23,040bytes packed, exceeding this reference's16KiB local BRAM: place a requested shadow in safely initialized external RAM or avoid it.

## Normal firmware lifecycle and unsupported features

### Implemented ESP32-side QSPI subset

SPI mode0, MSB-first command byte always arrives on DQ0, then a32-bit address. Command[6:5] chooses1/2/4 lanes for address/data (encoding3 invalid); [2:1] chooses8/16/32-bit words (encoding3 invalid); [3] reverses bytes within16/32-bit words; [4] enables burst address increment; [0] selects read versus write; [7] must be zero. Reads consume **64 dummy bits (eight bytes)**, not eight clocks. In single-lane reads DQ1 is MISO. Raw CS_n immediately releases output ownership. The digital endpoint source records writes≤40MHz and reads≤16MHz as tested rates, not external-pin PVT qualification.

| QSPI address | Implemented subset |
| --- | --- |
|0xF1000000|Read0: deliberately does not claim a complete official framework ABI|
|0xF1000004|Read service frequency200000000|
|0xF1001000|IRQ enable low4 bits, default bit1(button change) enabled|
|0xF1001004|IRQ flags low4 bits, write-one-clear; button changes win simultaneous clear|
|0xF1001008|Forced button shadow (does not rewrite CPU physical button register)|
|0xF100100c|External-display shadow bit|
|0xF1002000|Physical pressed-high host bitmap|
|0xF1000100/0104|Overlay geometry360x240 /16bits per pixel|
|0xF2000000..0xF203ffff|Overlay write byte-address aperture; consumer accepts even16-bit words within its360x240 bitmap|

Other reads return zero; unsupported writes have no functional effect. Endpoint control/display shadows are not proof of a connected game framework. Vblank is tied low by this wrapper, so its vblank event cannot be advertised as functioning. The source includes mailbox ports internally, but this packaged wrapper leaves write outputs unconsumed and ties mailbox read data zero: **no native mailbox service** is present.

Power/menu/volume behavior is controlled by the ESP32 firmware's own state. The core provides its protocol/IRQ/overlay transport, not a native-app lifecycle negotiation. A JTAG-loaded image is not automatically registered as a running game. Do not erase ESP graphics after an arbitrary timeout as a firmware-state workaround. In the tested simple overlay flow volume graphics can appear and clear normally, but a main-menu game launch deliberately reconfigures the FPGA.

This endpoint does not provide a CPU native mailbox or SD assets. No capture FIFO of complete QSPI transactions is exposed; diagnostic counters and last address/data are lossy observation, not a transaction trace. Firmware versions need separately recorded qualification; the endpoint's V102 diagnostic identity is not proof of installed firmware version.

## Debug checklist

1. Verify200MHz service clock, synchronized reset release, board IRQ polarity and QSPI pins.
2. Read GBES ID/ABI, clock constant, IRQ status and changing heartbeat/transaction counters.
3. Observe physical button bitmap and independent CPU pending. Clear source before controller acknowledgement.
4. Verify COV2 ID before optional overlay writes and connect its pixel-domain clock/reset/stream.
5. If menus replace the diagnostic, inspect ESP32 lifecycle instead of treating all menu contents as stale RAM.

Resource/timing figures depend on overlay parameters and full SoC placement. This driver release makes no new routed-frequency or BRAM-utilization claim. Preserve packaged CDC constraints; an audit and positive routed setup/hold remain mandatory for a hardware release.
