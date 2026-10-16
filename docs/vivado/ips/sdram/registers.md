# Register reference

Core: `gamebub.org:ip:gamebub_sdram_mem:1.6`.

Generated from the reviewed driver register schema. Offsets are relative to the control base, not processor physical addresses.

| Name | Offset | Access | Reset or read value | Behavior |
| --- | --- | --- | --- | --- |
| `ID` | `0x000` | RO | 0x53345331 | S4S1 memory/control identity. |
| `COMMAND_RESPONSE` | `0x004` | RW | 0 | Write commands3=SET_OWNER,4=START,5=ABORT,6=SNAPSHOT,7=LOAD_TAPS; full strobes. Reads last mailbox AXI response (0 okay,2 failure). Backend completion sequence must advance. |
| `STATUS` | `0x008` | RO | 0 | bit0 link busy,bit1 link fault,owner[3:2] from last response (0PARK/1CPU/2TEST), not live until mailbox command. |
| `SEQUENCE` | `0x00C` | RO | 0 | Mailbox completions, including failed operations. |
| `SIZE_BYTES` | `0x010` | RO | 0x02000000 | 32MiB physical RAM, separate from CSRs. |
| `ABI` | `0x014` | RO | 1 | Exclusive ownership ABI1. |
| `LINK_RECOVER` | `0x018` | WO | 0 | Write1 with full strobes and link not busy to recover mailbox. Not automatic safe restoration of RAM contents. |
| `CONFIG_BASE_WORD` | `0x040` | RW | 0 | 24-bit physical halfword start; tester uses bursts of8 halfwords. |
| `CONFIG_COUNT_WORDS` | `0x044` | RW | 0 | 25-bit halfword count; base/count multiples8, nonzero, base+count<=16777216. |
| `CONFIG_PATTERNS_SEED` | `0x048` | RW | 0 | patterns[8:0] selects nine fill/verify passes, seed[31:16] (zero becomes1). |
| `CONFIG_CAPTURE_OWNER` | `0x04C` | RW | 0 | capture slot[1:0], capture delay[5:2], owner[31:30]0PARK/1CPU/2TEST (3invalid). |
| `CONFIG_TAPS` | `0x050` | RW | 0 | 80-bit packed16x5bit IDELAY requests in three words0x50,0x54,0x58; upper16 ofthird are unused. APPLY taps only parked through command7. |
| `CONFIG_TAG` | `0x05C` | RW | 0 | Four metadata words through0x68; not measured frequency proof. |
| `SNAPSHOT` | `0x100` | RO | 0 | 40 frozen words through0x19c; updated by completed mailbox operations. [0]status,[1]work,[2]total,[3]compares,[4]expected,[5]errors,[6]runID,[7]base,[8]count,[9]seed/patterns,[10..12]firsterror,[13]refresh,[14]tap/capture,[15]ST41identity,[16..31]DQerrors,[32..35]tag,[36..38]actual taps plus CPU response bits,[39]CPU data. Telemetry status bits0busy,1done,2passed,3failed,4invalid,5aborted,6needs_reset,7initialized,8fatal,9alignfault,10quiescent,11start_ready,12reading; error code[19:16]. |
| `CLOCK_ID` | `0x1000` | RO | 0x53344331 | S4C1 dedicated clock bank identity. |
| `CLOCK_COMMAND_STATUS` | `0x1004` | RW | 0 | Write1 full strobes applies staged clock only when safe/notbusy. Read bit0busy,1ready,2locked,3rejected,4reconfig_safe,error[15:8]. |
| `CLOCK_COMPLETIONS` | `0x1008` | RO | 0 | Clock operation completion count; includes rejected/failed. |
| `CLOCK_EPOCH` | `0x100C` | RO | 0 | Successful clock configuration count. |
| `CLOCK_M8` | `0x1020` | RW | 160 | Multiplier times8. M8=96D..192D and<=512. |
| `CLOCK_LOGICAL_D` | `0x1024` | RW | 1 | Logical DIVCLK1..5 in50MHz ABI; physical DIVCLK=2D at100MHz host. |
| `CLOCK_O` | `0x1028` | RW | 5 | Output divider3..7; frequency=6250000*M8/(D*O),166..250MHz. |
| `CLOCK_SERIAL_PHASE` | `0x102C` | RW | 90000 | 0..360000 millidegrees; round ticks=(phase*O+22500)/45000. |
| `CLOCK_QUARTER_PHASE` | `0x1030` | RW | 22500 | 0..90000 millidegrees; round ticks=(phase*O*4+22500)/45000; must equal serial ticks. |
| `CLOCK_METADATA` | `0x1034` | RW | 200000 | Requested kHz metadata only; hardware derives actual frequency independently. |
| `CLOCK_NOMINAL_HZ` | `0x1040` | RO | 0 | Rounded calculated Hz, not independent pin measurement. |
| `CLOCK_COMMAND_KHZ` | `0x1044` | RO | 0 | Measured serial-equivalent command kHz from internal quarter-rate meter. |
| `CLOCK_READ_KHZ` | `0x1048` | RO | 0 | Measured serial-equivalent read kHz from internal quarter-rate meter. |
| `CLOCK_ACTIVE_CONFIG` | `0x1060` | RO | 0 | Six active profile words through0x1074; not necessarily successfully locked until ready/epoch checks. |

Reserved addresses and unsupported features must follow the RTL response rules in the product guide. A schema table is not proof of register behavior.
