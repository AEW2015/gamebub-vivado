<!-- SPDX-License-Identifier: 0BSD -->

# Licensing

This repository uses multiple licenses. This guide does not relicense upstream or third-party material. Per-file notices and applicable upstream licenses take precedence over general descriptions here.

## Original independent work

The original README and this licensing guide are licensed under the [BSD Zero Clause License (0BSD)](LICENSES/0BSD.txt).

Other independently authored material may use 0BSD when its author has the right to grant that license. Such files should explicitly identify `SPDX-License-Identifier: 0BSD`. Do not assume that every new or unmarked file is independent of upstream code.

The independent root quickstart, publication notes and other files explicitly marked 0BSD use that license. The imported `fpga/` tree, including drivers, examples, scripts and board definitions, retains the source tree's CERN-OHL-S-2.0 default unless a file specifies otherwise. The imported `docs/vivado/` guides are also distributed under CERN-OHL-S-2.0 unless explicitly marked otherwise. This import does not relicense them to 0BSD. No ESP32 firmware or upstream `scripts/` tree is included in this import.

0BSD permits use, modification, and redistribution, including commercial use, without requiring attribution. It includes warranty and liability disclaimers, subject to applicable law; it is not a guarantee against lawsuits.

## GameBub-derived material

Preserve the applicable license, copyright notices, source-sharing obligations, and other requirements when importing or modifying GameBub material. GameBub's published default licensing policy is:

| Upstream material | License |
| --- | --- |
| FPGA sources and hardware designs | [CERN-OHL-S-2.0](LICENSES/CERN-OHL-S-2.0.txt) |
| Firmware and scripts | [GPL-3.0-only](LICENSES/GPL-3.0-only.txt) |

See the [upstream licensing policy](https://github.com/elipsitz/gamebub#license). Explicit upstream exceptions continue to apply. These categories describe upstream material, not a blanket license applied to every future file in this repository.

The CERN and GPL texts included here are copied verbatim from GameBub's `LICENSE-CERN-OHL-S` and `LICENSE-GPL-V3` files. Including the GPL text does not mean this repository currently includes ESP32 firmware.

## Other third-party material

AMD/Xilinx software, generated products, dependencies, and other third-party material retain their own licenses and notices. Include or redistribute them only when permitted by their applicable terms. A reference to an AMD tool or IP does not grant permission to redistribute that product.

Do not replace third-party licenses or notices with 0BSD. Before importing source, identify its provenance and applicable license, retain required notices, and document any exceptions.

The application-template CMake files adapted from AMD's installed 2025.2 examples retain their MIT identifiers and AMD copyright notices. See [the MIT text](LICENSES/MIT.txt). This exception does not relicense the surrounding GameBub RTL, drivers or application code.

## Trademarks

Copyright licenses do not grant rights to GameBub, AMD, Xilinx, or other names and logos. This repository is an independent community project and does not claim endorsement by those owners.
