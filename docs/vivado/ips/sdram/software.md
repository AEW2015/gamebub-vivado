# SDRAM software and safe examples

The driver validates S4S1 ID, ABI1,32MiB capacity and S4C1 clock ID without writes.
`LookupConfig` matches a CSR base; `BindMemory` binds an independently discovered
32MiB MEM_AXI aperture. Never infer RAM from CSR `reg`. Native SDT emits
`xlnx,gamebub-sdram-mem-1.6`, with CTRL_AXI first and MEM_AXI second in `reg`.
A clean BSP still needs to verify the generated C table shape;
manual `CfgInitialize` remains available and ID checks reject a RAM-as-CSR mistake.
The empty checked-in config table intentionally discovers no devices.

Use the [XSA helper](../../../../fpga/sw_repo/tools/gamebub_memory_regions.py) for
one/both/multiple renamed RAM instances, I/D aliases and overlap checks. `add_to_app`
preflights conflicts, adds missing RAM ranges through Vitis's linker API, and
verifies retained bounds. Native SDT memory/linker discovery is a separate gate.

## Safe normal access

Boot entirely from BRAM, initialize driver, bind actual RAM, acquire CPU ownership,
then use ordinary memory loads/stores. Keep boot, stack/traps and recovery in BRAM
until the memory has been proved usable. Current local BRAM is16KiB: inspect each
ELF/map. Cache APIs are standalone BSP APIs, not replaced by this driver. Instruction
cache must be invalidated after writing a copied function; issue instruction fence
and data cache maintenance before execution. Test only linker-reserved scratch.

## Destructive tests and timing

All tester/ownership/clock code, stack and trap/interrupt handlers must remain in
BRAM. Stop other masters, flush dirty lines before TEST/PARK and invalidate after
external writes. ScratchTest needs the tested span uncached so reads cannot pass
from cache alone. Reservation consent flags are caller attestations, not hardware
proof. No driver can infer arbitrary DMA/interrupt activity or live heap use.

`RunTest` tests the explicitly reserved range; it leaves TEST ownership even on
success. Abort/timeouts never silently grant CPU. Inspect state, abort/drain,
invalidate caches and reacquire CPU explicitly. Every polling loop has a finite
budget, but a stalled MMIO bus access can trap/hang before polling progresses;
configure interconnect timeouts and a BRAM exception handler.

`CalculateClock` is a pure integer profile search. `ApplyClock` is opt-in, requires
a caller safety callback twice and PARK/reconfig_safe, writes only validated
profiles and waits for a new completion plus ready/no-error/actual-Hz checks.
On failure it leaves clients parked; there is no silent50MHz fallback. Frequency
profile apply invalidates SDRAM contents. `GetClockStatus` reports calculated Hz
and independently metered command/read kHz. `LoadTaps` requires the same explicit
safety callback, PARK ownership and16 taps in0..31; it verifies actual readbacks.
Automatic eye scans and full-system recovery are not implemented in this driver.

Examples in [`examples`](../../../../fpga/sw_repo/drivers/gbsdram/examples) are
individual read-only probe, destructive scratch/hardware test, copied-instruction,
and opt-in clock configuration sources. Probe selects the first generated CSR
instance (or an explicit base override), failing safely for an empty table.
Destructive examples need actual CSR, MEM_AXI and reserved scratch metadata.
Destructive tests are disabled by default;
clock example requires additional BRAM safety consent. Expected PASS output is
conditional on actual checks, never a config-disabled placeholder. Build/host
success is not physical memory qualification.
