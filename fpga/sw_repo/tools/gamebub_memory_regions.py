"""Validate processor-visible MEM_AXI RAM ranges from an XSA, without guessing.

Standard-library only. CSR ranges are never registered as linker RAM. Native SDT
memory discovery remains a separate qualification gate. Use add_to_app with the
Vitis 2025.2 application linker API only after reviewing the printed JSON.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import zipfile

SIZES = {"gamebub_sram_mem": 524288, "gamebub_sdram_mem": 33554432}


def _number(value):
    return value if isinstance(value, int) else int(value, 0)


def _overlap(a, b):
    return a["base"] < b["base"] + b["size"] and b["base"] < a["base"] + a["size"]


def from_xsa(xsa, cpu):
    """Return zero, one or several RAM instances for one explicit processor.

    Reject ambiguous handoffs, inconsistent aliases, wrong lengths, misaligned
    physical apertures and overlaps. Multiple I/D aliases of one range collapse.
    """
    with zipfile.ZipFile(xsa) as archive:
        roots = []
        for name in archive.namelist():
            if name.lower().endswith(".hwh"):
                root = ET.fromstring(archive.read(name))
                # HWH exports currently have no namespace; normalize if supplied.
                for node in root.iter():
                    node.tag = node.tag.rsplit("}", 1)[-1]
                if any(m.get("INSTANCE") == cpu for m in root.findall(".//MODULE")):
                    roots.append(root)
    if len(roots) != 1:
        raise ValueError(f"Expected one HWH containing processor {cpu!r}; found {len(roots)}")
    modules = {m.get("INSTANCE"): m for m in roots[0].findall(".//MODULE")}
    found = {}
    all_ranges = []
    for node in modules[cpu].findall(".//MEMRANGE"):
        instance = node.get("INSTANCE")
        if not instance or instance not in modules:
            continue
        base, high = _number(node.get("BASEVALUE")), _number(node.get("HIGHVALUE"))
        if high < base or base < 0 or high > 0xFFFFFFFF:
            raise ValueError(f"Invalid 32-bit range: {instance}")
        candidate = {"instance": instance, "base": base, "size": high-base+1,
                     "address_block": node.get("ADDRESSBLOCK")}
        all_ranges.append(candidate)
        ip = modules[instance].get("MODTYPE")
        if ip not in SIZES or node.get("ADDRESSBLOCK") != "Mem":
            continue
        if node.get("MEMTYPE", "").upper() != "MEMORY":
            raise ValueError(f"MEM_AXI is not marked MEMORY: {instance}")
        if node.get("IS_DATA", "").upper() != "TRUE":
            continue
        if candidate["size"] != SIZES[ip] or base % SIZES[ip]:
            raise ValueError(f"Unexpected/misaligned MEM_AXI span: {instance}: {candidate}")
        candidate["ip"] = ip
        clean = re.sub(r"[^A-Za-z0-9_]", "_", instance)
        candidate["name"] = "gbmem_" + clean
        if instance in found and found[instance] != candidate:
            raise ValueError(f"Inconsistent data aliases for {instance}")
        found[instance] = candidate
    result = sorted(found.values(), key=lambda r: (r["base"], r["instance"]))
    if len({r["name"] for r in result}) != len(result):
        raise ValueError("Sanitized linker region names collide")
    for ram in result:
        for other in all_ranges:
            # I/D aliases of this exact RAM range are safe, all other overlap is not.
            same = all(ram[k] == other[k] for k in ("instance", "base", "size", "address_block"))
            if not same and _overlap(ram, other):
                raise ValueError(f"Overlapping processor-visible ranges: {ram} / {other}")
    return result


def add_to_app(app, regions):
    """Register reviewed RAM only; reject conflicts before any mutation."""
    linker = app.get_ld_script()
    existing = []
    for row in linker.get_memory_regions():
        existing.append(dict(name=row["name"], base=_number(row["base_address"]), size=_number(row["size"])))
    planned = []
    names = set()
    for row in regions:
        if row.get("ip") not in SIZES or row.get("address_block") != "Mem" or row["size"] != SIZES[row["ip"]] or row["base"] % row["size"]:
            raise ValueError(f"Not a reviewed MEM_AXI region: {row}")
        if row["name"] in names:
            raise ValueError("Duplicate region names")
        names.add(row["name"])
        for other in existing + planned:
            exact = row["base"] == other["base"] and row["size"] == other["size"]
            if row["name"] == other["name"] and not exact:
                raise ValueError(f"Existing linker name has different bounds: {row['name']}")
            if _overlap(row, other) and not exact:
                raise ValueError(f"Overlapping linker regions: {row} / {other}")
        planned.append(row)
    for row in planned:
        # A native SDT region with another name but exact bounds is reused.
        if not any(row["base"] == old["base"] and row["size"] == old["size"] for old in existing):
            linker.add_memory_region(name=row["name"], base_address=hex(row["base"]), size=hex(row["size"]))
            existing.append(row)
    actual = linker.get_memory_regions()
    for row in planned:
        if not any(_number(old["base_address"]) == row["base"] and _number(old["size"]) == row["size"] for old in actual):
            raise RuntimeError(f"Vitis did not retain memory region: {row}")
    return linker


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("xsa", type=Path)
    parser.add_argument("--cpu", required=True, help="Actual processor INSTANCE in the XSA")
    args = parser.parse_args()
    print(json.dumps(from_xsa(args.xsa, args.cpu), indent=2))
