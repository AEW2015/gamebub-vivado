<!-- SPDX-License-Identifier: 0BSD -->

# GameBub packaged IP

Use the [quickstart](../../QUICKSTART.md) to register the current catalog through the board repository's installer. This import includes eight selected packages, including the combined ESP32 communications core used in the reference. It does not include every historical package from the development archive.

Each package contains `component.xml`, RTL, GUI Tcl and applicable constraints/integration documentation. Custom bus definitions are under [board_files/interfaces](../board_files/interfaces). Keep the repository layout intact: the installer registers these definitions with the selected packages.

Start with the [product guides](../../docs/vivado/README.md) and [drivers/examples](../sw_repo/README.md). See [known limitations](TODO.md) and [validation status](../../docs/vivado/validation.md). Optional metadata-only version bumps are not enabled in this catalog.
