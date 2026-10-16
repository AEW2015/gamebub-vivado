#!/usr/bin/env python3
"""Generate or check Markdown catalogs from the five current GameBub IP packages."""

from __future__ import annotations

import argparse
import hashlib
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


SPIRIT = "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009"
NS = {"spirit": SPIRIT}
CORES = {
    "esp32": ("gamebub_esp32_v102_v1_14", "gamebub_esp32_v102"),
    "sram": ("gamebub_sram_mem_v1_6", "gamebub_sram_mem"),
    "sdram": ("gamebub_sdram_mem_v1_6", "gamebub_sdram_mem"),
    "lcd": ("gamebub_lcd_axis_v1_5", "gamebub_lcd_axis"),
    "audio": ("gamebub_dac_audio_v1_3", "gamebub_dac_audio"),
}


def _q(name: str) -> str:
    return f"{{{SPIRIT}}}{name}"


def _text(element: ET.Element | None, default: str = "") -> str:
    if element is None or element.text is None:
        return default
    return element.text.strip()


def _cell(value: str) -> str:
    return value.replace("|", r"\|").replace("\r\n", "<br>").replace("\n", "<br>")


def _inline(value: str) -> str:
    if not value:
        return "—"
    return f"`{_cell(value)}`"


def _attr(element: ET.Element | None, name: str) -> str:
    if element is None:
        return ""
    return element.attrib.get(_q(name), "")


def _component_identity(component: ET.Element) -> tuple[str, str, str]:
    vendor = _text(component.find("spirit:vendor", NS))
    library = _text(component.find("spirit:library", NS))
    name = _text(component.find("spirit:name", NS))
    version = _text(component.find("spirit:version", NS))
    return f"{vendor}:{library}:{name}:{version}", name, version


def _user_parameters(component: ET.Element) -> list[tuple[str, str, str]]:
    parameters: list[tuple[str, str, str]] = []
    direct_parameters = component.find("spirit:parameters", NS)
    if direct_parameters is None:
        return parameters
    for parameter in direct_parameters.findall("spirit:parameter", NS):
        value = parameter.find("spirit:value", NS)
        if value is None or _attr(value, "resolve") != "user":
            continue
        name = _text(parameter.find("spirit:name", NS), "(unnamed)")
        default = _text(value, "(empty)")
        description = _text(parameter.find("spirit:displayName", NS))
        if not description:
            description = _text(parameter.find("spirit:description", NS), "No description supplied in component metadata.")
        parameters.append((name, default, description))
    return parameters


def _interface_parameters(interface: ET.Element) -> dict[str, str]:
    parameters: dict[str, str] = {}
    parameter_container = interface.find("spirit:parameters", NS)
    if parameter_container is None:
        return parameters
    for parameter in parameter_container.findall("spirit:parameter", NS):
        name = _text(parameter.find("spirit:name", NS)).upper()
        value = _text(parameter.find("spirit:value", NS))
        if name and value:
            parameters[name] = value
    return parameters


def _bus_type(element: ET.Element | None) -> str:
    fields = [_attr(element, key) for key in ("vendor", "library", "name", "version")]
    return ":".join(fields) if element is not None else ""


def _bus_interfaces(component: ET.Element) -> list[tuple[str, ...]]:
    result: list[tuple[str, ...]] = []
    container = component.find("spirit:busInterfaces", NS)
    if container is None:
        return result
    for interface in container.findall("spirit:busInterface", NS):
        name = _text(interface.find("spirit:name", NS), "(unnamed)")
        bus_type = _bus_type(interface.find("spirit:busType", NS))
        abstraction = _bus_type(interface.find("spirit:abstractionType", NS))
        mode_tags = {"master", "slave", "mirroredMaster", "mirroredSlave", "system", "monitor"}
        mode = ", ".join(child.tag.rsplit("}", 1)[-1] for child in interface if child.tag.rsplit("}", 1)[-1] in mode_tags) or "(not specified)"
        maps: list[str] = []
        port_maps = interface.find("spirit:portMaps", NS)
        if port_maps is not None:
            for port_map in port_maps.findall("spirit:portMap", NS):
                logical = _text(port_map.find("spirit:logicalPort/spirit:name", NS))
                physical = _text(port_map.find("spirit:physicalPort/spirit:name", NS))
                maps.append(f"{logical} → {physical}" if logical and physical else " → ".join((logical, physical)))
        parameters = _interface_parameters(interface)
        result.append(
            (
                name,
                bus_type,
                abstraction,
                mode,
                "<br>".join(maps) if maps else "—",
                parameters.get("ASSOCIATED_CLOCK", "—"),
                parameters.get("ASSOCIATED_RESET", "—"),
                parameters.get("ASSOCIATED_BUSIF", "—"),
            )
        )
    return result


