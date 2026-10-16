<!-- SPDX-License-Identifier: 0BSD -->

# GameBub in the Vitis Examples sidebar

These are native **embedded application templates** for Vitis Unified IDE **2025.2**, MicroBlaze V and the standalone OS. They do not require the workspace builder to copy sources manually. The same software repository supplies both the custom BSP drivers and the templates.

## 1. Get the source

Clone the repository into a path without spaces, or pull the update in your existing clone:

```powershell
git clone https://github.com/AEW2015/gamebub-vivado.git C:/fpga/gamebub-vivado
```

Do not clone into an existing directory. For an existing clone, save your changes before using `git pull` there.

## 2. Register the embedded software repository

Open or create a Vitis workspace first. In Vitis 2025.2, open the Command Palette (**Ctrl+Shift+P**) and select **Embedded SW Repositories...**.

Add this directory under **Workspace Repositories**:

```text
C:/fpga/gamebub-vivado/fpga/sw_repo
```

Alternatively use **Global Repositories (available across workspaces)** if you want the same local checkout available in future workspaces. Choose **Rescan Repositories**, then **OK**. This adds a local software-repository path; it does not upload source or configure an FPGA.

Use the `sw_repo` directory, not its `drivers` subdirectory or the Vivado `ip_repo`. The Examples sidebar's separate Git-repository controls for other example types are not a replacement for registering this embedded software repository. Clone/pull the GitHub repository normally, then rescan the local embedded repository.

## 3. Create/build the platform

Create a **Platform Component from XSA**, selecting the matching GameBub hardware export, **MicroBlaze V**, **standalone** and a domain name of your choice. In that domain's BSP settings, select the MDM JTAG UART for stdin/stdout (`mdm_1` in the reference design).

Build the platform. The relevant peripherals should bind to `gbesp32`, `gbaudio`, `gbsram` and `gbsdram` rather than a generic fallback. A platform created before adding the repository may need BSP regeneration/rebuild; prefer a fresh platform when learning, and do not reset someone else's customized BSP without saving it.

The supplied [reference creation script](../../fpga/vivado/gamebub_ipi_demo/README.md) exports a metadata-only XSA without programming hardware. It is enough to build software, but not to run it on a board.

## 4. Select and build an example

1. Open **View > Examples** using the left toolbar or menu.
2. Expand **Embedded Software Examples** and search/filter for **GameBub**. Look for titles starting with `GameBub -`; there is no requirement for a separate top-level GameBub repository heading.
3. Select an example and choose **Create Application Component from Template**.
4. Give the component a name, select your platform and standalone domain, then finish.
5. Select the new component in Flow Navigator and click **Build**.

The native creation flow copies the selected template and generates its metadata. CMake binds the relevant CSR addresses from the selected platform. There is no lab address map to paste into C code. Creating/importing and building are normal separate IDE actions; simply selecting a template does not run a build or download an ELF.

### Templates

All IDs begin with `gamebub_`. The suffixes below also match the existing command-line example names.

| Suffix | Purpose / prerequisites |
| --- | --- |
| `app_tester` | Combined compact LCD tester: SRAM, Audio, Vibration, SDRAM; all six peripheral classes required; memory writes guarded |
| `hello_jtag` | Hello-world through the selected console; MDM UART and BRAM |
| `esp32_poll` | Read buttons; combined ESP32 core |
| `qspi_diagnostics` | Read ESP32 diagnostics; not a lossless QSPI trace |
| `cpu_overlay` | Draw a CPU panel under ESP32 overlay priority; CPU-overlay option required |
| `custom_demo` | Composition example with buttons and CPU overlay |
| `buttons_irq` | Level-high ESP32 interrupt directly routed to one AXI INTC |
| `tpg_bars`, `tpg_patterns` | AMD TPG stream into the configured LCD/FIFO path |
| `audio_tone` | Bounded, low-level tone; reference audio clock and configured ESP32/DAC |
| `vibration_pulse` | Bounded pulse; one two-bit all-output GPIO physically bound to vibration |
| `sram_probe`, `sdram_probe` | Read-only control identification, not a physical RAM test |
| `sram_scratch`, `sdram_scratch` | Reserved-range tests, disabled by default |
| `sram_instruction`, `sdram_instruction` | Copied-instruction experiments, disabled by default |
| `sram_test`, `sdram_test` | Controller test-engine experiments, disabled by default |
| `sdram_timing` | Parked-client retiming experiment, disabled by default |

