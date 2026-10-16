# SPDX-License-Identifier: CERN-OHL-S-2.0
"""Exercise native EMBD_APP discovery/create/build, never manual source import.

Run with Vitis 2025.2 -s, an XSA and a fresh workspace. No hardware access.
"""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import vitis

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE))
from create_workspace import hardware, elf_bounds


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('xsa', type=Path)
    cli.add_argument('workspace', type=Path)
    cli.add_argument('--app', action='append', help='Template suffix; repeat to select a subset')
    cli.add_argument('--platform-export', type=Path, help='Reuse an owned matching gamebub_platform export instead of rebuilding its unchanged BSP')
    args = cli.parse_args()
    work = args.workspace.resolve()
    if work.exists():
        raise ValueError('Fresh owned workspace required')
    apps = json.loads((ROOT / 'fpga/sw_repo/templates/apps.json').read_text())
    names = [a['name'] for a in apps]
    chosen = args.app or names
    if not chosen or any(a not in names for a in chosen):
        raise ValueError('Unknown template')
    cpu, bindings, _ = hardware(args.xsa)
    report = {'status':'INCOMPLETE', 'hardware_access':'none',
              'mechanism':'public Vitis EMBD_APP discovery and create_app_component(template=...)',
              'xsa_sha256':hashlib.sha256(args.xsa.read_bytes()).hexdigest(), 'apps':[]}
    report['source_bindings'] = {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
        for folder in [ROOT/'fpga/sw_repo/lib/sw_apps', ROOT/'fpga/sw_repo/templates']
        for p in folder.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
    client = vitis.create_client()
    try:
        client.set_workspace(str(work))
        client.add_embedded_sw_repo(level='LOCAL', path=str(ROOT / 'fpga/sw_repo'))
        templates = client.get_templates(type='EMBD_APP')
        (work / 'native-template-list.txt').write_text(str(templates), encoding='utf-8')
        report['discovery'] = str(templates)
        if not all('gamebub_' + a in str(templates).lower() for a in names):
            raise RuntimeError('Not all GameBub templates are advertised by native embedded discovery')
        print('GAMEBUB_NATIVE_TEMPLATE_DISCOVERY_PASS count=' + str(len(names)), flush=True)
        if args.platform_export:
            export = args.platform_export.resolve()
            xsas = list((export/'hw').glob('*.xsa'))
            if len(xsas)!=1 or hashlib.sha256(xsas[0].read_bytes()).hexdigest()!=report['xsa_sha256']:
                raise ValueError('Reused platform must contain the exact supplied XSA')
            for name in ('gbesp32','gbaudio','gbsram','gbsdram'):
                if not (export/'sw/standalone_cpu/include'/(name+'.h')).is_file():
                    raise ValueError('Reused BSP lacks native driver header: '+name)
            client.add_platform_repos(str(export.parent))
            report['platform_reused_from'] = str(export)
        else:
            platform = client.create_platform_component(name='gamebub_platform', hw_design=str(args.xsa.resolve()),
                cpu=cpu, os='standalone', domain_name='standalone_cpu', generate_dtb=False)
            domain = platform.get_domain('standalone_cpu')
            domain.set_config('os', 'standalone_stdout', 'mdm_1')
            domain.set_config('os', 'standalone_stdin', 'mdm_1')
            if platform.build() != 0:
                raise RuntimeError('Platform build failed')
            driver_list = str(domain.get_drivers())
            report['drivers'] = driver_list
            if not all(d in driver_list for d in ['gbesp32','gbaudio','gbsram','gbsdram']):
                raise RuntimeError('Native custom BSP driver binding missing')
        xpfm = client.find_platform_in_repos('gamebub_platform')
        # This is the GUI's additional pre-creation gate. Reused platforms may
        # have stale app_list.yaml even though the sidebar advertises a template.
        empyro = shutil.which('empyro.bat') or shutil.which('empyro')
        if not empyro:
            raise RuntimeError('empyro is required to exercise GUI BSP validation')
        domain_path = Path(xpfm).parent / 'sw/standalone_cpu'
        for suffix in chosen:
            template = 'gamebub_' + suffix
            result = subprocess.run([empyro, 'validate_bsp', '-t', template,
                '-d', str(domain_path), '-r', str(work/'_ide/.wsdata/.repo.yaml')],
                capture_output=True, text=True)
            (work/(template+'-validate-bsp.log')).write_text(result.stdout+result.stderr)
            if result.returncode:
                raise RuntimeError('GUI BSP validation failed: '+template+
                    '. Regenerate BSP and rebuild the platform after repository updates. '+result.stdout+result.stderr)
            app = client.create_app_component(name='native_' + suffix, platform=xpfm,
                domain='standalone_cpu', template=template)
            # Same native creation as the Examples sidebar. Do not import files,
            # generate headers here or repair the linker after creation.
            if app.build() != 0:
                raise RuntimeError('Native template build failed: ' + template)
            elfs = list((work / ('native_' + suffix) / 'build').glob('*.elf'))
            if len(elfs) != 1:
                raise RuntimeError('Expected one native template ELF')
            info = elf_bounds(elfs[0], bindings['BRAM_SIZE'])
            info.update(template=template, component='native_' + suffix,
                sha256=hashlib.sha256(elfs[0].read_bytes()).hexdigest())
            report['apps'].append(info)
            print('GAMEBUB_NATIVE_TEMPLATE_BUILD_PASS ' + template, flush=True)
        report['status'] = 'PASS'
    except Exception as error:
        report['status'] = 'FAIL'
        report['error'] = str(error)
        raise
    finally:
        if work.is_dir():
            (work / 'template-evidence.json').write_text(json.dumps(report, indent=2) + '\n')
        vitis.dispose()


if __name__ == '__main__':
    main()
