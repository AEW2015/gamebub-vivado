# SPDX-License-Identifier: CERN-OHL-S-2.0
"""Format canonical C sources, then regenerate the native Vitis applications.

Use --check for a non-mutating check. License details: root LICENSE.md.
Generated lib/sw_apps sources must not be formatted independently.
"""

from pathlib import Path
import argparse
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
SW = ROOT / 'fpga/sw_repo'


def canonical_sources():
    """Yield only authored C inputs; omit generated applications and test mocks."""
    folders = [SW / 'templates', ROOT / 'fpga/vivado/gamebub_ipi_demo/software']
    for driver in sorted((SW / 'drivers').iterdir()):
        if driver.is_dir():
            folders.extend([driver / 'src', driver / 'examples'])
    return sorted(path for folder in folders for path in folder.iterdir()
                  if path.is_file() and path.suffix in ('.c', '.h'))


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument('--check', action='store_true', help='Reject formatting/template drift')
    cli.add_argument('--clang-format', default='clang-format', help='Formatter executable or path')
    args = cli.parse_args()
    formatter = shutil.which(args.clang_format)
    if not formatter:
        cli.error('clang-format not found; install it or pass --clang-format PATH')
    files = canonical_sources()
    command = [formatter, '--style=file:' + str(SW / '.clang-format')]
    command += ['--dry-run', '--Werror'] if args.check else ['-i']
    subprocess.run(command + [str(path) for path in files], check=True)
    # Canonical bytes, not another formatting pass, define generated sources.
    command = [sys.executable, str(SW / 'tools/generate_app_templates.py')]
    if args.check:
        command.append('--check')
    subprocess.run(command, check=True)
    print('SOFTWARE_STYLE_PASS', len(files), 'canonical C files')


if __name__ == '__main__':
    main()
