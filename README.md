<!-- SPDX-License-Identifier: 0BSD -->

# GameBub Vivado & Vitis Development Kit

Community Vivado and Vitis development kit for GameBub: board files, packaged AXI IP, MicroBlaze V drivers, example applications, and documentation for LCD, ESP32 communications, SRAM, SDRAM, audio, and vibration.

## Project scope

The development kit is intended to make it easier to build GameBub FPGA designs using Vivado IP Integrator and write bare-metal applications in Vitis.

- Vivado board definitions and interface presets.
- Packaged peripheral IP and reference block designs.
- MicroBlaze V drivers and separate example applications.
- Integration guides, simulations, and reproducible validation evidence.

The initial target is GameBub Rev4 hardware with Vivado/Vitis 2025.2. Compatibility and hardware-test status will be documented for each release.

## Getting started with Vivado 2025.2

Clone into a path without spaces:

```powershell
git clone https://github.com/AEW2015/gamebub-vivado.git C:/fpga/gamebub-vivado
```

At the Vivado welcome screen, run this in the **Tcl Console**:

```tcl
source C:/fpga/gamebub-vivado/fpga/board_files/install_gamebub_current_repositories.tcl
```

Create an RTL project, select **GameBub Rev4**, board-file version **2.0**, then source the same command again inside the project to register the IP catalog. Board-file 2.0 is not hardware revision 2.0.

See the [step-by-step quickstart](QUICKSTART.md) for the GUI flow, reference block design, Vitis applications and safety checks. No FuseSoC is required.

| Content | Location |
| --- | --- |
| Board files, presets and physical interfaces | [fpga/board_files](fpga/board_files/README.md) |
| Packaged IP | [fpga/ip_repo](fpga/ip_repo/README.md) |
| Product guides, registers and integration | [docs/vivado](docs/vivado/README.md) |
| Drivers, examples and tests | [fpga/sw_repo](fpga/sw_repo/README.md) |
| Reproducible reference design and workspace builder | [fpga/vivado/gamebub_ipi_demo](fpga/vivado/gamebub_ipi_demo/README.md) |

To select and build individual applications in Vitis, use the [Examples sidebar walkthrough](docs/vivado/vitis-examples.md). Register `fpga/sw_repo` through **Embedded SW Repositories...**; native templates are listed under **Embedded Software Examples**.

For AI-assisted development, install the portable [GameBub agent skill](skills/README.md). See [AMD Ross setup](docs/vivado/amd-ross-setup.md) for optional official agent skills and Vivado MCP integration; Ross release compatibility is separate from this repository's 2025.2 target.

Select **GameBub - App Tester** for the combined compact LCD UI with SRAM, SDRAM, audio and vibration pages. The native sidebar now provides 20 templates. Memory writes are guarded by default; see the walkthrough for prerequisites and controls. After repository updates, rescan first; if the existing platform rejects the new template, create/build a new platform. BSP regeneration alone did not reliably refresh the list in observed 2025.2 GUI use.

## Status

This is a source/software candidate targeting Vivado/Vitis 2025.2. It includes the current board package, eight selected IP packages, four custom drivers and a builder for 19 separate Vitis applications. Optional version-bumped IP packaging candidates and historical lab projects are deliberately excluded.

The reference builder validates the BD and exports a **metadata-only XSA**. It does not route a design or produce/program a bitstream. See [validation status](docs/vivado/validation.md) and [source-import verification](docs/vivado/public-import.md) for the distinction between historical SDK evidence, checks on this checkout, and outstanding hardware gates. No prebuilt BIT, ELF or XSA is included in this source import.

This is an independent community project, not an official GameBub or AMD/Xilinx release. No hardware qualification is implied by this repository's initial publication.

## Upstream projects

- [GameBub hardware, FPGA sources, and firmware](https://github.com/elipsitz/gamebub)
- [GameBub documentation](https://docs.gamebub.net/)
- [GameBub core framework](https://github.com/gamebub/framework)
- [GameBub example core](https://github.com/gamebub/core-example)

## Licensing

This is a mixed-license project. Independent documentation explicitly marked **0BSD** uses that license. Imported FPGA material, drivers and guides retain **CERN-OHL-S-2.0** unless otherwise specified. Any imported GameBub firmware/scripts must retain their applicable **GPL-3.0-only** terms; other third-party material retains its own terms.

See [LICENSE.md](LICENSE.md) for the licensing policy and full license texts. GameBub names and logos remain subject to their owners' trademark rights; copyright licenses do not grant trademark permission.
