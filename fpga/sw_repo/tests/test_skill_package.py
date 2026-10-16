# SPDX-License-Identifier: 0BSD
"""Portable skill packaging checks; not an agent or MCP acceptance test."""
from pathlib import Path
import re
import unittest
import yaml

ROOT = Path(__file__).resolve().parents[3]


class SkillPackage(unittest.TestCase):
    def test_installation_guide_local_links(self):
        paths = [ROOT/'skills/README.md', ROOT/'skills/gamebub-vivado/SKILL.md',
                 ROOT/'docs/vivado/amd-ross-setup.md']
        for path in paths:
            for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
                if re.match(r'[a-z]+://', link) or link.startswith('#'):
                    continue
                with self.subTest(page=path.name, link=link):
                    self.assertTrue((path.parent/link.split('#')[0]).resolve().exists())

    def test_entrypoint_and_workflow_resources(self):
        folder = ROOT/'skills/gamebub-vivado'
        text = (folder/'SKILL.md').read_text(encoding='utf-8')
        sections = text.split('---', 2)
        self.assertEqual(sections[0], '')
        metadata = yaml.safe_load(sections[1])
        self.assertEqual(metadata['name'], folder.name)
        self.assertTrue(metadata['description'])
        self.assertEqual(metadata['license'], '0BSD')
        for name in ('README.md', 'QUICKSTART.md', 'docs/vivado/validation.md',
                     'docs/vivado/vitis-examples.md', 'docs/vivado/memory-cache.md',
                     'fpga/board_files/install_gamebub_current_repositories.tcl',
                     'fpga/sw_repo/templates/apps.json',
                     'fpga/sw_repo/tools/generate_app_templates.py',
                     'fpga/vivado/gamebub_ipi_demo/test_app_templates.py'):
            with self.subTest(resource=name):
                self.assertTrue((ROOT/name).is_file())


if __name__ == '__main__':
    unittest.main()
