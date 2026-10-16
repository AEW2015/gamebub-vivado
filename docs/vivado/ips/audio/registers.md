# Register reference

Core: `gamebub.org:ip:gamebub_dac_audio:1.3`.

Generated from the reviewed driver register schema. Offsets are relative to the control base, not processor physical addresses.

| Name | Offset | Access | Reset or read value | Behavior |
| --- | --- | --- | --- | --- |
| `ID` | `0x000` | RO | 0x53504b01 | Speaker identity, not a separate capability or ABI register. |
| `COMMAND` | `0x004` | WO/RAZ | 0 | Full-strobe write1 starts valid stopped tone, write2 stops. Other values SLVERR; reads0. |
| `STATUS` | `0x008` | RO | 0 | Running bit0, reason[6:4]:0 normal/stop,2 heartbeat expiry,3 stop_n,4 duration expiry. |
| `REMAINING` | `0x00C` | RO | 0 | Remaining total session ms. |
| `HEARTBEAT_FRAMES` | `0x010` | RO/WO | 0 | Read advancing audio frame counter. Full-strobe write0x53504b31 refreshes500ms lease; other writes SLVERR. |
| `SAMPLE_RATE` | `0x014` | RO | 48293 | Fixed rounded nominal sample-rate constant, not measurement. Actual rate CLOCK_HZ/608. |
| `CLOCK` | `0x018` | RO | CLOCK_HZ | Packaged audio clock parameter in Hz. |
| `FREQUENCY` | `0x020` | RW stopped only | DEFAULT_FREQUENCY | Tone20..12000Hz. DDS multiplier88936 assumes nominal29.361979MHz clock. |
| `LEVEL` | `0x024` | RW stopped only | DEFAULT_LEVEL | Linear digital amplitude0..100 percent, not ESP32 analog volume. |
| `WAVEFORM` | `0x028` | RW stopped only | 0 | 0sine,1square,2triangle. |
| `CHANNELS` | `0x02C` | RW stopped only | 0 | 0both,1left,2right. |
| `LIMIT` | `0x030` | RW stopped only | DEFAULT_LIMIT_MS | 100..30000ms session; heartbeat does not extend this bound. |

Reserved addresses and unsupported features must follow the RTL response rules in the product guide. A schema table is not proof of register behavior.
