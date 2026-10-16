# SDRAM separate examples

Each `.c` has an independent `main`; choose one plus `gbsdram` driver. Probe
selects the first generated CSR configuration when no base override is supplied;
an empty configuration table fails safely. Read
the [software guide](../../../../../docs/vivado/ips/sdram/software.md) first.

Use definitions `GB_EXAMPLE_CTRL_BASE`, `GB_EXAMPLE_MEMORY_BASE`,
`GB_SCRATCH_OFFSET`, `GB_SCRATCH_BYTES` from reviewed XSA/linker metadata.
Destructive apps additionally require `GB_ALLOW_DESTRUCTIVE=1` and
`GB_BRAM_EXECUTION_CONFIRMED=1`. Confirm all other masters parked, no live code/data
in SDRAM, and boot/stack/traps/recovery in BRAM before defining them.
Examples flush then disable data cache and intentionally leave it disabled.

`gbsdram_timing_example.c` also requires `GB_ALLOW_RETIMING=1`; it selects200MHz
serial180° (quarter45°), applies a validated profile, prints actual calculated Hz
and leaves PARK ownership. It does not claim a memory PASS or resume clients.
Its callback attests compile-time BRAM/client safety; a production system must
replace this with actual application-wide quiescence checks.

Do not run these against RAM containing the ELF/stack or a framebuffer client.
No Vitis or hardware execution is claimed by these example sources alone.
