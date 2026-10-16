<!-- SPDX-License-Identifier: CERN-OHL-S-2.0 -->

# Software source conventions

Drivers, examples and native Vitis templates use file-purpose headers, retained
SPDX identifiers, and a short pointer to `LICENSE.md` at repository root. Missing
notices in the imported custom software have been marked under the existing
FPGA-tree licensing policy, not relicensed. AMD-derived CMake retains its MIT
identifier and original notices.

## Where to make a change

| Area | Canonical source | What its comments explain |
| --- | --- | --- |
| Custom BSP libraries | `fpga/sw_repo/drivers/*/src` | API units, runtime identity, ownership and limits |
| BSP Import Examples | `fpga/sw_repo/drivers/*/examples` | Setup, guarded operations and expected evidence |
| Native sidebar apps | `fpga/sw_repo/templates`, shared `demo_program.h` | Controls, safety switches, UI and actuator scheduling |
| BSP/application build | Driver CMake/YAML and template CMake | SDT properties, dependencies, instance selection and BRAM placement |
| Generated sidebar copies | `fpga/sw_repo/lib/sw_apps` | File purpose and canonical generator; do not edit independently |

The common demo implementation is
[`demo_program.h`](../../fpga/vivado/gamebub_ipi_demo/software/demo_program.h).
The native application generator is
[`generate_app_templates.py`](../../fpga/sw_repo/tools/generate_app_templates.py).
AMD standalone, `xiltimer`, console, GPIO, interrupt and TPG libraries are supplied
by the installed tools/platform. They are not custom GameBub library sources to
reformat or relicense here.

## Readability rules

- Four-space C indentation, a 100-column target, separate definitions, and no
  compressed multi-statement control flow. The formatter does not add braces or
  rewrite program logic.
- Public API comments specify units, prerequisites, side effects and limitations.
  A read-only identity check is never described as a RAM/PHY test.
- Inline comments explain why ordering matters: mailbox sequences, coherent
  snapshots, cache maintenance, ownership, overlay index/data writes and stop
  conditions. Avoid comments that only repeat the next assignment.
- Preserve existing notices. A license pointer supplements the SPDX identifier;
  it does not replace the applicable license or third-party terms.

## Format and regenerate

From repository root, with `clang-format` installed (validated here with 23.1.3):

```powershell
python fpga/sw_repo/tools/format_sources.py
python fpga/sw_repo/tools/format_sources.py --check
```

Pass `--clang-format C:/path/to/clang-format.exe` if needed. The write command
formats only canonical C inputs and then regenerates all native apps. The check
command is read-only. To regenerate copies without formatting:

```powershell
python fpga/sw_repo/tools/generate_app_templates.py
```

## What did not change

No C code tokens changed in this readability pass: 108 existing C/header/include
files were compared with the previous Git revision after ignoring comments,
whitespace and escaped line continuations. This is a source-level check, not
compiler or hardware equivalence proof.

Register maps, memory sizes, safety defaults, scratch ranges, linker decisions
and hardware are unchanged. In particular, App Tester still overwrites its
configured 4-KiB scratch ranges only after A is pressed; other guarded examples
retain their conservative defaults. A cache/parking acknowledgement is not an
automatic system-wide safety mechanism.

Run the [software checks](../../fpga/sw_repo/README.md#host-and-documentation-checks)
after changing canonical inputs. Existing Vitis projects contain imported source
copies: recreate/reimport an application (or deliberately update its source)
to see these comments. Regenerating its BSP alone does not refresh an existing
application's imported files. See the
[execution record](software-readability-validation.json) for this pass's checks;
no FPGA rebuild or hardware deployment is part of a comments-only update.
