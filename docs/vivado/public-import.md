<!-- SPDX-License-Identifier: 0BSD -->

# Public source import

This checkout is a curated source import of the GameBub Vivado/Vitis software/documentation candidate. It is not a dump of the development workspace or a new hardware-qualified release.

This page records the initial import. The subsequent [native Vitis application-template update](vitis-examples.md) adds sidebar discovery and creation/build for all 19 examples; its executed results are recorded separately.

## Included

- Rev4 board-file 2.0, custom interface definitions and the current-repositories installer.
- Eight current packaged IP versions; their RTL, constraints and IP metadata are preserved.
- The 37-page developer guide, plus this publication note.
- Four SDT/CMake drivers, standalone examples, host/RTL tests and the 19-application workspace builder.
- A portable Vivado reference recreation, schema/catalog documentation generators and a portable-checks CI workflow.

## Deliberately excluded

Historical board/IP versions, experimental version-bumped IP packages, unrelated lab projects, private workstation outputs, simulation/build caches, prebuilt BIT/ELF/XSA/DCP files and generated API HTML are not imported. Unreferenced generated AMD Clocking Wizard outputs are excluded; its packaged `serdes4_mmcm_ip.xci` configuration is retained for Vivado to regenerate. ESP32 firmware and SD-card assets are not part of this upload. The archived development-only SDK freezer is omitted; public reference and packaging tools remain available.

The reference `reference_bd.tcl` retains the original export hash recorded by its inventory. The public installer only adjusts historical-repository guidance; it retains the same current version set. Simulation runners discover Icarus executables on PATH, retaining the Windows fallback. The packaging tool includes this repository's mixed-license files in its output. Retained package files, custom RTL/constraints and IP metadata remain byte-identical to the SDK snapshot; generated Clocking Wizard outputs are regenerated rather than published.

## Verification scope

The [validation ledger](validation.md) describes the preceding SDK's native Vitis builds/imports and selected RTL tests. It is not a claim that a GitHub-hosted runner has built Vivado hardware. The following checks were executed locally on this public checkout on 2026-10-16; no hardware was programmed.

| Source-import check | Result |
| --- | --- |
| Native Vivado 2025.2 catalog discovery/IPX integrity | All eight packages pass. Nine inherited association/FREQ_HZ warnings remain; no package ERROR. |
| Fresh reference BD creation and validation | Pass, including audio reset, cache windows and explicit SDRAM hold tie-off. |
| Clean generated-output experiment | Pass: after excluding 28 generated Clocking Wizard files, a second fresh reference regenerated its HDL from XCI and exported a metadata-only XSA. |
| Native Vitis 2025.2 BSP/application builds | Four custom drivers discovered; all 19 applications build. Maximum ELF load end is 14,432 bytes, within 16,384-byte BRAM. Applications were not executed. |
| C11 host driver suites | All four pass with warnings treated as errors. |
| Python metadata/documentation tests | Eleven tests pass, plus seven memory-linker helper cases. |
| ESP32 control RTL | Both optional-overlay variants pass, with QSPI pins idle. |
| Memory control RTL | SRAM and SDRAM CSR/backend cases pass, with PHY telemetry modeled. |
| Audio control RTL | Nominal-clock watchdog/lease/duration test passes without forcing timer ticks. |
| Documentation | Register tables, all five interface catalogs, Markdown links and Doxygen/offline HTML build pass. |

The Vitis build used the first fresh metadata export. The second export proves regeneration without shipping the generated clock HDL; neither export is a bitstream. Selected RTL tests are not end-to-end CPU/PHY/display or acoustic verification.

Native catalog warnings concern physical bus/clock associations, IDELAY reference association and standalone video-status clock metadata. The reference validation also emits inherited SmartConnect/empty-address-query/ECC notices; Vitis emits vendor generated-configuration and RWX load-segment warnings. These are not silently suppressed. Inherited source whitespace is retained to keep imported packages byte-identical.

See the [source manifest](../../SOURCE_MANIFEST.json) for hashes and scope. Raw workstation logs, generated projects and compiled artifacts remain outside Git; GitHub Actions and mouse-driven GUI acceptance are separate, unexecuted publication gates.

Full release qualification still needs the integration/hardware gates in the ledger. The example XSA export is metadata-only; it cannot configure a board.
