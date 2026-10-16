# GBAudio verification

Run [run_tests.ps1](../../../../fpga/sw_repo/drivers/gbaudio/tests/run_tests.ps1) with the installed MSYS2 UCRT GCC. The harness compiles the real core/lookup source with `-std=c11 -Wall -Wextra -Werror` and mock MMIO.

Observed2026-10-16: `GBAUDIO_MOCK_MMIO_PASS id lookup no_start_init ranges running_guard start stop heartbeat`.

Checks cover ID failure/success, nonnominal clock rejection, exact configuration lookup, no initialization/self-test writes, sample-rate derivation, invalid level rejection before writes, running-state guard, five-field configuration, start/stop command values, heartbeat key, and invalid live configuration rejecting start. This is a driver contract test, not an engine model: it does not prove watchdog elapsed time, serializer timing, output waveforms, AXI channel behavior or audible sound.

## Executed exact packaged-RTL test

[Run the Icarus regression](../../../../fpga/sw_repo/tests/rtl/audio/run_tests.py). It compiles the unchanged1.3 packaged wrapper, peripheral, engine and sine table with a functional ODDR model. The packaged clock/timing defaults are preserved: nominal29,361,979Hz, **no accelerated timer or forced DUT state**. The run simulates approximately1.2seconds and can take several minutes on the host. Compiler/run logs and source SHA-256 values are saved in the selected output directory.

Executed PASS: identity/nominal clock reads, stalled AXI R/B responses and separate AW/W, misaligned read/reserved write errors, invalid configuration rejecting start, stopped-only configuration, explicit start/stop and synchronized physical stop_n. A100ms total-duration session ends with reason4. A600ms session receives heartbeat after300ms and remains running past the initial500ms lease, but still ends at total duration with reason4. A1000ms session without heartbeat ends at the500ms lease with reason2. Those are actual engine timer cycles, not a mock software counter.

This does not qualify ODDR electrical timing, DSP waveform correctness across all channels, codec behavior, acoustic output or absolute physical oscillator accuracy. Nominal simulated time is not measured hardware time.

Required downstream verification:

1. Generate configuration and compile each app against the actual standalone BSP; native Vitis discovery/import remains a separate gate.
2. Extend exact packaged RTL coverage to all waveforms/channels and signed sample endpoints, DSP frame608cycles, falling-BCLK setup and simultaneous timeout/stop priorities. The AXI/stop/watchdog contract cases above are executed, not pending.
3. On a positively routed timing-qualified image, deliberately start a short low-level tone, confirm stop_n/default stop, remove heartbeat in a bounded longer test, verify duration/reason and stop on app exit.
4. Obtain a physical listening observation and document ESP32/DAC volume/routing. Digital frames do not establish acoustic output or calibrated loudness.

No FPGA, ESP32 or hardware programming was performed during this documentation/driver task. No new bitstream or acoustic qualification is claimed.
