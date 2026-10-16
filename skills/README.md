<!-- SPDX-License-Identifier: 0BSD -->

# GameBub agent skills

[gamebub-vivado/SKILL.md](gamebub-vivado/SKILL.md) teaches a skill-capable coding agent this repository's board/IP, IPI, Vitis and tester workflows. `SKILL.md` (singular) with YAML frontmatter is the agent entrypoint; this README is the installation guide. It complements AMD Ross's general FPGA skills rather than copying or bundling AMD software.

## Install the GameBub skill

For current Codex, copy the folder into a supported discovery location. The root `skills/` distribution folder is **not** automatically discovered just because you cloned this repository. Open a PowerShell terminal at your clone's root:

```powershell
$gamebubSkillSource = (Resolve-Path ./skills/gamebub-vivado).Path
$gamebubSkillDestination = Join-Path $env:USERPROFILE '.agents/skills/gamebub-vivado'
if (Test-Path -LiteralPath $gamebubSkillDestination) {
    throw 'An installed GameBub skill already exists. Review it before updating; this command will not overwrite it.'
}
New-Item -ItemType Directory -Force -Path (Split-Path $gamebubSkillDestination) | Out-Null
Copy-Item -LiteralPath $gamebubSkillSource -Destination $gamebubSkillDestination -Recurse
```

This installs one user-scoped copy. For repository-only discovery instead, set the destination to `./.agents/skills/gamebub-vivado`; do not install both. For other clients, copy the same folder into that client's documented skill location. Review third-party instructions before installation. See [OpenAI's skill discovery documentation](https://developers.openai.com/codex/skills).

Start a new agent session if it is not discovered. In Codex, check `/skills` and try:

```text
Use $gamebub-vivado to review my GameBub Vivado block diagram and matching
Vitis platform. Inspect only; do not program or flash anything.
```

Installation adds instructions, not access to Vivado or hardware. Updating the Git clone does not update a copied installation: compare and deliberately replace your owned installed copy. The existing workstation-specific `godot-gamebub` skill is separate and is not overwritten by this package.

## Add AMD Ross

Follow [AMD Ross setup for this repository](../docs/vivado/amd-ross-setup.md) for the official download links, Codex plugin/MCP commands, VS Code route, and the important 2025.2/2026.1 distinction.

## Scope and verification

This independent skill is 0BSD; linked RTL and drivers retain their own licenses. No AMD skills, executables, credentials or workstation MCP settings are bundled. The skill is documentation, not a guarantee of device safety or timing closure. Review it against the current repository when changing IP versions.
