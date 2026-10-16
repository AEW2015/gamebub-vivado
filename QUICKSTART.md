<!-- SPDX-License-Identifier: 0BSD -->

For the `20261016_cdc2` IP constraint repair and fresh-project checks, see the [CDC update guide](docs/vivado/cdc-constraint-update.md). The board remains Rev4 / board-file 2.0.

# Vivado and Vitis 2025.2 quickstart

## Requirements

- Vivado **2025.2**, including Artix-7 support; target part `xc7a100tcsg324-1`.
- Vitis **2025.2** for MicroBlaze V standalone applications.
- A checkout in a path **without spaces**, for example `C:/fpga/gamebub-vivado`.
- Git; Python with [documentation requirements](fpga/sw_repo/requirements-docs.txt) for optional checks.

Use your own checkout/output paths below. Vivado commands belong in its Tcl Console; shell commands belong in a terminal configured for the respective AMD tool. No hardware connection is needed to create the project or build software.

## 1. Register the board files

Start Vivado 2025.2 with no project open. In the Tcl Console:

```tcl
set gamebub_root C:/fpga/gamebub-vivado
source $gamebub_root/fpga/board_files/install_gamebub_current_repositories.tcl
get_board_parts -quiet gamebub.org:gamebub_rev4:part0:2.0
```

The final command should return `gamebub.org:gamebub_rev4:part0:2.0`. If not, check the path and restart Vivado before retrying. Registering at the welcome screen makes the board available in the New Project wizard.

## 2. Create a GUI project and register the IP

1. Choose **Create Project**, a new project directory and **RTL Project**. You can select **Do not specify sources at this time**.
2. On **Default Part**, select **Boards**, search **GameBub**, and choose **GameBub Rev4**, file version **2.0**. Leave Board Rev set to **Latest**.
3. Finish creating the project.
4. Run the helper again in the Tcl Console:

```tcl
source C:/fpga/gamebub-vivado/fpga/board_files/install_gamebub_current_repositories.tcl
get_property BOARD_PART [current_project]
get_ipdefs -all gamebub.org:ip:*
```

The second helper call sets this project's IP repository paths. It preserves unrelated IP paths and does not change an existing project's selected board or upgrade its IP.

Create a block design using **IP Integrator > Create Block Design**. The catalog should contain:

| IP | Supported version |
| --- | --- |
| ESP32 communications | 1.14 |
| LCD AXI4-Stream | 1.5 |
| SRAM memory | 1.6 |
| SDR SDRAM memory | 1.6 |
| DAC audio | 1.3 |
| Standalone ESP32 IRQ gate / QSPI | 1.2 / 1.2 |
| Video status | 1.1 |

Use the combined ESP32 core in the reference; the two standalone packages are retained for compatibility, not added beside it on the same physical pins. Board definitions also describe physical interfaces for which this repository does not supply a controller, such as the cartridge and HDMI buses.

## 3. Use the reference or wire your own design

For a manual design, follow the [integration guide](docs/vivado/getting-started.md) and [clock/reset table](docs/vivado/clocks-resets.md). The reference uses a 50 MHz oscillator, 100 MHz processor/AXI, 200 MHz ESP32 service/IDELAY reference, and a separate pixel MMCM. Start with ordinary AMD Clocking Wizard and Processor System Reset IP; do not infer clock domains from interface names alone.

The easiest complete reference is the Tcl recreation. From this repository's root, in a Vivado-configured terminal:

```powershell
vivado -mode batch -source fpga/vivado/gamebub_ipi_demo/create_design.tcl -tclargs C:/fpga-builds/gamebub-reference-001
```

The output directory must not already exist. On Windows, use the installed `vivado.bat` path if `vivado` is not on PATH. The script creates and validates a project, generates IP and a wrapper, and exports `gamebub_demo.xsa`. Open `C:/fpga-builds/gamebub-reference-001/gamebub_demo.xpr` to inspect the BD in the GUI.

**This command stops before synthesis/implementation.** It does not generate a bitstream or program hardware. Before programming a design built from this source, verify constraints, routed setup/hold timing, DRC, CDC and I/O timing. Physical pin presets alone are not timing sign-off.

For your own BD, save a reviewable export in Vivado:

```tcl
validate_bd_design
save_bd_design
write_bd_tcl -force C:/fpga-builds/review_bd.tcl
```

## 4. Build the Vitis examples

For native sidebar selection, follow [GameBub in the Vitis Examples sidebar](docs/vivado/vitis-examples.md): add `fpga/sw_repo` through **Embedded SW Repositories...**, build your platform, then select a **GameBub -** template under **Embedded Software Examples** and create/build the application. The templates are separate from BSP driver Import Examples.

The original scripted workspace builder is also available:

From a Vitis-configured terminal, at the repository root:

```powershell
vitis -s fpga/vivado/gamebub_ipi_demo/create_workspace.py C:/fpga-builds/gamebub-reference-001/gamebub_demo.xsa C:/fpga-builds/gamebub-vitis-001
```

Use a new workspace directory. The script registers `fpga/sw_repo` locally, creates a standalone platform, verifies native BSP driver discovery and builds 19 separate application components. Open that workspace in Vitis to study each component. To build only a subset, append repeatable options such as `--app hello_jtag --app esp32_poll`; repeatable options avoid Windows batch comma-parsing issues.

Start with `hello_jtag`, then `esp32_poll`. A hardware run needs a matching, timing-qualified bitstream as well as its XSA and ELF. The metadata-only XSA cannot configure an FPGA. The builder does not download or run applications.

The custom RAM spans are registered through the checked XSA-derived linker helper; native SDT RAM/linker discovery remains an open integration item. See [memory ownership/cache rules](docs/vivado/memory-cache.md) before running memory examples. Destructive tests are disabled by default and require explicit reservation/ownership acknowledgements. Deliberately running audio/vibration applications actuates the board.

For manual Vitis platform/repository setup, separate application purposes and JTAG console guidance, see the [Vitis workflow](docs/vivado/vitis-workflow.md).

## 5. Optional portable checks

```powershell
python -m pip install -r fpga/sw_repo/requirements-docs.txt
python fpga/sw_repo/tests/run_host.py
python -m unittest discover -s fpga/sw_repo/tests -p 'test_*.py'
python fpga/sw_repo/tools/test_memory_regions.py
python fpga/sw_repo/tools/generate_docs.py --check
python fpga/sw_repo/tools/catalog_docs.py --check
python fpga/sw_repo/tests/check_docs.py
```

The host driver tests need a C11 GCC compiler. Documentation HTML also needs Doxygen. Mock-MMIO and metadata checks are not substitutes for physical peripheral tests; read the [qualification status](docs/vivado/validation.md).

For a read-only native catalog check in a fresh Vivado batch session:

```powershell
vivado -mode batch -source fpga/vivado/gamebub_ipi_demo/validate_catalog.tcl
```

This checks discovery and IPX integrity for all eight packages; it does not synthesize or change them.
