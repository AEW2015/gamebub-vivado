<!-- SPDX-License-Identifier: 0BSD -->

# CDC constraint package update — 2026-10-16

Release marker: `20261016_cdc2`. Physical board file remains **2.0**. ESP32 **1.14** and SDRAM **1.6** retain their VLNVs, register maps and RTL; each package's `coreRevision` increases to **2**. This is a constraint-packaging repair, not a new PHY or software ABI.

## What changes

- ESP32: replace the rejected procedural `if` in `esp32_cdc.xdc` with pure XDC. The optional CPU-overlay enable exception applies only to its first synchronizer D pin. The second stage remains timed.
- SDRAM: include `constraints/sdram_cdc.xdc` as an implementation-only, LATE, core-scoped input. Retain the established 16-ns request / 20-ns response flight budgets and 16-ns Gray-meter budgets. Explicit 8-ns skew checks cover those buses. Only named first-stage synchronizer data pins and dedicated reset-release pipe asynchronous pins are excepted. Normal PHY and intra-clock paths remain timed; the established command-to-serializer/read uncertainty margins are retained.
- The repository installer prints `GAMEBUB_CONSTRAINT_RELEASE=20261016_cdc2`. The reference generator checks that both packaged XDC files are discovered.

No board-pin change, clock-frequency reduction, blanket asynchronous clock group, memory-data false path or tool-installation patch is part of this update. External SDRAM/SRAM/LCD/QSPI I/O timing qualification remains separate; this repair does not invent delays for unspecified board/device timing.

## Start a new build from the Git checkout

Update a clean clone normally; preserve local changes first. In Vivado 2025.2 at the welcome screen, substituting your clone location:

```tcl
source D:/codex_archive_2026/gamebub-vivado-public/fpga/board_files/install_gamebub_current_repositories.tcl
```

Create a new project using **GameBub Rev4, board-file 2.0**, then source the same installer again inside that project. Confirm the printed release marker. Do not accidentally point at the older development checkout (`.../gamebub/gamebub-source/...`); C001 used that older repository location.

Add the same IP interfaces and clocks as before. Review the sources/compile order: both `esp32_cdc.xdc` and `sdram_cdc.xdc` must be present with the intended core scope and late order. No project-level duplicate of these CDC constraints is needed.

To generate the repository's documented reference project and metadata XSA in a new folder, from the checkout root:

```powershell
& C:/Xilinx/2025.2/Vivado/bin/vivado.bat -mode batch -source fpga/vivado/gamebub_ipi_demo/create_design.tcl -tclargs C:/fpga-builds/gamebub-cdc2-reference
```

That script does not run synthesis/implementation or program hardware. Open the generated `.xpr` and run your normal build. A timing-clean result is still required; the original C001 route also had one genuine **−0.039 ns TPG internal** setup violation, which these CDC fixes must not conceal.

## Existing project caution

Same-version IP updates can leave generated products or cached DCPs stale. Prefer a new project for initial verification. For a private copy of an existing project, refresh the catalog, review **Report IP Status**, upgrade/regenerate the changed IP as offered, and rebuild affected synthesis/implementation products. If Vivado does not pick up the changed revision, recreate those IP instances in the private copy. Do not hand-edit generated `.gen` files or delete somebody else's project to force an update.

## Evidence boundary

The original report was WNS **−3.487 ns**, TNS **−498.637 ns**, 1,558 failing endpoints. Most were mailbox/Gray-meter/reset CDC paths without their intended exceptions/budgets; the overlay exception had been rejected by the XDC parser.

`fpga/vivado/gamebub_ipi_demo/validate_routed_cdc.tcl` can inspect these packaged XDCs against an existing routed checkpoint without changing the source project. Use a new output directory. It checks real endpoint matches and retained payload budgets and writes reports/checkpoint. This tests constraint application on existing placement/routing, not a fresh routed build or exhaustive runtime-clock qualification. Read the [execution record](cdc-constraint-validation.json) for the actual achieved gates.
