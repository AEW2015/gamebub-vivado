# GBEsp32 verification

## Executed host test

Run [run_tests.ps1](../../../../fpga/sw_repo/drivers/gbesp32/tests/run_tests.ps1) from PowerShell with the installed MSYS2 UCRT GCC. It compiles real core+lookup C with `-std=c11 -Wall -Wextra -Werror`, mock AMD primitive headers, a mock register bank and a packed-pixel model.

Observed2026-10-16: `GBESP32_MOCK_MMIO_PASS id lookup irq bounds packing transparent opaque capability`.

Checks include ID failure, exact ABI, non-writing initialization/self-test, renamed/multiple-base lookup, bitmap masking, W1C calls, invalid IRQ option, diagnostic limits, last pixel, out-of-bounds rejection, no wrapped packed writes, clear transparent/opaque, and optional-capability rejection without writes. The mock is not RTL simulation; it cannot establish QSPI timing, simultaneous-event priority, CDC safety, frame packing or actual bus error response.

## Executed exact-RTL CPU contract test

[Run the Icarus regression](../../../../fpga/sw_repo/tests/rtl/esp32/run_tests.py). It compiles the unchanged packaged1.14 wrapper, endpoint and overlay source with functional OBUF/IOBUF models, once with both overlays disabled and once with CPU+AXIS overlay enabled. Source SHA-256 values and complete compiler/run logs are recorded in the selected output directory's `result.json`.

Both configurations pass: exact ID/ABI/200MHz constant, two-cycle read data pipeline, separate AW/W arrivals, held/stable R/B responses under backpressure, misaligned-read and read-only-write SLVERR, real synchronized physical press/release, level IRQ clear/reassert, and a monitored same-cycle physical change/W1C commit proving event priority. Enabled overlay checks COV2 identity, out-of-bounds index rejection, packed RAM contents, last-pixel access and index wrap. Disabled overlay checks write SLVERR and absent identity.

This test keeps serial QSPI pins idle. It does **not** verify serial protocol, pin margins, metastability, rendered overlay priority or complete stream framing; its packed-RAM checks are not a screenshot or full display simulation.

## Required downstream gates

- Compare schema and constants with wrapper/endpoint RTL; generated tables must fail on drift.
- Compile examples with actual standalone BSP and generated configuration; qualify renamed/multiple instances and Vitis import.
- Extend exact RTL coverage to serial protocol, both ESP32 overlay representations, rendered ESP-over-CPU alpha priority and full stream framing/backpressure. The CPU contract cases above are executed, not pending.
- Hardware on a timing-qualified bitstream: press/release buttons, sustained service heartbeat, physical IRQ recovery, volume overlay appears/clears over CPU graphics. Record source/BIT/XSA/ELF hashes and installed firmware version.

No hardware was accessed, no bitstream produced, and no new physical or routed timing PASS is claimed by this driver work. Earlier hardware observations are context, not evidence for freshly generated software.
