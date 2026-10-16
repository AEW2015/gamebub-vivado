---
name: gamebub-vivado
description: Build, review and debug GameBub Rev4 Vivado IPI designs, packaged board/IP interfaces and bare-metal MicroBlaze V Vitis examples in the gamebub-vivado repository. Use for GameBub clocks, memory ownership, LCD/ESP32 overlays and tester applications; not general desktop Godot development.
license: 0BSD
---

<!-- SPDX-License-Identifier: 0BSD -->

# GameBub Vivado/Vitis development

Work in the user's selected checkout of `AEW2015/gamebub-vivado`. Find the root from its `fpga/board_files`, `fpga/ip_repo`, `fpga/sw_repo` and `docs/vivado` directories; do not hardcode the original author's drive letters. If this skill is installed outside the checkout, resolve these paths from the working repository, not from the installed skill directory.

## Locate the authoritative inputs

- Start with `README.md`, `QUICKSTART.md` and `docs/vivado/validation.md`. Read only the product guides needed for the task under `docs/vivado/ips`.
- Board-file version 2.0 describes physical Rev4, FPGA `xc7a100tcsg324-1`. Verify the selected part and actual board revision before programming.
- Target Vivado/Vitis 2025.2 unless the user requests migration. AMD Ross's current tested version is separate; inspect its compatibility guidance rather than silently upgrading the project.
- Treat `component.xml`, packaged RTL/XDC and driver schemas as the interface contract. Plans, previous chat and successful compilation are not proof that today's hardware works.

## Vivado IPI work

Use `fpga/board_files/install_gamebub_current_repositories.tcl` to register this checkout. Source it at the welcome screen for board discovery and again after project creation for project IP discovery. Follow `docs/vivado/getting-started.md` and `clocks-resets.md`; use `fpga/vivado/gamebub_ipi_demo` for the reproducible reference.

The reference uses MicroBlaze V/AXI at 100 MHz and ESP32 service at 200 MHz, with explicit clock-domain crossing. AXI, pixel/overlay, audio and SDRAM reference clocks have distinct roles. Propagate actual clock-wizard output frequencies instead of pasting a rounded frequency into interface metadata. Read the packaged reset polarity and clock association before wiring reset constants or relying on automation.

Validate the BD and address map before building. Include packaged constraints once; inspect active files and object matches before adding project-level constraints. Do not hide real timing paths with broad clock groups or false paths. A source or software-only change does not automatically require an FPGA rebuild.

Use the connected Vivado MCP for live tool inspection when available, or native Tcl/batch tools when appropriate. Inspect the tools actually exposed by the client; do not assume a particular MCP tool name. Never restart the user's Vivado/hardware server or take ownership of JTAG just to establish connectivity.

## Vitis templates and application changes

Read `docs/vivado/vitis-examples.md` before guiding GUI setup. Register `fpga/sw_repo` through **Embedded SW Repositories...**, not the general example Git/HLS repository dialog. Register/rescan before creating the platform.

An existing domain can retain a stale `app_list.yaml`: a template may appear in the sidebar yet fail domain validation. **Regenerate BSP and Build did not reliably refresh that list in observed Vitis 2025.2 GUI use.** Inspect the workspace index and both BSP/export lists. The reliable workaround is a new platform created after registration; a fresh workspace also worked. Preserve customized platforms and failed logs. Do not promise regeneration fixes it or modify the AMD installation to work around it.

Native application sources are generated from `fpga/sw_repo/templates/apps.json` and its canonical headers. Edit those inputs, not just `lib/sw_apps` copies. Then run:

```text
python fpga/sw_repo/tools/generate_app_templates.py
python fpga/sw_repo/tools/generate_app_templates.py --check
python -m unittest discover -s fpga/sw_repo/tests -p "test_*.py"
```

Use `fpga/vivado/gamebub_ipi_demo/test_app_templates.py` with Vitis, a matching XSA and a new output workspace to verify discovery, GUI `validate_bsp`, native creation and ELF bounds. A reused platform may itself have a stale list. Do not touch a user's platform export for an automated experiment.

The combined template is `gamebub_app_tester`: SRAM, Audio, Vibration and SDRAM pages, L/R shoulders to switch, A start, B stop. The guarded build uses `-Os` and occupies 16,352 bytes including a reserved 2-KiB stack in the reference 16-KiB BRAM. Additional features or enabled memory writes may need 32 KiB or more; check the ELF rather than placing the tester in the RAM it overwrites.

## Runtime boundaries

- SRAM/SDRAM RAM apertures are different from control registers. Addresses come from the selected platform metadata; avoid fixed lab addresses. Current memory ports are AXI4-Lite, not burst AXI4. Native external-memory linker discovery remains a known gap; BRAM-resident code can access RAM without linker regions.
- Before destructive memory tests, reserve the range, verify the full aperture, park other clients and maintain/disable caches as documented in `docs/vivado/memory-cache.md`. The settings flags acknowledge these facts; they do not enforce system-wide parking. SDRAM must be initialized before C startup if `.data`, `.bss` or stack are placed there.
- COV2 CPU pixels are two-bit `{opaque, white}`: 0 transparent, 2 black, 3 white. CPU and ESP32 menu layers are independent; preserve ESP32 priority. The tester uses a black center with transparent surroundings. The host button register reverses the native 12-bit ordering; preserve the tested conversion rather than reusing unverified masks.
- Plain vibration GPIO has no independent watchdog. Do not pause/debug the CPU during an active pulse. Keep slow rendering outside actuator intervals and stop outputs on B, timeout and app change. Audio also depends on the ESP32-configured DAC and actual audio clock.
- Installed ESP32 firmware owns power/menu/volume behavior. Do not reflash it, clear its overlay memory on a timer, or suppress menus as an unrequested shortcut.

## Evidence and handoff

For software, run relevant host tests and a native build against the selected hardware metadata. For changed RTL, exercise the actual interface and relevant failure/backpressure/CDC cases. For an FPGA release, bind the bitstream and ELF to the source revision, XSA, routed setup/hold/pulse/route/DRC reports and hashes. A compiled ELF, metadata-only XSA or passing host mock is not hardware qualification.

Program only when requested and only after identifying the target and artifacts. Keep flash/ESP32 firmware changes separate from volatile FPGA configuration. Report what was built, simulated and physically observed, plus unresolved limitations. Preserve upstream licenses; mark independent additions explicitly rather than relicensing derived work.

For the maintained guides, see [GameBub documentation](https://github.com/AEW2015/gamebub-vivado/tree/main/docs/vivado) and [agent setup](https://github.com/AEW2015/gamebub-vivado/blob/main/skills/README.md).
