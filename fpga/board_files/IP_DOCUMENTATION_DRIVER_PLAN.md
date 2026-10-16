<!-- SPDX-License-Identifier: 0BSD -->

# Documentation and driver roadmap

The public source import contains GitHub-native guides for the five independent custom cores, four SDT/CMake drivers, host and selected RTL tests, and a reproducible Vivado/Vitis reference. LCD has no invented CSR driver; examples reuse AMD's TPG, GPIO, interrupt controller and JTAG console drivers.

See the [developer guide](../../docs/vivado/README.md), [software repository](../sw_repo/README.md) and [executed qualification status](../../docs/vivado/validation.md).

## Remaining release gates

- Manual GUI acceptance of Vitis Import Examples and Vivado Open IP Example Design, separate from backend/Tcl tests.
- Native SDT RAM/linker discovery; retain the checked XSA-derived helper until proven.
- End-to-end processor cache/instruction and memory PHY tests, complete QSPI/ESP32 behavior and stream/display verification.
- Routed timing, CDC, external-I/O review and physical peripheral qualification for a named final bitstream.
- Native BSP qualification of any future version-bumped packages before changing the current catalog.
- Deliberate GitHub Pages publication if desired; Markdown is already readable without a site build.

Do not treat a build, packaging integrity check or host mock PASS as hardware qualification. Keep destructive memory and actuator tests opt-in and preserve source/artifact identities in release evidence.
