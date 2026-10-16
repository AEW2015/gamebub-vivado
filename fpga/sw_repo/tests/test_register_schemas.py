"""Source/schema structure checks; behavioral meaning is tested in RTL suites."""
from pathlib import Path
import json
import re
import unittest
import yaml

ROOT=Path(__file__).resolve().parents[3]


class RegisterSchemas(unittest.TestCase):
    def test_all_driver_headers_and_sources_bound(self):
        for driver in sorted((ROOT/'fpga/sw_repo/drivers').iterdir()):
            if not driver.is_dir(): continue
            with self.subTest(driver=driver.name):
                schema=json.loads((driver/'data/registers.json').read_text())
                offsets={int(str(r['offset']),0) if isinstance(r['offset'],str) else r['offset'] for r in schema['registers']}
                self.assertEqual(len(offsets),len(schema['registers']))
                for off in offsets: self.assertEqual(off%4,0)
                header=(driver/'src'/f'{driver.name}_hw.h').read_text()
                constants=re.findall(r'^#define\s+(\w+_OFFSET)\s+(0x[0-9a-fA-F]+|[0-9]+)[uUlL]*\s*$',header,re.M)
                self.assertTrue(constants)
                for name,value in constants:
                    self.assertIn(int(value,0),offsets,f'{name} is not reviewed in schema')
                for relative in schema['rtl_files']:
                    source=(ROOT/relative).resolve()
                    self.assertTrue(source.is_relative_to(ROOT))
                    self.assertTrue(source.is_file(),relative)
                meta=yaml.safe_load((driver/'data'/f'{driver.name}.yaml').read_text())
                self.assertEqual(meta['type'],'driver')
                self.assertEqual(meta['required'],['compatible','reg'])
                self.assertEqual(meta['config'],[{'gbesp32':'GBEsp32','gbaudio':'GBAudio','gbsram':'GBSram','gbsdram':'GBSdram'}[driver.name]+'_Config'])
                for example in meta.get('examples',{}):
                    self.assertTrue((driver/'examples'/example).is_file(),example)


if __name__=='__main__': unittest.main()
