"""Generate GitHub register tables and offline HTML from canonical sources.

Use --check in CI to reject schema/table drift. --html writes only to a fresh
output directory; generated HTML never replaces Markdown sources.
"""
from pathlib import Path
import argparse
import hashlib
import html
import json
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[3]
DRIVERS = ROOT / 'fpga/sw_repo/drivers'
NAMES = {'gbesp32': 'esp32', 'gbsram': 'sram', 'gbsdram': 'sdram', 'gbaudio': 'audio'}


def tables(check=False):
    evidence = []
    for name, guide in NAMES.items():
        schema = DRIVERS / name / 'data/registers.json'
        data = json.loads(schema.read_text(encoding='utf-8'))
        rows = ['# Register reference', '', f"Core: `{data['core']}`.", '',
                'Generated from the reviewed driver register schema. Offsets are relative to the control base, not processor physical addresses.', '',
                '| Name | Offset | Access | Reset or read value | Behavior |',
                '| --- | --- | --- | --- | --- |']
        seen = set()
        for reg in data['registers']:
            off = int(str(reg['offset']), 0) if isinstance(reg['offset'], str) else reg['offset']
            if off in seen or off < 0 or off % 4:
                raise ValueError(f'{name}: invalid or duplicate offset {off}')
            seen.add(off)
            value = reg.get('reset')
            reset = 'not applicable' if value is None else str(value)
            desc = reg['description'].replace('|', '\\|').replace('\n', ' ')
            rows.append(f"| `{reg['name']}` | `0x{off:03X}` | {reg['access']} | {reset} | {desc} |")
        rows += ['', 'Reserved addresses and unsupported features must follow the RTL response rules in the product guide. A schema table is not proof of register behavior.', '']
        expected = '\n'.join(rows)
        target = ROOT / 'docs/vivado/ips' / guide / 'registers.md'
        if check:
            if not target.exists() or target.read_text(encoding='utf-8') != expected:
                raise ValueError(f'Generated register guide is stale: {target}')
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(expected, encoding='utf-8')
        sources = []
        for relative in data['rtl_files']:
            source = (ROOT / relative).resolve()
            if not source.is_relative_to(ROOT) or not source.is_file():
                raise ValueError(f'Missing or escaping RTL binding: {relative}')
            sources.append({'path': relative, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
        evidence.append({'driver': name, 'register_count': len(seen), 'rtl_sources': sources,
                         'schema_sha256': hashlib.sha256(schema.read_bytes()).hexdigest()})
    print(f'REGISTER_DOCS_CHECK_PASS drivers={len(evidence)}')
    return evidence


def offline(output, doxygen):
    from markdown_it import MarkdownIt
    if output.exists():
        raise ValueError('Fresh HTML output directory required')
    output.mkdir(parents=True)
    parser = MarkdownIt('commonmark', {'html': False}).enable('table')
    docs = ROOT / 'docs/vivado'
    count = 0
    for source in docs.rglob('*'):
        if not source.is_file():
            continue
        target = output / 'docs/vivado' / source.relative_to(docs)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        if source.suffix == '.md':
            body = parser.render(source.read_text(encoding='utf-8'))
            # Only local Markdown links change extension. GitHub URLs remain.
            def link(match):
                url = match.group(1)
                linked=(source.parent / url.split('#',1)[0]).resolve()
                if '://' not in url and linked.is_relative_to(docs) and linked.is_file():
                    url = re.sub(r'\.md(?=#|$)', '.html', url)
                return 'href="' + url + '"'
            body = re.sub(r'href="([^"]+)"', link, body)
            target.with_suffix('.html').write_text('<!doctype html><meta charset="utf-8"><title>GameBub developer guide</title>'
                '<style>body{font:16px/1.5 system-ui;max-width:1050px;margin:2rem auto;padding:0 1rem}table{border-collapse:collapse}td,th{border:1px solid #aaa;padding:.4rem}pre{overflow:auto;background:#eee;padding:1rem}</style>' + body, encoding='utf-8')
            count += 1
    # Preserve relative source links in a standalone offline bundle.
    shutil.copytree(ROOT / 'fpga/sw_repo', output / 'fpga/sw_repo', ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
    shutil.copytree(ROOT / 'fpga/vivado/gamebub_ipi_demo', output / 'fpga/vivado/gamebub_ipi_demo')
    # Catalog pages link to component.xml and the quickstart links to runtime
    # assets. Keep the curated public source tree usable in an offline bundle.
    for folder in ['fpga/board_files', 'fpga/ip_repo', 'LICENSES', '.github']:
        if (ROOT/folder).is_dir():
            shutil.copytree(ROOT/folder, output/folder,
                            ignore=shutil.ignore_patterns('__pycache__', '*.pyc', '.Xil'))
    for name in ['README.md', 'QUICKSTART.md', 'LICENSE.md', 'SOURCE_MANIFEST.json',
                 '.gitignore', '.gitattributes']:
        if (ROOT/name).is_file():
            shutil.copy2(ROOT/name, output/name)
    api = output / 'api'
    config = output / 'Doxyfile'
    headers = ' '.join('"' + (p / 'src').as_posix() + '"' for p in DRIVERS.iterdir() if p.is_dir())
    config.write_text(f'''PROJECT_NAME = "GameBub Vivado drivers"
OUTPUT_DIRECTORY = "{api.as_posix()}"
INPUT = {headers}
FILE_PATTERNS = *.h
RECURSIVE = YES
EXTRACT_ALL = YES
GENERATE_HTML = YES
GENERATE_LATEX = NO
HAVE_DOT = NO
WARN_AS_ERROR = FAIL_ON_WARNINGS
WARN_IF_UNDOCUMENTED = YES
WARN_LOGFILE = "{(output / 'doxygen-warnings.log').as_posix()}"
QUIET = YES
''', encoding='utf-8')
    result = subprocess.run([str(doxygen), str(config)], capture_output=True, text=True)
    (output / 'doxygen-console.log').write_text(result.stdout + result.stderr, encoding='utf-8')
    if result.returncode or not (api / 'html/index.html').is_file():
        raise RuntimeError(f'Doxygen failed: see {output}')
    (output / 'index.html').write_text('<meta http-equiv="refresh" content="0;url=docs/vivado/README.html">', encoding='utf-8')
    print(f'OFFLINE_DOCS_PASS markdown_pages={count} api=api/html/index.html')


if __name__ == '__main__':
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--check', action='store_true')
    cli.add_argument('--html', type=Path)
    cli.add_argument('--doxygen', default='doxygen')
    args = cli.parse_args()
    result = tables(args.check)
    if args.html:
        offline(args.html.resolve(), args.doxygen)
        (args.html / 'source-bindings.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
