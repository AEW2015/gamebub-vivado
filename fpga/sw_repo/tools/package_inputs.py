"""Prepare output-only documentation/software IP candidates; never edit catalog.

Run prepare, native Vivado package_ip.tcl OUTPUT, then verify. New VLNVs are
metadata-only candidates, not timing/hardware releases. Finalize after final docs
regeneration using a fresh --out directory; prior evidence is never overwritten.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[3]
if not (REPO / "fpga/ip_repo").is_dir():
    # Root-level copy in the standalone distribution resolves its frozen SDK.
    REPO = Path(__file__).resolve().parent / "sdk"
SPECS = [
    ("gamebub_esp32_v102", "1.14", "1.15", "ESP32 Communications", "gbesp32", "esp32"),
    ("gamebub_sram_mem", "1.6", "1.7", "SRAM Memory", "gbsram", "sram"),
    ("gamebub_sdram_mem", "1.6", "1.7", "SDR SDRAM Memory", "gbsdram", "sdram"),
    ("gamebub_lcd_axis", "1.5", "1.6", "LCD AXI4-Stream", "", "lcd"),
    ("gamebub_dac_audio", "1.3", "1.4", "DAC Audio", "gbaudio", "audio"),
]
NS = {"s": "http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def files(root):
    return sorted(p for p in root.rglob("*") if p.is_file() and "__pycache__" not in p.parts)


def copytree(source, target):
    shutil.copytree(source, target, ignore=shutil.ignore_patterns("__pycache__", ".git", "*.pyc"))


def folder(name, version):
    return f"{name}_v{version.replace('.', '_')}"


def prepare(out, docs):
    out.mkdir(parents=True, exist_ok=False)
    if not (docs / "index.html").is_file():
        raise ValueError("--docs must be the completed offline HTML output directory")
    baseline = []
    packages = []
    copytree(REPO / "fpga/sw_repo", out / "sdk/fpga/sw_repo")
    copytree(REPO / "fpga/vivado/gamebub_ipi_demo", out / "sdk/fpga/vivado/gamebub_ipi_demo")
    copytree(REPO / "fpga/board_files", out / "sdk/fpga/board_files")
    copytree(REPO / "docs/vivado", out / "sdk/docs/vivado")
    for name in ("README.md", "LICENSE.md", "LICENSE-GPL-V3", "LICENSE-CERN-OHL-S"):
        if (REPO / name).is_file():
            shutil.copy2(REPO / name, out / "sdk" / name)
    if (REPO / "LICENSES").is_dir():
        copytree(REPO / "LICENSES", out / "sdk/LICENSES")
    copytree(docs, out / "sdk/docs_html")
    # The portable reference SDK preserves the current version set. Candidate
    # packages are separate; no automatic upgrades or current installer changes.
    current = [(name, old) for name, old, *_ in SPECS] + [("gamebub_esp32_irq", "1.2"), ("gamebub_esp32_qspi", "1.2"), ("gamebub_video_status", "1.1")]
    for name, version in current:
        copytree(REPO / "fpga/ip_repo" / folder(name, version), out / "sdk/fpga/ip_repo" / folder(name, version))
    copytree(REPO / "fpga/board_files/interfaces", out / "ip_repo/interfaces")
    for name, old, new, title, driver, doc in SPECS:
        source = REPO / "fpga/ip_repo" / folder(name, old)
        target = out / "ip_repo" / folder(name, new)
        copytree(source, target)
        gui = target / "xgui" / f"{folder(name, old)}.tcl"
        if gui.is_file():
            shutil.copy2(gui, target / "xgui" / f"{folder(name, new)}.tcl")
        for path in files(source):
            baseline.append({"source": str(path.relative_to(REPO)).replace("\\", "/"), "target": str((target/path.relative_to(source)).relative_to(out)).replace("\\", "/"), "sha256": digest(path), "metadata": path.name == "component.xml"})
        copytree(docs, target / "doc/sdk")
        if driver:
            copytree(REPO / "fpga/sw_repo/drivers" / driver, target / "software/drivers" / driver)
        (target / "examples").mkdir(exist_ok=True)
        # A sourceable portable hook, not an unproven AMD TTCL example generator.
        hook = """# Source this hook, then call gamebub_create_sdk_example NEW_OUTPUT.
# This is an explicit reference-design recreation, not an in-place BD mutation.
set gamebub_sdk [file normalize [file join [file dirname [info script]] ../../../sdk]]
proc gamebub_create_sdk_example {output} {
 global gamebub_sdk argv
 if {![file isfile $gamebub_sdk/fpga/vivado/gamebub_ipi_demo/create_design.tcl]} {error {Keep ip_repo and sdk together in the delivered distribution}}
 if {[current_project -quiet] ne ""} {error {Use a fresh Vivado session without an open project}}
 set argv [list $output]
 source $gamebub_sdk/fpga/vivado/gamebub_ipi_demo/create_design.tcl
}
puts "GAMEBUB_SDK_EXAMPLE_HOOK_READY=$gamebub_sdk"
"""
        (target / "examples/sdk_example.tcl").write_text(hook, encoding="utf-8")
        packages.append(dict(folder=target.name, version=new, title=title, driver=driver, doc=doc,
                             software=[str(p.relative_to(target)).replace("\\", "/") for p in files(target / "software")] if driver else []))
    (out / "source-baseline.json").write_text(json.dumps(baseline, indent=2)+"\n", encoding="utf-8")
    (out / "package-inputs.json").write_text(json.dumps(packages, indent=2)+"\n", encoding="utf-8")
    lines = ["set packages {"]
    for row in packages:
        lines.append(" {"+" ".join("{"+str(row[k])+"}" for k in ("folder", "version", "title", "driver", "doc"))+"}")
    lines.append("}")
    for row in packages:
        lines.append("set sdk_software("+row["folder"]+") {"+" ".join("{"+f+"}" for f in row["software"])+"}")
    (out / "inputs.tcl").write_text("\n".join(lines)+"\n", encoding="utf-8")
    shutil.copy2(Path(__file__), out / "package_inputs.py")
    shutil.copy2(Path(__file__).with_name("package_ip.tcl"), out / "package_ip.tcl")
    (out / "README.md").write_text("""# GameBub SDK metadata-only IP candidates

