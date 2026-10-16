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

## Status

This repository is being prepared for the development-kit source import. This initial commit contains only the README and licensing information; board files, IP, software, and build artifacts are not included yet.

This is an independent community project, not an official GameBub or AMD/Xilinx release. No hardware qualification is implied by this repository's initial publication.

## Upstream projects

- [GameBub hardware, FPGA sources, and firmware](https://github.com/elipsitz/gamebub)
- [GameBub documentation](https://docs.gamebub.net/)
- [GameBub core framework](https://github.com/gamebub/framework)
- [GameBub example core](https://github.com/gamebub/core-example)

## Licensing

This is a mixed-license project. Original independent documentation in this initial commit uses **0BSD**. Imported or derived GameBub material retains its applicable **CERN-OHL-S-2.0** or **GPL-3.0-only** license; other third-party material retains its own terms.

See [LICENSE.md](LICENSE.md) for the licensing policy and full license texts. GameBub names and logos remain subject to their owners' trademark rights; copyright licenses do not grant trademark permission.
