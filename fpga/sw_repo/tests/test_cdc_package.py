# SPDX-License-Identifier: 0BSD
"""Package regression guards; routed endpoint matching needs native Vivado."""
from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
NS = {'s':'http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009',
      'x':'http://www.xilinx.com'}


class CdcPackage(unittest.TestCase):
    def test_sdram_xdc_is_scoped_late_implementation_input(self):
        folder = ROOT/'fpga/ip_repo/gamebub_sdram_mem_v1_6'
        tree = ET.parse(folder/'component.xml').getroot()
        files = [f for f in tree.findall('.//s:file', NS)
                 if f.findtext('s:name', namespaces=NS)=='constraints/sdram_cdc.xdc']
        self.assertEqual(len(files), 1)
        types = [f.text for f in files[0].findall('s:userFileType', NS)]
        self.assertIn('SCOPED_TO_REF_gamebub_sdram_mem', types)
        self.assertIn('USED_IN_implementation', types)
        self.assertNotIn('USED_IN_synthesis', types)
        self.assertEqual(files[0].findtext('s:define/s:value', namespaces=NS), 'late')
        self.assertTrue((folder/'constraints/sdram_cdc.xdc').is_file())

    def test_cdc_constraints_use_pure_xdc_without_blanket_clock_cuts(self):
        for core, name in [('gamebub_sdram_mem_v1_6','sdram_cdc.xdc'),
                           ('gamebub_esp32_v102_v1_14','esp32_cdc.xdc')]:
            path = ROOT/'fpga/ip_repo'/core/'constraints'/name
            commands = '\n'.join(line for line in path.read_text().splitlines()
                                 if line.strip() and not line.lstrip().startswith('#'))
            self.assertNotRegex(commands, r'(?m)^\s*(if|foreach|proc|while|for)\s')
            self.assertNotIn('set_clock_groups', commands)
            self.assertNotRegex(commands, r'set_false_path[^\n]*get_clocks')


if __name__ == '__main__':
    unittest.main()
