# Reproducible GameBub IPI documentation reference

`reference_bd.tcl` is the user's revised export, retained byte-for-byte. `inventory.json` identifies its hash, 24 cells and 18 VLNVs. `create_design.tcl` reconstructs it in a fresh project, uses current board-file 2.0 and adds one explicit constant-zero tie-off for SDRAM `reconfig_hold` (the export relied on an implicit zero).

The script validates audio stop/reset and cache windows, generates IP output products and a wrapper, and exports `gamebub_demo.xsa` without synthesis or a bitstream. It never connects to hardware. Existing board/IP versions and running images remain unchanged.

```powershell
vivado -mode batch -source fpga/vivado/gamebub_ipi_demo/create_design.tcl -tclargs D:/builds/gamebub-sdk-001
vitis -s fpga/vivado/gamebub_ipi_demo/create_workspace.py D:/builds/gamebub-sdk-001/gamebub_demo.xsa D:/builds/gamebub-vitis-001
```

Use the [GitHub developer guide](../../../docs/vivado/README.md) and its [validation ledger](../../../docs/vivado/validation.md). The diagram is a software/documentation fixture, not a newly timing-qualified hardware release. It has 16 KiB BRAM; each ELF must fit its map and stack. A metadata-only XSA cannot program the board.

For native GUI example selection, use the [Vitis Examples sidebar walkthrough](../../../docs/vivado/vitis-examples.md). `test_app_templates.py` verifies actual template discovery/create/build without the original builder's manual source-import path.