def _ports(component: ET.Element) -> list[tuple[str, str, str]]:
    model = component.find("spirit:model", NS)
    ports_element = model.find("spirit:ports", NS) if model is not None else None
    if ports_element is None:
        return []
    ports: list[tuple[str, str, str]] = []
    for port in ports_element.findall("spirit:port", NS):
        name = _text(port.find("spirit:name", NS), "(unnamed)")
        wire = port.find("spirit:wire", NS)
        direction = _text(wire.find("spirit:direction", NS), "(unspecified)") if wire is not None else "(no wire)"
        vector = wire.find("spirit:vector", NS) if wire is not None else None
        if vector is None:
            bounds = "scalar"
        else:
            left = _text(vector.find("spirit:left", NS), "?")
            right = _text(vector.find("spirit:right", NS), "?")
            bounds = f"[{left}:{right}]"
        ports.append((name, direction, bounds))
    return ports


def render_catalog(root: Path, slug: str) -> str:
    package_dir, _expected_name = CORES[slug]
    component_path = root / "fpga" / "ip_repo" / package_dir / "component.xml"
    if not component_path.is_file():
        raise FileNotFoundError(f"missing component metadata: {component_path}")
    component = ET.parse(component_path).getroot()
    vlnv, name, version = _component_identity(component)
    if not name or not version:
        raise ValueError(f"component name/version missing in {component_path}")
    digest = hashlib.sha256(component_path.read_bytes()).hexdigest()
    source_link = f"../../../../fpga/ip_repo/{package_dir}/component.xml"

    lines = [
        f"# {name} component catalog",
        "",
        "Generated reference to the packaged IP metadata. It describes declarations in `component.xml`; it does not claim measured timing, performance, or board-level validation.",
        "",
        f"- VLNV: `{vlnv}`",
        f"- Component version: `{version}`",
        f"- Component metadata SHA-256: `{digest}`",
        f"- Source: [`component.xml`]({source_link})",
        "",
        "## User parameters",
        "",
        "Values are taken from direct component-root `spirit:parameters` entries whose `spirit:value` has `spirit:resolve=\"user\"`. The description uses `spirit:displayName`, then `spirit:description`; missing descriptions remain explicit.",
        "",
        "| Parameter | Default | Description |",
        "| --- | --- | --- |",
    ]
    parameters = _user_parameters(component)
    if parameters:
        lines.extend(f"| `{_cell(name)}` | {_inline(value)} | {_cell(description)} |" for name, value, description in parameters)
    else:
        lines.append("| — | — | No direct user-resolved component parameters are declared. |")

    lines.extend(
        [
            "",
            "## Bus interfaces and clock/reset association",
            "",
            "Port maps and association values come from the component's bus interface declarations. A dash means the corresponding metadata is not declared there.",
            "",
            "| Interface | Bus type | Abstraction | Mode | Logical → physical port maps | Associated clock | Associated reset | Associated bus interfaces |",
            "| --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    interfaces = _bus_interfaces(component)
    if interfaces:
        for row in interfaces:
            lines.append("| " + " | ".join(_cell(value) for value in row) + " |")
    else:
        lines.append("| — | — | — | — | No bus interfaces declared. | — | — | — |")

    lines.extend(
        [
            "",
            "## Top-level HDL ports",
            "",
            "Names, directions, and vector bounds are read from `spirit:model/spirit:ports`; scalar ports are marked `scalar`.",
            "",
            "| Port | Direction | Vector bounds |",
            "| --- | --- | --- |",
        ]
    )
    ports = _ports(component)
    if ports:
        lines.extend(f"| `{_cell(port)}` | `{_cell(direction)}` | `{_cell(bounds)}` |" for port, direction, bounds in ports)
    else:
        lines.append("| — | — | — | No top-level HDL ports declared. |")
    return "\n".join(lines) + "\n"


def generate(root: Path, check: bool = False) -> list[str]:
    """Write catalogs, or return paths whose checked-in content has drifted."""
    root = root.resolve()
    drift: list[str] = []
    for slug in CORES:
        output = root / "docs" / "vivado" / "ips" / slug / "catalog.md"
        expected = render_catalog(root, slug)
        if check:
            if not output.is_file() or output.read_text(encoding="utf-8") != expected:
                drift.append(output.relative_to(root).as_posix())
        else:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(expected, encoding="utf-8", newline="\n")
            print(f"Wrote {output.relative_to(root).as_posix()}")
    return drift


def main() -> int:
    root = Path(__file__).resolve().parents[3]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if generated catalogs are missing or stale")
    args = parser.parse_args()
    try:
        drift = generate(root, check=args.check)
    except (ET.ParseError, OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if args.check:
        if drift:
            for path in drift:
                print(f"DRIFT: {path}", file=sys.stderr)
            return 1
        print(f"Catalogs match all {len(CORES)} component.xml sources.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
