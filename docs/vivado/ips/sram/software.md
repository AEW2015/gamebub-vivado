# SRAM software and examples

`GBSram_CfgInitialize` reads identity, capacity and exact supported capability
value without writes; `SelfTest` repeats these read-only checks. Neither starts a
test or changes timings. A wrong/missing slave can raise a CPU bus exception
before any software timeout: provide a trap handler and hardware interconnect
timeout policy. Poll budgets count register reads, not microseconds.

`LookupConfig` matches the CSR base address. `GBSram_Config` has only `Name` and
`BaseAddress`, in SDT YAML order (`compatible`, `reg`). The checked-in empty
config table is a safe no-instance fallback, not an automatically populated BSP.
Native SDT emits `xlnx,gamebub-sram-mem-1.6`, with CTRL_AXI first and MEM_AXI
second in `reg`. The binding selects the first (CSR) base; generated C table
shape must still be verified by a clean native BSP build.
Manual `CfgInitialize` is supported; reject accidental RAM-as-CSR binding by ID.

Call `BindMemory` with the independently discovered `MEM_AXI/Mem` region. The
[XSA helper](../../../../fpga/sw_repo/tools/gamebub_memory_regions.py) handles one,
both or multiple renamed RAM instances and overlap rejection. CSR driver
discovery alone does **not** make the memory appear in the Vitis linker.

## Cache and safety contract

Keep executable code, stack, traps and ownership-test routines in local BRAM.
The reference export has 16 KiB, not an assumed 32 KiB. Inspect ELF section sizes
and the linker map. Never test the live stack, code or allocated data. Reserve a
specific scratch region in the linker/application allocator. Stop every other
master, flush dirty cache lines before tester ownership, invalidate after external
writes. CPU `ScratchTest` additionally needs caching disabled for the span, so
reads observe external RAM rather than a cache hit; it does not manipulate global
cache policy on the application's behalf. Pass explicit `Reservation` consent
flags only after performing those operations.

Examples are separate small sources under
[`examples`](../../../../fpga/sw_repo/drivers/gbsram/examples):

- `gbsram_probe_example.c`: read-only identity probe (not a physical RAM test).
- `gbsram_scratch_example.c`: explicit reserved-range destructive CPU test,
  four patterns and all four byte lanes.
- `gbsram_test_example.c`: one hardware fill/verify pass then STOP/drain.
- `gbsram_instruction_example.c`: opt-in RISC-V copied function, using platform
  cache callbacks and a caller-reserved executable scratch region.

Probe selects the first actual generated CSR instance when no base override is
supplied; an empty table fails safely. Destructive examples require discovered
CSR/RAM bases supplied by the reference application builder or explicit build
definitions. They do nothing unless
`GB_ALLOW_DESTRUCTIVE=1` and a scratch offset/size are explicitly provided.
The copied instruction example requires RISC-V and uncached/correctly maintained
RAM; it must not be advertised as hardware-tested merely because it compiles.

Expected output is `GBSRAM_PROBE_PASS`, `GBSRAM_SCRATCH_PASS` or
`GBSRAM_TEST_PASS` only after the corresponding actual checks. A config-needed
message is not a pass. Failure does not free the scratch reservation; inspect
controller ownership/fault state from BRAM before resuming clients.
