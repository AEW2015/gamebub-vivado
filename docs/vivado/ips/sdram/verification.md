# SDRAM verification and release gates

Host MMIO mocks cover non-destructive identity/ABI validation, ownership request
and refreshed owner status, snapshot sequencing, positive and deliberately failed
hardware-test status, invalid reservations, bounded stuck-mailbox polling and
rejected unsafe clock requests. Pure profile tests check every0.125MHz request
from166through250MHz for legal parameters and monotonic actual frequency. This is
a calculation test, **not** additional hardware timing cases or an RTL PHY model.

The Python XSA helper has synthetic HWH tests for single SRAM/SDRAM, both memories,
multiple renamed instances, I/D alias collapse, absent memory, invalid lengths,
overlaps and existing native linker regions. Real exported XSA and native Vitis
linker integration remain separate qualification gates.

Before release, require native SDT/config discovery, BSP and all separate examples
build,16KiB BRAM map/stack review, cache traffic/instruction fetch RTL simulation,
five-case routed setup/hold/pulse/route/DRC, reviewed SDRAM CDC and external I/O
constraints. No physical retiming is authorized by a host PASS. Hardware tests
must reserve or exclusively own all32MiB, log actual clocks/taps/phase/counters
and use a known failing/error-injection control. Do not assume200MHz must fail.

For copied instructions, capture the CPU PC/instruction fetch route and returned
value, not just data write/readback. For errors/timeouts, prove the BRAM recovery
path remains alive and no CPU RAM client resumes prematurely.
