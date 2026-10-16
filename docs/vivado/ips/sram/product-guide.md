# SRAM product guide

## Overview and supported interfaces

The 1.6 core wraps a 512 KiB, 16-bit asynchronous SRAM. `MEM_AXI` and `CTRL_AXI`
are separate **AXI4-Lite** slaves, not native burst interfaces. A processor cache
master needs SmartConnect burst-to-Lite conversion. Cache line fills/writebacks
are split into independent words; this is not evidence of video scanout bandwidth.
No coherence, exclusive accesses, atomics, ECC or DMA engine are implemented.

The memory endpoint accepts one outstanding operation, arbitrates writes ahead of
simultaneous reads, independently captures AW/W, and drains both 16-bit halves of
each 32-bit word before returning its response. Byte writes use WSTRB. Reads return
the containing aligned 32-bit word. Use naturally aligned loads/stores; do not
depend on cross-word unaligned accesses. Denied CPU requests and unsupported
control addresses/commands return SLVERR. The public wrapper retains only the low
19 memory-address bits: an oversized interconnect mapping can alias physical RAM
rather than returning an out-of-range error. Map exactly 512 KiB. CPU access is denied
while tester ownership is requested or granted, or the PHY is not ready.

## Clocks, resets and IPI

Use stable `host_clk` = 100 MHz and matching synchronized active-low host reset.
The internal SRAM clock tree supplies 100 MHz scheduler and 400 MHz DDR I/O.
The physical memory is asynchronous: those frequencies describe the PHY, not a
clock delivered to a synchronous SRAM. Fixed 8:1 OSERDESE2/ISERDESE2 serialization
has nominal 1.25 ns slots. Slot increments are not measured pin-edge accuracy;
REL timing rounds to scheduler words. The core has no runtime frequency selector.

Connect `SRAM` through the Rev4 board interface. Connect both AXI ports to the
100 MHz system domain. Map `MEM_AXI/Mem` as exactly 512 KiB, aligned to 512 KiB;
map `CTRL_AXI` outside the CPU cache window. The example uses RAM `0x76000000`,
but drivers accept generated base addresses and never hardcode it. Configure both
instruction/data cache windows to contain RAM, not CSRs. A cache window may span
unmapped holes; those holes remain inaccessible.

Use the packaged SRAM CDC constraints and inspect the resulting implementation.
Constraints do not replace review of external SRAM timing/PCB delays. Do not add
blanket asynchronous/false-path constraints merely to remove negative slack.

## Ownership and destructive tests

Normal CPU mode is ready only when status armed/busy/applying are clear and live
ownership is `clock_ready=1, request=0, grant=0`. Test START asserts the request,
the arbiter drains CPU work, and only then grants the tester. STOP removes the
request; software must wait for CPU-ready status before accessing RAM again.

Hardware test configuration uses **16-bit word** offsets/counts. Nine patterns
and five modes exist in RTL (fill/verify, byte lanes, March, address, immediate).
The public driver initially exposes one complete fill/verify pass for pattern0..8,
preserving the current timing fields. The engine repeats while armed; the driver
polls a completed pass then stops, so some of the next pass may already overwrite
the explicitly reserved range. Cumulative nonzero failures produce failure, not
a silently cleared PASS. Use a deliberate clear-results procedure in a dedicated
diagnostic application when a fresh measurement is needed.

APPLY changes active tester settings; it does not silently change CPU timings.
ADOPT_PROFILE changes normal timings only after a successful tested profile and
an exclusive drain. The first driver does not expose adoption/raw timing writes:
build a separate opt-in BRAM-resident diagnostic before experimenting.

## Resource, performance and support limits

No new routed utilization or measured throughput is claimed by this driver
release. Historical hardware evidence belongs to its named image, not every IPI
composition. Instruction execution depends on arbitration, cache conversion,
linker placement and cache maintenance; host C tests cannot prove instruction
fetches. Build and routed timing qualification remain required for each image.