## Safety and selection rules

### Combined App Tester

Select **GameBub - App Tester** (`gamebub_app_tester`) for the combined UI:

- L/R shoulders select SRAM, Audio, Vibration or SDRAM.
- A starts the selected test; B stops. Outputs stop when switching apps.
- The compact black panel has white text; the surrounding CPU layer is transparent so TPG bars remain visible. The independent ESP32 menu layer retains priority.
- Audio is a 440-Hz, 5% level tone for nominally 250 ms. Vibration is a nominal 100-ms forward/coast pulse. GPIO vibration has no independent hardware watchdog; do not halt/debug the processor during a pulse.
- SRAM/SDRAM show **GUARDED**, not PASS, until `GB_ALLOW_DESTRUCTIVE`, `GB_BRAM_EXECUTION_CONFIRMED` and a nonzero, word-aligned `GB_SCRATCH_BYTES` are set in the imported `gamebub_settings.h`. Set `GB_SCRATCH_OFFSET` to a reserved range and park all other clients first. The same offset/length is used for both RAMs, so it must fit both.
- Enabled memory tests use uncached CPU accesses in 256-byte chunks: zero, ones, address, inverted-address and byte-lane checks. The progress bar covers the configured scratch range only, not the entire memory unless explicitly configured. This is not an exhaustive memory/timing qualification. Cache is flushed and disabled when starting a memory test; it is not automatically re-enabled. SDRAM is left CPU-owned.

The selected platform needs one combined ESP32 core with the COV2 two-bit CPU overlay enabled, DAC audio, SRAM and SDRAM control and memory apertures, AMD TPG and one two-bit all-output vibration AXI GPIO. The TPG must already be wired through the correct FIFO/LCD path, and the ESP32 overlay stream connected. The template cannot create those hardware connections. It links into local BRAM and uses a scanline renderer instead of a large framebuffer.

The combined application's CMake adds `-Os` even in Debug to fit the reference 16-KiB BRAM. The guarded build loads through byte 16,352, including its reserved 2-KiB stack, leaving only 32 bytes of unallocated BRAM. Disabling optimization, enabling destructive tests or adding features may require more BRAM; use 32 KiB or more for development and check linker usage rather than moving test code into the RAM being tested.

After adding/updating the repository, **rescan repositories, Regenerate BSP and Build the platform**, then create the application. Existing domains cache their supported-template list; a sidebar entry alone does not refresh it.

- **Build never runs hardware.** Deliberately running the audio or vibration ELF actuates the board. The GPIO motor has no independent CPU-hang watchdog.
- Memory/retiming examples print a disabled/refusal result by default, not PASS. Before editing the imported application's `gamebub_settings.h`, verify its entire memory mapping, reserve the scratch range, park all other masters and satisfy the [cache/ownership requirements](memory-cache.md). These flags acknowledge preconditions; they do not park other hardware automatically.
- RAM bases come from the selected BSP's generated secondary `reg` macros. Physical capacities follow the current fixed controller contract (512 KiB SRAM / 32 MiB SDRAM), not a measurement of your Address Editor window. Verify the full aperture before enabling destructive tests.
- Templates require a unique LMB BRAM boot region and link there, with a 2 KiB stack and no heap. External RAM linker registration is not required for these BRAM-resident examples, and native SDT external-memory linker discovery is not claimed.
- Each required peripheral class must be unambiguous. Multiple GPIOs, TPGs or instances of a required custom core cause an explicit selection error rather than guessing. Create an instance-selection variant for those designs.
- The IRQ template checks generated interrupt flags/channel and resolves the INTC parent in the selected domain's Vitis 2025.2 `hw_artifacts/*_baremetal.dts`. Unsupported/missing metadata fails clearly; it does not silently assume interrupt zero.
- Software cannot establish that a GPIO or stream is physically wired correctly. Use the matching reference/validated BD and a timing-qualified bitstream before running. Console output, compilation and host mocks are not physical qualification.

