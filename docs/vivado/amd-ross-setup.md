<!-- SPDX-License-Identifier: 0BSD -->

# GameBub with AMD Ross Agentic AI

Checked against AMD's public setup guides on **2026-10-16**. These are optional installation instructions, not an installer executed by this repository. AMD Ross provides general agent skills and tool integration; the [GameBub skill](../../skills/README.md) supplies board-specific context.

## Versions first

This GameBub repository targets **Vivado/Vitis 2025.2**. AMD currently identifies **2026.1** as Ross's tested Vivado/Vitis baseline and describes the MCP's Tcl transport as architecturally compatible with other releases. That does **not** establish that every current Ross tool works with 2025.2. Keep 2025.2 explicitly selected, check individual feature requirements, and try read-only inspection first. Do not upgrade a working project merely to install skills. [AMD compatibility guidance](https://github.com/Xilinx/ross-ai-assistant/blob/main/docs/getting-started/README.md)

## 1. Choose one tool connection

Obtain the platform-appropriate download from [AMD Ross downloads](https://www.amd.com/en/support/downloads/ross-agentic-ai.html):

- **VS Code/Cursor:** install the Vivado AI Extension VSIX through **Extensions → … → Install from VSIX…**. Set **Vivado Path** to the installed 2025.2 executable. The extension bundles the tool server; do not add a second server for the same connection.
- **Codex CLI or another CLI client:** install the standalone Windows/Linux Vivado MCP Server and register it with your client.

If an existing Vivado MCP already works, inspect/reuse that configuration first. This guide does not require replacing it. Follow the [official MCP guide](https://github.com/Xilinx/ross-ai-assistant/blob/main/docs/getting-started/vivado-mcp.md) for the actual downloaded package's requirements.

## 2. Codex: add Ross skills

Clone AMD's repository into a new directory outside your GameBub checkout, for example:

```powershell
git clone https://github.com/Xilinx/ross-ai-assistant.git C:/fpga-tools/ross-ai-assistant
codex plugin marketplace add C:/fpga-tools/ross-ai-assistant
codex plugin add amd-ross-agentic-ai-assistant@amd-ross-agentic-ai-assistant
```

The plugin adds skills, **not the Vivado server binary**. Use `/plugins` to inspect it. Do not also copy or install the same AMD skills with `npx skills add`; duplicates can cause ambiguous selection. If your client lacks `codex plugin`, use AMD's documented manual/skills installation route for that client rather than modifying the AMD tool installation. Cached plugins need their own update/reinstallation after the clone changes. [AMD plugin installation](https://github.com/Xilinx/ross-ai-assistant/blob/main/docs/getting-started/install-plugin.md)

## 3. Codex: register the standalone MCP if needed

Only if no suitable connection is already configured: adapt the executable filename to the downloaded Windows package, then run:

```powershell
codex mcp add vivado-ross --env VIVADO_PATH=C:/Xilinx/2025.2/Vivado/bin/vivado.bat -- C:/fpga-tools/vivado-mcp-server.exe --stdio-bridge
```

The paths above are examples, not files supplied by this repository. Confirm the downloaded server accepts the launcher before use. Codex stores MCP settings in the user's configuration; retain unrelated entries and do not commit secrets. This command registers a tool connection; it does not build or program a board. [AMD Codex MCP configuration](https://github.com/Xilinx/ross-ai-assistant/blob/main/docs/getting-started/vivado-mcp.md#openai-codex-cli)

## 4. Documentation search

The extension includes AMD documentation-search configuration. For a standalone setup, follow [AMD's documentation-search setup](https://ross.amd.com/chat#setup), linked from the [Ross README](https://github.com/Xilinx/ross-ai-assistant#install-the-amd-doc-search-mcp-server). Keep authentication outside this repository. For documentation that must remain local, AMD also provides a [local knowledge-base guide](https://github.com/Xilinx/ross-ai-assistant/tree/main/docs/local-kb).

## 5. Verify without touching hardware

Start a new agent session with the GameBub checkout open. Confirm the GameBub skill and intended Ross skills are visible, and ask:

```text
Use the GameBub skill. List the connected Vivado tools, report the actual
Vivado version, and inspect my selected project's part and board_part.
Do not change the project, start implementation, connect to JTAG or program
hardware. Tell me which requested checks are unavailable.
```

Separate three results: skill discovery, live MCP access and design validation. A visible plugin does not prove connectivity, and connectivity does not prove a correct design. For a full demonstration use the [GameBub quickstart](../../QUICKSTART.md) and [Vitis Examples guide](vitis-examples.md); hardware tests remain an explicit later step.

## Installation status

These instructions were checked against the linked official documentation; this documentation change did **not** install or upgrade Ross, change local agent settings, or test the current Ross distribution against GameBub hardware. The existing project validation records do not qualify a newly downloaded MCP release.
