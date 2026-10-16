# SRAM separate examples

Each `.c` contains its own `main`; never link all of them into one application.
Select one source and the `gbsram` BSP driver. The setup header is not an app.
Read the [software guide](../../../../../docs/vivado/ips/sram/software.md).

Build definitions:

| Definition | Meaning |
| --- | --- |
| `GB_EXAMPLE_CTRL_BASE` | Actual CTRL_AXI CSR base from XSA |
| `GB_EXAMPLE_MEMORY_BASE` | Actual MEM_AXI base from XSA |
| `GB_SCRATCH_OFFSET`, `GB_SCRATCH_BYTES` | Explicit linker-reserved byte range |
| `GB_ALLOW_DESTRUCTIVE=1` | User accepts overwrite of that range |
| `GB_BRAM_EXECUTION_CONFIRMED=1` | Entire code/stack/traps BRAM; other clients parked |

Probe is read-only and selects the first generated configuration when its base
override is absent; an empty table fails safely. All other examples disable data caching after flushing
and intentionally leave it disabled on return; this is a diagnostic app, not a
transparent helper inside an arbitrary running game. Instruction example requires
RISC-V executable scratch and issues `fence.i` plus BSP cache maintenance.
No Vitis build or hardware PASS is implied by the existence of these sources.
