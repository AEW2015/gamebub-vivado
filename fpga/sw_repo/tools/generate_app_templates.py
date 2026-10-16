# SPDX-License-Identifier: CERN-OHL-S-2.0
"""Materialize native Vitis apps from canonical source; --check rejects drift."""
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[3]
SW = ROOT / 'fpga/sw_repo'
CANONICAL = SW / 'templates'


def expected():
    apps = json.loads((CANONICAL / 'apps.json').read_text())
    output = {}
    for app in apps:
        template = 'gamebub_' + app['name']
        folder = SW / 'lib/sw_apps' / template
        files = {}
        description = 'Standalone MicroBlaze V GameBub example; building never runs hardware.'
        if app.get('guarded'):
            description += ' Destructive/retiming operations are disabled until explicitly configured.'
        elif app['name'] in ('audio_tone', 'vibration_pulse'):
            description += ' Deliberately running this ELF actuates the board for a bounded interval.'
        yaml = '# SPDX-License-Identifier: CERN-OHL-S-2.0\n%YAML 1.2\n---\n'
        yaml += 'title: ' + json.dumps('GameBub - ' + app['title']) + '\ntype: apps\n'
        yaml += 'description: ' + json.dumps(description) + '\n'
        yaml += 'supported_processors:\n  - microblaze_riscv\nsupported_os:\n  - standalone\n'
        yaml += 'depends_libs:\n  xiltimer: {}\ndepends:\n'
        for driver, props in app['drivers'].items():
            yaml += f'  {driver}:\n' + ''.join('    - ' + p + '\n' for p in props)
        yaml += 'required_mem:\n  bram:\n    size: 0x4000\nlinker_constraints:\n  heap: 0x0\n  stack: 0x800\n...\n'
        files['data/' + template + '.yaml'] = yaml.encode()
        cmake = (CANONICAL / 'CMakeLists.txt.in').read_text()
        for key, value in {'TEMPLATE': template, 'CMAKE_METADATA': template.capitalize(),
                           'DRIVERS': ' '.join(app['drivers']),
                           'IRQ': '1' if app.get('kind') == 11 else '0'}.items():
            cmake = cmake.replace('@' + key + '@', value)
        if app['name'] == 'vibration_pulse':
            marker = 'include(${CMAKE_CURRENT_SOURCE_DIR}/gamebub_bindings.cmake)'
            cmake = cmake.replace(marker, 'include(${CMAKE_CURRENT_SOURCE_DIR}/gamebub_vibration.cmake)\n' + marker)
            files['src/gamebub_vibration.cmake'] = (CANONICAL / 'gamebub_vibration.cmake').read_bytes()
        files['src/CMakeLists.txt'] = cmake.encode()
        for name in ('gamebub_settings.h', 'gamebub_bindings.cmake'):
            files['src/' + name] = (CANONICAL / name).read_bytes()
        main = '/* SPDX-License-Identifier: CERN-OHL-S-2.0 */\n#include "gamebub_settings.h"\n'
        if 'kind' in app:
            main += f'#define GB_DEMO_KIND {app["kind"]}\n#define GB_APP_NAME "{app["name"]}"\n#include "demo_program.h"\n'
            files['src/demo_program.h'] = (ROOT / 'fpga/vivado/gamebub_ipi_demo/software/demo_program.h').read_bytes()
        else:
            driver = next(iter(app['drivers']))
            memory = 'SRAM' if driver == 'gbsram' else 'SDRAM'
            main += '#include "platform_bindings.h"\n'
            main += f'#define GB_EXAMPLE_CTRL_BASE GB_{memory}_CTRL_BASE\n#define GB_EXAMPLE_MEMORY_BASE GB_{memory}_MEMORY_BASE\n#include "driver_example.inc"\n'
            examples = SW / 'drivers' / driver / 'examples'
            files['src/driver_example.inc'] = (examples / app['example']).read_bytes()
            files['src/' + driver + '_example_setup.h'] = (examples / (driver + '_example_setup.h')).read_bytes()
        files['src/main.c'] = main.encode()
        for relative, body in files.items():
            output[folder / relative] = body
    return apps, output


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--check', action='store_true')
    ns = cli.parse_args()
    apps, files = expected()
    for path, body in files.items():
        if ns.check:
            if not path.is_file() or path.read_bytes() != body:
                raise SystemExit('Template drift: ' + str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(body)
    print('NATIVE_APP_TEMPLATES_PASS', len(apps), 'templates', len(files), 'files')


if __name__ == '__main__':
    main()
