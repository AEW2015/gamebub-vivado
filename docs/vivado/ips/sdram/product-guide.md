# SDR SDRAM product guide

## Features and interfaces

`gamebub.org:ip:gamebub_sdram_mem:1.6` presents 32 MiB SDRAM through `MEM_AXI`
and memory-test/MMCM registers through `CTRL_AXI` (8 KiB). Both are **AXI4-Lite**.
SmartConnect may split cache transactions; the core does not offer native AXI
bursts, coherence, atomic/exclusive operations or guaranteed framebuffer bandwidth.
Normal CPU reads/writes select one aligned 32-bit slice of an internal 128-bit
transfer. WSTRB controls byte lanes; read returns containing aligned word.
The frontend independently captures AW/W, retains responses under backpressure,
and serializes memory/control transactions. Instruction access is permitted only
inside RAM; instruction accesses to CSRs and instruction writes return SLVERR.

Unsupported address regions return DECERR; invalid alignment, command, busy/fault,
ownership/health violations return SLVERR. Faulted clock/mailbox can make external
RAM inaccessible. A C poll budget cannot rescue a processor already executing
from failing SDRAM.

## IPI, clocks and addresses

Connect `SDRAM` to the matching Rev4 board interface. Supply stable 100 MHz
`host_clk` and active-low host reset, independent stable 200 MHz `refclk200` and
its reset for IDELAYCTRL. Neither is the dynamic external memory clock. The core
contains a dedicated runtime MMCM and 4:1 SDR OSERDESE2/ISERDESE2 PHY with sixteen
IDELAYE2 inputs. Its command/read serial clocks and quarter-rate control clocks
must not drive CPU/debug/LCD/reference domains. Leave `reconfig_hold` explicitly
zero for the initial software-controlled clock path; `memory_safe`, `reconfig_safe`,
`link_fault`, `clock_ready` are status wires, not new software-readable GPIOs.

Map MEM_AXI as exactly 32 MiB aligned to 32 MiB, and CTRL_AXI as 8 KiB aligned to
8 KiB outside all cacheable RAM windows. Public example RAM at `0x78000000` is
valid even when private `C_BASE_ADDR` is `0x60000000`: `s4_axi_split` retains
public low25 bits and reconstructs private addresses. Private base must remain
64 MiB aligned. Do not expose a CSR page as linker RAM, or expand MEM_AXI beyond
the actual physical 32 MiB. Both I/D cache windows must cover the actual memory.

## Ownership and initialization

Backend resets to PARK, not CPU. `SetOwner(CPU)` is needed before normal memory
use; it is rejected until initialized, IDELAY ready, healthy and quiescent. Ownership
is exclusive: CPU=1, tester=2, PARK=0. `GetOwner` sends a snapshot command because
the owner bits in host status describe the **last mailbox response**, not a live
cross-domain wire. Tester START requires TEST ownership; ABORT drains safely.
PARK is idle ownership with normal refresh, not SDRAM self-refresh.

The tester performs full fill then independent verify for each selected pattern.
Base/count are 16-bit word units and multiples8. Nine patterns: zero, ones,
AAAA,5555, walking-one, walking-zero, address, inverse-address, PRBS. Full 32 MiB
all-pattern test requires150,994,944 comparisons and301,989,888 halfword operations.
PASS requires a new run ID, done/passed, no invalid/aborted/fatal/reset-needed flags,
zero errors and exact expected comparison count. Progress/counters alone are not
enough. Settings tags are software metadata, not physical timing measurements.

## Dynamic clock controls

The normalized ABI computes Hz as `6,250,000*M8/(D*O)`; M8 is multiplier times8,
D logical1..5, O3..7, 96D<=M8<=192D, M8<=512, frequency166..250MHz. Physical MMCM
DIVCLK is2D because this core uses100MHz input while preserving the older50MHz
profile ABI. Read serial phase and quarter phase must encode the same absolute
MMCM time shift: phase ticks round from `serial_mdeg*O/45000` and
`quarter_mdeg*O*4/45000`. A requested90° serial phase means22.5° quarter-rate phase.
The requested frequency is nearest achievable, not guaranteed exact0.125MHz steps.

Clock apply requires PARK and hardware `reconfig_safe`, resets/reprograms the
private MMCM, checks readback, lock transitions and internal command/read meters.
Calculated nominal Hz and internally measured serial-equivalent kHz are distinct;
neither is a direct probe of the pin/PCB. Changes reinitialize SDRAM: invalidate
existing data and reestablish ownership. On error remain in BRAM, preserve faults,
and do not blindly resume clients. Failed apply can require FPGA reconfiguration.

Per-DQ IDELAY/capture controls exist in registers; the initial driver provides
guarded `LoadTaps` but no automatic tap sweep or eye finder. Taps load only in PARK;
test configuration changes do not prove the physical setting was applied.

## Timing and performance limitations

Do not extrapolate a user-observed250MHz passing point to all phases/taps or PVT.
Default dynamic timing smoke covers only five selected cases (166MHz at serial
0/360°,200MHz180°,250MHz0/360°), not exhaustive dynamic-range qualification.
Preserve packaged-versus-project SDRAM CDC constraints as an integration release
gate. No blanket false paths and no new utilization/throughput numbers are claimed.
