# Build and study the Vitis examples

Use Vitis Unified IDE 2025.2, an XSA from the matching diagram and the [software repository](../../fpga/sw_repo/README.md). The reference script exports hardware metadata only; you still need a matching, timing-qualified bitstream before running on a board.

## Create components

For the native Examples sidebar, follow the [application-template walkthrough](vitis-examples.md). Register the same `fpga/sw_repo` root through **Embedded SW Repositories...**, then create an application from a **GameBub -** template. The original workspace-builder path below remains available.

Create a platform from XSA, select the MicroBlaze V processor and standalone OS, and select MDM for stdin/stdout. Add `fpga/sw_repo` as a **workspace-local embedded software repository** before building the platform. Inspect the generated BSP driver list and configuration: loading a YAML file into a folder is not proof that SDT matched the device.

Each demo should appear as a separate application component. The automated entrypoint is:

```powershell
vitis -s fpga/vivado/gamebub_ipi_demo/create_workspace.py D:/builds/gamebub-sdk-001/gamebub_demo.xsa D:/builds/gamebub-vitis-001
```

The workspace builder uses metadata from the supplied XSA, imports source into fresh application components and builds without connecting to hardware. Inspect its JSON build evidence for what actually passed. It must not silently replace a custom driver with manually copied source while reporting native BSP discovery as passed.

Control interfaces may occupy a 64 KiB Address Editor window even when the implemented register decode uses 4 KiB or 8 KiB. Do not assume every unused address in the allocated window causes an error: wrapper address truncation can create aliases. Use only the documented offsets and keep CSRs uncached.

## Learning order

| Application | Purpose | Physical side effects |
| --- | --- | --- |
| `hello_jtag` | Console and processor execution | None |
| `esp32_poll` | Identify core, read buttons/status | No output changes |
| `buttons_irq` | Device pending latch and INTC path | Clears CPU event latch; no QSPI service changes |
| `tpg_bars`, `tpg_patterns` | Configure AMD TPG and LCD stream | Changes display |
| `cpu_overlay` | Transparent/opaque CPU pixels below ESP32 | Changes display |
| `audio_tone` | Bounded low-level test tone | Audible output; requires deliberate run |
| `vibration_pulse` | Short forward/coast GPIO pulse | Motor activity; requires deliberate run |
| `sram_scratch`, `sdram_scratch` | Reserved-region read/write verification | Destructive to selected RAM bytes |
| Memory instruction/test/timing examples | Advanced ownership/cache/controller study | Destructive; follow individual safety preconditions |

Availability and exact build results belong in [validation status](validation.md), not in an assumed completed list. Some examples are callable functions imported by the workspace builder; standalone `main` wrappers bind the platform configuration. Unsupported advanced functions must return an explicit error, not print PASS.

## JTAG execution

Configure the FPGA first, then select the correct MicroBlaze V hart in XSDB/Vitis and download the matching ELF. Do not hardcode target number 5: cable/device ordering changes. Open the MDM JTAG console and resume the processor. There is no baud-rate setting for JTAG UART.

No programming command is included in the build script. Avoid unbounded printing in ISRs; a stopped host can fill the JTAG UART FIFO. Hardware tests require the exact bitstream/XSA/ELF identity and a recovery image. Persistent flash and ESP32 firmware are outside this software build.
