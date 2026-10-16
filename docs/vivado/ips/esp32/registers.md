# Register reference

Core: `gamebub.org:ip:gamebub_esp32_v102:1.14`.

Generated from the reviewed driver register schema. Offsets are relative to the control base, not processor physical addresses.

| Name | Offset | Access | Reset or read value | Behavior |
| --- | --- | --- | --- | --- |
| `ID` | `0x000` | RO | 0x47424553 | GBES identity. |
| `ABI` | `0x004` | RO | 0x00010005 | CPU overlay independent alpha/ink ABI. |
| `CAP` | `0x008` | RO | parameter-dependent | 7 always; OR 216 when both CPU overlay and overlay AXIS enabled. Driver checks aggregate optional mask 0xD8; no invented individual bit names. |
| `CLOCK` | `0x00C` | RO | 200000000 | Required service clock Hz; RTL constant, not frequency measurement. |
| `DIAG_CONTROL` | `0x010` | RW | 0 | Selector[4:0]; changing bit8 injects diagnostic event. Byte strobes honored. Do not write for ordinary monitoring. |
| `STATUS` | `0x014` | RO | 0 | Bit0 ESP IRQ request, bit1 CPU pending, bit2 registered CPU IRQ. |
| `DIAG_DATA` | `0x018` | RO | selector-dependent | Selected endpoint diagnostic word, sampled non-atomically. |
| `BUTTONS` | `0x020` | RO | 0 | Pressed-high host bitmap[11:0], reverse of native input bit order. |
| `PENDING` | `0x024` | RW1C | 0 | Bit0 independent CPU change latch. Press/release sets; event wins simultaneous clear. |
| `IRQ_ENABLE` | `0x028` | RW | 0 | Bit0 enables CPU level IRQ. Does not gate ESP IRQ. |
| `GATE_ID` | `0x080` | RO | 0x47424952 | GBIR identity. |
| `GATE_MANUAL` | `0x084` | RW | 0 | Manual assertion bit0 only if C_MANUAL_OVERRIDE; otherwise write SLVERR. |
| `GATE_STATUS` | `0x088` | RO | 0 | Bit0 request, bit1 synchronized request, bit2 actual gate assertion. |
| `GATE_CAP` | `0x08C` | RO | parameter-dependent | C_MANUAL_OVERRIDE value. |
| `GATE_ABI` | `0x090` | RO | 2 | IRQ gate ABI. |
| `DIAG_BANK` | `0x100` | RO | dynamic | 16 aligned words 0x100..0x13c, diagnostic selectors0..15; snapshots not atomic. |
| `OVERLAY_ENABLE` | `0x200` | RW | 0 | Bit0 CPU layer enable; writes SLVERR when optional layer absent. |
| `WORD_INDEX` | `0x204` | RW | 0 | 0..5759, full strobe required. Auto increments and wraps after word data writes. |
| `WORD_DATA` | `0x208` | RW | 0 | Write16 2-bit pixels LSB-first; each byte strobe enables4 pixels. Read returns last written bus word, NOT framebuffer readback. |
| `DIMENSIONS` | `0x20C` | RO | 0x00f00180 | Height240 upper16, width384 lower16 (also returned when absent). |
| `WORD_WRITES` | `0x210` | RO | 0 | Accepted nonzero-strobe packed writes counter. |
| `OVERLAY_ID` | `0x214` | RO | parameter-dependent | 0x434f5632 COV2 when optional layer enabled; zero otherwise. |
| `PIXEL_BITS` | `0x218` | RO | 2 | Bits per pixel {opaque,white}. |
| `WORD_COUNT` | `0x21C` | RO | 5760 | Packed bitmap word count. |
| `PIXEL_INDEX` | `0x224` | RW | 0 | 0..92159, full strobe required. Row-major logical coordinate y*384+x. |
| `PIXEL_DATA` | `0x228` | WO | not applicable | Low2 bits write one pixel if byte0 strobe. Read SLVERR; index auto increments/wraps. |
| `PIXEL_WRITES` | `0x22C` | RO | 0 | Accepted single pixel writes counter. |
| `PIXEL_COUNT` | `0x230` | RO | 92160 | Logical pixel count. |

Reserved addresses and unsupported features must follow the RTL response rules in the product guide. A schema table is not proof of register behavior.
