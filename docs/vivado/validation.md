# SDK validation and remaining qualification

The SDK is a software/documentation release candidate for the versioned reference. It is not a new hardware-qualified bitstream. No FPGA, ESP32 firmware or persistent flash has been programmed during this work.

This ledger records the preceding SDK qualification. The [public source-import report](public-import.md) records additional fresh Vivado/Vitis and test runs from the published checkout, including its current ELF bounds.

## Executed gates

| Gate | Result and scope |
| --- | --- |
| Reference recreation | Native Vivado 2025.2 BD validation, current IP output generation and metadata-only XSA export pass. Cache windows and audio stop/reset connection are checked. |
| Driver binding | Native Vitis 2025.2 discovers GBEsp32, GBAudio, GBSram and GBSdram through YAML/SDT and generates configuration tables with actual CSR bases. No manual driver-source fallback is used. |
| Application set | Nineteen separate application components build against the BSP. All ELF load segments fit 16 KiB BRAM; the maximum end address is 14,408 bytes. Five advanced memory applications also build with their explicit destructive/retiming guards enabled, without being executed. |
| Native example import | All four drivers pass installed Vitis 2025.2 backend Import Examples and application builds, with imported sources matching the canonical examples. This version-guarded internal backend check is not a public API guarantee or mouse-driven GUI acceptance. |
| Native application templates | All 19 GameBub application templates pass native Examples-tree discovery and public-API creation/build, with 101 imported source files checked. Maximum ELF end is 14,432 bytes in 16 KiB BRAM. See the [sidebar walkthrough and verification record](vitis-examples.md). No manual source import or post-creation linker repair is used. |
| Host driver tests | Four C11 mock-MMIO suites pass with warnings treated as errors. They cover API arguments, emitted operations, read-only identification and selected negative controls. |
| RAM registration helper | Synthetic tests cover single/both/renamed/multiple memory instances, aliases, invalid capacities, overlap rejection and existing linker regions. Real XSA extraction identifies the exact SRAM/SDRAM capacities. |
| ESP32 control RTL | Current packaged source passes both optional-overlay variants, including independent AXI AW/W, response stalls, read latency, button/W1C event ordering and optional-feature errors. QSPI remains idle in this control-contract test. |
| Memory control RTL | Exact current CSR/backend modules pass selected ownership, status/error and AXI backpressure tests. PHY telemetry is modeled; this is not SDRAM/SRAM pin or CPU-cache simulation. |
| Audio temporal RTL | Current control RTL passes at the nominal clock over real watchdog/lease intervals, without forcing timer ticks. Functional primitive models do not establish acoustic output or full DSP correctness. |
| Documentation build | Register tables bind source hashes, Doxygen API HTML builds, Markdown link/fence and checker unit tests run locally. The final source/evidence manifest records the accepted snapshot. |

## Release gates still separate

- Mouse-driven Vitis **Import Examples** and Vivado **Open IP Example Design** acceptance remain separate from the successful backend and explicit Tcl entrypoint tests.
- Native SDT RAM/linker discovery is not implemented. The checked XSA-derived application-linker helper remains necessary.
- End-to-end CPU cache/instruction transactions, QSPI waveform/firmware co-simulation and a complete hardware regression are not established by the control-contract tests.
- No routed timing/CDC/external-I/O sign-off or new physical output observations are part of this SDK build. Existing known constraints work remains open. Memory frequency/phase/tap electrical margins need separate board testing.
- GitHub Actions and optional Pages publication have not run remotely. Files must be committed/pushed in the intended repository, and Pages enabled deliberately, before an online site exists.

The first metadata-only export failed because the top-level wrapper was absent. The corrected fresh-project export generates/adds the wrapper and sets the top before exporting; the failed output/log is preserved rather than used as a release artifact.

The installed AMD BSP emits excess-initializer warnings in its generated MicroBlaze V configuration and linker warnings about RWX bare-metal load segments. These are not hidden. Custom drivers compile under host warnings-as-errors; hardware/cache validation remains separate from the vendor BSP build result.

Optional version-bumped IP candidates package the same RTL/constraints with generated guides and SDK payloads; they do not replace the installed catalog. Native IPX integrity checks cover metadata packaging, not new-VLNV BSP or hardware qualification. SDT-only software file groups retain legacy MDD warnings, and inherited memory-interface clock-association warnings remain documented rather than suppressed.

Use the [implementation plan](../../fpga/board_files/IP_DOCUMENTATION_DRIVER_PLAN.md) for outstanding work and the [software repository](../../fpga/sw_repo/README.md) for reproducible tests. Full logs, source hashes and SDK artifacts are bound by the local handoff manifest; do not substitute historical app-tester bitstream results for these gates.
