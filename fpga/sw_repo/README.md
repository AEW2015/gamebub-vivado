# GameBub bare metal software repository

This repository supplies independent-core C drivers for Vivado/Vitis 2025.2. Read the [developer guide](../../docs/vivado/README.md), [memory safety rules](../../docs/vivado/memory-cache.md) and [validation status](../../docs/vivado/validation.md) before running examples.

| Driver | Hardware | Scope |
| --- | --- | --- |
| `gbesp32` | ESP32 Communications 1.14 | Identification, buttons/IRQ, diagnostics and optional CPU overlay |
| `gbsram` | SRAM Memory 1.6 | Ownership/control/test and exact RAM binding |
| `gbsdram` | SDRAM Memory 1.6 | Ownership/control/test and guarded timing access |
| `gbaudio` | DAC Audio 1.3 | Bounded test tones, heartbeat and stop |

LCD, FIFO, reset and fixed clock generators need no invented register driver. Reuse AMD `XV_tpg`, `XGpio`, `XIntc` and the MDM `uartlite`/standalone console stack. Add this folder as a LOCAL embedded software repository before creating/building the Vitis platform. Use generated SDT configuration, not hardcoded addresses from a different project.

Native **application templates** live under `lib/sw_apps`: add this software-repository root through **Embedded SW Repositories...**, then select a **GameBub -** entry under **Embedded Software Examples**. See the [sidebar walkthrough](../../docs/vivado/vitis-examples.md). These templates use normal application creation and Build, without manually copying C files.

Driver-local `examples` and BSP **Import Examples** remain a separate path. The [original workspace builder](../vivado/gamebub_ipi_demo/create_workspace.py) also creates separately openable Vitis applications and binds their platform configuration. Inspect generated config/driver lists to confirm native BSP binding.

## Source readability and maintenance

Canonical driver code is in `drivers/*/src`; BSP-import examples are in
`drivers/*/examples`. Shared app code/settings are in `templates` and
`../vivado/gamebub_ipi_demo/software/demo_program.h`. The 20 sidebar applications
in `lib/sw_apps` are generated copies: change their canonical inputs, not each
copy. See [software source conventions](../../docs/vivado/software-style.md).

File headers identify purpose and licensing; API comments describe units,
ownership and safety. Inline comments explain sequencing and limitations.
Existing AMD MIT notices are retained. AMD standalone, timer, console and other
vendor BSP libraries remain tool-supplied; this repository documents how it uses
them rather than modifying their source.

The checked-in `.clang-format` uses four spaces, a 100-column target and expanded
control flow. With `clang-format` installed (this pass used **23.1.3**):

```powershell
python fpga/sw_repo/tools/format_sources.py
python fpga/sw_repo/tools/format_sources.py --check
```

Use `--clang-format C:/path/to/clang-format.exe` if it is not on PATH. The write
command formats canonical C and regenerates the applications. `--check` changes
nothing. Formatting/comments do not change register maps, default safety flags,
scratch ranges, linker placement or FPGA hardware.

## Host and documentation checks

Run from the repository root:

```powershell
python fpga/sw_repo/tests/run_host.py --output-dir D:/builds/gamebub-host-001
python fpga/sw_repo/tools/generate_docs.py --check
python fpga/sw_repo/tools/catalog_docs.py --check
python fpga/sw_repo/tools/generate_app_templates.py --check
python fpga/sw_repo/tests/check_docs.py
python fpga/sw_repo/tools/generate_docs.py --html D:/builds/gamebub-docs-001 --doxygen C:/tools/doxygen/doxygen.exe
```

Use `python -m pip install -r fpga/sw_repo/requirements-docs.txt` in your own virtual environment for documentation tools. Doxygen is a separate executable. Generated API HTML lives under `api/html`; Markdown remains directly readable on GitHub. Host tests mock MMIO and cannot establish QSPI waveform correctness, cache behavior or physical memory access.

Driver code follows the repository FPGA licensing policy unless a file states otherwise. Preserve vendor copyrights/licenses in reused AMD software; no AMD driver has been relicensed or copied into these custom drivers. No device is programmed or flashed by the tests or workspace builder.
