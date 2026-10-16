# SPDX-License-Identifier: CERN-OHL-S-2.0
"""Compile the exact tester source with modeled peripherals, no hardware access."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

SW = Path(__file__).resolve().parents[1]


class AppTester(unittest.TestCase):
    def test_controls_rendering_guards_and_bounded_outputs(self):
        gcc = shutil.which('gcc')
        if os.name == 'nt' and Path('C:/msys64/ucrt64/bin/gcc.exe').is_file():
            gcc = 'C:/msys64/ucrt64/bin/gcc.exe'
        if not gcc:
            self.skipTest('GCC unavailable')
        env = dict(os.environ)
        env['PATH'] = str(Path(gcc).parent) + os.pathsep + env.get('PATH', '')
        with tempfile.TemporaryDirectory(prefix='gb-tester-') as folder:
            root = Path(folder)
            (root/'platform_bindings.h').write_text(
                '#define GB_VIBRATION_BASE 0x1000U\n#define GB_SRAM_MEMORY_SIZE 0x80000U\n#define GB_SDRAM_MEMORY_SIZE 0x2000000U\n')
            (root/'xgpio_l.h').write_text('#include "xil_io.h"\n#define XGPIO_DATA_OFFSET 0\n#define XGpio_WriteReg(b,o,v) Xil_Out32((b)+(o),(v))\n')
            (root/'sleep.h').write_text('/* no host sleeps */\n')
            (root/'xil_cache.h').write_text('void Xil_DCacheFlush(void);\nvoid Xil_DCacheDisable(void);\n')
            (root/'xil_printf.h').write_text('void print(const char*);\n')
            (root/'gamebub_settings.h').write_bytes((SW/'templates/app_tester_settings.h').read_bytes())
            includes = [root, SW/'templates', SW/'tests/mock_include']
            includes += [SW/'drivers'/d/'src' for d in ['gbesp32','gbaudio','gbsram','gbsdram']]
            for guarded in (True, False):
                exe = root/('guarded.exe' if guarded else 'enabled.exe')
                cmd = [gcc, '-std=c11', '-Wall', '-Wextra', '-Werror', '-O2']
                for include in includes:
                    cmd += ['-I', str(include)]
                if guarded:
                    cmd += ['-DGB_ALLOW_DESTRUCTIVE=0']
                cmd += [str(SW/'tests/test_app_tester.c'), '-o', str(exe)]
                result = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=60)
                self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
                result = subprocess.run([str(exe)], env=env, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
                self.assertIn('APP_TESTER_HOST_PASS', result.stdout)


if __name__ == '__main__':
    unittest.main()
