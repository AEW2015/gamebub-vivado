# SPDX-License-Identifier: 0BSD
"""Check the curated checkout's runtime assets without AMD tools."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
NS = {'s': 'http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009'}


class Distribution(unittest.TestCase):
    def test_current_catalog_files_are_self_contained(self):
        components = sorted((ROOT / 'fpga/ip_repo').glob('*/component.xml'))
        self.assertEqual(len(components), 8)
        for component in components:
            with self.subTest(package=component.parent.name):
                tree = ET.parse(component).getroot()
                for name in tree.findall('.//s:file/s:name', NS):
                    target = (component.parent / name.text).resolve()
                    self.assertTrue(target.is_relative_to(ROOT), name.text)
                    self.assertTrue(target.is_file(), name.text)

    def test_board_runtime_assets_exist(self):
        board = ROOT / 'fpga/board_files/gamebub_rev4/2.0'
        tree = ET.parse(board / 'board.xml').getroot()
        self.assertEqual(tree.findtext('file_version'), '2.0')
        self.assertTrue((board / tree.attrib['preset_file']).is_file())
        self.assertTrue((board / 'part0_pins.xml').is_file())
        for image in tree.findall('./images/image'):
            self.assertTrue((board / image.attrib['name']).is_file())
        interfaces = ROOT / 'fpga/board_files/interfaces'
        self.assertTrue(list(interfaces.rglob('bus.xml')))
        self.assertTrue(list(interfaces.rglob('abstraction.xml')))

    def test_license_and_entrypoints_exist(self):
        for relative in ('LICENSE.md', 'LICENSES/0BSD.txt',
                         'LICENSES/CERN-OHL-S-2.0.txt',
                         'LICENSES/GPL-3.0-only.txt', 'QUICKSTART.md',
                         'fpga/board_files/install_gamebub_current_repositories.tcl',
                         'fpga/vivado/gamebub_ipi_demo/create_design.tcl',
                         'fpga/vivado/gamebub_ipi_demo/create_workspace.py'):
            with self.subTest(path=relative):
                self.assertTrue((ROOT / relative).is_file())


if __name__ == '__main__':
    unittest.main()
