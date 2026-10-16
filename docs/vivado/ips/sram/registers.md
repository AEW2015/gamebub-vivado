# Register reference

Core: `gamebub.org:ip:gamebub_sram_mem:1.6`.

Generated from the reviewed driver register schema. Offsets are relative to the control base, not processor physical addresses.

| Name | Offset | Access | Reset or read value | Behavior |
| --- | --- | --- | --- | --- |
| `ID` | `0x000` | RO | 0x53524802 | Shared SRAM identity. |
| `COMMAND` | `0x004` | WO | 0 | One-hot W1 pulses START=1 STOP=2 APPLY=4 CLEAR=8 SNAPSHOT=16 ADOPT_PROFILE=32 RESTORE_PROFILE=64. Full WSTRB required; invalid/busy command returns SLVERR. Reads return zero. |
| `STATUS` | `0x008` | RO | 0 | bit0 armed, bit1 not quiescent, bit2 applying, bit3 fault. |
| `SNAPSHOT_SEQUENCE` | `0x00C` | RO | 0 | Increments on accepted SNAPSHOT. |
| `CAPABILITIES` | `0x010` | RO | 0x0003011f | ABI1, fixed PHY clock, modes0..4; exact driver-supported value. |
| `WORDS` | `0x014` | RO | 262144 | Number of physical 16-bit SRAM words (512KiB). |
| `OWNERSHIP` | `0x018` | RO | 0 | bit0 tester request, bit1 tester grant, bit2 clock_ready. Live. |
| `PROFILE` | `0x01C` | RO | 0 | bit0 profile passed, bit1 profile pending, bit2 normal timing differs from defaults. |
| `SHADOW_BASE_WORD` | `0x020` | RW | 0 | Physical 16-bit word offset, 0..262143. |
| `SHADOW_COUNT_WORDS` | `0x024` | RW | DEFAULT_TEST_WORDS | 1..262144 words; base+count <=262144. |
| `SHADOW_PATTERN_MODE` | `0x028` | RW | 0x1d0f0008 | pattern[3:0]0..8, mode[6:4]0..4, bit7 reserved0, descending8, stop_on_error9, reserved[15:10]0, seed[31:16]. |
| `SHADOW_TIMING0` | `0x02C` | RW | 0x20202040 | READ,WE,SETUP,HOLD: four 8-bit slots, 1.25ns nominal slot resolution. |
| `SHADOW_TIMING1` | `0x030` | RW | 0x00002020 | REL[7:0],ADDR[15:8] slots; upper16 reserved0. |
| `SHADOW_DWELL_MS` | `0x034` | RW | 0 | 0..60000ms. |
| `SHADOW_RESERVED` | `0x038` | RW | 0 | Must be zero for valid config. |
| `SHADOW_METADATA` | `0x03C` | RW | 0 | Opaque metadata word (RTL does not constrain it). |
| `ACTIVE_CONFIG` | `0x040` | RO | same as shadow | Eight consecutive active configuration words through0x5c, changed by accepted APPLY when quiescent. |
| `NORMAL_TIMINGS_LO` | `0x060` | RO | 0x20202040 | Current normal-operation timing low32. |
| `NORMAL_TIMINGS_HI` | `0x064` | RO | 0x2020 | Current normal-operation timing high16. |
| `SNAPSHOT` | `0x100` | RO | 0 | 64 consecutive frozen status words through0x1fc; SNAPSHOT command required. [0]status,[1]epoch,[2]work,[3]total,[4]passes,[5]completed,[6]aborts,[7]failures,[8..11]first error,[12..13]active cycles,[14..15]payload bytes,[16..17]elapsed cycles,[18]reads,[19]writes,[20]cursor,[21]host Hz,[22..29]config,[30]PHY Hz,[31]clock,[32..47]perDQ errors,[48]owner,[49..50]normal timing,[51]profile,[52..63]zero. |

Reserved addresses and unsupported features must follow the RTL response rules in the product guide. A schema table is not proof of register behavior.
