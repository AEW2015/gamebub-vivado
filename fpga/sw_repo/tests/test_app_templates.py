# SPDX-License-Identifier: CERN-OHL-S-2.0
"""Portable source-drift, metadata and CMake binding negative tests."""
from pathlib import Path
import importlib.util
import json
import shutil
import subprocess
import tempfile
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[3]
SW = ROOT / 'fpga/sw_repo'
SPEC = importlib.util.spec_from_file_location('app_generator', SW / 'tools/generate_app_templates.py')
GEN = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GEN)


class NativeTemplates(unittest.TestCase):
    def test_generated_sources_match_canonical(self):
        apps, files = GEN.expected()
        self.assertEqual(len(apps), 19)
        for p, body in files.items():
            with self.subTest(path=p.relative_to(ROOT)):
                self.assertEqual(p.read_bytes(), body)

    def test_metadata_and_safe_defaults(self):
        apps = json.loads((SW / 'templates/apps.json').read_text())
        for app in apps:
            name = 'gamebub_' + app['name']
            root = SW / 'lib/sw_apps' / name
            meta = yaml.safe_load((root / 'data' / (name + '.yaml')).read_text())
            self.assertEqual(meta['type'], 'apps')
            self.assertEqual(meta['supported_processors'], ['microblaze_riscv'])
            self.assertEqual(meta['supported_os'], ['standalone'])
            self.assertEqual(meta['depends'], app['drivers'])
            self.assertEqual(meta['linker_constraints'], {'heap':0, 'stack':2048})
            self.assertIn('#define GB_ALLOW_DESTRUCTIVE 0', (root / 'src/gamebub_settings.h').read_text())
            self.assertIn('#define GB_ALLOW_RETIMING 0', (root / 'src/gamebub_settings.h').read_text())

    def run_binding(self, metadata, xparameters='', good=True, parent=5, motor=False):
        cmake = shutil.which('cmake')
        if not cmake:
            matches = list(Path('C:/Xilinx/2025.2/Vitis/tps').glob('**/cmake.exe'))
            cmake = str(matches[0]) if matches else None
        if not cmake:
            self.skipTest('CMake unavailable; native Vitis checks remain required')
        with tempfile.TemporaryDirectory(prefix='gb-app-bindings-') as folder:
            path = Path(folder)
            (path / 'include').mkdir()
            (path / 'hw_artifacts').mkdir()
            (path / 'include/xparameters.h').write_text(xparameters)
            (path / 'hw_artifacts/cpu_baremetal.dts').write_text(
                '/dts-v1/; / { renamed: interrupt-controller@ab000000 { compatible = "xlnx,axi-intc-4.1"; '
                'reg = <0xab000000 0x10000>; phandle = <0xb>; }; '
                'esp: endpoint@12340000 { compatible = "xlnx,gamebub-esp32-v102-1.14"; '
                'reg = <0x12340000 0x10000>; interrupt-parent = <' + ('&renamed' if parent == 5 else hex(parent)) + '>; }; };')
            script = 'cmake_minimum_required(VERSION 3.16)\n'
            script += f'set(CMAKE_CURRENT_BINARY_DIR "{path.as_posix()}")\nset(CMAKE_INCLUDE_PATH "{(path / "include").as_posix()}")\n'
            script += 'set(TOTAL_MEM_CONTROLLERS cpu_lmb_bram_if_cntlr_memory_0)\n'
            script += metadata + '\n'
            if motor:
                script += 'include("' + (SW / 'templates/gamebub_vibration.cmake').as_posix() + '")\n'
            script += 'include("' + (SW / 'templates/gamebub_bindings.cmake').as_posix() + '")\n'
            (path / 'check.cmake').write_text(script)
            result = subprocess.run([cmake, '-P', str(path / 'check.cmake')], capture_output=True, text=True, timeout=30)
            if good:
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                return (path / 'platform_bindings.h').read_text()
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_renamed_memory_and_nonreference_address(self):
        result = self.run_binding('set(GB_NATIVE_DEPS gbsram)\nset(GBSRAM_NUM_DRIVER_INSTANCES renamed_ram)\nset(GBSRAM0_PROP_LIST 0x12340000)',
            '#define XPAR_RENAMED_RAM_BASEADDR_1 0x90000000\n')
        self.assertIn('#define GB_SRAM_CTRL_BASE 0x12340000U', result)
        self.assertIn('#define GB_SRAM_MEMORY_BASE 0x90000000U', result)

    def test_ambiguous_gpio_rejected(self):
        self.run_binding('set(GB_NATIVE_DEPS gpio)\nset(GPIO_NUM_DRIVER_INSTANCES motor leds)\nset(GPIO0_PROP_LIST 0x12340000)', good=False)

    def test_missing_ram_aperture_rejected(self):
        self.run_binding('set(GB_NATIVE_DEPS gbsram)\nset(GBSRAM_NUM_DRIVER_INSTANCES renamed_ram)\nset(GBSRAM0_PROP_LIST 0x12340000)', good=False)

    def test_actual_irq_and_parent_checked(self):
        meta = 'set(GB_NATIVE_DEPS gbesp32 intc)\nset(GB_NATIVE_IRQ 1)\nset(GBESP32_NUM_DRIVER_INSTANCES esp)\nset(INTC_NUM_DRIVER_INSTANCES intc)\nset(GBESP320_PROP_LIST 0x12340000 0x2003)\nset(INTC0_PROP_LIST 0xab000000)'
        self.assertIn('#define GB_ESP32_IRQ 3U', self.run_binding(meta))
        self.assertIn('#define GB_ESP32_IRQ 3U', self.run_binding(meta, parent=11))
        self.run_binding(meta.replace('0x2003', '0x1003'), good=False)
        self.run_binding(meta, good=False, parent=9)

    def test_vibration_rejects_input_or_button_gpio(self):
        meta = 'set(GB_NATIVE_DEPS gpio)\nset(GPIO_NUM_DRIVER_INSTANCES motor)\nset(GPIO0_PROP_LIST 0x12340000 0x2 0x1)'
        self.assertIn('GB_VIBRATION_BASE 0x12340000U', self.run_binding(meta, motor=True))
        self.run_binding(meta.replace('0x2 0x1', '0xc 0x1'), motor=True, good=False)
        self.run_binding(meta.replace('0x2 0x1', '0x2 0x0'), motor=True, good=False)

    def test_external_boot_region_rejected(self):
        self.run_binding('set(TOTAL_MEM_CONTROLLERS external_sdram)', good=False)


if __name__ == '__main__':
    unittest.main()