Keep `ip_repo` and `sdk` together. No running hardware or current repository was
changed. Candidate versions change documentation/software packaging only; source
RTL/XDC/XCI bytes are checked against `source-baseline.json`. Timing, CDC and
hardware acceptance are not implied. Add `ip_repo` as a private repository only
after reviewing the package checks; do not auto-upgrade an existing project.

The drivers and portable reference SDK target the baseline compatible strings,
not these new candidate VLNVs. New-version SDT/BSP binding must be qualified
separately before claiming applications on candidate versions work unchanged.
The native Software Driver file group still emits Vivado's legacy MLD/MDD
warning because these packages deliberately target SDT YAML/CMake, not legacy
SDK discovery. No placeholder MDD or unsupported legacy flow is fabricated.

Each core has Product Guide, Data Sheet, Getting Started and canonical software
file groups. LCD has no invented CSR driver. Offline HTML includes Markdown/API
pages. Source `examples/sdk_example.tcl`, then explicitly call
`gamebub_create_sdk_example NEW_OUTPUT` in a fresh Vivado session to recreate the
baseline reference. Native GUI `Open IP Example Design` generation remains a
separate acceptance check; this portable hook is not an AMD TTCL generator.
Deliver this entire directory, not an unverified `ipx::archive_core` extraction:
linked offline HTML resources and the SDK sibling must remain present.

Rebuild: prepare a fresh output with `package_inputs.py prepare --docs DOCS --out
OUT`, run native Vivado `-source OUT/package_ip.tcl -tclargs OUT`, then
`package_inputs.py verify --out OUT`. Full logs and source hashes are retained.
""", encoding="utf-8")
    print("SDK_IP_INPUTS_PREPARED", out)


def verify(out):
    baseline = json.loads((out / "source-baseline.json").read_text(encoding="utf-8"))
    for row in baseline:
        if digest(REPO / row["source"]) != row["sha256"]:
            raise ValueError(f"Current source changed during package run: {row['source']}")
        if not row["metadata"] and digest(out / row["target"]) != row["sha256"]:
            raise ValueError(f"Original package payload changed: {row['target']}")
    entries = json.loads((out / "package-inputs.json").read_text(encoding="utf-8"))
    for row in entries:
        root = ET.parse(out / "ip_repo" / row["folder"] / "component.xml").getroot()
        if root.findtext("s:version", namespaces=NS) != row["version"]:
            raise ValueError("Candidate VLNV version mismatch")
        # Native file group env IDs prove type registration, not GUI button use.
        envs = [e.text for e in root.findall(".//s:envIdentifier", NS)]
        for suffix in ("docs.productguide", "docs.datasheet", "docs.gettingstartedguide", "examples"):
            if not any(e.endswith(":"+suffix) for e in envs):
                raise ValueError(f"Missing {suffix}: {row['folder']}")
        if row["driver"] and not any(e.endswith(":sw.driver") for e in envs):
            raise ValueError("Missing software driver group")
        for path in row["software"]:
            relative = Path(path).relative_to("software/drivers")
            if digest(out/"ip_repo"/row["folder"]/path) != digest(REPO/"fpga/sw_repo/drivers"/relative):
                raise ValueError(f"Divergent canonical software: {path}")
    log = out / "package.vivado.log"
    text = log.read_text(encoding="utf-8", errors="replace")
    if "SDK_IP_PACKAGING_DONE" not in text or len(re.findall(r"^SDK_IP_INTEGRITY_PASS .*result=1$", text, re.M)) != 5:
        raise ValueError("Native integrity evidence missing")
    artifacts = [{"role":"catalog_payload", "path":str(p.relative_to(out)).replace("\\", "/"), "sha256":digest(p)} for p in files(out) if p.name not in ("HANDOFF.json",) and p.stat().st_size]
    manifest = {"overall":"PASS", "scope":"Metadata/catalog package integrity only; no timing/PHY/hardware qualification", "checks":{"native_ipx_integrity":{"status":"pass","evidence":"package.vivado.log"},"unchanged_current_sources_and_payload":{"status":"pass","evidence":"source-baseline.json"},"canonical_driver_copies":{"status":"pass","evidence":"package-inputs.json"}}, "artifacts":artifacts}
    (out/"HANDOFF.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print("SDK_IP_PACKAGE_VERIFY_PASS",len(artifacts))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("prepare", "verify"))
    parser.add_argument("--docs", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.mode == "prepare":
        if args.docs is None: parser.error("prepare requires --docs")
        prepare(args.out.resolve(), args.docs.resolve())
    else:
        verify(args.out.resolve())
