# SRAM verification and release status

The driver host test mocks MMIO to prove ID/capacity/capability matching,
non-destructive initialization, empty lookup, range/alignment/consent rejection,
CPU-ready checks, independent byte lanes and failure on mismatched identity.
It does not model the PHY, arbitration latency, external AC timing or CPU caches.
Hardware RunTest happy/timeout/state coverage is a separate testbench gate; do
not equate a mock register model with RTL simulation.

Run the shared host harness and Python helper tests from repository root:

```powershell
python fpga/sw_repo/tests/run_host.py --help
python fpga/sw_repo/tools/test_memory_regions.py
```

Before hardware release require native BSP discovery/config review, separate
example builds and section/map checks, CPU cache refill/writeback and instruction
fetch simulation, positive routed setup/hold/pulse, zero failed routes/DRC,
CDC and external-I/O review. Test an explicitly reserved region first, then
full-memory destructive patterns only when no live client uses SRAM. Exercise a
known-error control and check the tester reports it. Capture offsets, pattern,
read/write/completion/error counters, timing settings and artifact hashes.

This documentation/software work does not change or program the FPGA or ESP32.