## Troubleshooting

**Nothing listed:** check the exact `fpga/sw_repo` path, rescan the embedded repositories and reopen the Examples view. If necessary restart Vitis. Do not change the AMD installation's `sw_apps` directory.

**Old GameBub code selected:** inspect the BSP driver paths and remove/reorder obsolete duplicate GameBub repository entries after saving your work. Keep unrelated AMD/third-party repositories intact. Rescan and rebuild the affected platform rather than assuming a matching driver name proves the desired checkout was used.

**Template listed but creation/build fails:** read the first missing-driver/memory/metadata error. The platform must contain the selected example's peripherals. Bind custom drivers and rebuild the BSP before retrying in a new component. Preserve the failed component/log when investigating.

**"Not a valid template name" despite being listed:** the platform's generated `app_list.yaml` predates the repository update. In the platform editor, select the standalone domain's Board Support Package, click **Regenerate BSP**, then **Build** the platform and retry. Do not edit the generated list or the AMD installation manually.

**Address/instance selection failure:** use one supported instance per required peripheral class, or make an explicit application-specific selection. Renamed instances are supported; ambiguous multiple instances are not selected automatically.

## Automated native discovery/build verification

From a Vitis-configured terminal at this repository's root:

```powershell
vitis -s fpga/vivado/gamebub_ipi_demo/test_app_templates.py C:/fpga-builds/gamebub-reference-001/gamebub_demo.xsa C:/fpga-builds/gamebub-native-templates-001
```

Use a new workspace. This lists native embedded templates, creates/builds all 20 using `create_app_component(template=...)`, checks ELF bounds and writes `template-evidence.json`. It does not manually import source or fix addresses/linkers after creation, and never connects to hardware. Add repeatable `--app hello_jtag --app esp32_poll` options to select a subset. This script is optional; sidebar users do not need it.

Native backend discovery/build is tested separately from mouse-driven acceptance of every GUI action. See [validation status](validation.md) for the recorded scope.

### Executed verification (2026-10-16)

The added App Tester passes native discovery (20 templates visible), the GUI's `validate_bsp` gate, native application creation and ELF build. Host tests exercise both guarded and opted-in mocked memory paths, buttons, rendering and actuator shutdown. See the [App Tester verification record](app-tester-validation.json). This template has not been run on physical hardware; the earlier compact UI's hardware observations do not qualify this new package automatically.

All **19** templates are advertised by the native Examples-tree service and create/build successfully through the public Vitis API. The final run verified **101 imported source files**, allowing only Vitis's normal application-name/library substitutions in CMake. Maximum ELF load end is **14,432 bytes**, within the reference's 16 KiB BRAM.

The final all-template run reused an owned BSP built during the preceding fresh-platform run, with the exact matching XSA. There was no manual source import, address patch or post-creation linker repair. Two earlier IRQ-metadata failures are preserved and explained in the [machine-readable verification record](native-template-validation.json). All destructive/retiming paths remained disabled, and no hardware was run. Manual mouse-driven GUI acceptance remains a separate check.

Portable checks also exercise renamed memory instances, non-reference addresses, missing RAM apertures, ambiguous GPIO selection, IRQ flags/parent mismatch, unsuitable motor GPIO configuration and external-memory boot rejection. Generated templates are checked against canonical source in CI.

For developer iteration only, `--platform-export` can reuse an owned, matching `gamebub_platform` export. The verifier requires the exact XSA and native driver headers. Vitis may refresh that export's domain metadata during application creation; do not point this option at someone else's working platform.
